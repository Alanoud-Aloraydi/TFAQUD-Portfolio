-- Transaction-wide care invariants, installed with the initial migration.
CREATE FUNCTION guard_account_care() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.app_mode IS NOT NULL AND
       NEW.app_mode IS DISTINCT FROM OLD.app_mode THEN
        RAISE EXCEPTION 'An assigned account mode cannot change'
            USING ERRCODE = '23514';
    END IF;
    IF NEW.first_name IS NULL AND (
        EXISTS (SELECT 1 FROM patient WHERE account_id = NEW.id) OR
        EXISTS (SELECT 1 FROM care_circle_manager WHERE account_id = NEW.id)
    ) THEN
        RAISE EXCEPTION 'Care requires a complete account profile'
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER guard_account_care
BEFORE UPDATE ON account FOR EACH ROW EXECUTE FUNCTION guard_account_care();

CREATE FUNCTION lock_care_parent() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    old_circle uuid;
    new_circle uuid;
BEGIN
    IF TG_OP <> 'INSERT' THEN old_circle := OLD.care_circle_id; END IF;
    IF TG_OP <> 'DELETE' THEN new_circle := NEW.care_circle_id; END IF;
    IF TG_TABLE_NAME = 'care_circle_manager' AND TG_OP <> 'DELETE' THEN
        PERFORM 1 FROM account WHERE id = NEW.account_id FOR UPDATE;
        IF NOT EXISTS (
            SELECT 1 FROM account WHERE id = NEW.account_id
            AND app_mode = 'detailed' AND first_name IS NOT NULL
        ) THEN
            RAISE EXCEPTION 'Managers require complete detailed accounts'
                USING ERRCODE = '23514';
        END IF;
    END IF;
    PERFORM 1 FROM care_circle
        WHERE id IN (old_circle, new_circle) ORDER BY id FOR UPDATE;
    IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER lock_patient_circle
BEFORE INSERT OR UPDATE OR DELETE ON patient
FOR EACH ROW EXECUTE FUNCTION lock_care_parent();

CREATE TRIGGER lock_manager_circle
BEFORE INSERT OR UPDATE OR DELETE ON care_circle_manager
FOR EACH ROW EXECUTE FUNCTION lock_care_parent();

CREATE FUNCTION assert_care_circle(circle_key uuid) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
    patient_count integer;
    manager_count integer;
    patient_account uuid;
    patient_mode text;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM care_circle WHERE id = circle_key) THEN
        RETURN;
    END IF;
    SELECT count(*) INTO patient_count FROM patient
        WHERE care_circle_id = circle_key;
    SELECT count(*) INTO manager_count FROM care_circle_manager
        WHERE care_circle_id = circle_key;
    IF patient_count <> 1 OR manager_count < 1 THEN
        RAISE EXCEPTION 'A circle requires one patient and at least one manager'
            USING ERRCODE = '23514';
    END IF;
    SELECT account_id INTO patient_account FROM patient
        WHERE care_circle_id = circle_key;
    IF patient_account IS NOT NULL THEN
        SELECT app_mode INTO patient_mode FROM account
            WHERE id = patient_account AND first_name IS NOT NULL;
        IF patient_mode IS NULL THEN
            RAISE EXCEPTION 'An active patient requires a complete account'
                USING ERRCODE = '23514';
        END IF;
        IF patient_mode = 'detailed' AND NOT EXISTS (
            SELECT 1 FROM care_circle_manager
            WHERE care_circle_id = circle_key AND account_id = patient_account
        ) THEN
            RAISE EXCEPTION 'A detailed patient must manage their own circle'
                USING ERRCODE = '23514';
        END IF;
    END IF;
END;
$$;

CREATE FUNCTION check_care_circle() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_TABLE_NAME = 'care_circle' THEN
        IF TG_OP <> 'DELETE' THEN PERFORM assert_care_circle(NEW.id); END IF;
        IF TG_OP <> 'INSERT' THEN PERFORM assert_care_circle(OLD.id); END IF;
    ELSE
        IF TG_OP <> 'DELETE' THEN
            PERFORM assert_care_circle(NEW.care_circle_id);
        END IF;
        IF TG_OP <> 'INSERT' THEN
            PERFORM assert_care_circle(OLD.care_circle_id);
        END IF;
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER check_circle_complete
AFTER INSERT OR UPDATE ON care_circle DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_care_circle();

CREATE CONSTRAINT TRIGGER check_patient_circle_complete
AFTER INSERT OR UPDATE OR DELETE ON patient DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_care_circle();

CREATE CONSTRAINT TRIGGER check_manager_circle_complete
AFTER INSERT OR UPDATE OR DELETE ON care_circle_manager
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_care_circle();
