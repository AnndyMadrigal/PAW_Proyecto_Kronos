/*
    Kronos - 04_views.sql

    Vistas internas para consultas y reportes.
    La web no debería llamarlas directo; la web llama SPs.
*/

SET NOCOUNT ON;
USE Kronos;

EXEC(N'
CREATE VIEW access_vw_users_with_roles AS
SELECT
    u.id AS user_id,
    u.username,
    u.email,
    u.full_name,
    u.phone,
    u.is_active,
    u.deleted,
    STRING_AGG(r.name, '', '') AS roles
FROM access_tbl_users u
LEFT JOIN access_tbl_user_roles ur ON ur.user_id = u.id
LEFT JOIN access_tbl_roles r ON r.id = ur.role_id
GROUP BY u.id, u.username, u.email, u.full_name, u.phone, u.is_active, u.deleted;
');

EXEC(N'
CREATE VIEW access_vw_audit_log_search AS
SELECT
    a.id,
    a.user_id,
    u.full_name AS user_name,
    a.action,
    a.entity_name,
    a.entity_id,
    a.ip_address,
    a.created_at
FROM access_tbl_audit_logs a
LEFT JOIN access_tbl_users u ON u.id = a.user_id;
');

EXEC(N'
CREATE VIEW patient_vw_active_patients AS
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.identification_number,
    p.birth_date,
    p.phone,
    p.email,
    p.status_id,
    status_item.name AS status_name,
    p.created_at
FROM patient_tbl_patients p
LEFT JOIN config_tbl_catalog_items status_item ON status_item.id = p.status_id
WHERE p.deleted = 0 AND p.is_active = 1;
');

EXEC(N'
CREATE VIEW patient_vw_summary AS
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.identification_number,
    p.birth_date,
    p.phone,
    p.email,
    p.status_id,
    status_item.name AS status_name,
    d.name AS district_name,
    c.name AS canton_name,
    pr.name AS province_name
FROM patient_tbl_patients p
LEFT JOIN config_tbl_catalog_items status_item ON status_item.id = p.status_id
LEFT JOIN location_tbl_addresses a ON a.id = p.address_id
LEFT JOIN location_tbl_districts d ON d.id = a.location_district_id
LEFT JOIN location_tbl_cantons c ON c.id = d.location_canton_id
LEFT JOIN location_tbl_provinces pr ON pr.id = c.location_province_id
WHERE p.deleted = 0;
');

EXEC(N'
CREATE VIEW patient_vw_medical_activity AS
SELECT
    p.id AS patient_id,
    p.first_name,
    p.last_name,
    COUNT(DISTINCT n.id) AS note_count,
    COUNT(DISTINCT pc.id) AS condition_count,
    COUNT(DISTINCT pm.id) AS medication_count,
    COUNT(DISTINCT pa.id) AS allergy_count,
    COUNT(DISTINCT vs.id) AS vital_sign_count
FROM patient_tbl_patients p
LEFT JOIN medical_tbl_record_notes n ON n.patient_id = p.id AND n.deleted = 0
LEFT JOIN medical_tbl_patient_conditions pc ON pc.patient_id = p.id AND pc.deleted = 0
LEFT JOIN medical_tbl_patient_medications pm ON pm.patient_id = p.id AND pm.deleted = 0
LEFT JOIN medical_tbl_patient_allergies pa ON pa.patient_id = p.id AND pa.deleted = 0
LEFT JOIN medical_tbl_patient_vital_signs vs ON vs.patient_id = p.id
WHERE p.deleted = 0
GROUP BY p.id, p.first_name, p.last_name;
');

EXEC(N'
CREATE VIEW medical_vw_record_access_logs AS
SELECT
    l.id,
    l.medical_record_id,
    l.patient_id,
    p.first_name,
    p.last_name,
    l.user_id,
    u.full_name AS user_name,
    l.access_type_id,
    t.name AS access_type_name,
    l.access_reason,
    l.ip_address,
    l.device_info,
    l.created_at
FROM medical_tbl_record_access_logs l
INNER JOIN patient_tbl_patients p ON p.id = l.patient_id
INNER JOIN access_tbl_users u ON u.id = l.user_id
INNER JOIN config_tbl_catalog_items t ON t.id = l.access_type_id;
');

EXEC(N'
CREATE VIEW staff_vw_schedule AS
SELECT
    a.id,
    a.staff_member_id,
    s.first_name,
    s.last_name,
    a.available_date,
    a.start_time,
    a.end_time,
    a.is_available
FROM staff_tbl_availability a
INNER JOIN staff_tbl_members s ON s.id = a.staff_member_id
WHERE a.deleted = 0;
');

EXEC(N'
CREATE VIEW service_vw_event_calendar AS
SELECT
    e.id,
    e.patient_id,
    p.first_name AS patient_first_name,
    p.last_name AS patient_last_name,
    e.event_type_id,
    et.name AS event_type_name,
    e.status_id,
    st.name AS status_name,
    e.scheduled_start_at,
    e.scheduled_end_at,
    e.main_staff_member_id,
    sm.first_name AS staff_first_name,
    sm.last_name AS staff_last_name
FROM service_tbl_events e
LEFT JOIN patient_tbl_patients p ON p.id = e.patient_id
LEFT JOIN staff_tbl_members sm ON sm.id = e.main_staff_member_id
LEFT JOIN config_tbl_catalog_items et ON et.id = e.event_type_id
LEFT JOIN config_tbl_catalog_items st ON st.id = e.status_id
WHERE e.deleted = 0;
');

EXEC(N'
CREATE VIEW service_vw_event_detail AS
SELECT
    e.*
FROM service_tbl_events e
WHERE e.deleted = 0;
');

EXEC(N'
CREATE VIEW service_vw_report_events AS
SELECT * FROM service_vw_event_calendar;
');

EXEC(N'
CREATE VIEW service_vw_inventory_usage AS
SELECT
    u.id,
    u.service_event_id,
    u.inventory_item_id,
    i.name AS inventory_item_name,
    u.inventory_batch_id,
    u.quantity_used,
    u.created_at
FROM service_tbl_event_inventory_usage u
INNER JOIN inventory_tbl_items i ON i.id = u.inventory_item_id;
');

EXEC(N'
CREATE VIEW inventory_vw_stock_by_item AS
SELECT
    i.id AS inventory_item_id,
    i.name,
    c.name AS category_name,
    u.name AS unit_name,
    i.minimum_stock,
    SUM(ISNULL(b.quantity_available, 0)) AS quantity_available
FROM inventory_tbl_items i
INNER JOIN inventory_tbl_categories c ON c.id = i.inventory_category_id
INNER JOIN inventory_tbl_units u ON u.id = i.inventory_unit_id
LEFT JOIN inventory_tbl_batches b ON b.inventory_item_id = i.id AND b.deleted = 0
WHERE i.deleted = 0
GROUP BY i.id, i.name, c.name, u.name, i.minimum_stock;
');

EXEC(N'
CREATE VIEW inventory_vw_stock_by_location AS
SELECT
    i.id AS inventory_item_id,
    i.name AS inventory_item_name,
    l.id AS location_id,
    l.name AS location_name,
    SUM(ISNULL(b.quantity_available, 0)) AS quantity_available
FROM inventory_tbl_items i
LEFT JOIN inventory_tbl_batches b ON b.inventory_item_id = i.id AND b.deleted = 0
LEFT JOIN location_tbl_locations l ON l.id = b.location_id
WHERE i.deleted = 0
GROUP BY i.id, i.name, l.id, l.name;
');

EXEC(N'
CREATE VIEW inventory_vw_low_stock AS
SELECT *
FROM inventory_vw_stock_by_item
WHERE quantity_available <= minimum_stock;
');

EXEC(N'
CREATE VIEW inventory_vw_expiring_batches AS
SELECT
    b.id,
    b.inventory_item_id,
    i.name AS inventory_item_name,
    b.location_id,
    l.name AS location_name,
    b.batch_number,
    b.expiration_date,
    b.quantity_available
FROM inventory_tbl_batches b
INNER JOIN inventory_tbl_items i ON i.id = b.inventory_item_id
INNER JOIN location_tbl_locations l ON l.id = b.location_id
WHERE b.deleted = 0 AND b.quantity_available > 0 AND b.expiration_date IS NOT NULL;
');

EXEC(N'
CREATE VIEW inventory_vw_report_movements AS
SELECT
    m.id,
    m.inventory_item_id,
    i.name AS inventory_item_name,
    m.location_id,
    l.name AS location_name,
    mt.name AS movement_type_name,
    st.name AS source_type_name,
    m.quantity,
    m.unit_cost,
    m.total_cost,
    m.movement_date,
    m.created_by_user_id
FROM inventory_tbl_movements m
INNER JOIN inventory_tbl_items i ON i.id = m.inventory_item_id
INNER JOIN location_tbl_locations l ON l.id = m.location_id
INNER JOIN config_tbl_catalog_items mt ON mt.id = m.movement_type_id
INNER JOIN config_tbl_catalog_items st ON st.id = m.source_type_id;
');

EXEC(N'
CREATE VIEW financial_vw_transactions_summary AS
SELECT
    transaction_type,
    CAST(transaction_date AS date) AS transaction_day,
    SUM(amount) AS total_amount
FROM financial_tbl_transactions
WHERE deleted = 0
GROUP BY transaction_type, CAST(transaction_date AS date);
');

EXEC(N'
CREATE VIEW financial_vw_balance_by_period AS
SELECT
    YEAR(transaction_date) AS year_number,
    MONTH(transaction_date) AS month_number,
    SUM(CASE WHEN transaction_type = N''income'' THEN amount ELSE 0 END) AS total_income,
    SUM(CASE WHEN transaction_type = N''expense'' THEN amount ELSE 0 END) AS total_expense,
    SUM(CASE WHEN transaction_type = N''income'' THEN amount WHEN transaction_type = N''expense'' THEN -amount ELSE 0 END) AS balance
FROM financial_tbl_transactions
WHERE deleted = 0
GROUP BY YEAR(transaction_date), MONTH(transaction_date);
');

EXEC(N'
CREATE VIEW financial_vw_invoice_status AS
SELECT
    i.id,
    i.invoice_number,
    i.patient_id,
    p.first_name,
    p.last_name,
    i.issue_date,
    i.due_date,
    i.status_id,
    s.name AS status_name,
    i.total_amount
FROM financial_tbl_invoices i
LEFT JOIN patient_tbl_patients p ON p.id = i.patient_id
INNER JOIN config_tbl_catalog_items s ON s.id = i.status_id
WHERE i.deleted = 0;
');

EXEC(N'
CREATE VIEW notification_vw_pending AS
SELECT *
FROM notification_tbl_logs
WHERE sent_at IS NULL;
');

EXEC(N'
CREATE VIEW system_vw_error_summary AS
SELECT
    id,
    user_id,
    source,
    message,
    created_at
FROM system_tbl_error_logs;
');

SET NOCOUNT OFF;
