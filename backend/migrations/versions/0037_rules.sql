-- The care and medication rules of the database, on the merged care circle
-- (migration 0037). Functions are fn_<rule>; triggers are
-- trg_<table>_<rule>, and each fires only on the columns its rule reads.

-- ---------------------------------------------------------------------
-- Accounts: the mode is assigned once, and an account that cares keeps
-- its profile (a patient also keeps the birth date and city the circle
-- reads from it).
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_guard_account_care() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.app_mode IS NOT NULL AND
       NEW.app_mode IS DISTINCT FROM OLD.app_mode THEN
        RAISE EXCEPTION 'An assigned account mode cannot change'
            USING ERRCODE = '23514';
    END IF;
    IF NEW.first_name IS NULL AND (
        EXISTS (SELECT 1 FROM care_circle WHERE account_id = NEW.id) OR
        EXISTS (SELECT 1 FROM care_circle_manager WHERE account_id = NEW.id)
    ) THEN
        RAISE EXCEPTION 'Care requires a complete account profile'
            USING ERRCODE = '23514';
    END IF;
    IF (NEW.birth_date IS NULL OR NEW.city IS NULL) AND
       EXISTS (SELECT 1 FROM care_circle WHERE account_id = NEW.id) THEN
        RAISE EXCEPTION 'A patient keeps the birth date and city'
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_account_guard_care
BEFORE UPDATE OF app_mode, first_name, last_name, display_name,
    birth_date, city ON account
FOR EACH ROW EXECUTE FUNCTION fn_guard_account_care();

-- ---------------------------------------------------------------------
-- Locks: a circle change takes the linked account first, then the
-- circle, in the order the server takes them, so two changes to one
-- circle run one after the other.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_lock_care_circle() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    old_circle uuid;
    new_circle uuid;
BEGIN
    IF TG_TABLE_NAME = 'care_circle' THEN
        IF TG_OP <> 'DELETE' AND NEW.account_id IS NOT NULL THEN
            PERFORM 1 FROM account WHERE id = NEW.account_id FOR UPDATE;
        END IF;
        IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
        RETURN NEW;
    END IF;
    IF TG_OP <> 'INSERT' THEN old_circle := OLD.care_circle_id; END IF;
    IF TG_OP <> 'DELETE' THEN
        new_circle := NEW.care_circle_id;
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

CREATE TRIGGER trg_care_circle_lock
BEFORE INSERT OR UPDATE OF account_id ON care_circle
FOR EACH ROW EXECUTE FUNCTION fn_lock_care_circle();

CREATE TRIGGER trg_care_circle_manager_lock
BEFORE INSERT OR UPDATE OR DELETE ON care_circle_manager
FOR EACH ROW EXECUTE FUNCTION fn_lock_care_circle();

-- ---------------------------------------------------------------------
-- A complete circle, checked when the transaction commits: at least one
-- manager; a patient with an account has a complete account with a birth
-- date and a city, and manages the circle when in the detailed mode.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_assert_care_circle(circle_key uuid) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
    circle_row care_circle%ROWTYPE;
    manager_count integer;
    patient_mode text;
BEGIN
    SELECT * INTO circle_row FROM care_circle WHERE id = circle_key;
    IF NOT FOUND THEN RETURN; END IF;
    SELECT count(*) INTO manager_count FROM care_circle_manager
        WHERE care_circle_id = circle_key;
    IF manager_count < 1 THEN
        RAISE EXCEPTION 'A circle requires at least one manager'
            USING ERRCODE = '23514';
    END IF;
    IF circle_row.account_id IS NOT NULL THEN
        SELECT app_mode INTO patient_mode FROM account
            WHERE id = circle_row.account_id
              AND first_name IS NOT NULL
              AND birth_date IS NOT NULL
              AND city IS NOT NULL;
        IF patient_mode IS NULL THEN
            RAISE EXCEPTION 'An active patient requires a complete account'
                USING ERRCODE = '23514';
        END IF;
        IF patient_mode = 'detailed' AND NOT EXISTS (
            SELECT 1 FROM care_circle_manager
            WHERE care_circle_id = circle_key
              AND account_id = circle_row.account_id
        ) THEN
            RAISE EXCEPTION 'A detailed patient must manage their own circle'
                USING ERRCODE = '23514';
        END IF;
    END IF;
END;
$$;

CREATE FUNCTION fn_check_care_circle() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF TG_TABLE_NAME = 'care_circle' THEN
        PERFORM fn_assert_care_circle(NEW.id);
    ELSE
        IF TG_OP <> 'DELETE' THEN
            PERFORM fn_assert_care_circle(NEW.care_circle_id);
        END IF;
        IF TG_OP <> 'INSERT' THEN
            PERFORM fn_assert_care_circle(OLD.care_circle_id);
        END IF;
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER trg_care_circle_check_complete
AFTER INSERT OR UPDATE OF account_id ON care_circle
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_check_care_circle();

CREATE CONSTRAINT TRIGGER trg_care_circle_manager_check_complete
AFTER INSERT OR UPDATE OR DELETE ON care_circle_manager
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_check_care_circle();

-- ---------------------------------------------------------------------
-- Medicines: every change to a medicine locks its circle first, so the
-- deferred checks below see one change at a time.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_lock_medication_circle() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    old_circle uuid;
    new_circle uuid;
    circle_key uuid;
BEGIN
    IF TG_TABLE_NAME = 'medication_plan' THEN
        IF TG_OP <> 'INSERT' THEN old_circle := OLD.care_circle_id; END IF;
        IF TG_OP <> 'DELETE' THEN new_circle := NEW.care_circle_id; END IF;
    ELSIF TG_TABLE_NAME = 'medication_plan_version' THEN
        IF TG_OP <> 'INSERT' THEN
            SELECT care_circle_id INTO old_circle FROM medication_plan
            WHERE id = OLD.medication_plan_id;
        END IF;
        IF TG_OP <> 'DELETE' THEN
            SELECT care_circle_id INTO new_circle FROM medication_plan
            WHERE id = NEW.medication_plan_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'medication_schedule' THEN
        IF TG_OP <> 'INSERT' THEN
            SELECT p.care_circle_id INTO old_circle
            FROM medication_plan p
            JOIN medication_plan_version v
                ON v.medication_plan_id = p.id
            WHERE v.id = OLD.plan_version_id;
        END IF;
        IF TG_OP <> 'DELETE' THEN
            SELECT p.care_circle_id INTO new_circle
            FROM medication_plan p
            JOIN medication_plan_version v
                ON v.medication_plan_id = p.id
            WHERE v.id = NEW.plan_version_id;
        END IF;
    ELSE
        IF TG_OP <> 'INSERT' THEN
            SELECT p.care_circle_id INTO old_circle
            FROM medication_plan p
            JOIN medication_plan_version v
                ON v.medication_plan_id = p.id
            JOIN medication_schedule s ON s.plan_version_id = v.id
            WHERE s.id = OLD.schedule_id;
        END IF;
        IF TG_OP <> 'DELETE' THEN
            SELECT p.care_circle_id INTO new_circle
            FROM medication_plan p
            JOIN medication_plan_version v
                ON v.medication_plan_id = p.id
            JOIN medication_schedule s ON s.plan_version_id = v.id
            WHERE s.id = NEW.schedule_id;
        END IF;
    END IF;
    FOR circle_key IN
        SELECT id FROM care_circle
        WHERE id IN (old_circle, new_circle)
        ORDER BY id
    LOOP
        PERFORM 1 FROM care_circle WHERE id = circle_key FOR UPDATE;
    END LOOP;
    IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_medication_plan_lock
BEFORE INSERT OR UPDATE OR DELETE ON medication_plan
FOR EACH ROW EXECUTE FUNCTION fn_lock_medication_circle();
CREATE TRIGGER trg_medication_plan_version_lock
BEFORE INSERT OR UPDATE OR DELETE ON medication_plan_version
FOR EACH ROW EXECUTE FUNCTION fn_lock_medication_circle();
CREATE TRIGGER trg_medication_schedule_lock
BEFORE INSERT OR UPDATE OR DELETE ON medication_schedule
FOR EACH ROW EXECUTE FUNCTION fn_lock_medication_circle();
CREATE TRIGGER trg_medication_schedule_day_lock
BEFORE INSERT OR UPDATE OR DELETE ON medication_schedule_day
FOR EACH ROW EXECUTE FUNCTION fn_lock_medication_circle();
CREATE TRIGGER trg_medication_schedule_month_day_lock
BEFORE INSERT OR UPDATE OR DELETE ON medication_schedule_month_day
FOR EACH ROW EXECUTE FUNCTION fn_lock_medication_circle();

-- The days a medicine version runs: from the later of its treatment start
-- and its own start, to the earliest of its treatment end, its own end and
-- the day it was stopped in the patient's own zone. A cancelled version
-- runs on no day.
CREATE FUNCTION fn_medication_treatment_period(
    plan_row medication_plan,
    version_row medication_plan_version
) RETURNS daterange
LANGUAGE plpgsql STABLE AS $$
DECLARE
    starts_on date := greatest(
        version_row.treatment_starts_on,
        version_row.effective_from_on
    );
    ends_on date := least(
        COALESCE(version_row.treatment_ends_on + 1, 'infinity'::date),
        COALESCE(version_row.effective_until_on, 'infinity'::date),
        COALESCE(
            (plan_row.stopped_at AT TIME ZONE (
                SELECT time_zone FROM care_circle
                WHERE id = plan_row.care_circle_id
            ))::date + 1,
            'infinity'::date
        )
    );
BEGIN
    IF version_row.cancelled_at IS NOT NULL THEN
        RETURN 'empty'::daterange;
    END IF;
    IF starts_on >= ends_on THEN RETURN 'empty'::daterange; END IF;
    RETURN daterange(starts_on, ends_on, '[)');
END;
$$;

CREATE FUNCTION fn_assert_medication_plan(plan_key uuid) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
    plan_row medication_plan%ROWTYPE;
BEGIN
    SELECT * INTO plan_row FROM medication_plan WHERE id = plan_key;
    IF NOT FOUND THEN RETURN; END IF;
    IF (SELECT count(*) FROM medication_plan_version
        WHERE medication_plan_id = plan_key
          AND effective_until_on IS NULL
          AND cancelled_at IS NULL) <> 1 THEN
        RAISE EXCEPTION 'A medication plan needs one open version'
            USING ERRCODE = '23514';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM (
            SELECT effective_until_on,
                   lead(effective_from_on) OVER (
                       ORDER BY effective_from_on
                   ) AS next_from
            FROM medication_plan_version
            WHERE medication_plan_id = plan_key
              AND cancelled_at IS NULL
        ) periods
        WHERE next_from IS NOT NULL
          AND effective_until_on IS DISTINCT FROM next_from
    ) THEN
        RAISE EXCEPTION 'Medication revisions must be contiguous'
            USING ERRCODE = '23514';
    END IF;
    IF EXISTS (
        SELECT 1 FROM medication_plan_version v
        WHERE v.medication_plan_id = plan_key
          AND NOT EXISTS (
              SELECT 1 FROM medication_schedule s
              WHERE s.plan_version_id = v.id
          )
    ) THEN
        RAISE EXCEPTION 'Each medication version requires a schedule'
            USING ERRCODE = '23514';
    END IF;
    IF EXISTS (
        SELECT 1 FROM medication_schedule s
        JOIN medication_plan_version v ON v.id = s.plan_version_id
        WHERE v.medication_plan_id = plan_key
          AND s.repeat = 'weekly'
          AND (
              NOT EXISTS (
                  SELECT 1 FROM medication_schedule_day d
                  WHERE d.schedule_id = s.id
              )
              OR EXISTS (
                  SELECT 1 FROM medication_schedule_month_day m
                  WHERE m.schedule_id = s.id
              )
          )
    ) THEN
        RAISE EXCEPTION 'Each medication schedule requires a weekday'
            USING ERRCODE = '23514';
    END IF;
    IF EXISTS (
        SELECT 1 FROM medication_schedule s
        JOIN medication_plan_version v ON v.id = s.plan_version_id
        WHERE v.medication_plan_id = plan_key
          AND s.repeat = 'monthly'
          AND (
              NOT EXISTS (
                  SELECT 1 FROM medication_schedule_month_day m
                  WHERE m.schedule_id = s.id
              )
              OR EXISTS (
                  SELECT 1 FROM medication_schedule_day d
                  WHERE d.schedule_id = s.id
              )
          )
    ) THEN
        RAISE EXCEPTION 'Each monthly schedule requires a day of the month'
            USING ERRCODE = '23514';
    END IF;
    IF EXISTS (
        SELECT 1 FROM medication_schedule s
        JOIN medication_plan_version v ON v.id = s.plan_version_id
        WHERE v.medication_plan_id = plan_key
          AND s.repeat = 'interval'
          AND (
              EXISTS (
                  SELECT 1 FROM medication_schedule_day d
                  WHERE d.schedule_id = s.id
              )
              OR EXISTS (
                  SELECT 1 FROM medication_schedule_month_day m
                  WHERE m.schedule_id = s.id
              )
          )
    ) THEN
        RAISE EXCEPTION 'An interval schedule has no weekdays or month days'
            USING ERRCODE = '23514';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM medication_schedule s
        JOIN medication_schedule_day d ON d.schedule_id = s.id
        JOIN medication_plan_version v ON v.id = s.plan_version_id
        WHERE v.medication_plan_id = plan_key
        GROUP BY v.id, d.weekday, s.time_of_day
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION 'Medication times cannot overlap on one weekday'
            USING ERRCODE = '23514';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM medication_schedule s
        JOIN medication_schedule_month_day m ON m.schedule_id = s.id
        JOIN medication_plan_version v ON v.id = s.plan_version_id
        WHERE v.medication_plan_id = plan_key
        GROUP BY v.id, m.month_day, s.time_of_day
        HAVING count(*) > 1
    ) OR EXISTS (
        SELECT 1
        FROM medication_schedule a
        JOIN medication_schedule b
          ON b.plan_version_id = a.plan_version_id
         AND b.time_of_day = a.time_of_day
         AND b.id > a.id
        JOIN medication_plan_version v ON v.id = a.plan_version_id
        WHERE v.medication_plan_id = plan_key
          AND (
              a.repeat <> b.repeat
              OR a.repeat = 'interval'
              OR (
                  a.repeat = 'monthly'
                  AND EXISTS (
                      SELECT 1 FROM medication_schedule_month_day x
                      WHERE x.schedule_id = a.id AND x.month_day >= 28
                  )
                  AND EXISTS (
                      SELECT 1 FROM medication_schedule_month_day y
                      WHERE y.schedule_id = b.id AND y.month_day >= 28
                  )
              )
          )
    ) THEN
        RAISE EXCEPTION 'Medication times cannot overlap on one day'
            USING ERRCODE = '23514';
    END IF;
    IF EXISTS (
        SELECT 1 FROM medication_schedule s
        JOIN medication_plan_version v ON v.id = s.plan_version_id
        WHERE v.medication_plan_id = plan_key
          AND (v.dosage_form, s.dose_unit) NOT IN (
              ('tablet', 'tablet'),
              ('capsule', 'capsule'),
              ('liquid', 'mL'),
              ('drops', 'drop'),
              ('inhaler', 'puff'),
              ('injection', 'mL'),
              ('injection', 'unit')
          )
    ) THEN
        RAISE EXCEPTION 'Dose unit does not match the dosage form'
            USING ERRCODE = '23514';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM medication_plan_version own_version
        JOIN medication_plan other
          ON other.care_circle_id = plan_row.care_circle_id
         AND other.id <> plan_row.id
        JOIN medication_plan_version other_version
          ON other_version.medication_plan_id = other.id
         AND other_version.normalized_name = own_version.normalized_name
        WHERE own_version.medication_plan_id = plan_row.id
          AND fn_medication_treatment_period(plan_row, own_version)
              && fn_medication_treatment_period(other, other_version)
    ) THEN
        RAISE EXCEPTION 'Medication treatment periods overlap'
            USING ERRCODE = '23514';
    END IF;
END;
$$;

CREATE FUNCTION fn_check_medication_plan() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    old_plan uuid;
    new_plan uuid;
BEGIN
    IF TG_TABLE_NAME = 'medication_plan' THEN
        IF TG_OP <> 'INSERT' THEN old_plan := OLD.id; END IF;
        IF TG_OP <> 'DELETE' THEN new_plan := NEW.id; END IF;
    ELSIF TG_TABLE_NAME = 'medication_plan_version' THEN
        IF TG_OP <> 'INSERT' THEN old_plan := OLD.medication_plan_id; END IF;
        IF TG_OP <> 'DELETE' THEN new_plan := NEW.medication_plan_id; END IF;
    ELSIF TG_TABLE_NAME = 'medication_schedule' THEN
        IF TG_OP <> 'INSERT' THEN
            SELECT medication_plan_id INTO old_plan
            FROM medication_plan_version
            WHERE id = OLD.plan_version_id;
        END IF;
        IF TG_OP <> 'DELETE' THEN
            SELECT medication_plan_id INTO new_plan
            FROM medication_plan_version
            WHERE id = NEW.plan_version_id;
        END IF;
    ELSE
        IF TG_OP <> 'INSERT' THEN
            SELECT v.medication_plan_id INTO old_plan
            FROM medication_schedule s
            JOIN medication_plan_version v ON v.id = s.plan_version_id
            WHERE s.id = OLD.schedule_id;
        END IF;
        IF TG_OP <> 'DELETE' THEN
            SELECT v.medication_plan_id INTO new_plan
            FROM medication_schedule s
            JOIN medication_plan_version v ON v.id = s.plan_version_id
            WHERE s.id = NEW.schedule_id;
        END IF;
    END IF;
    IF new_plan IS NOT NULL THEN
        PERFORM fn_assert_medication_plan(new_plan);
    END IF;
    IF old_plan IS NOT NULL AND old_plan IS DISTINCT FROM new_plan THEN
        PERFORM fn_assert_medication_plan(old_plan);
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER trg_medication_plan_check_complete
AFTER INSERT OR UPDATE OF care_circle_id, stopped_at OR DELETE
ON medication_plan
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_check_medication_plan();
CREATE CONSTRAINT TRIGGER trg_medication_plan_version_check_complete
AFTER INSERT OR UPDATE OF medication_plan_id, normalized_name,
    dosage_form, treatment_starts_on, treatment_ends_on,
    effective_from_on, effective_until_on, cancelled_at OR DELETE
ON medication_plan_version
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_check_medication_plan();
CREATE CONSTRAINT TRIGGER trg_medication_schedule_check_complete
AFTER INSERT OR UPDATE OF plan_version_id, time_of_day, dose_unit,
    repeat, interval_days OR DELETE
ON medication_schedule
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_check_medication_plan();
CREATE CONSTRAINT TRIGGER trg_medication_schedule_day_check_complete
AFTER INSERT OR UPDATE OR DELETE ON medication_schedule_day
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_check_medication_plan();
CREATE CONSTRAINT TRIGGER trg_medication_schedule_month_day_check_complete
AFTER INSERT OR UPDATE OR DELETE ON medication_schedule_month_day
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_check_medication_plan();

-- A dose record's date is a day its schedule has a dose: on the version's
-- days, inside its dates, and before the medicine was stopped (in the
-- patient's own zone).
CREATE FUNCTION fn_check_medication_dose() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM medication_schedule s
        JOIN medication_plan_version v ON v.id = s.plan_version_id
        JOIN medication_plan p ON p.id = v.medication_plan_id
        JOIN care_circle c ON c.id = p.care_circle_id
        WHERE s.id = NEW.schedule_id
          AND (
              (
                  s.repeat = 'weekly'
                  AND EXISTS (
                      SELECT 1 FROM medication_schedule_day d
                      WHERE d.schedule_id = s.id
                        AND d.weekday = extract(isodow FROM NEW.scheduled_on)
                  )
              )
              OR (
                  s.repeat = 'monthly'
                  AND EXISTS (
                      SELECT 1 FROM medication_schedule_month_day m
                      WHERE m.schedule_id = s.id
                        AND least(
                            m.month_day,
                            extract(day FROM (
                                date_trunc('month', NEW.scheduled_on)
                                + interval '1 month - 1 day'
                            ))::int
                        ) = extract(day FROM NEW.scheduled_on)::int
                  )
              )
              OR (
                  s.repeat = 'interval'
                  AND (NEW.scheduled_on - v.treatment_starts_on)
                      % s.interval_days = 0
              )
          )
          AND NEW.scheduled_on >= v.treatment_starts_on
          AND (
              v.treatment_ends_on IS NULL
              OR NEW.scheduled_on <= v.treatment_ends_on
          )
          AND v.cancelled_at IS NULL
          AND NEW.scheduled_on >= v.effective_from_on
          AND (
              v.effective_until_on IS NULL
              OR NEW.scheduled_on < v.effective_until_on
          )
          AND (
              p.stopped_at IS NULL
              OR (NEW.scheduled_on + s.time_of_day)
                  AT TIME ZONE c.time_zone < p.stopped_at
          )
    ) THEN
        RAISE EXCEPTION 'Dose date does not belong to this schedule'
            USING ERRCODE = '23514';
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER trg_medication_dose_record_check_valid
AFTER INSERT OR UPDATE OF schedule_id, scheduled_on
ON medication_dose_record
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_check_medication_dose();
