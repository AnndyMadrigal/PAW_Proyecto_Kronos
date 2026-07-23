/*
    Kronos - 07_stored_procedures.sql

    Crea los SPs que va a consumir el API.
    Los orquestadores ya tienen sus parámetros base y validaciones iniciales.
    La lógica fina de cada proceso se completa conforme se desarrolle el sitio.
*/

SET NOCOUNT ON;
USE Kronos;

-------------------------------------------------------------------------------
-- SPs de apoyo que ya pueden guardar logs básicos
-------------------------------------------------------------------------------

EXEC(N'
CREATE PROCEDURE access_sp_internal_audit_log_create
    @user_id int = NULL,
    @action nvarchar(100),
    @entity_name nvarchar(150),
    @entity_id int = NULL,
    @old_value nvarchar(max) = NULL,
    @new_value nvarchar(max) = NULL,
    @ip_address nvarchar(45) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO access_tbl_audit_logs
        (user_id, action, entity_name, entity_id, old_value, new_value, ip_address, created_at)
    VALUES
        (@user_id, @action, @entity_name, @entity_id, @old_value, @new_value, @ip_address, SYSDATETIME());

    SELECT CAST(1 AS bit) AS success, SCOPE_IDENTITY() AS audit_log_id;
END;
');

EXEC(N'
CREATE PROCEDURE system_sp_error_logs_create
    @user_id int = NULL,
    @source nvarchar(150) = NULL,
    @message nvarchar(max),
    @detail nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO system_tbl_error_logs
        (user_id, source, message, detail, created_at)
    VALUES
        (@user_id, @source, @message, @detail, SYSDATETIME());

    SELECT CAST(1 AS bit) AS success, SCOPE_IDENTITY() AS error_log_id;
END;
');

EXEC(N'
CREATE PROCEDURE notification_sp_logs_create
    @user_id int = NULL,
    @patient_id int = NULL,
    @service_event_id int = NULL,
    @notification_type_id int,
    @recipient nvarchar(256) = NULL,
    @subject nvarchar(250) = NULL,
    @message nvarchar(max) = NULL,
    @status_id int
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO notification_tbl_logs
        (user_id, patient_id, service_event_id, notification_type_id, recipient, subject, message, status_id, created_at)
    VALUES
        (@user_id, @patient_id, @service_event_id, @notification_type_id, @recipient, @subject, @message, @status_id, SYSDATETIME());

    SELECT CAST(1 AS bit) AS success, SCOPE_IDENTITY() AS notification_log_id;
END;
');

EXEC(N'
CREATE PROCEDURE medical_sp_records_log_access
    @medical_record_id int,
    @patient_id int,
    @user_id int,
    @staff_member_id int = NULL,
    @access_type_id int,
    @access_reason nvarchar(500) = NULL,
    @ip_address nvarchar(45) = NULL,
    @device_info nvarchar(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO medical_tbl_record_access_logs
        (medical_record_id, patient_id, user_id, staff_member_id, access_type_id, access_reason, ip_address, device_info, created_at)
    VALUES
        (@medical_record_id, @patient_id, @user_id, @staff_member_id, @access_type_id, @access_reason, @ip_address, @device_info, SYSDATETIME());

    SELECT CAST(1 AS bit) AS success, SCOPE_IDENTITY() AS access_log_id;
END;
');

-------------------------------------------------------------------------------
-- SPs orquestadores
-------------------------------------------------------------------------------

EXEC(N'
CREATE PROCEDURE financial_sp_orc_invoices_generate
    @patient_id int = NULL,
    @service_event_id int = NULL,
    @issue_date date = NULL,
    @due_date date = NULL,
    @notes nvarchar(max) = NULL,
    @created_by_user_id int,
    @invoice_items_json nvarchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @invoice_items_json IS NULL OR ISJSON(@invoice_items_json) <> 1
        THROW 50000, N''invoice_items_json debe ser un JSON válido.'', 1;

    -- Pendiente completar la lógica transaccional completa.
    SELECT CAST(1 AS bit) AS success, N''Contrato de financial_sp_orc_invoices_generate creado.'' AS message;
END;
');

EXEC(N'
CREATE PROCEDURE financial_sp_orc_invoices_register_payment
    @financial_invoice_id int,
    @amount decimal(18,2),
    @financial_payment_method_id int,
    @transaction_date datetime2(0) = NULL,
    @description nvarchar(max) = NULL,
    @created_by_user_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @amount < 0
        THROW 50000, N''amount debe ser mayor o igual a cero.'', 1;

    SELECT CAST(1 AS bit) AS success, N''Contrato de financial_sp_orc_invoices_register_payment creado.'' AS message;
END;
');

EXEC(N'
CREATE PROCEDURE financial_sp_orc_receipts_register_purchase
    @supplier_id int = NULL,
    @financial_donor_id int = NULL,
    @receipt_date date = NULL,
    @location_id int,
    @notes nvarchar(max) = NULL,
    @created_by_user_id int,
    @receipt_items_json nvarchar(max),
    @create_financial_transaction bit,
    @financial_payment_method_id int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @receipt_items_json IS NULL OR ISJSON(@receipt_items_json) <> 1
        THROW 50000, N''receipt_items_json debe ser un JSON válido.'', 1;

    SELECT CAST(1 AS bit) AS success, N''Contrato de financial_sp_orc_receipts_register_purchase creado.'' AS message;
END;
');

EXEC(N'
CREATE PROCEDURE service_sp_orc_events_create
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
        THROW 50000, N''scheduled_end_at debe ser mayor que scheduled_start_at.'', 1;
    IF @staff_json IS NOT NULL AND ISJSON(@staff_json) <> 1
        THROW 50000, N''staff_json debe ser un JSON válido.'', 1;
    IF @services_json IS NOT NULL AND ISJSON(@services_json) <> 1
        THROW 50000, N''services_json debe ser un JSON válido.'', 1;

    SELECT CAST(1 AS bit) AS success, N''Contrato de service_sp_orc_events_create creado.'' AS message;
END;
');

EXEC(N'
CREATE PROCEDURE service_sp_orc_events_reschedule
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
        THROW 50000, N''scheduled_end_at debe ser mayor que scheduled_start_at.'', 1;

    SELECT CAST(1 AS bit) AS success, N''Contrato de service_sp_orc_events_reschedule creado.'' AS message;
END;
');

EXEC(N'
CREATE PROCEDURE service_sp_orc_events_cancel
    @service_event_id int,
    @reason nvarchar(500),
    @changed_by_user_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NULLIF(LTRIM(RTRIM(@reason)), N'''') IS NULL
        THROW 50000, N''La razón de cancelación es requerida.'', 1;

    SELECT CAST(1 AS bit) AS success, N''Contrato de service_sp_orc_events_cancel creado.'' AS message;
END;
');

EXEC(N'
CREATE PROCEDURE service_sp_orc_events_complete_full
    @service_event_id int,
    @completed_by_user_id int,
    @completed_by_staff_member_id int = NULL,
    @completion_summary nvarchar(max) = NULL,
    @actual_start_at datetime2(0) = NULL,
    @actual_end_at datetime2(0) = NULL,
    @notes_json nvarchar(max) = NULL,
    @services_json nvarchar(max) = NULL,
    @inventory_usage_json nvarchar(max) = NULL,
    @vital_signs_json nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @notes_json IS NOT NULL AND ISJSON(@notes_json) <> 1 THROW 50000, N''notes_json debe ser un JSON válido.'', 1;
    IF @services_json IS NOT NULL AND ISJSON(@services_json) <> 1 THROW 50000, N''services_json debe ser un JSON válido.'', 1;
    IF @inventory_usage_json IS NOT NULL AND ISJSON(@inventory_usage_json) <> 1 THROW 50000, N''inventory_usage_json debe ser un JSON válido.'', 1;
    IF @vital_signs_json IS NOT NULL AND ISJSON(@vital_signs_json) <> 1 THROW 50000, N''vital_signs_json debe ser un JSON válido.'', 1;

    SELECT CAST(1 AS bit) AS success, N''Contrato de service_sp_orc_events_complete_full creado.'' AS message;
END;
');

EXEC(N'
CREATE PROCEDURE medical_sp_orc_records_get_detail
    @medical_record_id int = NULL,
    @patient_id int = NULL,
    @accessed_by_user_id int,
    @access_reason nvarchar(500) = NULL,
    @ip_address nvarchar(45) = NULL,
    @device_info nvarchar(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT CAST(1 AS bit) AS success, N''Contrato de medical_sp_orc_records_get_detail creado.'' AS message;
END;
');

EXEC(N'
CREATE PROCEDURE patient_sp_orc_patients_register
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
        THROW 50000, N''contacts_json debe ser un JSON válido.'', 1;

    SELECT CAST(1 AS bit) AS success, N''Contrato de patient_sp_orc_patients_register creado.'' AS message;
END;
');

-------------------------------------------------------------------------------
-- Contratos pendientes de completar
-------------------------------------------------------------------------------

DECLARE @procedures TABLE (name sysname NOT NULL PRIMARY KEY);

INSERT INTO @procedures (name)
VALUES
    (N'access_sp_users_create'),
    (N'access_sp_users_update_profile'),
    (N'access_sp_users_set_active'),
    (N'access_sp_users_delete'),
    (N'access_sp_auth_login'),
    (N'access_sp_auth_register_failed_attempt'),
    (N'access_sp_auth_logout'),
    (N'access_sp_password_reset_create'),
    (N'access_sp_password_reset_use'),
    (N'access_sp_user_roles_assign'),
    (N'access_sp_user_roles_remove'),
    (N'access_sp_report_audit_activity'),
    (N'patient_sp_patients_create'),
    (N'patient_sp_patients_update'),
    (N'patient_sp_patients_delete'),
    (N'patient_sp_patients_search'),
    (N'patient_sp_patients_get_detail'),
    (N'patient_sp_contacts_upsert'),
    (N'patient_sp_contacts_delete'),
    (N'patient_sp_report_registry'),
    (N'patient_sp_report_medical_activity'),
    (N'staff_sp_members_create'),
    (N'staff_sp_members_update'),
    (N'staff_sp_members_delete'),
    (N'staff_sp_members_search'),
    (N'staff_sp_availability_generate'),
    (N'staff_sp_availability_update'),
    (N'staff_sp_report_activity'),
    (N'medical_sp_records_open'),
    (N'medical_sp_records_update_status'),
    (N'medical_sp_record_notes_create'),
    (N'medical_sp_patient_conditions_upsert'),
    (N'medical_sp_patient_medications_upsert'),
    (N'medical_sp_patient_allergies_upsert'),
    (N'medical_sp_patient_vital_signs_create'),
    (N'medical_sp_record_attachments_create'),
    (N'medical_sp_record_attachments_download'),
    (N'medical_sp_report_care_plan_follow_up'),
    (N'service_sp_events_complete'),
    (N'service_sp_events_assign_staff'),
    (N'service_sp_events_add_note'),
    (N'service_sp_events_add_service'),
    (N'service_sp_events_register_inventory_usage'),
    (N'service_sp_events_validate_staff_availability'),
    (N'service_sp_internal_event_status_update'),
    (N'service_sp_internal_status_history_create'),
    (N'service_sp_report_events'),
    (N'service_sp_report_inventory_usage'),
    (N'inventory_sp_items_create'),
    (N'inventory_sp_items_update'),
    (N'inventory_sp_items_delete'),
    (N'inventory_sp_items_search'),
    (N'inventory_sp_movements_register_entry'),
    (N'inventory_sp_movements_register_exit'),
    (N'inventory_sp_movements_register_adjustment'),
    (N'inventory_sp_internal_stock_validate'),
    (N'inventory_sp_internal_batch_upsert'),
    (N'inventory_sp_internal_batch_quantity_update'),
    (N'inventory_sp_stock_get'),
    (N'inventory_sp_stock_check_low'),
    (N'inventory_sp_report_stock'),
    (N'inventory_sp_report_movements'),
    (N'inventory_sp_report_low_stock'),
    (N'inventory_sp_report_expiring_batches'),
    (N'financial_sp_transactions_create'),
    (N'financial_sp_invoices_create'),
    (N'financial_sp_invoice_items_add'),
    (N'financial_sp_receipts_create'),
    (N'financial_sp_receipt_items_add'),
    (N'financial_sp_internal_invoice_number_generate'),
    (N'financial_sp_internal_invoice_header_create'),
    (N'financial_sp_internal_invoice_items_add'),
    (N'financial_sp_internal_invoice_totals_recalculate'),
    (N'financial_sp_internal_invoice_payment_status_update'),
    (N'financial_sp_internal_receipt_number_generate'),
    (N'financial_sp_internal_receipt_header_create'),
    (N'financial_sp_internal_receipt_items_add'),
    (N'financial_sp_internal_transaction_create'),
    (N'financial_sp_report_summary'),
    (N'financial_sp_report_transactions'),
    (N'financial_sp_report_donations'),
    (N'financial_sp_report_invoices'),
    (N'financial_sp_report_receipts'),
    (N'config_sp_settings_upsert'),
    (N'config_sp_catalog_items_upsert'),
    (N'notification_sp_report_notifications'),
    (N'system_sp_report_errors');

DECLARE @name sysname;
DECLARE @sql nvarchar(max);

DECLARE procedure_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT name FROM @procedures;

OPEN procedure_cursor;
FETCH NEXT FROM procedure_cursor INTO @name;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID(@name, N'P') IS NULL
    BEGIN
        SET @sql = N'CREATE PROCEDURE ' + QUOTENAME(@name) + N'
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N''Contrato de ' + REPLACE(@name, '''', '''''') + N' creado; falta completar implementación.'' AS message;
END;';
        EXEC(@sql);
    END;

    FETCH NEXT FROM procedure_cursor INTO @name;
END;

CLOSE procedure_cursor;
DEALLOCATE procedure_cursor;

SET NOCOUNT OFF;
