/*
    Kronos - 03_indexes.sql

    Índices para las búsquedas y reportes más comunes.
    Luego se pueden ajustar con pruebas reales.
*/

SET NOCOUNT ON;
USE Kronos;

CREATE INDEX idx_access_tbl_user_sessions_user_active_created ON access_tbl_user_sessions(user_id, is_active, created_at);
CREATE INDEX idx_access_tbl_password_reset_tokens_user_expires ON access_tbl_password_reset_tokens(user_id, expires_at);
CREATE INDEX idx_access_tbl_audit_logs_user_created ON access_tbl_audit_logs(user_id, created_at);
CREATE INDEX idx_access_tbl_audit_logs_entity_created ON access_tbl_audit_logs(entity_name, entity_id, created_at);

CREATE INDEX idx_patient_tbl_patients_name ON patient_tbl_patients(last_name, first_name);
CREATE INDEX idx_patient_tbl_patients_status_deleted ON patient_tbl_patients(status_id, deleted);
CREATE UNIQUE INDEX idx_patient_tbl_patients_identification ON patient_tbl_patients(identification_number) WHERE identification_number IS NOT NULL;
CREATE INDEX idx_patient_tbl_contacts_patient_deleted ON patient_tbl_contacts(patient_id, deleted);

CREATE UNIQUE INDEX idx_staff_tbl_members_user ON staff_tbl_members(user_id) WHERE user_id IS NOT NULL;
CREATE UNIQUE INDEX idx_staff_tbl_members_identification ON staff_tbl_members(identification_number) WHERE identification_number IS NOT NULL;
CREATE INDEX idx_staff_tbl_members_role_active ON staff_tbl_members(staff_role_id, is_active);
CREATE INDEX idx_staff_tbl_availability_member_date ON staff_tbl_availability(staff_member_id, available_date);

CREATE INDEX idx_medical_tbl_records_patient_deleted ON medical_tbl_records(patient_id, deleted);
CREATE INDEX idx_medical_tbl_record_notes_patient_created ON medical_tbl_record_notes(patient_id, created_at);
CREATE INDEX idx_medical_tbl_patient_conditions_patient_deleted ON medical_tbl_patient_conditions(patient_id, deleted);
CREATE INDEX idx_medical_tbl_patient_medications_patient_deleted ON medical_tbl_patient_medications(patient_id, deleted);
CREATE INDEX idx_medical_tbl_patient_allergies_patient_deleted ON medical_tbl_patient_allergies(patient_id, deleted);
CREATE INDEX idx_medical_tbl_patient_vital_signs_patient_recorded ON medical_tbl_patient_vital_signs(patient_id, recorded_at);
CREATE INDEX idx_medical_tbl_record_access_logs_record_created ON medical_tbl_record_access_logs(medical_record_id, created_at);
CREATE INDEX idx_medical_tbl_record_access_logs_patient_created ON medical_tbl_record_access_logs(patient_id, created_at);
CREATE INDEX idx_medical_tbl_record_access_logs_user_created ON medical_tbl_record_access_logs(user_id, created_at);

CREATE INDEX idx_service_tbl_events_schedule ON service_tbl_events(scheduled_start_at, scheduled_end_at);
CREATE INDEX idx_service_tbl_events_patient_schedule ON service_tbl_events(patient_id, scheduled_start_at);
CREATE INDEX idx_service_tbl_events_status_schedule ON service_tbl_events(status_id, scheduled_start_at);
CREATE INDEX idx_service_tbl_events_type_schedule ON service_tbl_events(event_type_id, scheduled_start_at);
CREATE INDEX idx_service_tbl_event_staff_staff_event ON service_tbl_event_staff(staff_member_id, service_event_id);

CREATE INDEX idx_inventory_tbl_batches_item_expiration ON inventory_tbl_batches(inventory_item_id, expiration_date);
CREATE INDEX idx_inventory_tbl_batches_location_item ON inventory_tbl_batches(location_id, inventory_item_id);
CREATE INDEX idx_inventory_tbl_movements_item_date ON inventory_tbl_movements(inventory_item_id, movement_date);
CREATE INDEX idx_inventory_tbl_movements_location_date ON inventory_tbl_movements(location_id, movement_date);
CREATE INDEX idx_inventory_tbl_movements_type_source_date ON inventory_tbl_movements(movement_type_id, source_type_id, movement_date);

CREATE INDEX idx_financial_tbl_transactions_date ON financial_tbl_transactions(transaction_date);
CREATE INDEX idx_financial_tbl_transactions_category_date ON financial_tbl_transactions(financial_category_id, transaction_date);
CREATE INDEX idx_financial_tbl_transactions_type_date ON financial_tbl_transactions(transaction_type, transaction_date);
CREATE INDEX idx_financial_tbl_transactions_donor_date ON financial_tbl_transactions(financial_donor_id, transaction_date);
CREATE INDEX idx_financial_tbl_invoices_status_issue ON financial_tbl_invoices(status_id, issue_date);
CREATE INDEX idx_financial_tbl_receipts_status_date ON financial_tbl_receipts(status_id, receipt_date);

CREATE INDEX idx_notification_tbl_logs_status_created ON notification_tbl_logs(status_id, created_at);

SET NOCOUNT OFF;
