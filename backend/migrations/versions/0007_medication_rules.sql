-- Serialize medication changes per patient before deferred checks run.
CREATE FUNCTION lock_medication_patient() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    old_patient uuid;
    new_patient uuid;
    patient_key uuid;
BEGIN
    IF TG_TABLE_NAME = 'medication_plan' THEN
        IF TG_OP <> 'INSERT' THEN old_patient := OLD.patient_id; END IF;
        IF TG_OP <> 'DELETE' THEN new_patient := NEW.patient_id; END IF;
    ELSIF TG_TABLE_NAME = 'medication_plan_version' THEN
        IF TG_OP <> 'INSERT' THEN
            SELECT patient_id INTO old_patient FROM medication_plan
            WHERE id = OLD.medication_plan_id;
        END IF;
        IF TG_OP <> 'DELETE' THEN
            SELECT patient_id INTO new_patient FROM medication_plan
            WHERE id = NEW.medication_plan_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'medication_schedule' THEN
        IF TG_OP <> 'INSERT' THEN
            SELECT p.patient_id INTO old_patient
            FROM medication_plan p
            JOIN medication_plan_version v
                ON v.medication_plan_id = p.id
            WHERE v.id = OLD.plan_version_id;
        END IF;
        IF TG_OP <> 'DELETE' THEN
            SELECT p.patient_id INTO new_patient
            FROM medication_plan p
            JOIN medication_plan_version v
                ON v.medication_plan_id = p.id
            WHERE v.id = NEW.plan_version_id;
        END IF;
    ELSE
        IF TG_OP <> 'INSERT' THEN
            SELECT p.patient_id INTO old_patient
            FROM medication_plan p
            JOIN medication_plan_version v
                ON v.medication_plan_id = p.id
            JOIN medication_schedule s ON s.plan_version_id = v.id
            WHERE s.id = OLD.schedule_id;
        END IF;
        IF TG_OP <> 'DELETE' THEN
            SELECT p.patient_id INTO new_patient
            FROM medication_plan p
            JOIN medication_plan_version v
                ON v.medication_plan_id = p.id
            JOIN medication_schedule s ON s.plan_version_id = v.id
            WHERE s.id = NEW.schedule_id;
        END IF;
    END IF;

    FOR patient_key IN
        SELECT id FROM patient
        WHERE id IN (old_patient, new_patient)
        ORDER BY id
    LOOP
        PERFORM 1 FROM patient WHERE id = patient_key FOR UPDATE;
    END LOOP;
    IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER lock_medication_plan_patient
BEFORE INSERT OR UPDATE OR DELETE ON medication_plan
FOR EACH ROW EXECUTE FUNCTION lock_medication_patient();

CREATE TRIGGER lock_medication_version_patient
BEFORE INSERT OR UPDATE OR DELETE ON medication_plan_version
FOR EACH ROW EXECUTE FUNCTION lock_medication_patient();

CREATE TRIGGER lock_medication_schedule_patient
BEFORE INSERT OR UPDATE OR DELETE ON medication_schedule
FOR EACH ROW EXECUTE FUNCTION lock_medication_patient();

CREATE TRIGGER lock_medication_day_patient
BEFORE INSERT OR UPDATE OR DELETE ON medication_schedule_day
FOR EACH ROW EXECUTE FUNCTION lock_medication_patient();

CREATE FUNCTION medication_treatment_period(
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
            (plan_row.discontinued_at AT TIME ZONE 'Asia/Riyadh')::date + 1,
            'infinity'::date
        )
    );
BEGIN
    IF starts_on >= ends_on THEN RETURN 'empty'::daterange; END IF;
    RETURN daterange(starts_on, ends_on, '[)');
END;
$$;

CREATE FUNCTION assert_medication_plan(plan_key uuid) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
    plan_row medication_plan%ROWTYPE;
BEGIN
    SELECT * INTO plan_row FROM medication_plan WHERE id = plan_key;
    IF NOT FOUND THEN RETURN; END IF;

    IF (SELECT count(*) FROM medication_plan_version
        WHERE medication_plan_id = plan_key
          AND effective_until_on IS NULL) <> 1 THEN
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
          AND NOT EXISTS (
              SELECT 1 FROM medication_schedule_day d
              WHERE d.schedule_id = s.id
          )
    ) THEN
        RAISE EXCEPTION 'Each medication schedule requires a weekday'
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
          ON other.patient_id = plan_row.patient_id
         AND other.id <> plan_row.id
        JOIN medication_plan_version other_version
          ON other_version.medication_plan_id = other.id
         AND other_version.normalized_name = own_version.normalized_name
        WHERE own_version.medication_plan_id = plan_row.id
          AND medication_treatment_period(plan_row, own_version)
              && medication_treatment_period(other, other_version)
    ) THEN
        RAISE EXCEPTION 'Medication treatment periods overlap'
            USING ERRCODE = '23514';
    END IF;
END;
$$;

CREATE FUNCTION check_medication_plan() RETURNS trigger
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
        PERFORM assert_medication_plan(new_plan);
    END IF;
    IF old_plan IS NOT NULL AND old_plan IS DISTINCT FROM new_plan THEN
        PERFORM assert_medication_plan(old_plan);
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER check_medication_plan_complete
AFTER INSERT OR UPDATE OR DELETE ON medication_plan
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_medication_plan();

CREATE CONSTRAINT TRIGGER check_medication_version_complete
AFTER INSERT OR UPDATE OR DELETE ON medication_plan_version
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_medication_plan();

CREATE CONSTRAINT TRIGGER check_medication_schedule_complete
AFTER INSERT OR UPDATE OR DELETE ON medication_schedule
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_medication_plan();

CREATE CONSTRAINT TRIGGER check_medication_day_complete
AFTER INSERT OR UPDATE OR DELETE ON medication_schedule_day
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_medication_plan();

CREATE FUNCTION check_medication_dose() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM medication_schedule s
        JOIN medication_schedule_day d ON d.schedule_id = s.id
        JOIN medication_plan_version v ON v.id = s.plan_version_id
        JOIN medication_plan p ON p.id = v.medication_plan_id
        WHERE s.id = NEW.schedule_id
          AND d.weekday = extract(isodow FROM NEW.scheduled_on)
          AND NEW.scheduled_on >= v.treatment_starts_on
          AND (
              v.treatment_ends_on IS NULL
              OR NEW.scheduled_on <= v.treatment_ends_on
          )
          AND NEW.scheduled_on >= v.effective_from_on
          AND (
              v.effective_until_on IS NULL
              OR NEW.scheduled_on < v.effective_until_on
          )
          AND (
              p.discontinued_at IS NULL
              OR (NEW.scheduled_on + s.time_of_day)
                  AT TIME ZONE 'Asia/Riyadh' < p.discontinued_at
          )
    ) THEN
        RAISE EXCEPTION 'Dose date does not belong to this schedule'
            USING ERRCODE = '23514';
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER check_medication_dose_valid
AFTER INSERT OR UPDATE ON medication_dose_record
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_medication_dose();
