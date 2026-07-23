/*
    Kronos - 02_tables.sql

    Aquí se crean las tablas principales de Kronos.
    Todas usan la convención que acordamos:
    <modulo>_tbl_<nombre>.
*/

SET NOCOUNT ON;
USE Kronos;

-------------------------------------------------------------------------------
-- Ubicaciones
-------------------------------------------------------------------------------

CREATE TABLE location_tbl_provinces
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_location_tbl_provinces PRIMARY KEY,
    name nvarchar(100) NOT NULL,
    CONSTRAINT uq_location_tbl_provinces_name UNIQUE (name)
);

CREATE TABLE location_tbl_cantons
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_location_tbl_cantons PRIMARY KEY,
    location_province_id int NOT NULL,
    name nvarchar(100) NOT NULL,
    CONSTRAINT fk_location_tbl_cantons_province FOREIGN KEY (location_province_id) REFERENCES location_tbl_provinces(id),
    CONSTRAINT uq_location_tbl_cantons_province_name UNIQUE (location_province_id, name)
);

CREATE TABLE location_tbl_districts
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_location_tbl_districts PRIMARY KEY,
    location_canton_id int NOT NULL,
    name nvarchar(100) NOT NULL,
    CONSTRAINT fk_location_tbl_districts_canton FOREIGN KEY (location_canton_id) REFERENCES location_tbl_cantons(id),
    CONSTRAINT uq_location_tbl_districts_canton_name UNIQUE (location_canton_id, name)
);

CREATE TABLE location_tbl_addresses
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_location_tbl_addresses PRIMARY KEY,
    location_district_id int NOT NULL,
    address_line nvarchar(500) NOT NULL,
    reference nvarchar(500) NULL,
    is_active bit NOT NULL CONSTRAINT df_location_tbl_addresses_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_location_tbl_addresses_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_location_tbl_addresses_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_location_tbl_addresses_district FOREIGN KEY (location_district_id) REFERENCES location_tbl_districts(id)
);

CREATE TABLE location_tbl_locations
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_location_tbl_locations PRIMARY KEY,
    name nvarchar(150) NOT NULL,
    description nvarchar(500) NULL,
    address_id int NULL,
    is_active bit NOT NULL CONSTRAINT df_location_tbl_locations_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_location_tbl_locations_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_location_tbl_locations_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_location_tbl_locations_address FOREIGN KEY (address_id) REFERENCES location_tbl_addresses(id),
    CONSTRAINT uq_location_tbl_locations_name UNIQUE (name)
);

-------------------------------------------------------------------------------
-- Configuración
-------------------------------------------------------------------------------

CREATE TABLE config_tbl_settings
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_config_tbl_settings PRIMARY KEY,
    setting_type nvarchar(100) NOT NULL,
    setting_name nvarchar(150) NOT NULL,
    setting_value nvarchar(max) NOT NULL,
    description nvarchar(500) NULL,
    is_active bit NOT NULL CONSTRAINT df_config_tbl_settings_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_config_tbl_settings_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_config_tbl_settings_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_config_tbl_settings_type_name UNIQUE (setting_type, setting_name)
);

CREATE TABLE config_tbl_catalogs
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_config_tbl_catalogs PRIMARY KEY,
    name nvarchar(150) NOT NULL,
    description nvarchar(500) NULL,
    is_active bit NOT NULL CONSTRAINT df_config_tbl_catalogs_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_config_tbl_catalogs_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_config_tbl_catalogs_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_config_tbl_catalogs_name UNIQUE (name)
);

CREATE TABLE config_tbl_catalog_items
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_config_tbl_catalog_items PRIMARY KEY,
    catalog_id int NOT NULL,
    name nvarchar(150) NOT NULL,
    value nvarchar(150) NOT NULL,
    sort_order int NOT NULL CONSTRAINT df_config_tbl_catalog_items_sort_order DEFAULT (0),
    is_active bit NOT NULL CONSTRAINT df_config_tbl_catalog_items_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_config_tbl_catalog_items_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_config_tbl_catalog_items_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_config_tbl_catalog_items_catalog FOREIGN KEY (catalog_id) REFERENCES config_tbl_catalogs(id),
    CONSTRAINT uq_config_tbl_catalog_items_catalog_value UNIQUE (catalog_id, value)
);

CREATE TABLE config_tbl_document_types
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_config_tbl_document_types PRIMARY KEY,
    name nvarchar(150) NOT NULL,
    description nvarchar(500) NULL,
    is_active bit NOT NULL CONSTRAINT df_config_tbl_document_types_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_config_tbl_document_types_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_config_tbl_document_types_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_config_tbl_document_types_name UNIQUE (name)
);

-------------------------------------------------------------------------------
-- Acceso y seguridad
-------------------------------------------------------------------------------

CREATE TABLE access_tbl_users
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_access_tbl_users PRIMARY KEY,
    username nvarchar(100) NOT NULL,
    email nvarchar(256) NOT NULL,
    password nvarchar(500) NOT NULL,
    full_name nvarchar(200) NOT NULL,
    phone nvarchar(30) NULL,
    failed_login_attempts int NOT NULL CONSTRAINT df_access_tbl_users_failed_login_attempts DEFAULT (0),
    lockout_until datetime2(0) NULL,
    last_login_at datetime2(0) NULL,
    is_active bit NOT NULL CONSTRAINT df_access_tbl_users_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_access_tbl_users_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_access_tbl_users_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_access_tbl_users_username UNIQUE (username),
    CONSTRAINT uq_access_tbl_users_email UNIQUE (email)
);

CREATE TABLE access_tbl_roles
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_access_tbl_roles PRIMARY KEY,
    name nvarchar(100) NOT NULL,
    description nvarchar(500) NULL,
    is_active bit NOT NULL CONSTRAINT df_access_tbl_roles_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_access_tbl_roles_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_access_tbl_roles_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_access_tbl_roles_name UNIQUE (name)
);

CREATE TABLE access_tbl_permissions
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_access_tbl_permissions PRIMARY KEY,
    name nvarchar(150) NOT NULL,
    description nvarchar(500) NULL,
    is_active bit NOT NULL CONSTRAINT df_access_tbl_permissions_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_access_tbl_permissions_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_access_tbl_permissions_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_access_tbl_permissions_name UNIQUE (name)
);

CREATE TABLE access_tbl_role_permissions
(
    role_id int NOT NULL,
    permission_id int NOT NULL,
    created_at datetime2(0) NOT NULL CONSTRAINT df_access_tbl_role_permissions_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT pk_access_tbl_role_permissions PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_access_tbl_role_permissions_role FOREIGN KEY (role_id) REFERENCES access_tbl_roles(id),
    CONSTRAINT fk_access_tbl_role_permissions_permission FOREIGN KEY (permission_id) REFERENCES access_tbl_permissions(id)
);

CREATE TABLE access_tbl_user_roles
(
    user_id int NOT NULL,
    role_id int NOT NULL,
    created_at datetime2(0) NOT NULL CONSTRAINT df_access_tbl_user_roles_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT pk_access_tbl_user_roles PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_access_tbl_user_roles_user FOREIGN KEY (user_id) REFERENCES access_tbl_users(id),
    CONSTRAINT fk_access_tbl_user_roles_role FOREIGN KEY (role_id) REFERENCES access_tbl_roles(id)
);

CREATE TABLE access_tbl_user_sessions
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_access_tbl_user_sessions PRIMARY KEY,
    user_id int NOT NULL,
    login_at datetime2(0) NOT NULL,
    logout_at datetime2(0) NULL,
    token_id nvarchar(100) NULL,
    ip_address nvarchar(45) NULL,
    device_info nvarchar(500) NULL,
    is_revoked bit NOT NULL CONSTRAINT df_access_tbl_user_sessions_is_revoked DEFAULT (0),
    is_active bit NOT NULL CONSTRAINT df_access_tbl_user_sessions_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_access_tbl_user_sessions_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_access_tbl_user_sessions_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT fk_access_tbl_user_sessions_user FOREIGN KEY (user_id) REFERENCES access_tbl_users(id)
);

CREATE TABLE access_tbl_password_reset_tokens
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_access_tbl_password_reset_tokens PRIMARY KEY,
    user_id int NOT NULL,
    token nvarchar(500) NOT NULL,
    expires_at datetime2(0) NOT NULL,
    used_at datetime2(0) NULL,
    deleted bit NOT NULL CONSTRAINT df_access_tbl_password_reset_tokens_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_access_tbl_password_reset_tokens_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT fk_access_tbl_password_reset_tokens_user FOREIGN KEY (user_id) REFERENCES access_tbl_users(id),
    CONSTRAINT uq_access_tbl_password_reset_tokens_token UNIQUE (token)
);

CREATE TABLE access_tbl_audit_logs
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_access_tbl_audit_logs PRIMARY KEY,
    user_id int NULL,
    action nvarchar(100) NOT NULL,
    entity_name nvarchar(150) NOT NULL,
    entity_id int NULL,
    old_value nvarchar(max) NULL,
    new_value nvarchar(max) NULL,
    ip_address nvarchar(45) NULL,
    created_at datetime2(0) NOT NULL CONSTRAINT df_access_tbl_audit_logs_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT fk_access_tbl_audit_logs_user FOREIGN KEY (user_id) REFERENCES access_tbl_users(id)
);

CREATE TABLE system_tbl_error_logs
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_system_tbl_error_logs PRIMARY KEY,
    user_id int NULL,
    source nvarchar(150) NULL,
    message nvarchar(max) NOT NULL,
    detail nvarchar(max) NULL,
    created_at datetime2(0) NOT NULL CONSTRAINT df_system_tbl_error_logs_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT fk_system_tbl_error_logs_user FOREIGN KEY (user_id) REFERENCES access_tbl_users(id)
);

-------------------------------------------------------------------------------
-- Pacientes y personal
-------------------------------------------------------------------------------

CREATE TABLE patient_tbl_patients
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_patient_tbl_patients PRIMARY KEY,
    address_id int NULL,
    first_name nvarchar(100) NOT NULL,
    last_name nvarchar(150) NOT NULL,
    identification_number nvarchar(50) NULL,
    birth_date date NULL,
    gender_id int NULL,
    phone nvarchar(30) NULL,
    email nvarchar(256) NULL,
    status_id int NULL,
    is_active bit NOT NULL CONSTRAINT df_patient_tbl_patients_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_patient_tbl_patients_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_patient_tbl_patients_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_patient_tbl_patients_address FOREIGN KEY (address_id) REFERENCES location_tbl_addresses(id),
    CONSTRAINT fk_patient_tbl_patients_gender FOREIGN KEY (gender_id) REFERENCES config_tbl_catalog_items(id),
    CONSTRAINT fk_patient_tbl_patients_status FOREIGN KEY (status_id) REFERENCES config_tbl_catalog_items(id)
);

CREATE TABLE patient_tbl_contacts
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_patient_tbl_contacts PRIMARY KEY,
    patient_id int NOT NULL,
    contact_type_id int NOT NULL,
    full_name nvarchar(200) NOT NULL,
    relationship nvarchar(100) NULL,
    phone nvarchar(30) NULL,
    email nvarchar(256) NULL,
    is_primary_contact bit NOT NULL CONSTRAINT df_patient_tbl_contacts_is_primary DEFAULT (0),
    is_emergency_contact bit NOT NULL CONSTRAINT df_patient_tbl_contacts_is_emergency DEFAULT (0),
    notes nvarchar(max) NULL,
    is_active bit NOT NULL CONSTRAINT df_patient_tbl_contacts_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_patient_tbl_contacts_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_patient_tbl_contacts_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_patient_tbl_contacts_patient FOREIGN KEY (patient_id) REFERENCES patient_tbl_patients(id),
    CONSTRAINT fk_patient_tbl_contacts_contact_type FOREIGN KEY (contact_type_id) REFERENCES config_tbl_catalog_items(id)
);

CREATE TABLE staff_tbl_roles
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_staff_tbl_roles PRIMARY KEY,
    name nvarchar(100) NOT NULL,
    description nvarchar(500) NULL,
    is_active bit NOT NULL CONSTRAINT df_staff_tbl_roles_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_staff_tbl_roles_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_staff_tbl_roles_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_staff_tbl_roles_name UNIQUE (name)
);

CREATE TABLE staff_tbl_members
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_staff_tbl_members PRIMARY KEY,
    user_id int NULL,
    staff_role_id int NOT NULL,
    first_name nvarchar(100) NOT NULL,
    last_name nvarchar(150) NOT NULL,
    identification_number nvarchar(50) NULL,
    phone nvarchar(30) NULL,
    email nvarchar(256) NULL,
    is_active bit NOT NULL CONSTRAINT df_staff_tbl_members_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_staff_tbl_members_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_staff_tbl_members_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_staff_tbl_members_user FOREIGN KEY (user_id) REFERENCES access_tbl_users(id),
    CONSTRAINT fk_staff_tbl_members_role FOREIGN KEY (staff_role_id) REFERENCES staff_tbl_roles(id)
);

CREATE TABLE staff_tbl_specialties
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_staff_tbl_specialties PRIMARY KEY,
    name nvarchar(150) NOT NULL,
    description nvarchar(500) NULL,
    is_active bit NOT NULL CONSTRAINT df_staff_tbl_specialties_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_staff_tbl_specialties_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_staff_tbl_specialties_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_staff_tbl_specialties_name UNIQUE (name)
);

CREATE TABLE staff_tbl_member_specialties
(
    staff_member_id int NOT NULL,
    staff_specialty_id int NOT NULL,
    created_at datetime2(0) NOT NULL CONSTRAINT df_staff_tbl_member_specialties_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT pk_staff_tbl_member_specialties PRIMARY KEY (staff_member_id, staff_specialty_id),
    CONSTRAINT fk_staff_tbl_member_specialties_member FOREIGN KEY (staff_member_id) REFERENCES staff_tbl_members(id),
    CONSTRAINT fk_staff_tbl_member_specialties_specialty FOREIGN KEY (staff_specialty_id) REFERENCES staff_tbl_specialties(id)
);

CREATE TABLE staff_tbl_availability
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_staff_tbl_availability PRIMARY KEY,
    staff_member_id int NOT NULL,
    available_date date NOT NULL,
    start_time time(0) NOT NULL,
    end_time time(0) NOT NULL,
    is_available bit NOT NULL CONSTRAINT df_staff_tbl_availability_is_available DEFAULT (1),
    source_type_id int NULL,
    deleted bit NOT NULL CONSTRAINT df_staff_tbl_availability_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_staff_tbl_availability_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_staff_tbl_availability_member FOREIGN KEY (staff_member_id) REFERENCES staff_tbl_members(id),
    CONSTRAINT fk_staff_tbl_availability_source_type FOREIGN KEY (source_type_id) REFERENCES config_tbl_catalog_items(id),
    CONSTRAINT ck_staff_tbl_availability_time CHECK (end_time > start_time)
);

-------------------------------------------------------------------------------
-- Inventario y base financiera
-------------------------------------------------------------------------------

CREATE TABLE inventory_tbl_categories
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_inventory_tbl_categories PRIMARY KEY,
    name nvarchar(150) NOT NULL,
    description nvarchar(500) NULL,
    is_active bit NOT NULL CONSTRAINT df_inventory_tbl_categories_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_inventory_tbl_categories_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_inventory_tbl_categories_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_inventory_tbl_categories_name UNIQUE (name)
);

CREATE TABLE inventory_tbl_units
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_inventory_tbl_units PRIMARY KEY,
    name nvarchar(100) NOT NULL,
    abbreviation nvarchar(20) NULL,
    is_active bit NOT NULL CONSTRAINT df_inventory_tbl_units_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_inventory_tbl_units_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_inventory_tbl_units_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_inventory_tbl_units_name UNIQUE (name)
);

CREATE TABLE inventory_tbl_suppliers
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_inventory_tbl_suppliers PRIMARY KEY,
    name nvarchar(200) NOT NULL,
    contact_name nvarchar(200) NULL,
    phone nvarchar(30) NULL,
    email nvarchar(256) NULL,
    notes nvarchar(max) NULL,
    is_active bit NOT NULL CONSTRAINT df_inventory_tbl_suppliers_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_inventory_tbl_suppliers_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_inventory_tbl_suppliers_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_inventory_tbl_suppliers_name UNIQUE (name)
);

CREATE TABLE financial_tbl_donors
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_financial_tbl_donors PRIMARY KEY,
    name nvarchar(200) NOT NULL,
    contact_name nvarchar(200) NULL,
    phone nvarchar(30) NULL,
    email nvarchar(256) NULL,
    notes nvarchar(max) NULL,
    is_active bit NOT NULL CONSTRAINT df_financial_tbl_donors_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_financial_tbl_donors_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_financial_tbl_donors_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_financial_tbl_donors_name UNIQUE (name)
);

CREATE TABLE inventory_tbl_items
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_inventory_tbl_items PRIMARY KEY,
    inventory_category_id int NOT NULL,
    inventory_unit_id int NOT NULL,
    name nvarchar(200) NOT NULL,
    description nvarchar(500) NULL,
    minimum_stock decimal(18,4) NOT NULL CONSTRAINT df_inventory_tbl_items_minimum_stock DEFAULT (0),
    requires_expiration_date bit NOT NULL CONSTRAINT df_inventory_tbl_items_requires_expiration DEFAULT (0),
    is_active bit NOT NULL CONSTRAINT df_inventory_tbl_items_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_inventory_tbl_items_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_inventory_tbl_items_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_inventory_tbl_items_category FOREIGN KEY (inventory_category_id) REFERENCES inventory_tbl_categories(id),
    CONSTRAINT fk_inventory_tbl_items_unit FOREIGN KEY (inventory_unit_id) REFERENCES inventory_tbl_units(id)
);

CREATE TABLE inventory_tbl_batches
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_inventory_tbl_batches PRIMARY KEY,
    inventory_item_id int NOT NULL,
    location_id int NOT NULL,
    batch_number nvarchar(100) NULL,
    expiration_date date NULL,
    unit_cost decimal(18,2) NULL,
    quantity_initial decimal(18,4) NOT NULL,
    quantity_available decimal(18,4) NOT NULL,
    is_active bit NOT NULL CONSTRAINT df_inventory_tbl_batches_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_inventory_tbl_batches_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_inventory_tbl_batches_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_inventory_tbl_batches_item FOREIGN KEY (inventory_item_id) REFERENCES inventory_tbl_items(id),
    CONSTRAINT fk_inventory_tbl_batches_location FOREIGN KEY (location_id) REFERENCES location_tbl_locations(id),
    CONSTRAINT ck_inventory_tbl_batches_quantities CHECK (quantity_initial >= 0 AND quantity_available >= 0)
);

CREATE TABLE financial_tbl_categories
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_financial_tbl_categories PRIMARY KEY,
    name nvarchar(150) NOT NULL,
    transaction_type nvarchar(20) NOT NULL,
    description nvarchar(500) NULL,
    is_active bit NOT NULL CONSTRAINT df_financial_tbl_categories_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_financial_tbl_categories_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_financial_tbl_categories_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_financial_tbl_categories_name UNIQUE (name),
    CONSTRAINT ck_financial_tbl_categories_type CHECK (transaction_type IN (N'income', N'expense', N'adjustment'))
);

CREATE TABLE financial_tbl_payment_methods
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_financial_tbl_payment_methods PRIMARY KEY,
    name nvarchar(100) NOT NULL,
    description nvarchar(500) NULL,
    is_active bit NOT NULL CONSTRAINT df_financial_tbl_payment_methods_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_financial_tbl_payment_methods_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_financial_tbl_payment_methods_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_financial_tbl_payment_methods_name UNIQUE (name)
);

CREATE TABLE financial_tbl_invoices
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_financial_tbl_invoices PRIMARY KEY,
    invoice_number nvarchar(50) NOT NULL,
    patient_id int NULL,
    issue_date date NOT NULL,
    due_date date NULL,
    status_id int NOT NULL,
    subtotal decimal(18,2) NOT NULL,
    tax_amount decimal(18,2) NOT NULL CONSTRAINT df_financial_tbl_invoices_tax DEFAULT (0),
    total_amount decimal(18,2) NOT NULL,
    notes nvarchar(max) NULL,
    created_by_user_id int NOT NULL,
    is_active bit NOT NULL CONSTRAINT df_financial_tbl_invoices_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_financial_tbl_invoices_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_financial_tbl_invoices_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_financial_tbl_invoices_patient FOREIGN KEY (patient_id) REFERENCES patient_tbl_patients(id),
    CONSTRAINT fk_financial_tbl_invoices_status FOREIGN KEY (status_id) REFERENCES config_tbl_catalog_items(id),
    CONSTRAINT fk_financial_tbl_invoices_created_by FOREIGN KEY (created_by_user_id) REFERENCES access_tbl_users(id),
    CONSTRAINT uq_financial_tbl_invoices_number UNIQUE (invoice_number),
    CONSTRAINT ck_financial_tbl_invoices_amounts CHECK (subtotal >= 0 AND tax_amount >= 0 AND total_amount >= 0)
);

CREATE TABLE financial_tbl_invoice_items
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_financial_tbl_invoice_items PRIMARY KEY,
    financial_invoice_id int NOT NULL,
    service_id int NULL,
    description nvarchar(500) NOT NULL,
    quantity decimal(18,4) NOT NULL,
    unit_price decimal(18,2) NOT NULL,
    total_amount decimal(18,2) NOT NULL,
    created_at datetime2(0) NOT NULL CONSTRAINT df_financial_tbl_invoice_items_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT fk_financial_tbl_invoice_items_invoice FOREIGN KEY (financial_invoice_id) REFERENCES financial_tbl_invoices(id),
    CONSTRAINT ck_financial_tbl_invoice_items_amounts CHECK (quantity > 0 AND unit_price >= 0 AND total_amount >= 0)
);

CREATE TABLE financial_tbl_receipts
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_financial_tbl_receipts PRIMARY KEY,
    receipt_number nvarchar(50) NOT NULL,
    supplier_id int NULL,
    financial_donor_id int NULL,
    receipt_date date NOT NULL,
    status_id int NOT NULL,
    subtotal decimal(18,2) NOT NULL,
    tax_amount decimal(18,2) NOT NULL CONSTRAINT df_financial_tbl_receipts_tax DEFAULT (0),
    total_amount decimal(18,2) NOT NULL,
    notes nvarchar(max) NULL,
    created_by_user_id int NOT NULL,
    is_active bit NOT NULL CONSTRAINT df_financial_tbl_receipts_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_financial_tbl_receipts_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_financial_tbl_receipts_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_financial_tbl_receipts_supplier FOREIGN KEY (supplier_id) REFERENCES inventory_tbl_suppliers(id),
    CONSTRAINT fk_financial_tbl_receipts_donor FOREIGN KEY (financial_donor_id) REFERENCES financial_tbl_donors(id),
    CONSTRAINT fk_financial_tbl_receipts_status FOREIGN KEY (status_id) REFERENCES config_tbl_catalog_items(id),
    CONSTRAINT fk_financial_tbl_receipts_created_by FOREIGN KEY (created_by_user_id) REFERENCES access_tbl_users(id),
    CONSTRAINT uq_financial_tbl_receipts_number UNIQUE (receipt_number),
    CONSTRAINT ck_financial_tbl_receipts_amounts CHECK (subtotal >= 0 AND tax_amount >= 0 AND total_amount >= 0)
);

CREATE TABLE financial_tbl_receipt_items
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_financial_tbl_receipt_items PRIMARY KEY,
    financial_receipt_id int NOT NULL,
    inventory_item_id int NULL,
    description nvarchar(500) NOT NULL,
    quantity decimal(18,4) NOT NULL,
    unit_cost decimal(18,2) NOT NULL,
    total_amount decimal(18,2) NOT NULL,
    created_at datetime2(0) NOT NULL CONSTRAINT df_financial_tbl_receipt_items_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT fk_financial_tbl_receipt_items_receipt FOREIGN KEY (financial_receipt_id) REFERENCES financial_tbl_receipts(id),
    CONSTRAINT fk_financial_tbl_receipt_items_item FOREIGN KEY (inventory_item_id) REFERENCES inventory_tbl_items(id),
    CONSTRAINT ck_financial_tbl_receipt_items_amounts CHECK (quantity > 0 AND unit_cost >= 0 AND total_amount >= 0)
);

-------------------------------------------------------------------------------
-- Expedientes médicos y eventos de servicio
-------------------------------------------------------------------------------

CREATE TABLE medical_tbl_records
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_medical_tbl_records PRIMARY KEY,
    patient_id int NOT NULL,
    record_number nvarchar(50) NOT NULL,
    opened_at datetime2(0) NOT NULL,
    closed_at datetime2(0) NULL,
    status_id int NOT NULL,
    is_active bit NOT NULL CONSTRAINT df_medical_tbl_records_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_medical_tbl_records_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_medical_tbl_records_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_medical_tbl_records_patient FOREIGN KEY (patient_id) REFERENCES patient_tbl_patients(id),
    CONSTRAINT fk_medical_tbl_records_status FOREIGN KEY (status_id) REFERENCES config_tbl_catalog_items(id),
    CONSTRAINT uq_medical_tbl_records_number UNIQUE (record_number)
);

CREATE TABLE medical_tbl_conditions
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_medical_tbl_conditions PRIMARY KEY,
    name nvarchar(150) NOT NULL,
    description nvarchar(500) NULL,
    is_active bit NOT NULL CONSTRAINT df_medical_tbl_conditions_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_medical_tbl_conditions_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_medical_tbl_conditions_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_medical_tbl_conditions_name UNIQUE (name)
);

CREATE TABLE medical_tbl_medications
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_medical_tbl_medications PRIMARY KEY,
    name nvarchar(150) NOT NULL,
    description nvarchar(500) NULL,
    is_active bit NOT NULL CONSTRAINT df_medical_tbl_medications_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_medical_tbl_medications_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_medical_tbl_medications_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_medical_tbl_medications_name UNIQUE (name)
);

CREATE TABLE medical_tbl_allergies
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_medical_tbl_allergies PRIMARY KEY,
    name nvarchar(150) NOT NULL,
    description nvarchar(500) NULL,
    is_active bit NOT NULL CONSTRAINT df_medical_tbl_allergies_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_medical_tbl_allergies_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_medical_tbl_allergies_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_medical_tbl_allergies_name UNIQUE (name)
);

CREATE TABLE medical_tbl_record_notes
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_medical_tbl_record_notes PRIMARY KEY,
    medical_record_id int NOT NULL,
    patient_id int NOT NULL,
    staff_member_id int NOT NULL,
    note_type_id int NOT NULL,
    note_text nvarchar(max) NOT NULL,
    is_active bit NOT NULL CONSTRAINT df_medical_tbl_record_notes_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_medical_tbl_record_notes_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_medical_tbl_record_notes_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_medical_tbl_record_notes_record FOREIGN KEY (medical_record_id) REFERENCES medical_tbl_records(id),
    CONSTRAINT fk_medical_tbl_record_notes_patient FOREIGN KEY (patient_id) REFERENCES patient_tbl_patients(id),
    CONSTRAINT fk_medical_tbl_record_notes_staff FOREIGN KEY (staff_member_id) REFERENCES staff_tbl_members(id),
    CONSTRAINT fk_medical_tbl_record_notes_type FOREIGN KEY (note_type_id) REFERENCES config_tbl_catalog_items(id)
);

CREATE TABLE medical_tbl_patient_conditions
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_medical_tbl_patient_conditions PRIMARY KEY,
    patient_id int NOT NULL,
    medical_condition_id int NOT NULL,
    diagnosed_at date NULL,
    status_id int NULL,
    notes nvarchar(max) NULL,
    is_active bit NOT NULL CONSTRAINT df_medical_tbl_patient_conditions_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_medical_tbl_patient_conditions_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_medical_tbl_patient_conditions_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_medical_tbl_patient_conditions_patient FOREIGN KEY (patient_id) REFERENCES patient_tbl_patients(id),
    CONSTRAINT fk_medical_tbl_patient_conditions_condition FOREIGN KEY (medical_condition_id) REFERENCES medical_tbl_conditions(id),
    CONSTRAINT fk_medical_tbl_patient_conditions_status FOREIGN KEY (status_id) REFERENCES config_tbl_catalog_items(id)
);

CREATE TABLE medical_tbl_patient_medications
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_medical_tbl_patient_medications PRIMARY KEY,
    patient_id int NOT NULL,
    medical_medication_id int NOT NULL,
    dosage nvarchar(100) NULL,
    frequency nvarchar(100) NULL,
    start_date date NULL,
    end_date date NULL,
    notes nvarchar(max) NULL,
    is_active bit NOT NULL CONSTRAINT df_medical_tbl_patient_medications_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_medical_tbl_patient_medications_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_medical_tbl_patient_medications_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_medical_tbl_patient_medications_patient FOREIGN KEY (patient_id) REFERENCES patient_tbl_patients(id),
    CONSTRAINT fk_medical_tbl_patient_medications_medication FOREIGN KEY (medical_medication_id) REFERENCES medical_tbl_medications(id)
);

CREATE TABLE medical_tbl_patient_allergies
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_medical_tbl_patient_allergies PRIMARY KEY,
    patient_id int NOT NULL,
    medical_allergy_id int NOT NULL,
    reaction nvarchar(300) NULL,
    severity_id int NULL,
    notes nvarchar(max) NULL,
    is_active bit NOT NULL CONSTRAINT df_medical_tbl_patient_allergies_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_medical_tbl_patient_allergies_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_medical_tbl_patient_allergies_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_medical_tbl_patient_allergies_patient FOREIGN KEY (patient_id) REFERENCES patient_tbl_patients(id),
    CONSTRAINT fk_medical_tbl_patient_allergies_allergy FOREIGN KEY (medical_allergy_id) REFERENCES medical_tbl_allergies(id),
    CONSTRAINT fk_medical_tbl_patient_allergies_severity FOREIGN KEY (severity_id) REFERENCES config_tbl_catalog_items(id)
);

CREATE TABLE medical_tbl_patient_vital_signs
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_medical_tbl_patient_vital_signs PRIMARY KEY,
    patient_id int NOT NULL,
    staff_member_id int NULL,
    blood_pressure nvarchar(20) NULL,
    heart_rate int NULL,
    temperature decimal(5,2) NULL,
    oxygen_saturation decimal(5,2) NULL,
    respiratory_rate int NULL,
    recorded_at datetime2(0) NOT NULL,
    notes nvarchar(max) NULL,
    created_at datetime2(0) NOT NULL CONSTRAINT df_medical_tbl_patient_vital_signs_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT fk_medical_tbl_patient_vital_signs_patient FOREIGN KEY (patient_id) REFERENCES patient_tbl_patients(id),
    CONSTRAINT fk_medical_tbl_patient_vital_signs_staff FOREIGN KEY (staff_member_id) REFERENCES staff_tbl_members(id)
);

CREATE TABLE medical_tbl_patient_care_plans
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_medical_tbl_patient_care_plans PRIMARY KEY,
    patient_id int NOT NULL,
    title nvarchar(200) NOT NULL,
    description nvarchar(max) NULL,
    start_date date NULL,
    end_date date NULL,
    status_id int NOT NULL,
    created_by_staff_id int NULL,
    is_active bit NOT NULL CONSTRAINT df_medical_tbl_patient_care_plans_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_medical_tbl_patient_care_plans_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_medical_tbl_patient_care_plans_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_medical_tbl_patient_care_plans_patient FOREIGN KEY (patient_id) REFERENCES patient_tbl_patients(id),
    CONSTRAINT fk_medical_tbl_patient_care_plans_status FOREIGN KEY (status_id) REFERENCES config_tbl_catalog_items(id),
    CONSTRAINT fk_medical_tbl_patient_care_plans_staff FOREIGN KEY (created_by_staff_id) REFERENCES staff_tbl_members(id)
);

CREATE TABLE medical_tbl_patient_care_plan_activities
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_medical_tbl_patient_care_plan_activities PRIMARY KEY,
    patient_care_plan_id int NOT NULL,
    title nvarchar(200) NOT NULL,
    description nvarchar(max) NULL,
    due_date date NULL,
    completed_at datetime2(0) NULL,
    status_id int NOT NULL,
    is_active bit NOT NULL CONSTRAINT df_medical_tbl_patient_care_plan_activities_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_medical_tbl_patient_care_plan_activities_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_medical_tbl_patient_care_plan_activities_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_medical_tbl_patient_care_plan_activities_plan FOREIGN KEY (patient_care_plan_id) REFERENCES medical_tbl_patient_care_plans(id),
    CONSTRAINT fk_medical_tbl_patient_care_plan_activities_status FOREIGN KEY (status_id) REFERENCES config_tbl_catalog_items(id)
);

CREATE TABLE medical_tbl_record_attachments
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_medical_tbl_record_attachments PRIMARY KEY,
    medical_record_id int NOT NULL,
    patient_id int NOT NULL,
    document_type_id int NOT NULL,
    file_name nvarchar(255) NOT NULL,
    file_path nvarchar(1000) NOT NULL,
    content_type nvarchar(100) NULL,
    file_size bigint NULL,
    uploaded_by_user_id int NOT NULL,
    uploaded_at datetime2(0) NOT NULL,
    is_active bit NOT NULL CONSTRAINT df_medical_tbl_record_attachments_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_medical_tbl_record_attachments_deleted DEFAULT (0),
    CONSTRAINT fk_medical_tbl_record_attachments_record FOREIGN KEY (medical_record_id) REFERENCES medical_tbl_records(id),
    CONSTRAINT fk_medical_tbl_record_attachments_patient FOREIGN KEY (patient_id) REFERENCES patient_tbl_patients(id),
    CONSTRAINT fk_medical_tbl_record_attachments_document_type FOREIGN KEY (document_type_id) REFERENCES config_tbl_document_types(id),
    CONSTRAINT fk_medical_tbl_record_attachments_user FOREIGN KEY (uploaded_by_user_id) REFERENCES access_tbl_users(id)
);

CREATE TABLE medical_tbl_record_access_logs
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_medical_tbl_record_access_logs PRIMARY KEY,
    medical_record_id int NOT NULL,
    patient_id int NOT NULL,
    user_id int NOT NULL,
    staff_member_id int NULL,
    access_type_id int NOT NULL,
    access_reason nvarchar(500) NULL,
    ip_address nvarchar(45) NULL,
    device_info nvarchar(500) NULL,
    created_at datetime2(0) NOT NULL CONSTRAINT df_medical_tbl_record_access_logs_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT fk_medical_tbl_record_access_logs_record FOREIGN KEY (medical_record_id) REFERENCES medical_tbl_records(id),
    CONSTRAINT fk_medical_tbl_record_access_logs_patient FOREIGN KEY (patient_id) REFERENCES patient_tbl_patients(id),
    CONSTRAINT fk_medical_tbl_record_access_logs_user FOREIGN KEY (user_id) REFERENCES access_tbl_users(id),
    CONSTRAINT fk_medical_tbl_record_access_logs_staff FOREIGN KEY (staff_member_id) REFERENCES staff_tbl_members(id),
    CONSTRAINT fk_medical_tbl_record_access_logs_type FOREIGN KEY (access_type_id) REFERENCES config_tbl_catalog_items(id)
);

CREATE TABLE service_tbl_services
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_service_tbl_services PRIMARY KEY,
    name nvarchar(150) NOT NULL,
    description nvarchar(500) NULL,
    is_billable bit NOT NULL CONSTRAINT df_service_tbl_services_is_billable DEFAULT (0),
    default_price decimal(18,2) NULL,
    is_active bit NOT NULL CONSTRAINT df_service_tbl_services_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_service_tbl_services_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_service_tbl_services_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT uq_service_tbl_services_name UNIQUE (name)
);

ALTER TABLE financial_tbl_invoice_items
ADD CONSTRAINT fk_financial_tbl_invoice_items_service FOREIGN KEY (service_id) REFERENCES service_tbl_services(id);

CREATE TABLE service_tbl_events
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_service_tbl_events PRIMARY KEY,
    patient_id int NULL,
    event_type_id int NOT NULL,
    status_id int NOT NULL,
    scheduled_start_at datetime2(0) NOT NULL,
    scheduled_end_at datetime2(0) NOT NULL,
    actual_start_at datetime2(0) NULL,
    actual_end_at datetime2(0) NULL,
    location_type_id int NOT NULL,
    location_id int NULL,
    address_id int NULL,
    location_description nvarchar(500) NULL,
    main_staff_member_id int NULL,
    summary nvarchar(max) NULL,
    created_by_user_id int NOT NULL,
    is_active bit NOT NULL CONSTRAINT df_service_tbl_events_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_service_tbl_events_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_service_tbl_events_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_service_tbl_events_patient FOREIGN KEY (patient_id) REFERENCES patient_tbl_patients(id),
    CONSTRAINT fk_service_tbl_events_type FOREIGN KEY (event_type_id) REFERENCES config_tbl_catalog_items(id),
    CONSTRAINT fk_service_tbl_events_status FOREIGN KEY (status_id) REFERENCES config_tbl_catalog_items(id),
    CONSTRAINT fk_service_tbl_events_location_type FOREIGN KEY (location_type_id) REFERENCES config_tbl_catalog_items(id),
    CONSTRAINT fk_service_tbl_events_location FOREIGN KEY (location_id) REFERENCES location_tbl_locations(id),
    CONSTRAINT fk_service_tbl_events_address FOREIGN KEY (address_id) REFERENCES location_tbl_addresses(id),
    CONSTRAINT fk_service_tbl_events_main_staff FOREIGN KEY (main_staff_member_id) REFERENCES staff_tbl_members(id),
    CONSTRAINT fk_service_tbl_events_created_by FOREIGN KEY (created_by_user_id) REFERENCES access_tbl_users(id),
    CONSTRAINT ck_service_tbl_events_schedule CHECK (scheduled_end_at > scheduled_start_at)
);

CREATE TABLE service_tbl_event_staff
(
    service_event_id int NOT NULL,
    staff_member_id int NOT NULL,
    role_in_event_id int NULL,
    created_at datetime2(0) NOT NULL CONSTRAINT df_service_tbl_event_staff_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT pk_service_tbl_event_staff PRIMARY KEY (service_event_id, staff_member_id),
    CONSTRAINT fk_service_tbl_event_staff_event FOREIGN KEY (service_event_id) REFERENCES service_tbl_events(id),
    CONSTRAINT fk_service_tbl_event_staff_staff FOREIGN KEY (staff_member_id) REFERENCES staff_tbl_members(id),
    CONSTRAINT fk_service_tbl_event_staff_role FOREIGN KEY (role_in_event_id) REFERENCES config_tbl_catalog_items(id)
);

CREATE TABLE service_tbl_event_status_history
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_service_tbl_event_status_history PRIMARY KEY,
    service_event_id int NOT NULL,
    old_status_id int NULL,
    new_status_id int NOT NULL,
    reason nvarchar(500) NULL,
    changed_by_user_id int NOT NULL,
    changed_at datetime2(0) NOT NULL,
    CONSTRAINT fk_service_tbl_event_status_history_event FOREIGN KEY (service_event_id) REFERENCES service_tbl_events(id),
    CONSTRAINT fk_service_tbl_event_status_history_old_status FOREIGN KEY (old_status_id) REFERENCES config_tbl_catalog_items(id),
    CONSTRAINT fk_service_tbl_event_status_history_new_status FOREIGN KEY (new_status_id) REFERENCES config_tbl_catalog_items(id),
    CONSTRAINT fk_service_tbl_event_status_history_user FOREIGN KEY (changed_by_user_id) REFERENCES access_tbl_users(id)
);

CREATE TABLE service_tbl_event_notes
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_service_tbl_event_notes PRIMARY KEY,
    service_event_id int NOT NULL,
    staff_member_id int NULL,
    note_type_id int NOT NULL,
    note_text nvarchar(max) NOT NULL,
    is_active bit NOT NULL CONSTRAINT df_service_tbl_event_notes_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_service_tbl_event_notes_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_service_tbl_event_notes_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_service_tbl_event_notes_event FOREIGN KEY (service_event_id) REFERENCES service_tbl_events(id),
    CONSTRAINT fk_service_tbl_event_notes_staff FOREIGN KEY (staff_member_id) REFERENCES staff_tbl_members(id),
    CONSTRAINT fk_service_tbl_event_notes_type FOREIGN KEY (note_type_id) REFERENCES config_tbl_catalog_items(id)
);

CREATE TABLE service_tbl_event_services
(
    service_event_id int NOT NULL,
    service_id int NOT NULL,
    created_at datetime2(0) NOT NULL CONSTRAINT df_service_tbl_event_services_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT pk_service_tbl_event_services PRIMARY KEY (service_event_id, service_id),
    CONSTRAINT fk_service_tbl_event_services_event FOREIGN KEY (service_event_id) REFERENCES service_tbl_events(id),
    CONSTRAINT fk_service_tbl_event_services_service FOREIGN KEY (service_id) REFERENCES service_tbl_services(id)
);

CREATE TABLE inventory_tbl_movements
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_inventory_tbl_movements PRIMARY KEY,
    inventory_item_id int NOT NULL,
    inventory_batch_id int NULL,
    location_id int NOT NULL,
    movement_type_id int NOT NULL,
    source_type_id int NOT NULL,
    supplier_id int NULL,
    financial_donor_id int NULL,
    quantity decimal(18,4) NOT NULL,
    unit_cost decimal(18,2) NULL,
    total_cost decimal(18,2) NULL,
    movement_date datetime2(0) NOT NULL,
    notes nvarchar(max) NULL,
    created_by_user_id int NOT NULL,
    created_at datetime2(0) NOT NULL CONSTRAINT df_inventory_tbl_movements_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT fk_inventory_tbl_movements_item FOREIGN KEY (inventory_item_id) REFERENCES inventory_tbl_items(id),
    CONSTRAINT fk_inventory_tbl_movements_batch FOREIGN KEY (inventory_batch_id) REFERENCES inventory_tbl_batches(id),
    CONSTRAINT fk_inventory_tbl_movements_location FOREIGN KEY (location_id) REFERENCES location_tbl_locations(id),
    CONSTRAINT fk_inventory_tbl_movements_type FOREIGN KEY (movement_type_id) REFERENCES config_tbl_catalog_items(id),
    CONSTRAINT fk_inventory_tbl_movements_source FOREIGN KEY (source_type_id) REFERENCES config_tbl_catalog_items(id),
    CONSTRAINT fk_inventory_tbl_movements_supplier FOREIGN KEY (supplier_id) REFERENCES inventory_tbl_suppliers(id),
    CONSTRAINT fk_inventory_tbl_movements_donor FOREIGN KEY (financial_donor_id) REFERENCES financial_tbl_donors(id),
    CONSTRAINT fk_inventory_tbl_movements_user FOREIGN KEY (created_by_user_id) REFERENCES access_tbl_users(id),
    CONSTRAINT ck_inventory_tbl_movements_quantity CHECK (quantity > 0)
);

CREATE TABLE service_tbl_event_inventory_usage
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_service_tbl_event_inventory_usage PRIMARY KEY,
    service_event_id int NOT NULL,
    inventory_item_id int NOT NULL,
    inventory_batch_id int NULL,
    quantity_used decimal(18,4) NOT NULL,
    notes nvarchar(max) NULL,
    created_by_user_id int NOT NULL,
    created_at datetime2(0) NOT NULL CONSTRAINT df_service_tbl_event_inventory_usage_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT fk_service_tbl_event_inventory_usage_event FOREIGN KEY (service_event_id) REFERENCES service_tbl_events(id),
    CONSTRAINT fk_service_tbl_event_inventory_usage_item FOREIGN KEY (inventory_item_id) REFERENCES inventory_tbl_items(id),
    CONSTRAINT fk_service_tbl_event_inventory_usage_batch FOREIGN KEY (inventory_batch_id) REFERENCES inventory_tbl_batches(id),
    CONSTRAINT fk_service_tbl_event_inventory_usage_user FOREIGN KEY (created_by_user_id) REFERENCES access_tbl_users(id),
    CONSTRAINT ck_service_tbl_event_inventory_usage_quantity CHECK (quantity_used > 0)
);

CREATE TABLE financial_tbl_transactions
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_financial_tbl_transactions PRIMARY KEY,
    transaction_type nvarchar(20) NOT NULL,
    financial_category_id int NOT NULL,
    financial_payment_method_id int NULL,
    amount decimal(18,2) NOT NULL,
    transaction_date datetime2(0) NOT NULL,
    description nvarchar(max) NULL,
    financial_donor_id int NULL,
    supplier_id int NULL,
    patient_id int NULL,
    inventory_movement_id int NULL,
    service_event_id int NULL,
    financial_invoice_id int NULL,
    financial_receipt_id int NULL,
    created_by_user_id int NOT NULL,
    is_active bit NOT NULL CONSTRAINT df_financial_tbl_transactions_is_active DEFAULT (1),
    deleted bit NOT NULL CONSTRAINT df_financial_tbl_transactions_deleted DEFAULT (0),
    created_at datetime2(0) NOT NULL CONSTRAINT df_financial_tbl_transactions_created_at DEFAULT (SYSDATETIME()),
    updated_at datetime2(0) NULL,
    CONSTRAINT fk_financial_tbl_transactions_category FOREIGN KEY (financial_category_id) REFERENCES financial_tbl_categories(id),
    CONSTRAINT fk_financial_tbl_transactions_payment_method FOREIGN KEY (financial_payment_method_id) REFERENCES financial_tbl_payment_methods(id),
    CONSTRAINT fk_financial_tbl_transactions_donor FOREIGN KEY (financial_donor_id) REFERENCES financial_tbl_donors(id),
    CONSTRAINT fk_financial_tbl_transactions_supplier FOREIGN KEY (supplier_id) REFERENCES inventory_tbl_suppliers(id),
    CONSTRAINT fk_financial_tbl_transactions_patient FOREIGN KEY (patient_id) REFERENCES patient_tbl_patients(id),
    CONSTRAINT fk_financial_tbl_transactions_inventory_movement FOREIGN KEY (inventory_movement_id) REFERENCES inventory_tbl_movements(id),
    CONSTRAINT fk_financial_tbl_transactions_service_event FOREIGN KEY (service_event_id) REFERENCES service_tbl_events(id),
    CONSTRAINT fk_financial_tbl_transactions_invoice FOREIGN KEY (financial_invoice_id) REFERENCES financial_tbl_invoices(id),
    CONSTRAINT fk_financial_tbl_transactions_receipt FOREIGN KEY (financial_receipt_id) REFERENCES financial_tbl_receipts(id),
    CONSTRAINT fk_financial_tbl_transactions_created_by FOREIGN KEY (created_by_user_id) REFERENCES access_tbl_users(id),
    CONSTRAINT ck_financial_tbl_transactions_amount CHECK (amount >= 0),
    CONSTRAINT ck_financial_tbl_transactions_type CHECK (transaction_type IN (N'income', N'expense', N'adjustment'))
);

CREATE TABLE notification_tbl_logs
(
    id int IDENTITY(1,1) NOT NULL CONSTRAINT pk_notification_tbl_logs PRIMARY KEY,
    user_id int NULL,
    patient_id int NULL,
    service_event_id int NULL,
    notification_type_id int NOT NULL,
    recipient nvarchar(256) NULL,
    subject nvarchar(250) NULL,
    message nvarchar(max) NULL,
    status_id int NOT NULL,
    sent_at datetime2(0) NULL,
    error_message nvarchar(max) NULL,
    created_at datetime2(0) NOT NULL CONSTRAINT df_notification_tbl_logs_created_at DEFAULT (SYSDATETIME()),
    CONSTRAINT fk_notification_tbl_logs_user FOREIGN KEY (user_id) REFERENCES access_tbl_users(id),
    CONSTRAINT fk_notification_tbl_logs_patient FOREIGN KEY (patient_id) REFERENCES patient_tbl_patients(id),
    CONSTRAINT fk_notification_tbl_logs_service_event FOREIGN KEY (service_event_id) REFERENCES service_tbl_events(id),
    CONSTRAINT fk_notification_tbl_logs_type FOREIGN KEY (notification_type_id) REFERENCES config_tbl_catalog_items(id),
    CONSTRAINT fk_notification_tbl_logs_status FOREIGN KEY (status_id) REFERENCES config_tbl_catalog_items(id)
);

SET NOCOUNT OFF;
