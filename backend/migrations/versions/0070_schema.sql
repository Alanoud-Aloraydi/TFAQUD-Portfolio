-- The whole database of TFAQUD, as migrations 0001 to 0070 left it.
--
-- Revision 0070 runs this file on a new, empty database. Every later change
-- is a migration of its own (0071 on). Tables come in the order their
-- foreign keys need: each with its columns, its rules (checks, keys) and
-- its indexes. The one function a check calls comes first; the functions
-- the triggers call, and the triggers that keep the rules across tables,
-- come last.

-- The function a check calls ---------------------------------------------

CREATE FUNCTION fn_measurement_conditions_unique(items text[])
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
AS $function$
            SELECT cardinality(items) =
                cardinality(ARRAY(SELECT DISTINCT unnest(items)));
        $function$;

-- account -----------------------------------------------------------------
CREATE TABLE account (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    phone_number text NOT NULL,
    first_name text,
    last_name text,
    display_name text,
    app_mode text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    birth_date date,
    city text,
    avatar_code text,
    CONSTRAINT pk_account PRIMARY KEY (id),
    CONSTRAINT uq_account_phone_number UNIQUE (phone_number),
    CONSTRAINT ck_account_app_mode CHECK ((app_mode = ANY (ARRAY['detailed'::text, 'simplified'::text]))),
    CONSTRAINT ck_account_avatar_code CHECK (((avatar_code IS NULL) OR (avatar_code = ANY (ARRAY['w1_1'::text, 'w1_3'::text, 'w6_1'::text, 'w6_3'::text, 'w7_1'::text, 'w7_3'::text, 'm1_1'::text, 'm1_3'::text, 'm2_1'::text, 'm2_3'::text, 'm6_1'::text, 'm6_3'::text, 'sh_1'::text, 'sh_3'::text, 'gh_3'::text])))),
    CONSTRAINT ck_account_birth_date CHECK (((birth_date IS NULL) OR (birth_date >= '1900-01-01'::date))),
    CONSTRAINT ck_account_city CHECK (((city IS NULL) OR ((length(btrim(city)) >= 1) AND (length(btrim(city)) <= 60)))),
    CONSTRAINT ck_account_phone_format CHECK ((phone_number ~ '^\+[1-9][0-9]{1,14}$'::text)),
    CONSTRAINT ck_account_profile_names CHECK ((((first_name IS NULL) AND (last_name IS NULL) AND (display_name IS NULL)) OR ((first_name IS NOT NULL) AND (last_name IS NOT NULL) AND (display_name IS NOT NULL) AND ((length(btrim(first_name)) >= 1) AND (length(btrim(first_name)) <= 50)) AND ((length(btrim(last_name)) >= 1) AND (length(btrim(last_name)) <= 50)) AND ((length(btrim(display_name)) >= 1) AND (length(btrim(display_name)) <= 30)))))
);
COMMENT ON COLUMN account.first_name IS 'Null until onboarding saves the profile.';
COMMENT ON COLUMN account.app_mode IS 'Null until the account first joins care.';
COMMENT ON COLUMN account.birth_date IS 'Null for an account made before onboarding asked; required once the account is a patient.';

-- account_photo -----------------------------------------------------------
CREATE TABLE account_photo (
    account_id uuid NOT NULL,
    data bytea NOT NULL,
    CONSTRAINT pk_account_photo PRIMARY KEY (account_id),
    CONSTRAINT fk_account_photo_account_id_account FOREIGN KEY (account_id) REFERENCES account(id) ON DELETE CASCADE,
    CONSTRAINT ck_account_photo_data_size CHECK (((octet_length(data) >= 1) AND (octet_length(data) <= 4194304)))
);

-- account_session ---------------------------------------------------------
CREATE TABLE account_session (
    id uuid NOT NULL,
    account_id uuid NOT NULL,
    refresh_token_hash text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    push_subscription_id uuid,
    server_reminders boolean DEFAULT false NOT NULL,
    CONSTRAINT pk_account_session PRIMARY KEY (id),
    CONSTRAINT uq_account_session_push_subscription_id UNIQUE (push_subscription_id),
    CONSTRAINT uq_account_session_refresh_token_hash UNIQUE (refresh_token_hash),
    CONSTRAINT fk_account_session_account_id_account FOREIGN KEY (account_id) REFERENCES account(id) ON DELETE CASCADE,
    CONSTRAINT ck_account_session_refresh_hash CHECK ((refresh_token_hash ~ '^[0-9a-f]{64}$'::text)),
    CONSTRAINT ck_account_session_revocation_order CHECK ((revoked_at >= created_at))
);
CREATE INDEX ix_account_session_account_id ON account_session USING btree (account_id);

-- care_circle -------------------------------------------------------------
CREATE TABLE care_circle (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text,
    account_id uuid,
    first_name text,
    last_name text,
    avatar_code text,
    birth_date date,
    city text,
    time_zone text NOT NULL,
    latitude double precision,
    longitude double precision,
    blood_type text,
    conditions_status text,
    allergies_status text,
    leader_account_id uuid,
    CONSTRAINT pk_care_circle PRIMARY KEY (id),
    CONSTRAINT uq_care_circle_account_id UNIQUE (account_id),
    CONSTRAINT fk_care_circle_account_id_account FOREIGN KEY (account_id) REFERENCES account(id) ON DELETE RESTRICT,
    CONSTRAINT fk_care_circle_leader_account_id_account FOREIGN KEY (leader_account_id) REFERENCES account(id) ON DELETE SET NULL,
    CONSTRAINT ck_care_circle_account_source CHECK ((((account_id IS NOT NULL) AND (name IS NOT NULL) AND (first_name IS NULL) AND (last_name IS NULL) AND (avatar_code IS NULL) AND (birth_date IS NULL) AND (city IS NULL)) OR ((account_id IS NULL) AND (first_name IS NOT NULL) AND (last_name IS NOT NULL) AND (birth_date IS NOT NULL) AND (city IS NOT NULL)))),
    CONSTRAINT ck_care_circle_allergies_status CHECK (((allergies_status IS NULL) OR (allergies_status = ANY (ARRAY['none'::text, 'listed'::text])))),
    CONSTRAINT ck_care_circle_avatar_code CHECK (((avatar_code IS NULL) OR (avatar_code = ANY (ARRAY['w1_1'::text, 'w1_3'::text, 'w6_1'::text, 'w6_3'::text, 'w7_1'::text, 'w7_3'::text, 'm1_1'::text, 'm1_3'::text, 'm2_1'::text, 'm2_3'::text, 'm6_1'::text, 'm6_3'::text, 'sh_1'::text, 'sh_3'::text, 'gh_3'::text])))),
    CONSTRAINT ck_care_circle_birth_date CHECK (((birth_date IS NULL) OR (birth_date >= '1900-01-01'::date))),
    CONSTRAINT ck_care_circle_blood_type CHECK ((blood_type = ANY (ARRAY['A+'::text, 'A-'::text, 'B+'::text, 'B-'::text, 'AB+'::text, 'AB-'::text, 'O+'::text, 'O-'::text]))),
    CONSTRAINT ck_care_circle_city CHECK (((city IS NULL) OR ((length(btrim(city)) >= 1) AND (length(btrim(city)) <= 60)))),
    CONSTRAINT ck_care_circle_conditions_status CHECK (((conditions_status IS NULL) OR (conditions_status = ANY (ARRAY['none'::text, 'listed'::text])))),
    CONSTRAINT ck_care_circle_first_name CHECK (((first_name IS NULL) OR ((length(btrim(first_name)) >= 1) AND (length(btrim(first_name)) <= 50)))),
    CONSTRAINT ck_care_circle_last_name CHECK (((last_name IS NULL) OR ((length(btrim(last_name)) >= 1) AND (length(btrim(last_name)) <= 50)))),
    CONSTRAINT ck_care_circle_latitude CHECK (((latitude >= ('-90'::integer)::double precision) AND (latitude <= (90)::double precision))),
    CONSTRAINT ck_care_circle_longitude CHECK (((longitude >= ('-180'::integer)::double precision) AND (longitude <= (180)::double precision))),
    CONSTRAINT ck_care_circle_name CHECK (((name IS NULL) OR ((length(btrim(name)) >= 1) AND (length(btrim(name)) <= 60)))),
    CONSTRAINT ck_care_circle_time_zone CHECK (((length(btrim(time_zone)) >= 1) AND (length(btrim(time_zone)) <= 64)))
);
COMMENT ON COLUMN care_circle.name IS 'The patient''s own name for the circle; null for a patient without an account (others read «دائرة» and the name).';
COMMENT ON COLUMN care_circle.account_id IS 'The patient''s account; null for a patient without one.';
COMMENT ON COLUMN care_circle.first_name IS 'Only for a patient without an account; an account''s patient reads the account''s names.';
COMMENT ON COLUMN care_circle.birth_date IS 'Only for a patient without an account.';
COMMENT ON COLUMN care_circle.conditions_status IS 'Null until the question is answered; none or listed.';
COMMENT ON COLUMN care_circle.allergies_status IS 'Null until the question is answered; none or listed.';

-- appointment -------------------------------------------------------------
CREATE TABLE appointment (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    specialty text,
    kind text NOT NULL,
    scheduled_on date NOT NULL,
    time_of_day time without time zone NOT NULL,
    place text,
    remote_method text,
    status text DEFAULT 'scheduled'::text NOT NULL,
    created_by_account_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    other_text text,
    updated_by_account_id uuid,
    care_circle_id uuid NOT NULL,
    series_id uuid,
    reminder_lead_minutes smallint DEFAULT 60 NOT NULL,
    marked_missed boolean DEFAULT false NOT NULL,
    CONSTRAINT pk_appointment PRIMARY KEY (id),
    CONSTRAINT fk_appointment_care_circle_id_care_circle FOREIGN KEY (care_circle_id) REFERENCES care_circle(id) ON DELETE CASCADE,
    CONSTRAINT fk_appointment_created_by_account_id_account FOREIGN KEY (created_by_account_id) REFERENCES account(id) ON DELETE SET NULL,
    CONSTRAINT fk_appointment_updated_by_account_id_account FOREIGN KEY (updated_by_account_id) REFERENCES account(id) ON DELETE SET NULL,
    CONSTRAINT ck_appointment_kind CHECK ((kind = ANY (ARRAY['follow_up'::text, 'new_visit'::text, 'remote'::text, 'emergency'::text, 'test'::text, 'imaging'::text, 'eye_exam'::text, 'hearing_test'::text, 'surgery'::text, 'physio'::text, 'dialysis'::text, 'therapy_session'::text, 'dressing'::text, 'vaccine'::text, 'checkup'::text, 'dental'::text, 'pharmacy'::text, 'mental'::text, 'speech'::text, 'other'::text]))),
    CONSTRAINT ck_appointment_location_shape CHECK ((((kind = 'remote'::text) AND (remote_method IS NOT NULL) AND (remote_method = ANY (ARRAY['video'::text, 'phone'::text])) AND (place IS NULL)) OR ((kind <> 'remote'::text) AND (remote_method IS NULL) AND (place IS NOT NULL) AND (length(btrim(place)) > 0)))),
    CONSTRAINT ck_appointment_marked_missed CHECK (((NOT marked_missed) OR (status = 'scheduled'::text))),
    CONSTRAINT ck_appointment_other_text CHECK ((((kind = 'other'::text) AND (other_text IS NOT NULL) AND (length(btrim(other_text)) > 0) AND (char_length(other_text) <= 80)) OR ((kind <> 'other'::text) AND (other_text IS NULL)))),
    CONSTRAINT ck_appointment_place_length CHECK (((place IS NULL) OR (char_length(place) <= 160))),
    CONSTRAINT ck_appointment_specialty CHECK (((specialty IS NULL) OR ((length(btrim(specialty)) > 0) AND (char_length(specialty) <= 80)))),
    CONSTRAINT ck_appointment_status CHECK ((status = ANY (ARRAY['scheduled'::text, 'completed'::text, 'cancelled'::text])))
);
CREATE INDEX ix_appointment_care_circle_id ON appointment USING btree (care_circle_id);
CREATE INDEX ix_appointment_care_circle_id_scheduled_on_time_of_day ON appointment USING btree (care_circle_id, scheduled_on, time_of_day);
CREATE INDEX ix_appointment_created_by_account_id ON appointment USING btree (created_by_account_id);
CREATE INDEX ix_appointment_series_id ON appointment USING btree (series_id);
CREATE INDEX ix_appointment_updated_by_account_id ON appointment USING btree (updated_by_account_id);

-- appointment_companion ---------------------------------------------------
CREATE TABLE appointment_companion (
    appointment_id uuid NOT NULL,
    account_id uuid NOT NULL,
    CONSTRAINT pk_appointment_companion PRIMARY KEY (appointment_id, account_id),
    CONSTRAINT fk_appointment_companion_account_id_account FOREIGN KEY (account_id) REFERENCES account(id) ON DELETE CASCADE,
    CONSTRAINT fk_appointment_companion_appointment_id_appointment FOREIGN KEY (appointment_id) REFERENCES appointment(id) ON DELETE CASCADE
);
CREATE INDEX ix_appointment_companion_account_id ON appointment_companion USING btree (account_id);

-- appointment_visit -------------------------------------------------------
CREATE TABLE appointment_visit (
    appointment_id uuid NOT NULL,
    summary text,
    recommendations text,
    follow_up text,
    audio bytea,
    updated_by_account_id uuid,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pk_appointment_visit PRIMARY KEY (appointment_id),
    CONSTRAINT fk_appointment_visit_appointment_id_appointment FOREIGN KEY (appointment_id) REFERENCES appointment(id) ON DELETE CASCADE,
    CONSTRAINT fk_appointment_visit_updated_by_account_id_account FOREIGN KEY (updated_by_account_id) REFERENCES account(id) ON DELETE SET NULL,
    CONSTRAINT ck_appointment_visit_audio_size CHECK (((audio IS NULL) OR (octet_length(audio) <= 5242880))),
    CONSTRAINT ck_appointment_visit_follow_up_length CHECK (((follow_up IS NULL) OR (char_length(follow_up) <= 500))),
    CONSTRAINT ck_appointment_visit_recommendations_length CHECK (((recommendations IS NULL) OR (char_length(recommendations) <= 2000))),
    CONSTRAINT ck_appointment_visit_summary_length CHECK (((summary IS NULL) OR (char_length(summary) <= 2000)))
);
CREATE INDEX ix_appointment_visit_updated_by_account_id ON appointment_visit USING btree (updated_by_account_id);

-- care_circle_invitation --------------------------------------------------
CREATE TABLE care_circle_invitation (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    care_circle_id uuid NOT NULL,
    invited_by_account_id uuid,
    invitee_phone_number text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    responded_by_account_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    last_sent_at timestamp with time zone DEFAULT now() NOT NULL,
    responded_at timestamp with time zone,
    CONSTRAINT pk_care_circle_invitation PRIMARY KEY (id),
    CONSTRAINT fk_care_circle_invitation_care_circle_id_care_circle FOREIGN KEY (care_circle_id) REFERENCES care_circle(id) ON DELETE CASCADE,
    CONSTRAINT fk_care_circle_invitation_invited_by_account_id_account FOREIGN KEY (invited_by_account_id) REFERENCES account(id) ON DELETE SET NULL,
    CONSTRAINT fk_care_circle_invitation_responded_by_account_id_account FOREIGN KEY (responded_by_account_id) REFERENCES account(id) ON DELETE SET NULL,
    CONSTRAINT ck_care_circle_invitation_phone_format CHECK ((invitee_phone_number ~ '^\+[1-9][0-9]{1,14}$'::text)),
    CONSTRAINT ck_care_circle_invitation_status CHECK ((status = ANY (ARRAY['pending'::text, 'accepted'::text, 'declined'::text, 'cancelled'::text])))
);
CREATE INDEX ix_care_circle_invitation_care_circle_id ON care_circle_invitation USING btree (care_circle_id);
CREATE INDEX ix_care_circle_invitation_invited_by_account_id ON care_circle_invitation USING btree (invited_by_account_id);
CREATE INDEX ix_care_circle_invitation_invitee_phone_number ON care_circle_invitation USING btree (invitee_phone_number);
CREATE INDEX ix_care_circle_invitation_responded_by_account_id ON care_circle_invitation USING btree (responded_by_account_id);
CREATE UNIQUE INDEX uq_care_circle_invitation_circle_invitee_phone_number_pending ON care_circle_invitation USING btree (care_circle_id, invitee_phone_number) WHERE (status = 'pending'::text);

-- care_circle_manager -----------------------------------------------------
CREATE TABLE care_circle_manager (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    care_circle_id uuid NOT NULL,
    account_id uuid NOT NULL,
    can_edit_medications boolean DEFAULT true NOT NULL,
    can_edit_measurements boolean DEFAULT true NOT NULL,
    can_edit_appointments boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pk_care_circle_manager PRIMARY KEY (id),
    CONSTRAINT uq_care_circle_manager_care_circle_id_account_id UNIQUE (care_circle_id, account_id),
    CONSTRAINT fk_care_circle_manager_account_id_account FOREIGN KEY (account_id) REFERENCES account(id) ON DELETE RESTRICT,
    CONSTRAINT fk_care_circle_manager_care_circle_id_care_circle FOREIGN KEY (care_circle_id) REFERENCES care_circle(id) ON DELETE CASCADE
);
CREATE INDEX ix_care_circle_manager_account_id ON care_circle_manager USING btree (account_id);

-- care_circle_photo -------------------------------------------------------
CREATE TABLE care_circle_photo (
    care_circle_id uuid NOT NULL,
    data bytea NOT NULL,
    CONSTRAINT pk_care_circle_photo PRIMARY KEY (care_circle_id),
    CONSTRAINT fk_care_circle_photo_care_circle_id_care_circle FOREIGN KEY (care_circle_id) REFERENCES care_circle(id) ON DELETE CASCADE,
    CONSTRAINT ck_care_circle_photo_data_size CHECK (((octet_length(data) >= 1) AND (octet_length(data) <= 4194304)))
);

-- care_circle_request -----------------------------------------------------
CREATE TABLE care_circle_request (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    requested_by_account_id uuid NOT NULL,
    patient_phone_number text NOT NULL,
    proposed_app_mode text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    care_circle_id uuid,
    responded_by_account_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    responded_at timestamp with time zone,
    completed_at timestamp with time zone,
    CONSTRAINT pk_care_circle_request PRIMARY KEY (id),
    CONSTRAINT uq_care_circle_request_care_circle_id UNIQUE (care_circle_id),
    CONSTRAINT fk_care_circle_request_care_circle_id_care_circle FOREIGN KEY (care_circle_id) REFERENCES care_circle(id) ON DELETE CASCADE,
    CONSTRAINT fk_care_circle_request_requested_by_account_id_account FOREIGN KEY (requested_by_account_id) REFERENCES account(id) ON DELETE CASCADE,
    CONSTRAINT fk_care_circle_request_responded_by_account_id_account FOREIGN KEY (responded_by_account_id) REFERENCES account(id) ON DELETE SET NULL,
    CONSTRAINT ck_care_circle_request_completion CHECK ((((status = 'completed'::text) AND (care_circle_id IS NOT NULL) AND (completed_at IS NOT NULL)) OR ((status <> 'completed'::text) AND (care_circle_id IS NULL) AND (completed_at IS NULL)))),
    CONSTRAINT ck_care_circle_request_consent CHECK (((status <> 'accepted'::text) OR ((responded_by_account_id IS NOT NULL) AND (responded_at IS NOT NULL)))),
    CONSTRAINT ck_care_circle_request_phone_format CHECK ((patient_phone_number ~ '^\+[1-9][0-9]{1,14}$'::text)),
    CONSTRAINT ck_care_circle_request_proposed_app_mode CHECK ((proposed_app_mode = ANY (ARRAY['detailed'::text, 'simplified'::text]))),
    CONSTRAINT ck_care_circle_request_status CHECK ((status = ANY (ARRAY['pending'::text, 'accepted'::text, 'completed'::text, 'declined'::text, 'cancelled'::text, 'superseded'::text])))
);
CREATE INDEX ix_care_circle_request_patient_phone_number ON care_circle_request USING btree (patient_phone_number);
CREATE INDEX ix_care_circle_request_requested_by_account_id ON care_circle_request USING btree (requested_by_account_id);
CREATE INDEX ix_care_circle_request_responded_by_account_id ON care_circle_request USING btree (responded_by_account_id);
CREATE UNIQUE INDEX uq_care_circle_request_requested_by_patient_phone_number_open ON care_circle_request USING btree (requested_by_account_id, patient_phone_number) WHERE (status = ANY (ARRAY['pending'::text, 'accepted'::text]));
CREATE UNIQUE INDEX uq_care_circle_request_responded_by_account_id_accepted ON care_circle_request USING btree (responded_by_account_id) WHERE (status = 'accepted'::text);

-- emergency_contact -------------------------------------------------------
CREATE TABLE emergency_contact (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    relation text NOT NULL,
    phone_number text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    care_circle_id uuid NOT NULL,
    relation_other text,
    CONSTRAINT pk_emergency_contact PRIMARY KEY (id),
    CONSTRAINT uq_emergency_contact_care_circle_id_phone_number UNIQUE (care_circle_id, phone_number),
    CONSTRAINT fk_emergency_contact_care_circle_id_care_circle FOREIGN KEY (care_circle_id) REFERENCES care_circle(id) ON DELETE CASCADE,
    CONSTRAINT ck_emergency_contact_name CHECK (((length(btrim(name)) >= 1) AND (length(btrim(name)) <= 50))),
    CONSTRAINT ck_emergency_contact_phone_format CHECK ((phone_number ~ '^\+[1-9][0-9]{1,14}$'::text)),
    CONSTRAINT ck_emergency_contact_relation CHECK ((relation = ANY (ARRAY['son'::text, 'daughter'::text, 'husband'::text, 'wife'::text, 'other'::text]))),
    CONSTRAINT ck_emergency_contact_relation_other CHECK ((((relation = 'other'::text) AND (relation_other IS NOT NULL) AND ((length(btrim(relation_other)) >= 1) AND (length(btrim(relation_other)) <= 100))) OR ((relation <> 'other'::text) AND (relation_other IS NULL))))
);

-- measurement_plan --------------------------------------------------------
CREATE TABLE measurement_plan (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    kind text NOT NULL,
    created_by_account_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    stopped_at timestamp with time zone,
    stopped_by_account_id uuid,
    care_circle_id uuid NOT NULL,
    CONSTRAINT pk_measurement_plan PRIMARY KEY (id),
    CONSTRAINT fk_measurement_plan_care_circle_id_care_circle FOREIGN KEY (care_circle_id) REFERENCES care_circle(id) ON DELETE CASCADE,
    CONSTRAINT fk_measurement_plan_created_by_account_id_account FOREIGN KEY (created_by_account_id) REFERENCES account(id) ON DELETE SET NULL,
    CONSTRAINT fk_measurement_plan_stopped_by_account_id_account FOREIGN KEY (stopped_by_account_id) REFERENCES account(id) ON DELETE SET NULL,
    CONSTRAINT ck_measurement_plan_kind CHECK ((kind = ANY (ARRAY['glucose'::text, 'blood_pressure'::text]))),
    CONSTRAINT ck_measurement_plan_stopped_state CHECK (((stopped_at IS NOT NULL) OR (stopped_by_account_id IS NULL)))
);
CREATE INDEX ix_measurement_plan_care_circle_id ON measurement_plan USING btree (care_circle_id);
CREATE INDEX ix_measurement_plan_created_by_account_id ON measurement_plan USING btree (created_by_account_id);
CREATE INDEX ix_measurement_plan_stopped_by_account_id ON measurement_plan USING btree (stopped_by_account_id);
CREATE UNIQUE INDEX uq_measurement_plan_care_circle_id_kind_active ON measurement_plan USING btree (care_circle_id, kind) WHERE (stopped_at IS NULL);

-- measurement_plan_version ------------------------------------------------
CREATE TABLE measurement_plan_version (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    measurement_plan_id uuid NOT NULL,
    version_number integer NOT NULL,
    effective_from_on date NOT NULL,
    effective_until_on date,
    missed_after_minutes smallint NOT NULL,
    glucose_low smallint,
    glucose_high smallint,
    systolic_limit smallint,
    diastolic_limit smallint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_account_id uuid,
    CONSTRAINT pk_measurement_plan_version PRIMARY KEY (id),
    CONSTRAINT uq_measurement_plan_version_measurement_plan_effective_from_on UNIQUE (measurement_plan_id, effective_from_on),
    CONSTRAINT uq_measurement_plan_version_measurement_plan_id_version_number UNIQUE (measurement_plan_id, version_number),
    CONSTRAINT fk_measurement_plan_version_created_by_account_id_account FOREIGN KEY (created_by_account_id) REFERENCES account(id) ON DELETE SET NULL,
    CONSTRAINT fk_measurement_plan_version_measurement_plan_id FOREIGN KEY (measurement_plan_id) REFERENCES measurement_plan(id) ON DELETE CASCADE,
    CONSTRAINT ck_measurement_plan_version_effective_period CHECK (((effective_until_on IS NULL) OR (effective_until_on > effective_from_on))),
    CONSTRAINT ck_measurement_plan_version_missed_after_minutes CHECK (((missed_after_minutes >= 5) AND (missed_after_minutes <= 360))),
    CONSTRAINT ck_measurement_plan_version_target_shape CHECK ((((glucose_low IS NULL) AND (glucose_high IS NULL) AND (systolic_limit IS NULL) AND (diastolic_limit IS NULL)) OR ((glucose_low IS NOT NULL) AND (glucose_high IS NOT NULL) AND ((glucose_low >= 1) AND (glucose_low <= 999)) AND ((glucose_high >= 1) AND (glucose_high <= 999)) AND (glucose_high > glucose_low) AND (systolic_limit IS NULL) AND (diastolic_limit IS NULL)) OR ((glucose_low IS NULL) AND (glucose_high IS NULL) AND ((systolic_limit >= 1) AND (systolic_limit <= 999)) AND ((diastolic_limit >= 1) AND (diastolic_limit <= 999)) AND (systolic_limit > diastolic_limit)))),
    CONSTRAINT ck_measurement_plan_version_version_number CHECK ((version_number > 0))
);
COMMENT ON COLUMN measurement_plan_version.glucose_low IS 'Snapshot: the target this version judged readings by.';
CREATE INDEX ix_measurement_plan_version_created_by_account_id ON measurement_plan_version USING btree (created_by_account_id);

-- measurement_plan_time ---------------------------------------------------
CREATE TABLE measurement_plan_time (
    plan_version_id uuid NOT NULL,
    time_of_day time without time zone NOT NULL,
    measurement_state text,
    CONSTRAINT pk_measurement_plan_time PRIMARY KEY (plan_version_id, time_of_day),
    CONSTRAINT fk_measurement_plan_time_plan_version_id FOREIGN KEY (plan_version_id) REFERENCES measurement_plan_version(id) ON DELETE CASCADE,
    CONSTRAINT ck_measurement_plan_time_measurement_state CHECK (((measurement_state IS NULL) OR (measurement_state = ANY (ARRAY['fasting'::text, 'before_meal'::text, 'after_meal'::text, 'before_medicine'::text, 'after_medicine'::text, 'morning'::text]))))
);

-- measurement_plan_weekday ------------------------------------------------
CREATE TABLE measurement_plan_weekday (
    plan_version_id uuid NOT NULL,
    weekday smallint NOT NULL,
    CONSTRAINT pk_measurement_plan_weekday PRIMARY KEY (plan_version_id, weekday),
    CONSTRAINT fk_measurement_plan_weekday_plan_version_id FOREIGN KEY (plan_version_id) REFERENCES measurement_plan_version(id) ON DELETE CASCADE,
    CONSTRAINT ck_measurement_plan_weekday_weekday CHECK (((weekday >= 1) AND (weekday <= 7)))
);

-- measurement_reading -----------------------------------------------------
CREATE TABLE measurement_reading (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    plan_version_id uuid,
    scheduled_on date,
    kind text NOT NULL,
    outcome text NOT NULL,
    measured_at timestamp with time zone,
    note text,
    followed_up_at timestamp with time zone,
    recorded_by_account_id uuid,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    glucose_low smallint,
    glucose_high smallint,
    systolic_limit smallint,
    diastolic_limit smallint,
    scheduled_time time without time zone,
    conditions text[] DEFAULT '{}'::text[] NOT NULL,
    other_text text,
    care_circle_id uuid NOT NULL,
    glucose_value smallint,
    systolic_value smallint,
    diastolic_value smallint,
    skip_reason_code text,
    skip_reason_note text,
    CONSTRAINT pk_measurement_reading PRIMARY KEY (id),
    CONSTRAINT uq_measurement_reading_plan_version_scheduled_on_scheduled_time UNIQUE (plan_version_id, scheduled_on, scheduled_time),
    CONSTRAINT fk_measurement_reading_care_circle_id_care_circle FOREIGN KEY (care_circle_id) REFERENCES care_circle(id) ON DELETE CASCADE,
    CONSTRAINT fk_measurement_reading_plan_version_id_measurement_plan_time FOREIGN KEY (plan_version_id, scheduled_time) REFERENCES measurement_plan_time(plan_version_id, time_of_day) ON DELETE CASCADE,
    CONSTRAINT fk_measurement_reading_plan_version_id_measurement_plan_version FOREIGN KEY (plan_version_id) REFERENCES measurement_plan_version(id) ON DELETE CASCADE,
    CONSTRAINT fk_measurement_reading_recorded_by_account_id_account FOREIGN KEY (recorded_by_account_id) REFERENCES account(id) ON DELETE SET NULL,
    CONSTRAINT ck_measurement_reading_conditions CHECK ((conditions <@ ARRAY['fasting'::text, 'before_meal'::text, 'after_meal'::text, 'bedtime'::text, 'before_medicine'::text, 'after_medicine'::text, 'morning'::text, 'exertion'::text, 'stress'::text, 'illness'::text, 'other'::text])),
    CONSTRAINT ck_measurement_reading_conditions_once CHECK (fn_measurement_conditions_unique(conditions)),
    CONSTRAINT ck_measurement_reading_free_target_shape CHECK ((((glucose_low IS NULL) AND (glucose_high IS NULL) AND (systolic_limit IS NULL) AND (diastolic_limit IS NULL)) OR ((plan_version_id IS NULL) AND (outcome = 'read'::text) AND (((kind = 'glucose'::text) AND (glucose_low IS NOT NULL) AND (glucose_high IS NOT NULL) AND ((glucose_low >= 1) AND (glucose_low <= 999)) AND ((glucose_high >= 1) AND (glucose_high <= 999)) AND (glucose_low < glucose_high) AND (systolic_limit IS NULL) AND (diastolic_limit IS NULL)) OR ((kind = 'blood_pressure'::text) AND (systolic_limit IS NOT NULL) AND (diastolic_limit IS NOT NULL) AND ((systolic_limit >= 1) AND (systolic_limit <= 999)) AND ((diastolic_limit >= 1) AND (diastolic_limit <= 999)) AND (systolic_limit > diastolic_limit) AND (glucose_low IS NULL) AND (glucose_high IS NULL)))))),
    CONSTRAINT ck_measurement_reading_kind CHECK ((kind = ANY (ARRAY['glucose'::text, 'blood_pressure'::text]))),
    CONSTRAINT ck_measurement_reading_note_length CHECK (((note IS NULL) OR (char_length(note) <= 250))),
    CONSTRAINT ck_measurement_reading_other_text CHECK (((other_text IS NULL) OR (((char_length(other_text) >= 1) AND (char_length(other_text) <= 60)) AND ('other'::text = ANY (conditions))))),
    CONSTRAINT ck_measurement_reading_outcome CHECK ((outcome = ANY (ARRAY['read'::text, 'skipped'::text]))),
    CONSTRAINT ck_measurement_reading_schedule_pair CHECK ((((plan_version_id IS NULL) AND (scheduled_on IS NULL) AND (scheduled_time IS NULL)) OR ((plan_version_id IS NOT NULL) AND (scheduled_on IS NOT NULL) AND (scheduled_time IS NOT NULL)))),
    CONSTRAINT ck_measurement_reading_skip_linked CHECK (((outcome = 'read'::text) OR (plan_version_id IS NOT NULL))),
    CONSTRAINT ck_measurement_reading_skip_reason CHECK (((skip_reason_code IS NULL) OR (skip_reason_code = ANY (ARRAY['forgotten'::text, 'equipment_unavailable'::text, 'patient_refused'::text, 'unwell'::text, 'other'::text])))),
    CONSTRAINT ck_measurement_reading_skip_reason_note CHECK (((skip_reason_note IS NULL) OR ((skip_reason_code = 'other'::text) AND ((char_length(skip_reason_note) >= 1) AND (char_length(skip_reason_note) <= 250))))),
    CONSTRAINT ck_measurement_reading_skip_reason_outcome CHECK ((((outcome = 'read'::text) AND (skip_reason_code IS NULL) AND (skip_reason_note IS NULL)) OR (outcome = 'skipped'::text))),
    CONSTRAINT ck_measurement_reading_value_shape CHECK ((((outcome = 'skipped'::text) AND (measured_at IS NULL) AND (glucose_value IS NULL) AND (systolic_value IS NULL) AND (diastolic_value IS NULL) AND (followed_up_at IS NULL)) OR ((outcome = 'read'::text) AND (measured_at IS NOT NULL) AND (((kind = 'glucose'::text) AND ((glucose_value >= 1) AND (glucose_value <= 999)) AND (systolic_value IS NULL) AND (diastolic_value IS NULL)) OR ((kind = 'blood_pressure'::text) AND (glucose_value IS NULL) AND ((systolic_value >= 1) AND (systolic_value <= 999)) AND ((diastolic_value >= 1) AND (diastolic_value <= 999)) AND (systolic_value > diastolic_value))))))
);
COMMENT ON COLUMN measurement_reading.plan_version_id IS 'Null for a reading taken outside a plan.';
COMMENT ON COLUMN measurement_reading.glucose_low IS 'Snapshot: the target a reading without a plan was judged by.';
CREATE INDEX ix_measurement_reading_care_circle_id ON measurement_reading USING btree (care_circle_id);
CREATE INDEX ix_measurement_reading_recorded_by_account_id ON measurement_reading USING btree (recorded_by_account_id);

-- measurement_target ------------------------------------------------------
CREATE TABLE measurement_target (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    kind text NOT NULL,
    glucose_low smallint,
    glucose_high smallint,
    systolic_limit smallint,
    diastolic_limit smallint,
    care_circle_id uuid NOT NULL,
    CONSTRAINT pk_measurement_target PRIMARY KEY (id),
    CONSTRAINT uq_measurement_target_care_circle_id_kind UNIQUE (care_circle_id, kind),
    CONSTRAINT fk_measurement_target_care_circle_id_care_circle FOREIGN KEY (care_circle_id) REFERENCES care_circle(id) ON DELETE CASCADE,
    CONSTRAINT ck_measurement_target_kind CHECK ((kind = ANY (ARRAY['glucose'::text, 'blood_pressure'::text]))),
    CONSTRAINT ck_measurement_target_target_shape CHECK ((((kind = 'glucose'::text) AND (glucose_low IS NOT NULL) AND (glucose_high IS NOT NULL) AND ((glucose_low >= 1) AND (glucose_low <= 999)) AND ((glucose_high >= 1) AND (glucose_high <= 999)) AND (glucose_low < glucose_high) AND (systolic_limit IS NULL) AND (diastolic_limit IS NULL)) OR ((kind = 'blood_pressure'::text) AND (systolic_limit IS NOT NULL) AND (diastolic_limit IS NOT NULL) AND ((systolic_limit >= 1) AND (systolic_limit <= 999)) AND ((diastolic_limit >= 1) AND (diastolic_limit <= 999)) AND (systolic_limit > diastolic_limit) AND (glucose_low IS NULL) AND (glucose_high IS NULL))))
);

-- medication_plan ---------------------------------------------------------
CREATE TABLE medication_plan (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_by_account_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    stopped_at timestamp with time zone,
    stopped_by_account_id uuid,
    care_circle_id uuid NOT NULL,
    CONSTRAINT pk_medication_plan PRIMARY KEY (id),
    CONSTRAINT fk_medication_plan_care_circle_id_care_circle FOREIGN KEY (care_circle_id) REFERENCES care_circle(id) ON DELETE CASCADE,
    CONSTRAINT fk_medication_plan_created_by_account_id_account FOREIGN KEY (created_by_account_id) REFERENCES account(id) ON DELETE SET NULL,
    CONSTRAINT fk_medication_plan_stopped_by_account_id_account FOREIGN KEY (stopped_by_account_id) REFERENCES account(id) ON DELETE SET NULL,
    CONSTRAINT ck_medication_plan_stopped_state CHECK (((stopped_at IS NOT NULL) OR (stopped_by_account_id IS NULL)))
);
CREATE INDEX ix_medication_plan_care_circle_id ON medication_plan USING btree (care_circle_id);
CREATE INDEX ix_medication_plan_created_by_account_id ON medication_plan USING btree (created_by_account_id);
CREATE INDEX ix_medication_plan_stopped_by_account_id ON medication_plan USING btree (stopped_by_account_id);

-- medication_plan_version -------------------------------------------------
CREATE TABLE medication_plan_version (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    medication_plan_id uuid NOT NULL,
    version_number integer NOT NULL,
    name text NOT NULL,
    normalized_name text NOT NULL,
    dosage_form text NOT NULL,
    reason_for_use text,
    instructions text,
    treatment_starts_on date NOT NULL,
    treatment_ends_on date,
    created_by_account_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    strength_value numeric(10,3) NOT NULL,
    strength_unit text NOT NULL,
    effective_from_on date NOT NULL,
    effective_until_on date,
    missed_after_minutes smallint DEFAULT 60 NOT NULL,
    cancelled_at timestamp with time zone,
    CONSTRAINT pk_medication_plan_version PRIMARY KEY (id),
    CONSTRAINT uq_medication_plan_version_medication_plan_id_version_number UNIQUE (medication_plan_id, version_number),
    CONSTRAINT fk_medication_plan_version_created_by_account_id_account FOREIGN KEY (created_by_account_id) REFERENCES account(id) ON DELETE SET NULL,
    CONSTRAINT fk_medication_plan_version_medication_plan_id_medication_plan FOREIGN KEY (medication_plan_id) REFERENCES medication_plan(id) ON DELETE CASCADE,
    CONSTRAINT ck_medication_plan_version_dosage_form CHECK ((dosage_form = ANY (ARRAY['tablet'::text, 'capsule'::text, 'liquid'::text, 'drops'::text, 'inhaler'::text, 'nebulizer'::text, 'injection'::text]))),
    CONSTRAINT ck_medication_plan_version_effective_period CHECK (((effective_until_on IS NULL) OR (effective_until_on > effective_from_on))),
    CONSTRAINT ck_medication_plan_version_effective_treatment CHECK (((treatment_ends_on IS NULL) OR (treatment_ends_on >= effective_from_on))),
    CONSTRAINT ck_medication_plan_version_instructions_length CHECK (((instructions IS NULL) OR (char_length(instructions) <= 250))),
    CONSTRAINT ck_medication_plan_version_missed_after_minutes CHECK (((missed_after_minutes >= 5) AND (missed_after_minutes <= 360))),
    CONSTRAINT ck_medication_plan_version_name CHECK (((length(btrim(name)) >= 1) AND (length(btrim(name)) <= 50))),
    CONSTRAINT ck_medication_plan_version_normalized_name_nonblank CHECK ((length(btrim(normalized_name)) > 0)),
    CONSTRAINT ck_medication_plan_version_positive_strength CHECK ((strength_value > (0)::numeric)),
    CONSTRAINT ck_medication_plan_version_reason_for_use_length CHECK (((reason_for_use IS NULL) OR (char_length(reason_for_use) <= 100))),
    CONSTRAINT ck_medication_plan_version_strength_unit CHECK ((strength_unit = ANY (ARRAY['mg'::text, 'mcg'::text, 'mg/mL'::text, 'mg/5mL'::text, 'mcg/dose'::text, 'unit/mL'::text, '%'::text]))),
    CONSTRAINT ck_medication_plan_version_treatment_dates CHECK (((treatment_ends_on IS NULL) OR (treatment_ends_on >= treatment_starts_on))),
    CONSTRAINT ck_medication_plan_version_version_number CHECK ((version_number >= 1))
);
COMMENT ON COLUMN medication_plan_version.normalized_name IS 'Derived key of name (NFKC, casefold, one space) that the overlap rule compares.';
CREATE INDEX ix_medication_plan_version_created_by_account_id ON medication_plan_version USING btree (created_by_account_id);
CREATE UNIQUE INDEX uq_medication_plan_version_medication_plan_id_effective_from_on ON medication_plan_version USING btree (medication_plan_id, effective_from_on) WHERE (cancelled_at IS NULL);
CREATE UNIQUE INDEX uq_medication_plan_version_medication_plan_id_open ON medication_plan_version USING btree (medication_plan_id) WHERE ((effective_until_on IS NULL) AND (cancelled_at IS NULL));

-- medication_schedule -----------------------------------------------------
CREATE TABLE medication_schedule (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    plan_version_id uuid NOT NULL,
    time_of_day time without time zone NOT NULL,
    dose_value numeric(10,3) NOT NULL,
    dose_unit text NOT NULL,
    instructions text,
    repeat text DEFAULT 'weekly'::text NOT NULL,
    interval_days smallint,
    CONSTRAINT pk_medication_schedule PRIMARY KEY (id),
    CONSTRAINT fk_medication_schedule_plan_version_id_medication_plan_version FOREIGN KEY (plan_version_id) REFERENCES medication_plan_version(id) ON DELETE CASCADE,
    CONSTRAINT ck_medication_schedule_dose_unit CHECK ((dose_unit = ANY (ARRAY['tablet'::text, 'capsule'::text, 'mL'::text, 'drop'::text, 'puff'::text, 'unit'::text]))),
    CONSTRAINT ck_medication_schedule_instructions_length CHECK (((instructions IS NULL) OR (char_length(instructions) <= 250))),
    CONSTRAINT ck_medication_schedule_interval_days CHECK ((((repeat = 'interval'::text) AND (interval_days IS NOT NULL) AND ((interval_days >= 1) AND (interval_days <= 90))) OR ((repeat <> 'interval'::text) AND (interval_days IS NULL)))),
    CONSTRAINT ck_medication_schedule_positive_dose CHECK ((dose_value > (0)::numeric)),
    CONSTRAINT ck_medication_schedule_repeat CHECK ((repeat = ANY (ARRAY['weekly'::text, 'monthly'::text, 'interval'::text])))
);
CREATE INDEX ix_medication_schedule_plan_version_id ON medication_schedule USING btree (plan_version_id);

-- medication_dose_record --------------------------------------------------
CREATE TABLE medication_dose_record (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    schedule_id uuid NOT NULL,
    scheduled_on date NOT NULL,
    outcome text NOT NULL,
    taken_at timestamp with time zone,
    skip_reason_code text,
    skip_reason_note text,
    recorded_by_account_id uuid,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pk_medication_dose_record PRIMARY KEY (id),
    CONSTRAINT uq_medication_dose_record_schedule_id_scheduled_on UNIQUE (schedule_id, scheduled_on),
    CONSTRAINT fk_medication_dose_record_recorded_by_account_id_account FOREIGN KEY (recorded_by_account_id) REFERENCES account(id) ON DELETE SET NULL,
    CONSTRAINT fk_medication_dose_record_schedule_id_medication_schedule FOREIGN KEY (schedule_id) REFERENCES medication_schedule(id) ON DELETE CASCADE,
    CONSTRAINT ck_medication_dose_record_outcome CHECK ((outcome = ANY (ARRAY['taken'::text, 'skipped'::text]))),
    CONSTRAINT ck_medication_dose_record_outcome_details CHECK ((((outcome = 'taken'::text) AND (taken_at IS NOT NULL) AND (skip_reason_code IS NULL) AND (skip_reason_note IS NULL)) OR ((outcome = 'skipped'::text) AND (taken_at IS NULL)))),
    CONSTRAINT ck_medication_dose_record_skip_note CHECK (((skip_reason_note IS NULL) OR (skip_reason_code = 'other'::text))),
    CONSTRAINT ck_medication_dose_record_skip_reason CHECK (((skip_reason_code IS NULL) OR (skip_reason_code = ANY (ARRAY[('forgotten'::character varying)::text, ('unavailable'::character varying)::text, ('side_effects'::character varying)::text, ('patient_refused'::character varying)::text, ('other'::character varying)::text])))),
    CONSTRAINT ck_medication_dose_record_skip_reason_note_length CHECK (((skip_reason_note IS NULL) OR (char_length(skip_reason_note) <= 250))),
    CONSTRAINT ck_medication_dose_record_taken_before_recorded CHECK (((taken_at IS NULL) OR (taken_at <= recorded_at)))
);
CREATE INDEX ix_medication_dose_record_recorded_by_account_id ON medication_dose_record USING btree (recorded_by_account_id);
CREATE INDEX ix_medication_dose_record_scheduled_on ON medication_dose_record USING btree (scheduled_on);

-- medication_extra_dose ---------------------------------------------------
CREATE TABLE medication_extra_dose (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    medication_plan_id uuid NOT NULL,
    taken_at timestamp with time zone NOT NULL,
    dose_value numeric(10,3) NOT NULL,
    dose_unit text NOT NULL,
    recorded_by_account_id uuid,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pk_medication_extra_dose PRIMARY KEY (id),
    CONSTRAINT fk_medication_extra_dose_medication_plan_id_medication_plan FOREIGN KEY (medication_plan_id) REFERENCES medication_plan(id) ON DELETE CASCADE,
    CONSTRAINT fk_medication_extra_dose_recorded_by_account_id_account FOREIGN KEY (recorded_by_account_id) REFERENCES account(id) ON DELETE SET NULL,
    CONSTRAINT ck_medication_extra_dose_dose_unit CHECK ((dose_unit = ANY (ARRAY['tablet'::text, 'capsule'::text, 'mL'::text, 'drop'::text, 'puff'::text, 'unit'::text]))),
    CONSTRAINT ck_medication_extra_dose_positive_dose CHECK ((dose_value > (0)::numeric)),
    CONSTRAINT ck_medication_extra_dose_taken_before_recorded CHECK ((taken_at <= recorded_at))
);
CREATE INDEX ix_medication_extra_dose_medication_plan_id ON medication_extra_dose USING btree (medication_plan_id);
CREATE INDEX ix_medication_extra_dose_recorded_by_account_id ON medication_extra_dose USING btree (recorded_by_account_id);
CREATE INDEX ix_medication_extra_dose_taken_at ON medication_extra_dose USING btree (taken_at);

-- medication_plan_photo ---------------------------------------------------
CREATE TABLE medication_plan_photo (
    medication_plan_id uuid NOT NULL,
    data bytea NOT NULL,
    CONSTRAINT pk_medication_plan_photo PRIMARY KEY (medication_plan_id),
    CONSTRAINT fk_medication_plan_photo_medication_plan_id_medication_plan FOREIGN KEY (medication_plan_id) REFERENCES medication_plan(id) ON DELETE CASCADE,
    CONSTRAINT ck_medication_plan_photo_data_size CHECK (((octet_length(data) >= 1) AND (octet_length(data) <= 4194304)))
);

-- medication_schedule_day -------------------------------------------------
CREATE TABLE medication_schedule_day (
    schedule_id uuid NOT NULL,
    weekday smallint NOT NULL,
    CONSTRAINT pk_medication_schedule_day PRIMARY KEY (schedule_id, weekday),
    CONSTRAINT fk_medication_schedule_day_schedule_id_medication_schedule FOREIGN KEY (schedule_id) REFERENCES medication_schedule(id) ON DELETE CASCADE,
    CONSTRAINT ck_medication_schedule_day_weekday CHECK (((weekday >= 1) AND (weekday <= 7)))
);

-- medication_schedule_month_day -------------------------------------------
CREATE TABLE medication_schedule_month_day (
    schedule_id uuid NOT NULL,
    month_day smallint NOT NULL,
    CONSTRAINT pk_medication_schedule_month_day PRIMARY KEY (schedule_id, month_day),
    CONSTRAINT fk_medication_schedule_month_day_schedule_id_medication_d166 FOREIGN KEY (schedule_id) REFERENCES medication_schedule(id) ON DELETE CASCADE,
    CONSTRAINT ck_medication_schedule_month_day_month_day CHECK (((month_day >= 1) AND (month_day <= 28)))
);

-- notification_log --------------------------------------------------------
CREATE TABLE notification_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sent_at timestamp with time zone DEFAULT now() NOT NULL,
    kind text NOT NULL,
    target_id uuid NOT NULL,
    scheduled_on date NOT NULL,
    time_of_day time without time zone,
    CONSTRAINT pk_notification_log PRIMARY KEY (id),
    CONSTRAINT ck_notification_log_kind CHECK ((kind = ANY (ARRAY['dose_missed'::text, 'measurement_missed'::text, 'appointment_missed'::text, 'dose_reminder'::text, 'measurement_reminder'::text, 'appointment_day_before'::text, 'appointment_soon'::text, 'appointment_today'::text]))),
    CONSTRAINT ck_notification_log_time_of_day CHECK (((kind = ANY (ARRAY['dose_missed'::text, 'appointment_missed'::text])) = (time_of_day IS NULL)))
);
CREATE INDEX ix_notification_log_sent_at ON notification_log USING btree (sent_at);
CREATE UNIQUE INDEX uq_notification_log_kind_target_id_scheduled_on_time_of_day ON notification_log USING btree (kind, target_id, scheduled_on, time_of_day) NULLS NOT DISTINCT;

-- otp_request -------------------------------------------------------------
CREATE TABLE otp_request (
    id uuid NOT NULL,
    phone_number text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    expires_at timestamp with time zone,
    wrong_try_count integer DEFAULT 0 NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    verified_at timestamp with time zone,
    CONSTRAINT pk_otp_request PRIMARY KEY (id),
    CONSTRAINT ck_otp_request_expiry_order CHECK ((expires_at > created_at)),
    CONSTRAINT ck_otp_request_phone_format CHECK ((phone_number ~ '^\+[1-9][0-9]{1,14}$'::text)),
    CONSTRAINT ck_otp_request_status CHECK ((status = ANY (ARRAY['pending'::text, 'verified'::text, 'superseded'::text]))),
    CONSTRAINT ck_otp_request_verification_order CHECK ((verified_at >= created_at)),
    CONSTRAINT ck_otp_request_verification_state CHECK (((status = 'verified'::text) = (verified_at IS NOT NULL))),
    CONSTRAINT ck_otp_request_wrong_try_count CHECK ((wrong_try_count >= 0))
);
COMMENT ON COLUMN otp_request.expires_at IS 'Null until the first code is sent.';
CREATE INDEX ix_otp_request_phone_number ON otp_request USING btree (phone_number);
CREATE UNIQUE INDEX uq_otp_request_phone_number_pending ON otp_request USING btree (phone_number) WHERE (status = 'pending'::text);

-- otp_send ----------------------------------------------------------------
CREATE TABLE otp_send (
    id uuid NOT NULL,
    otp_request_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    status text DEFAULT 'reserved'::text NOT NULL,
    sent_at timestamp with time zone,
    device_id text,
    client_ip text,
    CONSTRAINT pk_otp_send PRIMARY KEY (id),
    CONSTRAINT fk_otp_send_otp_request_id_otp_request FOREIGN KEY (otp_request_id) REFERENCES otp_request(id) ON DELETE CASCADE,
    CONSTRAINT ck_otp_send_delivery_order CHECK ((sent_at >= created_at)),
    CONSTRAINT ck_otp_send_delivery_state CHECK (((status = 'sent'::text) = (sent_at IS NOT NULL))),
    CONSTRAINT ck_otp_send_status CHECK ((status = ANY (ARRAY['reserved'::text, 'sent'::text, 'failed'::text])))
);
CREATE INDEX ix_otp_send_client_ip_created_at ON otp_send USING btree (client_ip, created_at);
CREATE INDEX ix_otp_send_device_id_created_at ON otp_send USING btree (device_id, created_at);
CREATE INDEX ix_otp_send_otp_request_id_created_at ON otp_send USING btree (otp_request_id, created_at);

-- patient_allergy ---------------------------------------------------------
CREATE TABLE patient_allergy (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    kind text NOT NULL,
    code text NOT NULL,
    other_text text,
    care_circle_id uuid NOT NULL,
    CONSTRAINT pk_patient_allergy PRIMARY KEY (id),
    CONSTRAINT uq_patient_allergy_care_circle_id_kind_code UNIQUE (care_circle_id, kind, code),
    CONSTRAINT fk_patient_allergy_care_circle_id_care_circle FOREIGN KEY (care_circle_id) REFERENCES care_circle(id) ON DELETE CASCADE,
    CONSTRAINT ck_patient_allergy_kind_code CHECK ((((kind = 'medication'::text) AND (code = ANY (ARRAY['penicillin'::text, 'sulfa'::text, 'cephalosporins'::text, 'quinolones'::text, 'aspirin'::text, 'nsaids'::text, 'opioids'::text, 'contrast_media'::text, 'anesthesia'::text, 'other'::text]))) OR ((kind = 'food'::text) AND (code = ANY (ARRAY['milk'::text, 'eggs'::text, 'fish'::text, 'shellfish'::text, 'tree_nuts'::text, 'peanuts'::text, 'wheat'::text, 'soy'::text, 'sesame'::text, 'other'::text]))))),
    CONSTRAINT ck_patient_allergy_other_text CHECK ((((code = 'other'::text) AND (other_text IS NOT NULL) AND ((length(btrim(other_text)) >= 1) AND (length(btrim(other_text)) <= 100))) OR ((code <> 'other'::text) AND (other_text IS NULL))))
);

-- patient_condition -------------------------------------------------------
CREATE TABLE patient_condition (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    other_text text,
    care_circle_id uuid NOT NULL,
    CONSTRAINT pk_patient_condition PRIMARY KEY (id),
    CONSTRAINT uq_patient_condition_care_circle_id_code UNIQUE (care_circle_id, code),
    CONSTRAINT fk_patient_condition_care_circle_id_care_circle FOREIGN KEY (care_circle_id) REFERENCES care_circle(id) ON DELETE CASCADE,
    CONSTRAINT ck_patient_condition_code CHECK ((code = ANY (ARRAY['diabetes'::text, 'hypertension'::text, 'cholesterol'::text, 'heart'::text, 'stroke'::text, 'asthma'::text, 'kidney'::text, 'thyroid'::text, 'arthritis'::text, 'osteoporosis'::text, 'dementia'::text, 'depression_anxiety'::text, 'cancer'::text, 'other'::text]))),
    CONSTRAINT ck_patient_condition_other_text CHECK ((((code = 'other'::text) AND (other_text IS NOT NULL) AND ((length(btrim(other_text)) >= 1) AND (length(btrim(other_text)) <= 100))) OR ((code <> 'other'::text) AND (other_text IS NULL))))
);

-- task_snooze -------------------------------------------------------------
CREATE TABLE task_snooze (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    care_circle_id uuid NOT NULL,
    task text NOT NULL,
    task_id uuid NOT NULL,
    scheduled_on date NOT NULL,
    time_of_day time without time zone NOT NULL,
    minutes integer NOT NULL,
    remind_at timestamp with time zone NOT NULL,
    snoozed_by_account_id uuid,
    snoozed_at timestamp with time zone NOT NULL,
    notified_at timestamp with time zone,
    CONSTRAINT pk_task_snooze PRIMARY KEY (id),
    CONSTRAINT uq_task_snooze_task UNIQUE (task, task_id, scheduled_on, time_of_day),
    CONSTRAINT fk_task_snooze_care_circle_id_care_circle FOREIGN KEY (care_circle_id) REFERENCES care_circle(id) ON DELETE CASCADE,
    CONSTRAINT fk_task_snooze_snoozed_by_account_id_account FOREIGN KEY (snoozed_by_account_id) REFERENCES account(id) ON DELETE SET NULL,
    CONSTRAINT ck_task_snooze_minutes_range CHECK (((minutes >= 1) AND (minutes <= 720))),
    CONSTRAINT ck_task_snooze_remind_order CHECK ((remind_at > snoozed_at)),
    CONSTRAINT ck_task_snooze_task_kind CHECK ((task = ANY (ARRAY['dose'::text, 'measurement'::text])))
);
CREATE INDEX ix_task_snooze_care_circle_id ON task_snooze USING btree (care_circle_id);
CREATE INDEX ix_task_snooze_waiting ON task_snooze USING btree (remind_at) WHERE (notified_at IS NULL);

-- Functions the triggers call -------------------------------------------

CREATE FUNCTION fn_assert_care_circle(circle_key uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$;

CREATE FUNCTION fn_assert_medication_plan(plan_key uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
              ('inhaler', 'puff'), ('nebulizer', 'mL'),
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
$function$;

CREATE FUNCTION fn_check_care_circle()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$;

CREATE FUNCTION fn_check_medication_dose()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$;

CREATE FUNCTION fn_check_medication_plan()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$;

CREATE FUNCTION fn_guard_account_care()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$;

CREATE FUNCTION fn_lock_care_circle()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$;

CREATE FUNCTION fn_lock_medication_circle()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$;

CREATE FUNCTION fn_medication_treatment_period(plan_row medication_plan, version_row medication_plan_version)
 RETURNS daterange
 LANGUAGE plpgsql
 STABLE
AS $function$
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
$function$;

-- Triggers -------------------------------------------------------------

CREATE TRIGGER trg_account_guard_care BEFORE UPDATE OF app_mode, first_name, last_name, display_name, birth_date, city ON account FOR EACH ROW EXECUTE FUNCTION fn_guard_account_care();
CREATE CONSTRAINT TRIGGER trg_care_circle_check_complete AFTER INSERT OR UPDATE OF account_id ON care_circle DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION fn_check_care_circle();
CREATE TRIGGER trg_care_circle_lock BEFORE INSERT OR UPDATE OF account_id ON care_circle FOR EACH ROW EXECUTE FUNCTION fn_lock_care_circle();
CREATE CONSTRAINT TRIGGER trg_care_circle_manager_check_complete AFTER INSERT OR DELETE OR UPDATE ON care_circle_manager DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION fn_check_care_circle();
CREATE TRIGGER trg_care_circle_manager_lock BEFORE INSERT OR DELETE OR UPDATE ON care_circle_manager FOR EACH ROW EXECUTE FUNCTION fn_lock_care_circle();
CREATE CONSTRAINT TRIGGER trg_medication_dose_record_check_valid AFTER INSERT OR UPDATE OF schedule_id, scheduled_on ON medication_dose_record DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION fn_check_medication_dose();
CREATE CONSTRAINT TRIGGER trg_medication_plan_check_complete AFTER INSERT OR DELETE OR UPDATE OF care_circle_id, stopped_at ON medication_plan DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION fn_check_medication_plan();
CREATE TRIGGER trg_medication_plan_lock BEFORE INSERT OR DELETE OR UPDATE ON medication_plan FOR EACH ROW EXECUTE FUNCTION fn_lock_medication_circle();
CREATE CONSTRAINT TRIGGER trg_medication_plan_version_check_complete AFTER INSERT OR DELETE OR UPDATE OF medication_plan_id, normalized_name, dosage_form, treatment_starts_on, treatment_ends_on, effective_from_on, effective_until_on, cancelled_at ON medication_plan_version DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION fn_check_medication_plan();
CREATE TRIGGER trg_medication_plan_version_lock BEFORE INSERT OR DELETE OR UPDATE ON medication_plan_version FOR EACH ROW EXECUTE FUNCTION fn_lock_medication_circle();
CREATE CONSTRAINT TRIGGER trg_medication_schedule_check_complete AFTER INSERT OR DELETE OR UPDATE OF plan_version_id, time_of_day, dose_unit, repeat, interval_days ON medication_schedule DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION fn_check_medication_plan();
CREATE TRIGGER trg_medication_schedule_lock BEFORE INSERT OR DELETE OR UPDATE ON medication_schedule FOR EACH ROW EXECUTE FUNCTION fn_lock_medication_circle();
CREATE CONSTRAINT TRIGGER trg_medication_schedule_day_check_complete AFTER INSERT OR DELETE OR UPDATE ON medication_schedule_day DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION fn_check_medication_plan();
CREATE TRIGGER trg_medication_schedule_day_lock BEFORE INSERT OR DELETE OR UPDATE ON medication_schedule_day FOR EACH ROW EXECUTE FUNCTION fn_lock_medication_circle();
CREATE CONSTRAINT TRIGGER trg_medication_schedule_month_day_check_complete AFTER INSERT OR DELETE OR UPDATE ON medication_schedule_month_day DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION fn_check_medication_plan();
CREATE TRIGGER trg_medication_schedule_month_day_lock BEFORE INSERT OR DELETE OR UPDATE ON medication_schedule_month_day FOR EACH ROW EXECUTE FUNCTION fn_lock_medication_circle();
