/*
    Kronos - 14_rf05_expedientes_sp.sql

    RF-05 Gestion de Expedientes Clinicos.
    Version final y correcta (incluye fix de resultsets desfasados, las
    2 funciones agregadas despues (tipos de documento y borrado de
    adjuntos), fix de transaccion en registro de paciente, y los SPs de
    catalogo para condiciones medicas, medicamentos y ruta de adjuntos).

    Requiere: 02_tables.sql, 07_stored_procedures.sql, 99_seed_structure_data.sql

    Codigos de error personalizados (THROW):
      50100 -> Error de validacion generico
      50101 -> Paciente no existe o esta inactivo
      50102 -> El expediente no existe
      50103 -> El paciente ya tiene un expediente abierto
      50104 -> El expediente esta cerrado, no se puede modificar
      50105 -> La condicion medica indicada no existe en el catalogo
      50106 -> El medicamento indicado no existe en el catalogo
      50107 -> El tipo de documento indicado no es valido
      50108 -> El adjunto indicado no existe
      50109 -> El id de catalogo indicado no pertenece al catalogo esperado
*/

SET NOCOUNT ON;
USE Kronos;
GO


INSERT INTO staff_tbl_members
    (staff_role_id, first_name, last_name, identification_number, phone, email, is_active, deleted, created_at)
SELECT r.id, N'Ana', N'Rodríguez', N'1-1111-1111', N'8888-1111', N'ana.rodriguez@kronos.local', 1, 0, SYSDATETIME()
FROM staff_tbl_roles r WHERE r.name = N'Médico'

UNION ALL

SELECT r.id, N'Carlos', N'Jiménez', N'1-2222-2222', N'8888-2222', N'carlos.jimenez@kronos.local', 1, 0, SYSDATETIME()
FROM staff_tbl_roles r WHERE r.name = N'Enfermería'

UNION ALL

SELECT r.id, N'Laura', N'Vargas', N'1-3333-3333', N'8888-3333', N'laura.vargas@kronos.local', 1, 0, SYSDATETIME()
FROM staff_tbl_roles r WHERE r.name = N'Administrativo';

-------------------------------------------------------------------------------
-- 1. Apertura de expediente
-------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE medical_sp_records_open
    @patient_id int,
    @user_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (
        SELECT 1 FROM patient_tbl_patients
        WHERE id = @patient_id AND deleted = 0 AND is_active = 1
    )
        THROW 50101, N'El paciente indicado no existe o está inactivo.', 1;

    IF EXISTS (
        SELECT 1
        FROM medical_tbl_records r
        INNER JOIN config_tbl_catalog_items st ON st.id = r.status_id
        WHERE r.patient_id = @patient_id AND r.deleted = 0
          AND st.value IN (N'open', N'suspended')
    )
        THROW 50103, N'El paciente ya tiene un expediente abierto o suspendido.', 1;

    DECLARE @open_status_id int;
    SELECT @open_status_id = ci.id
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'medical_record_status' AND ci.value = N'open';

    DECLARE @new_record_id int;
    DECLARE @output_ids TABLE (id int);
    DECLARE @audit_discard TABLE (success bit, audit_log_id numeric(38,0));

    BEGIN TRAN;

        INSERT INTO medical_tbl_records (patient_id, record_number, opened_at, status_id, created_at)
        OUTPUT inserted.id INTO @output_ids
        VALUES (@patient_id, N'TEMP', SYSDATETIME(), @open_status_id, SYSDATETIME());

        SELECT @new_record_id = id FROM @output_ids;

        UPDATE medical_tbl_records
        SET record_number = N'EXP-' + RIGHT(N'000000' + CAST(@new_record_id AS nvarchar(10)), 6)
        WHERE id = @new_record_id;

        DECLARE @audit_new_value nvarchar(200);
        SET @audit_new_value = N'patient_id=' + CAST(@patient_id AS nvarchar(20));

        INSERT INTO @audit_discard
        EXEC access_sp_internal_audit_log_create
            @user_id = @user_id,
            @action = N'medical_records_open',
            @entity_name = N'medical_tbl_records',
            @entity_id = @new_record_id,
            @new_value = @audit_new_value;

    COMMIT;

    SELECT CAST(1 AS bit) AS success, @new_record_id AS medical_record_id;
END;
GO

-------------------------------------------------------------------------------
-- 2. Cambio de estado del expediente
-------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE medical_sp_records_update_status
    @medical_record_id int,
    @status_id int,
    @user_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @current_status_id int;
    SELECT @current_status_id = status_id
    FROM medical_tbl_records
    WHERE id = @medical_record_id AND deleted = 0;

    IF @current_status_id IS NULL
        THROW 50102, N'El expediente indicado no existe.', 1;

    DECLARE @new_status_value nvarchar(150);
    SELECT @new_status_value = ci.value
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'medical_record_status' AND ci.id = @status_id;

    IF @new_status_value IS NULL
        THROW 50109, N'El estado indicado no es válido.', 1;

    DECLARE @audit_discard TABLE (success bit, audit_log_id numeric(38,0));

    BEGIN TRAN;

        UPDATE medical_tbl_records
        SET status_id = @status_id,
            closed_at = CASE WHEN @new_status_value = N'closed' THEN SYSDATETIME() ELSE NULL END,
            updated_at = SYSDATETIME()
        WHERE id = @medical_record_id;

        DECLARE @audit_old_value nvarchar(200), @audit_new_value nvarchar(200);
        SET @audit_old_value = N'status_id=' + CAST(@current_status_id AS nvarchar(10));
        SET @audit_new_value = N'status_id=' + CAST(@status_id AS nvarchar(10));

        INSERT INTO @audit_discard
        EXEC access_sp_internal_audit_log_create
            @user_id = @user_id,
            @action = N'medical_records_update_status',
            @entity_name = N'medical_tbl_records',
            @entity_id = @medical_record_id,
            @old_value = @audit_old_value,
            @new_value = @audit_new_value;

    COMMIT;

    SELECT CAST(1 AS bit) AS success, @medical_record_id AS medical_record_id;
END;
GO

-------------------------------------------------------------------------------
-- 3. Notas clinicas
-------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE medical_sp_record_notes_create
    @medical_record_id int,
    @patient_id int,
    @staff_member_id int,
    @note_type_id int,
    @note_text nvarchar(max),
    @user_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NULLIF(LTRIM(RTRIM(@note_text)), N'') IS NULL
        THROW 50100, N'El texto de la nota es requerido.', 1;

    DECLARE @status_value nvarchar(150);
    SELECT @status_value = st.value
    FROM medical_tbl_records r
    INNER JOIN config_tbl_catalog_items st ON st.id = r.status_id
    WHERE r.id = @medical_record_id AND r.deleted = 0;

    IF @status_value IS NULL
        THROW 50102, N'El expediente indicado no existe.', 1;

    IF @status_value = N'closed'
        THROW 50104, N'El expediente está cerrado, no se puede modificar.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM config_tbl_catalog_items ci
        INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
        WHERE c.name = N'medical_note_type' AND ci.id = @note_type_id
    )
        THROW 50109, N'El tipo de nota indicado no es válido.', 1;

    DECLARE @new_note_id int;
    DECLARE @output_ids TABLE (id int);
    DECLARE @audit_discard TABLE (success bit, audit_log_id numeric(38,0));

    BEGIN TRAN;

        INSERT INTO medical_tbl_record_notes
            (medical_record_id, patient_id, staff_member_id, note_type_id, note_text, created_at)
        OUTPUT inserted.id INTO @output_ids
        VALUES (@medical_record_id, @patient_id, @staff_member_id, @note_type_id, @note_text, SYSDATETIME());

        SELECT @new_note_id = id FROM @output_ids;

        INSERT INTO @audit_discard
        EXEC access_sp_internal_audit_log_create
            @user_id = @user_id,
            @action = N'medical_record_notes_create',
            @entity_name = N'medical_tbl_record_notes',
            @entity_id = @new_note_id;

    COMMIT;

    SELECT CAST(1 AS bit) AS success, @new_note_id AS note_id;
END;
GO

-------------------------------------------------------------------------------
-- 4. Diagnostico (condiciones medicas del paciente)
-------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE medical_sp_patient_conditions_upsert
    @id int = NULL,
    @patient_id int,
    @medical_condition_id int,
    @diagnosed_at date = NULL,
    @status_id int = NULL,
    @notes nvarchar(max) = NULL,
    @user_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (
        SELECT 1 FROM patient_tbl_patients
        WHERE id = @patient_id AND deleted = 0 AND is_active = 1
    )
        THROW 50101, N'El paciente indicado no existe o está inactivo.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM medical_tbl_conditions
        WHERE id = @medical_condition_id AND deleted = 0 AND is_active = 1
    )
        THROW 50105, N'La condición médica indicada no existe en el catálogo.', 1;

    IF @status_id IS NULL
    BEGIN
        SELECT @status_id = ci.id
        FROM config_tbl_catalog_items ci
        INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
        WHERE c.name = N'condition_status' AND ci.value = N'active';
    END
    ELSE IF NOT EXISTS (
        SELECT 1 FROM config_tbl_catalog_items ci
        INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
        WHERE c.name = N'condition_status' AND ci.id = @status_id
    )
        THROW 50109, N'El estado de condición indicado no es válido.', 1;

    DECLARE @result_id int;
    DECLARE @output_ids TABLE (id int);
    DECLARE @audit_discard TABLE (success bit, audit_log_id numeric(38,0));

    BEGIN TRAN;

        IF @id IS NULL
        BEGIN
            INSERT INTO medical_tbl_patient_conditions
                (patient_id, medical_condition_id, diagnosed_at, status_id, notes, created_at)
            OUTPUT inserted.id INTO @output_ids
            VALUES (@patient_id, @medical_condition_id, @diagnosed_at, @status_id, @notes, SYSDATETIME());

            SELECT @result_id = id FROM @output_ids;

            INSERT INTO @audit_discard
            EXEC access_sp_internal_audit_log_create
                @user_id = @user_id, @action = N'medical_patient_conditions_create',
                @entity_name = N'medical_tbl_patient_conditions', @entity_id = @result_id;
        END
        ELSE
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM medical_tbl_patient_conditions
                WHERE id = @id AND patient_id = @patient_id AND deleted = 0
            )
                THROW 50100, N'La condición médica indicada no existe para este paciente.', 1;

            UPDATE medical_tbl_patient_conditions
            SET medical_condition_id = @medical_condition_id,
                diagnosed_at = @diagnosed_at,
                status_id = @status_id,
                notes = @notes,
                updated_at = SYSDATETIME()
            WHERE id = @id;

            SET @result_id = @id;

            INSERT INTO @audit_discard
            EXEC access_sp_internal_audit_log_create
                @user_id = @user_id, @action = N'medical_patient_conditions_update',
                @entity_name = N'medical_tbl_patient_conditions', @entity_id = @result_id;
        END

    COMMIT;

    SELECT CAST(1 AS bit) AS success, @result_id AS patient_condition_id;
END;
GO

-------------------------------------------------------------------------------
-- 5. Tratamientos (medicamentos del paciente)
-------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE medical_sp_patient_medications_upsert
    @id int = NULL,
    @patient_id int,
    @medical_medication_id int,
    @dosage nvarchar(100) = NULL,
    @frequency nvarchar(100) = NULL,
    @start_date date = NULL,
    @end_date date = NULL,
    @notes nvarchar(max) = NULL,
    @user_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (
        SELECT 1 FROM patient_tbl_patients
        WHERE id = @patient_id AND deleted = 0 AND is_active = 1
    )
        THROW 50101, N'El paciente indicado no existe o está inactivo.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM medical_tbl_medications
        WHERE id = @medical_medication_id AND deleted = 0 AND is_active = 1
    )
        THROW 50106, N'El medicamento indicado no existe en el catálogo.', 1;

    IF @end_date IS NOT NULL AND @start_date IS NOT NULL AND @end_date < @start_date
        THROW 50100, N'La fecha de fin no puede ser anterior a la fecha de inicio.', 1;

    DECLARE @result_id int;
    DECLARE @output_ids TABLE (id int);
    DECLARE @audit_discard TABLE (success bit, audit_log_id numeric(38,0));

    BEGIN TRAN;

        IF @id IS NULL
        BEGIN
            INSERT INTO medical_tbl_patient_medications
                (patient_id, medical_medication_id, dosage, frequency, start_date, end_date, notes, created_at)
            OUTPUT inserted.id INTO @output_ids
            VALUES (@patient_id, @medical_medication_id, @dosage, @frequency, @start_date, @end_date, @notes, SYSDATETIME());

            SELECT @result_id = id FROM @output_ids;

            INSERT INTO @audit_discard
            EXEC access_sp_internal_audit_log_create
                @user_id = @user_id, @action = N'medical_patient_medications_create',
                @entity_name = N'medical_tbl_patient_medications', @entity_id = @result_id;
        END
        ELSE
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM medical_tbl_patient_medications
                WHERE id = @id AND patient_id = @patient_id AND deleted = 0
            )
                THROW 50100, N'El medicamento indicado no existe para este paciente.', 1;

            UPDATE medical_tbl_patient_medications
            SET medical_medication_id = @medical_medication_id,
                dosage = @dosage,
                frequency = @frequency,
                start_date = @start_date,
                end_date = @end_date,
                notes = @notes,
                updated_at = SYSDATETIME()
            WHERE id = @id;

            SET @result_id = @id;

            INSERT INTO @audit_discard
            EXEC access_sp_internal_audit_log_create
                @user_id = @user_id, @action = N'medical_patient_medications_update',
                @entity_name = N'medical_tbl_patient_medications', @entity_id = @result_id;
        END

    COMMIT;

    SELECT CAST(1 AS bit) AS success, @result_id AS patient_medication_id;
END;
GO

-------------------------------------------------------------------------------
-- 6. Registro de adjuntos
-------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE medical_sp_record_attachments_create
    @medical_record_id int,
    @patient_id int,
    @document_type_id int,
    @file_name nvarchar(255),
    @file_path nvarchar(1000),
    @content_type nvarchar(100) = NULL,
    @file_size bigint = NULL,
    @uploaded_by_user_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM medical_tbl_records WHERE id = @medical_record_id AND deleted = 0)
        THROW 50102, N'El expediente indicado no existe.', 1;

    IF NOT EXISTS (SELECT 1 FROM config_tbl_document_types WHERE id = @document_type_id AND deleted = 0 AND is_active = 1)
        THROW 50107, N'El tipo de documento indicado no es válido.', 1;

    DECLARE @new_attachment_id int;
    DECLARE @output_ids TABLE (id int);
    DECLARE @audit_discard TABLE (success bit, audit_log_id numeric(38,0));

    BEGIN TRAN;

        INSERT INTO medical_tbl_record_attachments
            (medical_record_id, patient_id, document_type_id, file_name, file_path, content_type, file_size, uploaded_by_user_id, uploaded_at)
        OUTPUT inserted.id INTO @output_ids
        VALUES (@medical_record_id, @patient_id, @document_type_id, @file_name, @file_path, @content_type, @file_size, @uploaded_by_user_id, SYSDATETIME());

        SELECT @new_attachment_id = id FROM @output_ids;

        INSERT INTO @audit_discard
        EXEC access_sp_internal_audit_log_create
            @user_id = @uploaded_by_user_id,
            @action = N'medical_record_attachments_create',
            @entity_name = N'medical_tbl_record_attachments',
            @entity_id = @new_attachment_id;

    COMMIT;

    SELECT CAST(1 AS bit) AS success, @new_attachment_id AS attachment_id;
END;
GO

-------------------------------------------------------------------------------
-- 7. Descarga de adjuntos (deja registro de acceso)
-------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE medical_sp_record_attachments_download
    @attachment_id int,
    @user_id int,
    @ip_address nvarchar(45) = NULL,
    @device_info nvarchar(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @medical_record_id int, @patient_id int;

    SELECT @medical_record_id = medical_record_id, @patient_id = patient_id
    FROM medical_tbl_record_attachments
    WHERE id = @attachment_id AND deleted = 0;

    IF @medical_record_id IS NULL
        THROW 50108, N'El adjunto indicado no existe.', 1;

    DECLARE @download_type_id int;
    SELECT @download_type_id = ci.id
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'medical_record_access_type' AND ci.value = N'download';

    DECLARE @log_discard TABLE (success bit, access_log_id numeric(38,0));

    INSERT INTO @log_discard
    EXEC medical_sp_records_log_access
        @medical_record_id = @medical_record_id,
        @patient_id = @patient_id,
        @user_id = @user_id,
        @access_type_id = @download_type_id,
        @access_reason = N'Descarga de adjunto.',
        @ip_address = @ip_address,
        @device_info = @device_info;

    SELECT
        id, medical_record_id, patient_id, document_type_id,
        file_name, file_path, content_type, file_size
    FROM medical_tbl_record_attachments
    WHERE id = @attachment_id;
END;
GO

-------------------------------------------------------------------------------
-- 8. Eliminar adjunto (borrado logico)
-------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE medical_sp_record_attachments_delete
    @attachment_id int,
    @user_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM medical_tbl_record_attachments WHERE id = @attachment_id AND deleted = 0)
        THROW 50108, N'El adjunto indicado no existe.', 1;

    DECLARE @audit_discard TABLE (success bit, audit_log_id numeric(38,0));

    BEGIN TRAN;

        UPDATE medical_tbl_record_attachments
        SET deleted = 1
        WHERE id = @attachment_id;

        INSERT INTO @audit_discard
        EXEC access_sp_internal_audit_log_create
            @user_id = @user_id,
            @action = N'medical_record_attachments_delete',
            @entity_name = N'medical_tbl_record_attachments',
            @entity_id = @attachment_id;

    COMMIT;

    SELECT CAST(1 AS bit) AS success, @attachment_id AS attachment_id;
END;
GO

-------------------------------------------------------------------------------
-- 9. Detalle completo del expediente (con notas paginadas)
-------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE medical_sp_orc_records_get_detail
    @medical_record_id int = NULL,
    @patient_id int = NULL,
    @accessed_by_user_id int,
    @access_reason nvarchar(500) = NULL,
    @ip_address nvarchar(45) = NULL,
    @device_info nvarchar(500) = NULL,
    @page_number int = 1,
    @page_size int = 10
AS
BEGIN
    SET NOCOUNT ON;

    IF @medical_record_id IS NULL AND @patient_id IS NOT NULL
    BEGIN
        SELECT TOP (1) @medical_record_id = r.id
        FROM medical_tbl_records r
        INNER JOIN config_tbl_catalog_items st ON st.id = r.status_id
        WHERE r.patient_id = @patient_id AND r.deleted = 0
        ORDER BY CASE WHEN st.value IN (N'open', N'suspended') THEN 0 ELSE 1 END, r.opened_at DESC;
    END

    IF @medical_record_id IS NULL OR NOT EXISTS (SELECT 1 FROM medical_tbl_records WHERE id = @medical_record_id AND deleted = 0)
        THROW 50102, N'El expediente indicado no existe.', 1;

    DECLARE @view_type_id int;
    SELECT @view_type_id = ci.id
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'medical_record_access_type' AND ci.value = N'view';

    DECLARE @record_patient_id int;
    SELECT @record_patient_id = patient_id FROM medical_tbl_records WHERE id = @medical_record_id;

    DECLARE @log_discard TABLE (success bit, access_log_id numeric(38,0));

    INSERT INTO @log_discard
    EXEC medical_sp_records_log_access
        @medical_record_id = @medical_record_id,
        @patient_id = @record_patient_id,
        @user_id = @accessed_by_user_id,
        @access_type_id = @view_type_id,
        @access_reason = @access_reason,
        @ip_address = @ip_address,
        @device_info = @device_info;

    -- 1) Expediente + paciente
    SELECT
        r.id, r.patient_id, p.first_name, p.last_name, p.identification_number, p.birth_date,
        p.phone, p.email, r.record_number, r.opened_at, r.closed_at,
        r.status_id, st.name AS status_name, st.value AS status_value,
        r.created_at, r.updated_at
    FROM medical_tbl_records r
    INNER JOIN patient_tbl_patients p ON p.id = r.patient_id
    INNER JOIN config_tbl_catalog_items st ON st.id = r.status_id
    WHERE r.id = @medical_record_id;

    -- 2) Notas clinicas paginadas + total_count
    SELECT
        n.id, n.medical_record_id, n.patient_id, n.staff_member_id,
        s.first_name AS staff_first_name, s.last_name AS staff_last_name,
        n.note_type_id, nt.name AS note_type_name, n.note_text, n.created_at,
        COUNT(*) OVER() AS total_count
    FROM medical_tbl_record_notes n
    INNER JOIN staff_tbl_members s ON s.id = n.staff_member_id
    INNER JOIN config_tbl_catalog_items nt ON nt.id = n.note_type_id
    WHERE n.medical_record_id = @medical_record_id AND n.deleted = 0
    ORDER BY n.created_at DESC
    OFFSET (@page_number - 1) * @page_size ROWS FETCH NEXT @page_size ROWS ONLY;

    -- 3) Condiciones (diagnostico)
    SELECT
        pc.id, pc.patient_id, pc.medical_condition_id, mc.name AS condition_name,
        pc.diagnosed_at, pc.status_id, cs.name AS status_name, pc.notes, pc.created_at, pc.updated_at
    FROM medical_tbl_patient_conditions pc
    INNER JOIN medical_tbl_conditions mc ON mc.id = pc.medical_condition_id
    LEFT JOIN config_tbl_catalog_items cs ON cs.id = pc.status_id
    WHERE pc.patient_id = @record_patient_id AND pc.deleted = 0
    ORDER BY pc.diagnosed_at DESC;

    -- 4) Medicamentos (tratamientos)
    SELECT
        pm.id, pm.patient_id, pm.medical_medication_id, mm.name AS medication_name,
        pm.dosage, pm.frequency, pm.start_date, pm.end_date, pm.notes, pm.created_at, pm.updated_at
    FROM medical_tbl_patient_medications pm
    INNER JOIN medical_tbl_medications mm ON mm.id = pm.medical_medication_id
    WHERE pm.patient_id = @record_patient_id AND pm.deleted = 0
    ORDER BY pm.start_date DESC;

    -- 5) Adjuntos
    SELECT
        a.id, a.medical_record_id, a.document_type_id, dt.name AS document_type_name,
        a.file_name, a.content_type, a.file_size, a.uploaded_by_user_id, a.uploaded_at
    FROM medical_tbl_record_attachments a
    INNER JOIN config_tbl_document_types dt ON dt.id = a.document_type_id
    WHERE a.medical_record_id = @medical_record_id AND a.deleted = 0
    ORDER BY a.uploaded_at DESC;
END;
GO

-------------------------------------------------------------------------------
-- 10. Registro de paciente nuevo (dependencia del flujo alterno de RF-05)
--     CORREGIDO: la apertura de expediente ahora va dentro de la MISMA
--     transaccion que el registro del paciente. Antes, si el paso de abrir
--     expediente fallaba, el paciente ya habia quedado guardado (COMMIT
--     previo) pero el usuario veia un error, generando datos huerfanos.
-------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE patient_sp_orc_patients_register
    @first_name nvarchar(100),
    @last_name nvarchar(150),
    @identification_number nvarchar(50) = NULL,
    @birth_date date = NULL,
    @gender_id int = NULL,
    @phone nvarchar(30) = NULL,
    @email nvarchar(256) = NULL,
    @address_id int = NULL,
    @contacts_json nvarchar(max) = NULL,
    @open_medical_record bit = 0,
    @created_by_user_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @contacts_json IS NOT NULL AND ISJSON(@contacts_json) <> 1
        THROW 50000, N'contacts_json debe ser un JSON válido.', 1;

    IF NULLIF(LTRIM(RTRIM(@first_name)), N'') IS NULL OR NULLIF(LTRIM(RTRIM(@last_name)), N'') IS NULL
        THROW 50000, N'El nombre y apellido del paciente son requeridos.', 1;

    IF @identification_number IS NOT NULL AND EXISTS (
        SELECT 1 FROM patient_tbl_patients
        WHERE identification_number = @identification_number AND deleted = 0
    )
        THROW 50000, N'Ya existe un paciente registrado con esa identificación.', 1;

    DECLARE @active_status_id int;
    SELECT @active_status_id = ci.id
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'patient_status' AND ci.value = N'active';

    DECLARE @open_status_id int;
    IF @open_medical_record = 1
    BEGIN
        SELECT @open_status_id = ci.id
        FROM config_tbl_catalog_items ci
        INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
        WHERE c.name = N'medical_record_status' AND ci.value = N'open';
    END

    DECLARE @new_patient_id int;
    DECLARE @new_medical_record_id int = NULL;
    DECLARE @output_ids TABLE (id int);
    DECLARE @audit_discard TABLE (success bit, audit_log_id numeric(38,0));
    DECLARE @register_audit_new_value nvarchar(200);
    DECLARE @open_audit_new_value nvarchar(200);

    BEGIN TRAN;

        INSERT INTO patient_tbl_patients
            (address_id, first_name, last_name, identification_number, birth_date, gender_id, phone, email, status_id, created_at)
        OUTPUT inserted.id INTO @output_ids
        VALUES (@address_id, @first_name, @last_name, @identification_number, @birth_date, @gender_id, @phone, @email, @active_status_id, SYSDATETIME());

        SELECT @new_patient_id = id FROM @output_ids;

        IF @contacts_json IS NOT NULL
        BEGIN
            INSERT INTO patient_tbl_contacts
                (patient_id, contact_type_id, full_name, relationship, phone, email, is_primary_contact, is_emergency_contact, notes, created_at)
            SELECT
                @new_patient_id, j.contact_type_id, j.full_name, j.relationship, j.phone, j.email,
                ISNULL(j.is_primary_contact, 0), ISNULL(j.is_emergency_contact, 0), j.notes, SYSDATETIME()
            FROM OPENJSON(@contacts_json)
            WITH (
                contact_type_id int '$.contact_type_id',
                full_name nvarchar(200) '$.full_name',
                relationship nvarchar(100) '$.relationship',
                phone nvarchar(30) '$.phone',
                email nvarchar(256) '$.email',
                is_primary_contact bit '$.is_primary_contact',
                is_emergency_contact bit '$.is_emergency_contact',
                notes nvarchar(max) '$.notes'
            ) j;
        END

        SET @register_audit_new_value = N'patient_id=' + CAST(@new_patient_id AS nvarchar(20));

        INSERT INTO @audit_discard
        EXEC access_sp_internal_audit_log_create
            @user_id = @created_by_user_id,
            @action = N'patient_patients_register',
            @entity_name = N'patient_tbl_patients',
            @entity_id = @new_patient_id,
            @new_value = @register_audit_new_value;

        IF @open_medical_record = 1
        BEGIN
            INSERT INTO medical_tbl_records (patient_id, record_number, opened_at, status_id, created_at)
            OUTPUT inserted.id INTO @output_ids
            VALUES (@new_patient_id, N'TEMP', SYSDATETIME(), @open_status_id, SYSDATETIME());

            SELECT @new_medical_record_id = id FROM @output_ids;

            UPDATE medical_tbl_records
            SET record_number = N'EXP-' + RIGHT(N'000000' + CAST(@new_medical_record_id AS nvarchar(10)), 6)
            WHERE id = @new_medical_record_id;

            SET @open_audit_new_value = N'patient_id=' + CAST(@new_patient_id AS nvarchar(20));

            INSERT INTO @audit_discard
            EXEC access_sp_internal_audit_log_create
                @user_id = @created_by_user_id,
                @action = N'medical_records_open',
                @entity_name = N'medical_tbl_records',
                @entity_id = @new_medical_record_id,
                @new_value = @open_audit_new_value;
        END

    COMMIT;

    SELECT CAST(1 AS bit) AS success, @new_patient_id AS patient_id, @new_medical_record_id AS medical_record_id;
END;
GO

-------------------------------------------------------------------------------
-- 11. Listado de tipos de documento (para el combo de adjuntos)
-------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE config_sp_document_types_list
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        id,
        name,
        description
    FROM config_tbl_document_types
    WHERE deleted = 0
      AND is_active = 1
    ORDER BY name;
END;
GO

-------------------------------------------------------------------------------
-- 12. Listado de condiciones medicas (para el combo de Diagnostico)
-------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE medical_sp_conditions_list
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        id,
        name,
        description
    FROM medical_tbl_conditions
    WHERE deleted = 0
      AND is_active = 1
    ORDER BY name;
END;
GO

-------------------------------------------------------------------------------
-- 13. Listado de medicamentos (para el combo de Tratamientos)
-------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE medical_sp_medications_list
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        id,
        name,
        description
    FROM medical_tbl_medications
    WHERE deleted = 0
      AND is_active = 1
    ORDER BY name;
END;
GO

-------------------------------------------------------------------------------
-- 14. Ruta base de adjuntos (reemplaza el SQL crudo que habia en la API)
-------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE config_sp_settings_get_medical_attachments_root
AS
BEGIN
    SET NOCOUNT ON;

    SELECT setting_value
    FROM config_tbl_settings
    WHERE setting_type = N'files'
      AND setting_name = N'medical_attachments_root'
      AND deleted = 0;
END;
GO

SET NOCOUNT OFF;
PRINT 'RF-05 (Gestión de Expedientes Clínicos): Stored Procedures completos y correctos ejecutados.';
GO