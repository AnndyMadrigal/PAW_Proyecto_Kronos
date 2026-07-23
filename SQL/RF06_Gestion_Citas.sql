/*
    Kronos - RF06_Gestion_Citas_COMPLETO.sql


    PRE-REQUISITOS (deben existir ANTES de correr este script):
      1) Base de datos Kronos creada con el DDL base del equipo:
         01_schema.sql, 02_tables.sql, 03_indexes.sql, 04_views.sql,
         05_..., 06_functions.sql, 07_stored_procedures.sql,
         08_triggers.sql, 99_seed_structure_data.sql
         (o el script combinado 00_kronos_full_setup.sql / clean_install).
      2) Los stubs de 07_stored_procedures.sql para el modulo de citas
         deben existir (este script los completa con ALTER).

    Este script consolida, EN ESTE ORDEN, TODO lo de RF-06:
      1) 10_rf06_citas_sp.sql   -> SPs de citas (crear, editar,
         reprogramar, cancelar, listar, detalle, disponibilidad,
         busqueda de pacientes/colaboradores). Incluye:
           - el fix de service_sp_internal_status_history_create
             (antes devolvia un result set extra que hacia llegar
             service_event_id = 0 a la API).
           - las validaciones del Paso 5: paciente obligatorio,
             event_type_id/location_type_id deben existir en su
             catalogo, y location_description obligatorio si el tipo
             de ubicacion es 'en sede' o 'domiciliar' (la UI solo
             captura ese campo de texto libre, no location_id ni
             address_id).
      2) 11_rf06_catalogos_sp.sql -> SP de lectura de catalogos
         (config_sp_catalog_items_list), usado para poblar los combos
         del formulario de citas.
      3) 12_rf06_desactivar_trigger_duplicado.sql -> desactiva el
         trigger service_trg_events_status_history (08_triggers.sql),
         que duplica el historial de estados porque los SPs de citas
         ya lo registran explicitamente.
      4) 13_rf06_notificaciones_sp.sql -> SP para dejar registro de
         cada envio de correo (notification_sp_logs_create).
*/

-------------------------------------------------------------------------------
-- PARTE 1: 10_rf06_citas_sp.sql
-------------------------------------------------------------------------------

/*
    Kronos - 10_rf06_citas_sp.sql

    RF-06 Gestion de Citas (presenciales y domiciliares).

    Este script:
      1) Completa (ALTER) los SPs stub declarados en 07_stored_procedures.sql
         que ya tenian firma definida para el modulo de citas.
      2) Completa (ALTER) los SPs "contrato pendiente" que el generador
         automatico de 07_stored_procedures.sql ya creo como no-op y que
         RF-06 necesita:
           - service_sp_events_validate_staff_availability
           - service_sp_internal_status_history_create
           - service_sp_report_events
           - patient_sp_patients_search   (para el combo de pacientes)
           - staff_sp_members_search      (para el combo de colaboradores)
      3) Crea (CREATE) dos SPs nuevos que no estaban contemplados en el DDL:
           - service_sp_orc_events_update   (edicion completa de una cita)
           - service_sp_events_get_detail   (detalle + historial de una cita)

    Codigos de error personalizados (THROW) usados por estos SPs, para que
    la capa API los distinga por numero (ex.Number en SqlException):
      50000 -> Error de validacion generico (mensaje descriptivo)
      50010 -> Conflicto de horario (colaborador no disponible)
      50011 -> Paciente no existe o esta inactivo
      50012 -> Colaborador no existe o esta inactivo
      50013 -> La cita no existe (o esta eliminada)
      50014 -> La cita ya esta cancelada o completada, no se puede modificar

    Requiere que ya se hayan ejecutado 02_tables.sql, 04_views.sql,
    06_functions.sql, 07_stored_procedures.sql y 99_seed_structure_data.sql.
*/

SET NOCOUNT ON;
USE Kronos;
GO

-------------------------------------------------------------------------------
-- 1) service_sp_orc_events_create
--    Crea una cita (presencial o domiciliar), valida paciente, colaborador
--    y disponibilidad de horario, inserta staff/servicios asociados y deja
--    el primer registro en el historial de estados.
-------------------------------------------------------------------------------

ALTER PROCEDURE service_sp_orc_events_create
    @patient_id int = NULL,
    @event_type_id int,
    @scheduled_start_at datetime2(0),
    @scheduled_end_at datetime2(0),
    @location_type_id int,
    @location_id int = NULL,
    @address_id int = NULL,
    @location_description nvarchar(500) = NULL,
    @main_staff_member_id int = NULL,
    @summary nvarchar(max) = NULL,
    @created_by_user_id int,
    @staff_json nvarchar(max) = NULL,
    @services_json nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @scheduled_end_at <= @scheduled_start_at
        THROW 50000, N'scheduled_end_at debe ser mayor que scheduled_start_at.', 1;
    IF @staff_json IS NOT NULL AND ISJSON(@staff_json) <> 1
        THROW 50000, N'staff_json debe ser un JSON válido.', 1;
    IF @services_json IS NOT NULL AND ISJSON(@services_json) <> 1
        THROW 50000, N'services_json debe ser un JSON válido.', 1;

    -- RF-06 Paso 5: una cita siempre debe tener paciente.
    IF @patient_id IS NULL
        THROW 50000, N'El paciente es obligatorio.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM patient_tbl_patients
        WHERE id = @patient_id AND deleted = 0 AND is_active = 1
    )
        THROW 50011, N'El paciente indicado no existe o está inactivo.', 1;

    IF @main_staff_member_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM staff_tbl_members
        WHERE id = @main_staff_member_id AND deleted = 0 AND is_active = 1
    )
        THROW 50012, N'El colaborador indicado no existe o está inactivo.', 1;

    -- RF-06 Paso 5: event_type_id y location_type_id deben ser valores
    -- reales de sus catalogos, y la ubicacion debe traer el dato que le
    -- corresponde (sede si es "en sede", direccion si es "domiciliar").
    DECLARE @event_type_value nvarchar(150), @location_type_value nvarchar(150);

    SELECT @event_type_value = ci.value
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'service_event_type' AND ci.id = @event_type_id;

    IF @event_type_value IS NULL
        THROW 50000, N'El tipo de cita indicado no es válido.', 1;

    SELECT @location_type_value = ci.value
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'service_event_location_type' AND ci.id = @location_type_id;

    IF @location_type_value IS NULL
        THROW 50000, N'El tipo de ubicación indicado no es válido.', 1;

    IF @location_type_value IN (N'onsite', N'home')
        AND (@location_description IS NULL OR LTRIM(RTRIM(@location_description)) = N'')
        THROW 50000, N'Debe indicar la sede o dirección de la cita.', 1;

    IF @main_staff_member_id IS NOT NULL AND EXISTS (
        SELECT 1
        FROM service_tbl_events e
        INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
        WHERE e.deleted = 0
          AND st.value NOT IN (N'cancelled')
          AND e.main_staff_member_id = @main_staff_member_id
          AND e.scheduled_start_at < @scheduled_end_at
          AND e.scheduled_end_at > @scheduled_start_at
    )
        THROW 50010, N'El colaborador ya tiene una cita en ese horario.', 1;

    DECLARE @status_id int;
    SELECT @status_id = ci.id
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'service_event_status' AND ci.value = N'scheduled';

    DECLARE @new_event_id int;
    DECLARE @output_ids TABLE (id int);

    BEGIN TRAN;

        INSERT INTO service_tbl_events
            (patient_id, event_type_id, status_id, scheduled_start_at, scheduled_end_at,
             location_type_id, location_id, address_id, location_description,
             main_staff_member_id, summary, created_by_user_id, created_at)
        OUTPUT inserted.id INTO @output_ids
        VALUES
            (@patient_id, @event_type_id, @status_id, @scheduled_start_at, @scheduled_end_at,
             @location_type_id, @location_id, @address_id, @location_description,
             @main_staff_member_id, @summary, @created_by_user_id, SYSDATETIME());

        SELECT @new_event_id = id FROM @output_ids;

        IF @main_staff_member_id IS NOT NULL
        BEGIN
            INSERT INTO service_tbl_event_staff (service_event_id, staff_member_id, role_in_event_id, created_at)
            VALUES (@new_event_id, @main_staff_member_id, NULL, SYSDATETIME());
        END

        IF @staff_json IS NOT NULL
        BEGIN
            INSERT INTO service_tbl_event_staff (service_event_id, staff_member_id, role_in_event_id, created_at)
            SELECT @new_event_id, j.staff_member_id, j.role_in_event_id, SYSDATETIME()
            FROM OPENJSON(@staff_json)
            WITH (
                staff_member_id int '$.staff_member_id',
                role_in_event_id int '$.role_in_event_id'
            ) j
            WHERE j.staff_member_id <> ISNULL(@main_staff_member_id, -1);
        END

        IF @services_json IS NOT NULL
        BEGIN
            INSERT INTO service_tbl_event_services (service_event_id, service_id, created_at)
            SELECT @new_event_id, j.service_id, SYSDATETIME()
            FROM OPENJSON(@services_json)
            WITH (service_id int '$.service_id') j;
        END

        EXEC service_sp_internal_status_history_create
            @service_event_id = @new_event_id,
            @old_status_id = NULL,
            @new_status_id = @status_id,
            @reason = N'Cita creada.',
            @changed_by_user_id = @created_by_user_id;

    COMMIT;

    SELECT CAST(1 AS bit) AS success, @new_event_id AS service_event_id;
END;
GO

-------------------------------------------------------------------------------
-- 2) service_sp_orc_events_reschedule
--    Reprogramacion rapida: solo cambia fecha/hora. Valida disponibilidad
--    del colaborador principal en el nuevo horario (excluyendo la cita
--    misma) y deja rastro en el historial de estados.
-------------------------------------------------------------------------------

ALTER PROCEDURE service_sp_orc_events_reschedule
    @service_event_id int,
    @scheduled_start_at datetime2(0),
    @scheduled_end_at datetime2(0),
    @reason nvarchar(500) = NULL,
    @changed_by_user_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @scheduled_end_at <= @scheduled_start_at
        THROW 50000, N'scheduled_end_at debe ser mayor que scheduled_start_at.', 1;

    DECLARE @current_status_id int, @main_staff_member_id int, @status_value nvarchar(150);

    SELECT
        @current_status_id = e.status_id,
        @main_staff_member_id = e.main_staff_member_id,
        @status_value = st.value
    FROM service_tbl_events e
    INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
    WHERE e.id = @service_event_id AND e.deleted = 0;

    IF @current_status_id IS NULL
        THROW 50013, N'La cita indicada no existe.', 1;

    IF @status_value IN (N'cancelled', N'completed')
        THROW 50014, N'No se puede reprogramar una cita cancelada o completada.', 1;

    IF @main_staff_member_id IS NOT NULL AND EXISTS (
        SELECT 1
        FROM service_tbl_events e
        INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
        WHERE e.deleted = 0
          AND e.id <> @service_event_id
          AND st.value NOT IN (N'cancelled')
          AND e.main_staff_member_id = @main_staff_member_id
          AND e.scheduled_start_at < @scheduled_end_at
          AND e.scheduled_end_at > @scheduled_start_at
    )
        THROW 50010, N'El colaborador ya tiene una cita en ese horario.', 1;

    DECLARE @rescheduled_status_id int;
    SELECT @rescheduled_status_id = ci.id
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'service_event_status' AND ci.value = N'rescheduled';

    BEGIN TRAN;

        UPDATE service_tbl_events
        SET scheduled_start_at = @scheduled_start_at,
            scheduled_end_at = @scheduled_end_at,
            status_id = @rescheduled_status_id,
            updated_at = SYSDATETIME()
        WHERE id = @service_event_id;

        EXEC service_sp_internal_status_history_create
            @service_event_id = @service_event_id,
            @old_status_id = @current_status_id,
            @new_status_id = @rescheduled_status_id,
            @reason = @reason,
            @changed_by_user_id = @changed_by_user_id;

    COMMIT;

    SELECT CAST(1 AS bit) AS success, @service_event_id AS service_event_id;
END;
GO

-------------------------------------------------------------------------------
-- 3) service_sp_orc_events_update  (nuevo)
--    Edicion completa de una cita: paciente, tipo, horario, ubicacion,
--    direccion, colaborador principal, resumen, staff y servicios.
--    Si el horario cambia, valida disponibilidad y marca la cita como
--    "rescheduled"; si no cambia, mantiene el estado actual.
-------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE service_sp_orc_events_update
    @service_event_id int,
    @patient_id int = NULL,
    @event_type_id int,
    @scheduled_start_at datetime2(0),
    @scheduled_end_at datetime2(0),
    @location_type_id int,
    @location_id int = NULL,
    @address_id int = NULL,
    @location_description nvarchar(500) = NULL,
    @main_staff_member_id int = NULL,
    @summary nvarchar(max) = NULL,
    @reason nvarchar(500) = NULL,
    @changed_by_user_id int,
    @staff_json nvarchar(max) = NULL,
    @services_json nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @scheduled_end_at <= @scheduled_start_at
        THROW 50000, N'scheduled_end_at debe ser mayor que scheduled_start_at.', 1;
    IF @staff_json IS NOT NULL AND ISJSON(@staff_json) <> 1
        THROW 50000, N'staff_json debe ser un JSON válido.', 1;
    IF @services_json IS NOT NULL AND ISJSON(@services_json) <> 1
        THROW 50000, N'services_json debe ser un JSON válido.', 1;

    DECLARE @current_status_id int, @current_start datetime2(0), @current_end datetime2(0), @status_value nvarchar(150);

    SELECT
        @current_status_id = e.status_id,
        @current_start = e.scheduled_start_at,
        @current_end = e.scheduled_end_at,
        @status_value = st.value
    FROM service_tbl_events e
    INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
    WHERE e.id = @service_event_id AND e.deleted = 0;

    IF @current_status_id IS NULL
        THROW 50013, N'La cita indicada no existe.', 1;

    IF @status_value IN (N'cancelled', N'completed')
        THROW 50014, N'No se puede modificar una cita cancelada o completada.', 1;

    -- RF-06 Paso 5: una cita siempre debe tener paciente.
    IF @patient_id IS NULL
        THROW 50000, N'El paciente es obligatorio.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM patient_tbl_patients
        WHERE id = @patient_id AND deleted = 0 AND is_active = 1
    )
        THROW 50011, N'El paciente indicado no existe o está inactivo.', 1;

    IF @main_staff_member_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM staff_tbl_members
        WHERE id = @main_staff_member_id AND deleted = 0 AND is_active = 1
    )
        THROW 50012, N'El colaborador indicado no existe o está inactivo.', 1;

    -- RF-06 Paso 5: event_type_id y location_type_id deben ser valores
    -- reales de sus catalogos, y la ubicacion debe traer el dato que le
    -- corresponde (sede si es "en sede", direccion si es "domiciliar").
    DECLARE @event_type_value nvarchar(150), @location_type_value nvarchar(150);

    SELECT @event_type_value = ci.value
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'service_event_type' AND ci.id = @event_type_id;

    IF @event_type_value IS NULL
        THROW 50000, N'El tipo de cita indicado no es válido.', 1;

    SELECT @location_type_value = ci.value
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'service_event_location_type' AND ci.id = @location_type_id;

    IF @location_type_value IS NULL
        THROW 50000, N'El tipo de ubicación indicado no es válido.', 1;

    -- La UI solo captura location_description (texto libre) para la
    -- ubicacion; location_id/address_id no tienen selector en el
    -- formulario todavia, asi que la validacion se basa en el texto.
    IF @location_type_value IN (N'onsite', N'home')
        AND (@location_description IS NULL OR LTRIM(RTRIM(@location_description)) = N'')
        THROW 50000, N'Debe indicar la sede o dirección de la cita.', 1;

    DECLARE @schedule_changed bit = CASE
        WHEN @current_start <> @scheduled_start_at OR @current_end <> @scheduled_end_at THEN 1 ELSE 0 END;

    IF @main_staff_member_id IS NOT NULL AND EXISTS (
        SELECT 1
        FROM service_tbl_events e
        INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
        WHERE e.deleted = 0
          AND e.id <> @service_event_id
          AND st.value NOT IN (N'cancelled')
          AND e.main_staff_member_id = @main_staff_member_id
          AND e.scheduled_start_at < @scheduled_end_at
          AND e.scheduled_end_at > @scheduled_start_at
    )
        THROW 50010, N'El colaborador ya tiene una cita en ese horario.', 1;

    DECLARE @new_status_id int = @current_status_id;
    IF @schedule_changed = 1
    BEGIN
        SELECT @new_status_id = ci.id
        FROM config_tbl_catalog_items ci
        INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
        WHERE c.name = N'service_event_status' AND ci.value = N'rescheduled';
    END

    BEGIN TRAN;

        UPDATE service_tbl_events
        SET patient_id = @patient_id,
            event_type_id = @event_type_id,
            status_id = @new_status_id,
            scheduled_start_at = @scheduled_start_at,
            scheduled_end_at = @scheduled_end_at,
            location_type_id = @location_type_id,
            location_id = @location_id,
            address_id = @address_id,
            location_description = @location_description,
            main_staff_member_id = @main_staff_member_id,
            summary = @summary,
            updated_at = SYSDATETIME()
        WHERE id = @service_event_id;

        IF @staff_json IS NOT NULL
        BEGIN
            DELETE FROM service_tbl_event_staff WHERE service_event_id = @service_event_id;

            IF @main_staff_member_id IS NOT NULL
                INSERT INTO service_tbl_event_staff (service_event_id, staff_member_id, role_in_event_id, created_at)
                VALUES (@service_event_id, @main_staff_member_id, NULL, SYSDATETIME());

            INSERT INTO service_tbl_event_staff (service_event_id, staff_member_id, role_in_event_id, created_at)
            SELECT @service_event_id, j.staff_member_id, j.role_in_event_id, SYSDATETIME()
            FROM OPENJSON(@staff_json)
            WITH (
                staff_member_id int '$.staff_member_id',
                role_in_event_id int '$.role_in_event_id'
            ) j
            WHERE j.staff_member_id <> ISNULL(@main_staff_member_id, -1);
        END

        IF @services_json IS NOT NULL
        BEGIN
            DELETE FROM service_tbl_event_services WHERE service_event_id = @service_event_id;

            INSERT INTO service_tbl_event_services (service_event_id, service_id, created_at)
            SELECT @service_event_id, j.service_id, SYSDATETIME()
            FROM OPENJSON(@services_json)
            WITH (service_id int '$.service_id') j;
        END

        EXEC service_sp_internal_status_history_create
            @service_event_id = @service_event_id,
            @old_status_id = @current_status_id,
            @new_status_id = @new_status_id,
            @reason = @reason,
            @changed_by_user_id = @changed_by_user_id;

    COMMIT;

    SELECT CAST(1 AS bit) AS success, @service_event_id AS service_event_id;
END;
GO

-------------------------------------------------------------------------------
-- 4) service_sp_orc_events_cancel
--    Cancela una cita y deja el motivo en el historial de estados.
-------------------------------------------------------------------------------

ALTER PROCEDURE service_sp_orc_events_cancel
    @service_event_id int,
    @reason nvarchar(500),
    @changed_by_user_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NULLIF(LTRIM(RTRIM(@reason)), N'') IS NULL
        THROW 50000, N'La razón de cancelación es requerida.', 1;

    DECLARE @current_status_id int, @status_value nvarchar(150);

    SELECT @current_status_id = e.status_id, @status_value = st.value
    FROM service_tbl_events e
    INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
    WHERE e.id = @service_event_id AND e.deleted = 0;

    IF @current_status_id IS NULL
        THROW 50013, N'La cita indicada no existe.', 1;

    IF @status_value IN (N'cancelled', N'completed')
        THROW 50014, N'La cita ya está cancelada o completada.', 1;

    DECLARE @cancelled_status_id int;
    SELECT @cancelled_status_id = ci.id
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'service_event_status' AND ci.value = N'cancelled';

    BEGIN TRAN;

        UPDATE service_tbl_events
        SET status_id = @cancelled_status_id,
            updated_at = SYSDATETIME()
        WHERE id = @service_event_id;

        EXEC service_sp_internal_status_history_create
            @service_event_id = @service_event_id,
            @old_status_id = @current_status_id,
            @new_status_id = @cancelled_status_id,
            @reason = @reason,
            @changed_by_user_id = @changed_by_user_id;

    COMMIT;

    SELECT CAST(1 AS bit) AS success, @service_event_id AS service_event_id;
END;
GO

-------------------------------------------------------------------------------
-- 5) service_sp_internal_status_history_create
--    SP de apoyo (mismo espiritu que notification_sp_logs_create): inserta
--    un registro en service_tbl_event_status_history. Lo llaman los
--    orquestadores de citas; tambien puede llamarse solo si se necesita.
-------------------------------------------------------------------------------

ALTER PROCEDURE service_sp_internal_status_history_create
    @service_event_id int,
    @old_status_id int = NULL,
    @new_status_id int,
    @reason nvarchar(500) = NULL,
    @changed_by_user_id int
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO service_tbl_event_status_history
        (service_event_id, old_status_id, new_status_id, reason, changed_by_user_id, changed_at)
    VALUES
        (@service_event_id, @old_status_id, @new_status_id, @reason, @changed_by_user_id, SYSDATETIME());
END;
GO

-------------------------------------------------------------------------------
-- 6) service_sp_events_validate_staff_availability
--    Verifica si un colaborador esta disponible en un rango de fecha/hora.
--    Si no lo esta, ademas del bit de disponibilidad, devuelve hasta 3
--    horarios alternativos libres (mismo dia +1h/+2h y siguiente dia mismo
--    horario) para que la vista pueda sugerirlos.
-------------------------------------------------------------------------------

ALTER PROCEDURE service_sp_events_validate_staff_availability
    @staff_member_id int,
    @scheduled_start_at datetime2(0),
    @scheduled_end_at datetime2(0),
    @exclude_event_id int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @duration_minutes int = DATEDIFF(MINUTE, @scheduled_start_at, @scheduled_end_at);
    DECLARE @is_available bit = 1;

    IF EXISTS (
        SELECT 1
        FROM service_tbl_events e
        INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
        WHERE e.deleted = 0
          AND st.value NOT IN (N'cancelled')
          AND e.main_staff_member_id = @staff_member_id
          AND (@exclude_event_id IS NULL OR e.id <> @exclude_event_id)
          AND e.scheduled_start_at < @scheduled_end_at
          AND e.scheduled_end_at > @scheduled_start_at
    )
        SET @is_available = 0;

    SELECT @is_available AS is_available;

    IF @is_available = 0
    BEGIN
        ;WITH candidates AS (
            SELECT DATEADD(MINUTE, 60, @scheduled_start_at) AS candidate_start
            UNION ALL SELECT DATEADD(MINUTE, 120, @scheduled_start_at)
            UNION ALL SELECT DATEADD(DAY, 1, @scheduled_start_at)
            UNION ALL SELECT DATEADD(DAY, 2, @scheduled_start_at)
        )
        SELECT TOP (3)
            c.candidate_start,
            DATEADD(MINUTE, @duration_minutes, c.candidate_start) AS candidate_end
        FROM candidates c
        WHERE NOT EXISTS (
            SELECT 1
            FROM service_tbl_events e
            INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
            WHERE e.deleted = 0
              AND st.value NOT IN (N'cancelled')
              AND e.main_staff_member_id = @staff_member_id
              AND (@exclude_event_id IS NULL OR e.id <> @exclude_event_id)
              AND e.scheduled_start_at < DATEADD(MINUTE, @duration_minutes, c.candidate_start)
              AND e.scheduled_end_at > c.candidate_start
        )
        ORDER BY c.candidate_start;
    END
END;
GO

-------------------------------------------------------------------------------
-- 7) service_sp_report_events
--    Lista/consulta citas con filtros (fecha, paciente, colaborador,
--    estado, tipo). Alimenta tanto el calendario como el listado tabular.
-------------------------------------------------------------------------------

ALTER PROCEDURE service_sp_report_events
    @date_from date = NULL,
    @date_to date = NULL,
    @patient_id int = NULL,
    @staff_member_id int = NULL,
    @status_id int = NULL,
    @event_type_id int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.id,
        c.patient_id,
        c.patient_first_name,
        c.patient_last_name,
        c.event_type_id,
        c.event_type_name,
        c.status_id,
        c.status_name,
        st.value AS status_value,
        c.scheduled_start_at,
        c.scheduled_end_at,
        c.main_staff_member_id,
        c.staff_first_name,
        c.staff_last_name
    FROM service_vw_event_calendar c
    INNER JOIN config_tbl_catalog_items st ON st.id = c.status_id
    WHERE (@date_from IS NULL OR CAST(c.scheduled_start_at AS date) >= @date_from)
      AND (@date_to IS NULL OR CAST(c.scheduled_start_at AS date) <= @date_to)
      AND (@patient_id IS NULL OR c.patient_id = @patient_id)
      AND (@staff_member_id IS NULL OR c.main_staff_member_id = @staff_member_id)
      AND (@status_id IS NULL OR c.status_id = @status_id)
      AND (@event_type_id IS NULL OR c.event_type_id = @event_type_id)
    ORDER BY c.scheduled_start_at;
END;
GO

-------------------------------------------------------------------------------
-- 8) service_sp_events_get_detail  (nuevo)
--    Detalle completo de una cita (para vista de detalle/edicion) mas su
--    historial de estados. Devuelve dos result sets (Dapper QueryMultiple):
--    1) datos de la cita con nombres resueltos y datos de contacto
--    2) historial de cambios de estado
-------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE service_sp_events_get_detail
    @service_event_id int
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        e.id,
        e.patient_id,
        p.first_name AS patient_first_name,
        p.last_name AS patient_last_name,
        p.email AS patient_email,
        p.phone AS patient_phone,
        e.event_type_id,
        et.name AS event_type_name,
        et.value AS event_type_value,
        e.status_id,
        st.name AS status_name,
        st.value AS status_value,
        e.scheduled_start_at,
        e.scheduled_end_at,
        e.actual_start_at,
        e.actual_end_at,
        e.location_type_id,
        lt.name AS location_type_name,
        lt.value AS location_type_value,
        e.location_id,
        loc.name AS location_name,
        e.address_id,
        a.address_line,
        a.reference,
        e.location_description,
        e.main_staff_member_id,
        sm.first_name AS staff_first_name,
        sm.last_name AS staff_last_name,
        sm.email AS staff_email,
        sm.phone AS staff_phone,
        e.summary,
        e.created_by_user_id,
        e.created_at,
        e.updated_at
    FROM service_tbl_events e
    LEFT JOIN patient_tbl_patients p ON p.id = e.patient_id
    LEFT JOIN staff_tbl_members sm ON sm.id = e.main_staff_member_id
    LEFT JOIN config_tbl_catalog_items et ON et.id = e.event_type_id
    LEFT JOIN config_tbl_catalog_items st ON st.id = e.status_id
    LEFT JOIN config_tbl_catalog_items lt ON lt.id = e.location_type_id
    LEFT JOIN location_tbl_locations loc ON loc.id = e.location_id
    LEFT JOIN location_tbl_addresses a ON a.id = e.address_id
    WHERE e.id = @service_event_id AND e.deleted = 0;

    SELECT
        h.id,
        h.service_event_id,
        h.old_status_id,
        os.name AS old_status_name,
        h.new_status_id,
        ns.name AS new_status_name,
        h.reason,
        h.changed_by_user_id,
        u.full_name AS changed_by_full_name,
        h.changed_at
    FROM service_tbl_event_status_history h
    LEFT JOIN config_tbl_catalog_items os ON os.id = h.old_status_id
    INNER JOIN config_tbl_catalog_items ns ON ns.id = h.new_status_id
    LEFT JOIN access_tbl_users u ON u.id = h.changed_by_user_id
    WHERE h.service_event_id = @service_event_id
    ORDER BY h.changed_at DESC;
END;
GO

-------------------------------------------------------------------------------
-- 9) patient_sp_patients_search  (version minima)
--    Alimenta el combo de pacientes del formulario de citas.
-------------------------------------------------------------------------------

ALTER PROCEDURE patient_sp_patients_search
    @search nvarchar(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.id,
        p.first_name,
        p.last_name,
        p.identification_number,
        p.email,
        p.phone
    FROM patient_tbl_patients p
    WHERE p.deleted = 0
      AND p.is_active = 1
      AND (
            @search IS NULL
            OR p.first_name LIKE N'%' + @search + N'%'
            OR p.last_name LIKE N'%' + @search + N'%'
            OR p.identification_number LIKE N'%' + @search + N'%'
          )
    ORDER BY p.first_name, p.last_name;
END;
GO

-------------------------------------------------------------------------------
-- 10) staff_sp_members_search  (version minima)
--     Alimenta el combo de colaboradores del formulario de citas.
-------------------------------------------------------------------------------

ALTER PROCEDURE staff_sp_members_search
    @search nvarchar(200) = NULL,
    @staff_role_id int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        sm.id,
        sm.first_name,
        sm.last_name,
        sm.staff_role_id,
        r.name AS staff_role_name,
        sm.email,
        sm.phone
    FROM staff_tbl_members sm
    INNER JOIN staff_tbl_roles r ON r.id = sm.staff_role_id
    WHERE sm.deleted = 0
      AND sm.is_active = 1
      AND (@staff_role_id IS NULL OR sm.staff_role_id = @staff_role_id)
      AND (
            @search IS NULL
            OR sm.first_name LIKE N'%' + @search + N'%'
            OR sm.last_name LIKE N'%' + @search + N'%'
          )
    ORDER BY sm.first_name, sm.last_name;
END;
GO

SET NOCOUNT OFF;

-------------------------------------------------------------------------------
-- PARTE 2: 11_rf06_catalogos_sp.sql
-------------------------------------------------------------------------------

/*
    Kronos - 11_rf06_catalogos_sp.sql

    RF-06 Gestion de Citas - complemento.

    Agrega un SP de lectura para catalogos (config_tbl_catalog_items), que
    no existia en el DDL (solo habia un stub de escritura,
    config_sp_catalog_items_upsert). Lo necesita el formulario de citas
    para poblar los combos de tipo de cita, estado y tipo de ubicacion.

    Correr despues de 10_rf06_citas_sp.sql.
*/

SET NOCOUNT ON;
USE Kronos;
GO

-------------------------------------------------------------------------------
-- config_sp_catalog_items_list  (nuevo)
--    Devuelve los items activos de un catalogo, por nombre de catalogo
--    (ej. 'service_event_type', 'service_event_status',
--    'service_event_location_type').
-------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE config_sp_catalog_items_list
    @catalog_name nvarchar(150)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ci.id,
        ci.name,
        ci.value,
        ci.sort_order
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = @catalog_name
      AND ci.deleted = 0
      AND ci.is_active = 1
    ORDER BY ci.sort_order, ci.name;
END;
GO

SET NOCOUNT OFF;

-------------------------------------------------------------------------------
-- PARTE 3: 12_rf06_desactivar_trigger_duplicado.sql
-------------------------------------------------------------------------------

/*
    Kronos - 12_rf06_desactivar_trigger_duplicado.sql

    RF-06 Gestion de Citas - fix de historial duplicado.

    08_triggers.sql ya trae service_trg_events_status_history: un trigger
    AFTER UPDATE en service_tbl_events que inserta automaticamente una fila
    en service_tbl_event_status_history cada vez que cambia status_id, con
    un mensaje generico ("Cambio de estado automatico registrado por
    trigger.") y sin el motivo real ni el usuario que hizo el cambio.

    Los SPs de RF-06 (service_sp_orc_events_create/reschedule/update/cancel)
    ya registran ese mismo historial explicitamente, con el motivo real y
    el changed_by_user_id correcto (via service_sp_internal_status_history_create).
    Como el trigger tambien dispara en cada UPDATE que cambia status_id,
    el resultado eran DOS filas de historial por cada cambio de estado.

    Este script desactiva el trigger (no lo borra) para que solo quede el
    registro explicito de los SPs, que es mas completo. Si en el futuro
    otro modulo cambia status_id directamente por SQL sin pasar por estos
    SPs, se puede reactivar con:
        ALTER TABLE service_tbl_events ENABLE TRIGGER service_trg_events_status_history;
*/

SET NOCOUNT ON;
USE Kronos;
GO

ALTER TABLE service_tbl_events DISABLE TRIGGER service_trg_events_status_history;
GO

SET NOCOUNT OFF;

-------------------------------------------------------------------------------
-- PARTE 4: 13_rf06_notificaciones_sp.sql
-------------------------------------------------------------------------------

/*
    Kronos - 13_rf06_notificaciones_sp.sql

    RF-06 Gestion de Citas - notificaciones por correo.

    notification_sp_logs_create ya existia (07_stored_procedures.sql) pero
    no soportaba sent_at ni error_message, aunque notification_tbl_logs si
    tiene esas columnas. Se extiende (parametros nuevos al final, con
    default NULL, no rompe llamadas existentes) para poder registrar tanto
    los envios exitosos como los fallidos, tal como pide RF-06:
    "fallo de correo -> la cita se guarda igual y el error se registra en BD".
*/

SET NOCOUNT ON;
USE Kronos;
GO

CREATE OR ALTER PROCEDURE notification_sp_logs_create
    @user_id int = NULL,
    @patient_id int = NULL,
    @service_event_id int = NULL,
    @notification_type_id int,
    @recipient nvarchar(256) = NULL,
    @subject nvarchar(250) = NULL,
    @message nvarchar(max) = NULL,
    @status_id int,
    @sent_at datetime2(0) = NULL,
    @error_message nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO notification_tbl_logs
        (user_id, patient_id, service_event_id, notification_type_id, recipient, subject, message, status_id, sent_at, error_message, created_at)
    VALUES
        (@user_id, @patient_id, @service_event_id, @notification_type_id, @recipient, @subject, @message, @status_id, @sent_at, @error_message, SYSDATETIME());

    SELECT CAST(1 AS bit) AS success, SCOPE_IDENTITY() AS notification_log_id;
END;
GO

SET NOCOUNT OFF;

PRINT 'RF-06 (Gestion de Citas): script completo ejecutado correctamente.';
GO