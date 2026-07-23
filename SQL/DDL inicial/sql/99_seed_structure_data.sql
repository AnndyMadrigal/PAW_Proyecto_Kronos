/*
    Kronos - 99_seed_structure_data.sql

    Este archivo carga la data base que el sistema necesita para arrancar:
    roles, permisos, catálogos, opciones de formularios y algunos usuarios de prueba.

    No mete datos de operación real. Por eso aquí no hay sesiones, facturas,
    expedientes, citas ni movimientos de inventario.

    Las contraseñas de prueba quedan temporales. Cuando ya esté listo el login
    en .NET, se reemplazan por el formato real que genere la aplicación.
*/

SET NOCOUNT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    ---------------------------------------------------------------------------
    -- Configuración inicial
    ---------------------------------------------------------------------------

    IF NOT EXISTS (
        SELECT 1
        FROM config_tbl_settings
        WHERE setting_type = N'site' AND setting_name = N'app_name'
    )
    BEGIN
        INSERT INTO config_tbl_settings
            (setting_type, setting_name, setting_value, description, is_active, deleted, created_at)
        VALUES
            (N'site', N'app_name', N'Kronos', N'Nombre visible del sistema.', 1, 0, SYSDATETIME());
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM config_tbl_settings
        WHERE setting_type = N'site' AND setting_name = N'Cuidados Paliativos - San Rafael de Alajuela'
    )
    BEGIN
        INSERT INTO config_tbl_settings
            (setting_type, setting_name, setting_value, description, is_active, deleted, created_at)
        VALUES
            (N'site', N'organization_name', N'Asociación de Cuidados Paliativos', N'Nombre institucional mostrado en reportes y encabezados.', 1, 0, SYSDATETIME());
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM config_tbl_settings
        WHERE setting_type = N'files' AND setting_name = N'medical_attachments_root'
    )
    BEGIN
        INSERT INTO config_tbl_settings
            (setting_type, setting_name, setting_value, description, is_active, deleted, created_at)
        VALUES
            (N'files', N'medical_attachments_root', N'/uploads/medical-records', N'Ruta base para adjuntos de expedientes médicos.', 1, 0, SYSDATETIME());
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM config_tbl_settings
        WHERE setting_type = N'security' AND setting_name = N'max_failed_login_attempts'
    )
    BEGIN
        INSERT INTO config_tbl_settings
            (setting_type, setting_name, setting_value, description, is_active, deleted, created_at)
        VALUES
            (N'security', N'max_failed_login_attempts', N'3', N'Cantidad de intentos fallidos antes de bloqueo temporal.', 1, 0, SYSDATETIME());
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM config_tbl_settings
        WHERE setting_type = N'security' AND setting_name = N'lockout_minutes'
    )
    BEGIN
        INSERT INTO config_tbl_settings
            (setting_type, setting_name, setting_value, description, is_active, deleted, created_at)
        VALUES
            (N'security', N'lockout_minutes', N'15', N'Minutos de bloqueo tras exceder intentos fallidos.', 1, 0, SYSDATETIME());
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM config_tbl_settings
        WHERE setting_type = N'financial' AND setting_name = N'invoice_due_days'
    )
    BEGIN
        INSERT INTO config_tbl_settings
            (setting_type, setting_name, setting_value, description, is_active, deleted, created_at)
        VALUES
            (N'financial', N'invoice_due_days', N'30', N'Días por defecto para vencimiento de facturas.', 1, 0, SYSDATETIME());
    END;

    ---------------------------------------------------------------------------
    -- Catálogos
    ---------------------------------------------------------------------------

    DECLARE @catalogs TABLE
    (
        name nvarchar(150) NOT NULL,
        description nvarchar(500) NULL
    );

    INSERT INTO @catalogs (name, description)
    VALUES
        (N'user_status', N'Estados de usuarios del sistema.'),
        (N'patient_status', N'Estados administrativos del paciente.'),
        (N'gender', N'Opciones de género para formularios.'),
        (N'contact_type', N'Tipos de contacto del paciente.'),
        (N'staff_availability_source_type', N'Origen de disponibilidad del personal.'),
        (N'inventory_movement_type', N'Tipos de movimiento de inventario.'),
        (N'inventory_source_type', N'Origen operativo del movimiento de inventario.'),
        (N'medical_record_status', N'Estados de expediente médico.'),
        (N'medical_record_access_type', N'Tipos de acceso a expedientes médicos.'),
        (N'medical_note_type', N'Tipos de notas clínicas.'),
        (N'condition_status', N'Estados de condición médica.'),
        (N'allergy_severity', N'Severidad de alergias.'),
        (N'care_plan_status', N'Estados del plan de cuidado.'),
        (N'care_plan_activity_status', N'Estados de actividades del plan de cuidado.'),
        (N'service_event_type', N'Tipos de citas, visitas o eventos de servicio.'),
        (N'service_event_status', N'Estados de citas, visitas o eventos.'),
        (N'service_event_location_type', N'Tipos de ubicación para citas o visitas.'),
        (N'service_event_staff_role', N'Rol del personal dentro de una cita o visita.'),
        (N'service_event_note_type', N'Tipos de nota en citas o visitas.'),
        (N'financial_invoice_status', N'Estados de facturas.'),
        (N'financial_receipt_status', N'Estados de recibos.'),
        (N'financial_transaction_type', N'Tipos generales de movimientos financieros.'),
        (N'notification_type', N'Tipos de notificación.'),
        (N'notification_status', N'Estados de notificación.');

    INSERT INTO config_tbl_catalogs
        (name, description, is_active, deleted, created_at)
    SELECT
        c.name,
        c.description,
        1,
        0,
        SYSDATETIME()
    FROM @catalogs c
    WHERE NOT EXISTS (
        SELECT 1
        FROM config_tbl_catalogs t
        WHERE t.name = c.name
    );

    ---------------------------------------------------------------------------
    -- Opciones de catálogos
    ---------------------------------------------------------------------------

    DECLARE @catalog_items TABLE
    (
        catalog_name nvarchar(150) NOT NULL,
        name nvarchar(150) NOT NULL,
        value nvarchar(150) NOT NULL,
        sort_order int NOT NULL
    );

    INSERT INTO @catalog_items (catalog_name, name, value, sort_order)
    VALUES
        -- user_status
        (N'user_status', N'Activo', N'active', 10),
        (N'user_status', N'Inactivo', N'inactive', 20),
        (N'user_status', N'Bloqueado', N'locked', 30),

        -- patient_status
        (N'patient_status', N'Activo', N'active', 10),
        (N'patient_status', N'Pendiente de valoración', N'pending_assessment', 20),
        (N'patient_status', N'En seguimiento', N'in_follow_up', 30),
        (N'patient_status', N'Egresado', N'discharged', 40),
        (N'patient_status', N'Suspendido', N'suspended', 50),
        (N'patient_status', N'Fallecido', N'deceased', 60),
        (N'patient_status', N'Inactivo', N'inactive', 70),

        -- gender
        (N'gender', N'Femenino', N'female', 10),
        (N'gender', N'Masculino', N'male', 20),
        (N'gender', N'Otro', N'other', 30),
        (N'gender', N'No especificado', N'unspecified', 40),

        -- contact_type
        (N'contact_type', N'Familiar', N'family', 10),
        (N'contact_type', N'Responsable legal', N'legal_guardian', 20),
        (N'contact_type', N'Cuidador principal', N'primary_caregiver', 30),
        (N'contact_type', N'Contacto de emergencia', N'emergency_contact', 40),
        (N'contact_type', N'Profesional externo', N'external_professional', 50),
        (N'contact_type', N'Otro', N'other', 60),

        -- staff_availability_source_type
        (N'staff_availability_source_type', N'Manual', N'manual', 10),
        (N'staff_availability_source_type', N'Horario laboral', N'work_schedule', 20),
        (N'staff_availability_source_type', N'Permiso', N'leave', 30),
        (N'staff_availability_source_type', N'Ausencia', N'absence', 40),

        -- inventory_movement_type
        (N'inventory_movement_type', N'Entrada', N'in', 10),
        (N'inventory_movement_type', N'Salida', N'out', 20),
        (N'inventory_movement_type', N'Ajuste', N'adjustment', 30),

        -- inventory_source_type
        (N'inventory_source_type', N'Compra', N'purchase', 10),
        (N'inventory_source_type', N'Donación', N'donation', 20),
        (N'inventory_source_type', N'Cita o visita', N'service_event', 30),
        (N'inventory_source_type', N'Corrección de inventario', N'correction', 40),
        (N'inventory_source_type', N'Traslado interno', N'internal_transfer', 50),
        (N'inventory_source_type', N'Vencimiento', N'expiration', 60),
        (N'inventory_source_type', N'Daño o pérdida', N'damage_loss', 70),

        -- medical_record_status
        (N'medical_record_status', N'Abierto', N'open', 10),
        (N'medical_record_status', N'Cerrado', N'closed', 20),
        (N'medical_record_status', N'Suspendido', N'suspended', 30),

        -- medical_record_access_type
        (N'medical_record_access_type', N'Visualización', N'view', 10),
        (N'medical_record_access_type', N'Exportación', N'export', 20),
        (N'medical_record_access_type', N'Descarga de adjunto', N'download', 30),
        (N'medical_record_access_type', N'Impresión', N'print', 40),

        -- medical_note_type
        (N'medical_note_type', N'Observación general', N'general_observation', 10),
        (N'medical_note_type', N'Evolución clínica', N'clinical_evolution', 20),
        (N'medical_note_type', N'Indicación médica', N'medical_instruction', 30),
        (N'medical_note_type', N'Nota de enfermería', N'nursing_note', 40),
        (N'medical_note_type', N'Resultado de visita', N'visit_result', 50),
        (N'medical_note_type', N'Otro', N'other', 60),

        -- condition_status
        (N'condition_status', N'Activa', N'active', 10),
        (N'condition_status', N'Controlada', N'controlled', 20),
        (N'condition_status', N'Resuelta', N'resolved', 30),
        (N'condition_status', N'En observación', N'under_observation', 40),

        -- allergy_severity
        (N'allergy_severity', N'Leve', N'mild', 10),
        (N'allergy_severity', N'Moderada', N'moderate', 20),
        (N'allergy_severity', N'Severa', N'severe', 30),
        (N'allergy_severity', N'Crítica', N'critical', 40),
        (N'allergy_severity', N'Desconocida', N'unknown', 50),

        -- care_plan_status
        (N'care_plan_status', N'Activo', N'active', 10),
        (N'care_plan_status', N'En pausa', N'paused', 20),
        (N'care_plan_status', N'Finalizado', N'completed', 30),
        (N'care_plan_status', N'Cancelado', N'cancelled', 40),

        -- care_plan_activity_status
        (N'care_plan_activity_status', N'Pendiente', N'pending', 10),
        (N'care_plan_activity_status', N'En proceso', N'in_progress', 20),
        (N'care_plan_activity_status', N'Completada', N'completed', 30),
        (N'care_plan_activity_status', N'Vencida', N'overdue', 40),
        (N'care_plan_activity_status', N'Cancelada', N'cancelled', 50),

        -- service_event_type
        (N'service_event_type', N'Cita presencial', N'onsite_appointment', 10),
        (N'service_event_type', N'Visita domiciliar', N'home_visit', 20),
        (N'service_event_type', N'Control telefónico', N'phone_follow_up', 30),
        (N'service_event_type', N'Actividad interna', N'internal_activity', 40),
        (N'service_event_type', N'Otro', N'other', 50),

        -- service_event_status
        (N'service_event_status', N'Programada', N'scheduled', 10),
        (N'service_event_status', N'Reprogramada', N'rescheduled', 20),
        (N'service_event_status', N'En proceso', N'in_progress', 30),
        (N'service_event_status', N'Completada', N'completed', 40),
        (N'service_event_status', N'Cancelada', N'cancelled', 50),
        (N'service_event_status', N'No se presentó', N'no_show', 60),

        -- service_event_location_type
        (N'service_event_location_type', N'En sede', N'onsite', 10),
        (N'service_event_location_type', N'Domicilio', N'home', 20),
        (N'service_event_location_type', N'Externo', N'external', 30),
        (N'service_event_location_type', N'Telefónico', N'phone', 40),
        (N'service_event_location_type', N'Virtual', N'virtual', 50),

        -- service_event_staff_role
        (N'service_event_staff_role', N'Responsable principal', N'primary_responsible', 10),
        (N'service_event_staff_role', N'Médico', N'doctor', 20),
        (N'service_event_staff_role', N'Enfermería', N'nursing', 30),
        (N'service_event_staff_role', N'Voluntario', N'volunteer', 40),
        (N'service_event_staff_role', N'Apoyo administrativo', N'administrative_support', 50),

        -- service_event_note_type
        (N'service_event_note_type', N'Nota general', N'general', 10),
        (N'service_event_note_type', N'Resultado', N'result', 20),
        (N'service_event_note_type', N'Cancelación', N'cancellation', 30),
        (N'service_event_note_type', N'Reprogramación', N'reschedule', 40),
        (N'service_event_note_type', N'Seguimiento', N'follow_up', 50),

        -- financial_invoice_status
        (N'financial_invoice_status', N'Borrador', N'draft', 10),
        (N'financial_invoice_status', N'Emitida', N'issued', 20),
        (N'financial_invoice_status', N'Parcialmente pagada', N'partially_paid', 30),
        (N'financial_invoice_status', N'Pagada', N'paid', 40),
        (N'financial_invoice_status', N'Vencida', N'overdue', 50),
        (N'financial_invoice_status', N'Anulada', N'voided', 60),

        -- financial_receipt_status
        (N'financial_receipt_status', N'Borrador', N'draft', 10),
        (N'financial_receipt_status', N'Registrado', N'registered', 20),
        (N'financial_receipt_status', N'Anulado', N'voided', 30),

        -- financial_transaction_type
        (N'financial_transaction_type', N'Ingreso', N'income', 10),
        (N'financial_transaction_type', N'Egreso', N'expense', 20),
        (N'financial_transaction_type', N'Ajuste', N'adjustment', 30),

        -- notification_type
        (N'notification_type', N'Correo electrónico', N'email', 10),
        (N'notification_type', N'Sistema', N'system', 20),
        (N'notification_type', N'Recordatorio', N'reminder', 30),
        (N'notification_type', N'Alerta de inventario', N'inventory_alert', 40),
        (N'notification_type', N'Recuperación de contraseña', N'password_reset', 50),

        -- notification_status
        (N'notification_status', N'Pendiente', N'pending', 10),
        (N'notification_status', N'Enviada', N'sent', 20),
        (N'notification_status', N'Fallida', N'failed', 30),
        (N'notification_status', N'Reintentando', N'retrying', 40),
        (N'notification_status', N'Cancelada', N'cancelled', 50);

    INSERT INTO config_tbl_catalog_items
        (catalog_id, name, value, sort_order, is_active, deleted, created_at)
    SELECT
        c.id,
        i.name,
        i.value,
        i.sort_order,
        1,
        0,
        SYSDATETIME()
    FROM @catalog_items i
    INNER JOIN config_tbl_catalogs c
        ON c.name = i.catalog_name
    WHERE NOT EXISTS (
        SELECT 1
        FROM config_tbl_catalog_items t
        WHERE t.catalog_id = c.id
          AND t.value = i.value
    );

    ---------------------------------------------------------------------------
    -- Roles y permisos
    ---------------------------------------------------------------------------

    DECLARE @roles TABLE
    (
        name nvarchar(100) NOT NULL,
        description nvarchar(500) NULL
    );

    INSERT INTO @roles (name, description)
    VALUES
        (N'Administrador', N'Acceso completo a configuración, seguridad, operación, reportes y auditoría.'),
        (N'Médico', N'Acceso clínico para expedientes, notas, diagnósticos, tratamientos y reportes médicos.'),
        (N'Enfermería', N'Acceso clínico operativo para notas, signos vitales, visitas y consumo de insumos.'),
        (N'Inventario', N'Gestión de insumos, lotes, existencias, entradas, salidas y reportes de inventario.'),
        (N'Finanzas', N'Gestión de ingresos, egresos, donaciones, facturas, recibos y reportes financieros.'),
        (N'Administrativo', N'Gestión de pacientes, agenda, personal operativo y reportes generales.'),
        (N'Voluntario', N'Acceso limitado a agenda y actividades asignadas.');

    INSERT INTO access_tbl_roles
        (name, description, is_active, deleted, created_at)
    SELECT
        r.name,
        r.description,
        1,
        0,
        SYSDATETIME()
    FROM @roles r
    WHERE NOT EXISTS (
        SELECT 1
        FROM access_tbl_roles t
        WHERE t.name = r.name
    );

    DECLARE @permissions TABLE
    (
        name nvarchar(150) NOT NULL,
        description nvarchar(500) NULL
    );

    INSERT INTO @permissions (name, description)
    VALUES
        -- Access
        (N'access.users.read', N'Consultar usuarios.'),
        (N'access.users.create', N'Crear usuarios.'),
        (N'access.users.update', N'Actualizar usuarios.'),
        (N'access.users.delete', N'Eliminar lógicamente usuarios.'),
        (N'access.roles.manage', N'Gestionar roles y permisos.'),
        (N'access.audit.read', N'Consultar auditoría general del sistema.'),

        -- Patients
        (N'patients.read', N'Consultar pacientes.'),
        (N'patients.create', N'Crear pacientes.'),
        (N'patients.update', N'Actualizar pacientes.'),
        (N'patients.delete', N'Eliminar lógicamente pacientes.'),
        (N'patients.reports.read', N'Consultar reportes de pacientes.'),

        -- Staff
        (N'staff.read', N'Consultar personal.'),
        (N'staff.create', N'Crear personal.'),
        (N'staff.update', N'Actualizar personal.'),
        (N'staff.delete', N'Eliminar lógicamente personal.'),
        (N'staff.availability.manage', N'Gestionar disponibilidad del personal.'),

        -- Medical
        (N'medical.records.read', N'Ver resumen y detalle de expedientes médicos.'),
        (N'medical.records.create', N'Abrir expedientes médicos.'),
        (N'medical.records.update', N'Actualizar estado o metadatos del expediente médico.'),
        (N'medical.notes.read', N'Ver notas clínicas.'),
        (N'medical.notes.create', N'Crear notas clínicas.'),
        (N'medical.conditions.manage', N'Gestionar condiciones médicas del paciente.'),
        (N'medical.medications.manage', N'Gestionar medicamentos del paciente.'),
        (N'medical.allergies.manage', N'Gestionar alergias del paciente.'),
        (N'medical.vital_signs.read', N'Ver signos vitales.'),
        (N'medical.vital_signs.create', N'Registrar signos vitales.'),
        (N'medical.attachments.read', N'Ver o descargar adjuntos clínicos.'),
        (N'medical.attachments.create', N'Cargar adjuntos clínicos.'),
        (N'medical.reports.read', N'Consultar reportes médicos.'),
        (N'medical.access_audit.read', N'Consultar auditoría de acceso a expedientes.'),

        -- Service events
        (N'service.events.read', N'Consultar agenda, citas y visitas.'),
        (N'service.events.create', N'Crear citas o visitas.'),
        (N'service.events.update', N'Actualizar citas o visitas.'),
        (N'service.events.cancel', N'Cancelar citas o visitas.'),
        (N'service.events.complete', N'Completar citas o visitas.'),
        (N'service.reports.read', N'Consultar reportes de citas y visitas.'),

        -- Inventory
        (N'inventory.items.read', N'Consultar inventario.'),
        (N'inventory.items.create', N'Crear insumos o recursos.'),
        (N'inventory.items.update', N'Actualizar insumos o recursos.'),
        (N'inventory.items.delete', N'Eliminar lógicamente insumos o recursos.'),
        (N'inventory.movements.create', N'Registrar movimientos de inventario.'),
        (N'inventory.reports.read', N'Consultar reportes de inventario.'),

        -- Finance
        (N'financial.transactions.read', N'Consultar movimientos financieros.'),
        (N'financial.transactions.create', N'Crear movimientos financieros.'),
        (N'financial.invoices.create', N'Crear facturas.'),
        (N'financial.invoices.update', N'Actualizar facturas.'),
        (N'financial.receipts.create', N'Crear recibos.'),
        (N'financial.donors.manage', N'Gestionar donantes.'),
        (N'financial.reports.read', N'Consultar reportes financieros.'),

        -- Configuration
        (N'config.catalogs.manage', N'Gestionar catálogos.'),
        (N'config.settings.manage', N'Gestionar configuración general.'),
        (N'config.document_types.manage', N'Gestionar tipos de documento.'),
        (N'notifications.read', N'Consultar notificaciones.'),
        (N'system.errors.read', N'Consultar errores del sistema.');

    INSERT INTO access_tbl_permissions
        (name, description, is_active, deleted, created_at)
    SELECT
        p.name,
        p.description,
        1,
        0,
        SYSDATETIME()
    FROM @permissions p
    WHERE NOT EXISTS (
        SELECT 1
        FROM access_tbl_permissions t
        WHERE t.name = p.name
    );

    -- El administrador arranca con todos los permisos.
    INSERT INTO access_tbl_role_permissions
        (role_id, permission_id, created_at)
    SELECT
        r.id,
        p.id,
        SYSDATETIME()
    FROM access_tbl_roles r
    CROSS JOIN access_tbl_permissions p
    WHERE r.name = N'Administrador'
      AND NOT EXISTS (
          SELECT 1
          FROM access_tbl_role_permissions rp
          WHERE rp.role_id = r.id
            AND rp.permission_id = p.id
      );

    -- Permisos base para los otros roles.
    DECLARE @role_permissions TABLE
    (
        role_name nvarchar(100) NOT NULL,
        permission_name nvarchar(150) NOT NULL
    );

    INSERT INTO @role_permissions (role_name, permission_name)
    VALUES
        -- Médico
        (N'Médico', N'patients.read'),
        (N'Médico', N'patients.update'),
        (N'Médico', N'medical.records.read'),
        (N'Médico', N'medical.records.create'),
        (N'Médico', N'medical.records.update'),
        (N'Médico', N'medical.notes.read'),
        (N'Médico', N'medical.notes.create'),
        (N'Médico', N'medical.conditions.manage'),
        (N'Médico', N'medical.medications.manage'),
        (N'Médico', N'medical.allergies.manage'),
        (N'Médico', N'medical.vital_signs.read'),
        (N'Médico', N'medical.vital_signs.create'),
        (N'Médico', N'medical.attachments.read'),
        (N'Médico', N'medical.attachments.create'),
        (N'Médico', N'medical.reports.read'),
        (N'Médico', N'service.events.read'),
        (N'Médico', N'service.events.complete'),

        -- Enfermería
        (N'Enfermería', N'patients.read'),
        (N'Enfermería', N'medical.records.read'),
        (N'Enfermería', N'medical.notes.read'),
        (N'Enfermería', N'medical.notes.create'),
        (N'Enfermería', N'medical.vital_signs.read'),
        (N'Enfermería', N'medical.vital_signs.create'),
        (N'Enfermería', N'medical.attachments.read'),
        (N'Enfermería', N'service.events.read'),
        (N'Enfermería', N'service.events.update'),
        (N'Enfermería', N'service.events.complete'),
        (N'Enfermería', N'inventory.items.read'),
        (N'Enfermería', N'inventory.movements.create'),

        -- Inventario
        (N'Inventario', N'inventory.items.read'),
        (N'Inventario', N'inventory.items.create'),
        (N'Inventario', N'inventory.items.update'),
        (N'Inventario', N'inventory.items.delete'),
        (N'Inventario', N'inventory.movements.create'),
        (N'Inventario', N'inventory.reports.read'),

        -- Finanzas
        (N'Finanzas', N'financial.transactions.read'),
        (N'Finanzas', N'financial.transactions.create'),
        (N'Finanzas', N'financial.invoices.create'),
        (N'Finanzas', N'financial.invoices.update'),
        (N'Finanzas', N'financial.receipts.create'),
        (N'Finanzas', N'financial.donors.manage'),
        (N'Finanzas', N'financial.reports.read'),

        -- Administrativo
        (N'Administrativo', N'patients.read'),
        (N'Administrativo', N'patients.create'),
        (N'Administrativo', N'patients.update'),
        (N'Administrativo', N'patients.reports.read'),
        (N'Administrativo', N'staff.read'),
        (N'Administrativo', N'service.events.read'),
        (N'Administrativo', N'service.events.create'),
        (N'Administrativo', N'service.events.update'),
        (N'Administrativo', N'service.events.cancel'),
        (N'Administrativo', N'service.reports.read'),
        (N'Administrativo', N'notifications.read'),

        -- Voluntario
        (N'Voluntario', N'service.events.read');

    INSERT INTO access_tbl_role_permissions
        (role_id, permission_id, created_at)
    SELECT
        r.id,
        p.id,
        SYSDATETIME()
    FROM @role_permissions rp_src
    INNER JOIN access_tbl_roles r
        ON r.name = rp_src.role_name
    INNER JOIN access_tbl_permissions p
        ON p.name = rp_src.permission_name
    WHERE NOT EXISTS (
        SELECT 1
        FROM access_tbl_role_permissions rp
        WHERE rp.role_id = r.id
          AND rp.permission_id = p.id
    );

    ---------------------------------------------------------------------------
    -- Usuarios de prueba
    ---------------------------------------------------------------------------

    DECLARE @default_password nvarchar(500) = N'Kronos2026!';

    DECLARE @users TABLE
    (
        username nvarchar(100) NOT NULL,
        email nvarchar(256) NOT NULL,
        full_name nvarchar(200) NOT NULL,
        phone nvarchar(30) NULL,
        role_name nvarchar(100) NOT NULL
    );

    INSERT INTO @users (username, email, full_name, phone, role_name)
    VALUES
        (N'admin.kronos', N'admin@kronos.local', N'Administrador Kronos', N'8888-0001', N'Administrador'),
        (N'medico.demo', N'medico@kronos.local', N'Médico de Prueba', N'8888-0002', N'Médico'),
        (N'admin.operativo', N'operativo@kronos.local', N'Administrativo de Prueba', N'8888-0003', N'Administrativo');

    INSERT INTO access_tbl_users
        (username, email, password, full_name, phone, failed_login_attempts, lockout_until, last_login_at, is_active, deleted, created_at)
    SELECT
        u.username,
        u.email,
        @default_password,
        u.full_name,
        u.phone,
        0,
        NULL,
        NULL,
        1,
        0,
        SYSDATETIME()
    FROM @users u
    WHERE NOT EXISTS (
        SELECT 1
        FROM access_tbl_users t
        WHERE t.email = u.email
    );

    INSERT INTO access_tbl_user_roles
        (user_id, role_id, created_at)
    SELECT
        u.id,
        r.id,
        SYSDATETIME()
    FROM @users seed
    INNER JOIN access_tbl_users u
        ON u.email = seed.email
    INNER JOIN access_tbl_roles r
        ON r.name = seed.role_name
    WHERE NOT EXISTS (
        SELECT 1
        FROM access_tbl_user_roles ur
        WHERE ur.user_id = u.id
          AND ur.role_id = r.id
    );

    ---------------------------------------------------------------------------
    -- Roles y especialidades del personal
    ---------------------------------------------------------------------------

    DECLARE @staff_roles TABLE
    (
        name nvarchar(100) NOT NULL,
        description nvarchar(500) NULL
    );

    INSERT INTO @staff_roles (name, description)
    VALUES
        (N'Médico', N'Profesional médico responsable de atención clínica.'),
        (N'Enfermería', N'Personal de enfermería para atención y seguimiento.'),
        (N'Psicología', N'Profesional de apoyo psicológico.'),
        (N'Trabajo social', N'Profesional de apoyo social y familiar.'),
        (N'Administrativo', N'Personal administrativo.'),
        (N'Inventario', N'Personal responsable de inventario.'),
        (N'Finanzas', N'Personal responsable de finanzas.'),
        (N'Voluntario', N'Persona voluntaria de apoyo operativo.');

    INSERT INTO staff_tbl_roles
        (name, description, is_active, deleted, created_at)
    SELECT
        r.name,
        r.description,
        1,
        0,
        SYSDATETIME()
    FROM @staff_roles r
    WHERE NOT EXISTS (
        SELECT 1
        FROM staff_tbl_roles t
        WHERE t.name = r.name
    );

    DECLARE @staff_specialties TABLE
    (
        name nvarchar(150) NOT NULL,
        description nvarchar(500) NULL
    );

    INSERT INTO @staff_specialties (name, description)
    VALUES
        (N'Cuidados paliativos', N'Atención integral para pacientes con enfermedad avanzada o terminal.'),
        (N'Medicina general', N'Atención médica general.'),
        (N'Enfermería paliativa', N'Cuidado de enfermería enfocado en control de síntomas y confort.'),
        (N'Psicología clínica', N'Acompañamiento emocional y psicológico.'),
        (N'Trabajo social', N'Acompañamiento social, familiar e institucional.'),
        (N'Nutrición', N'Apoyo nutricional.'),
        (N'Terapia física', N'Apoyo físico y funcional.'),
        (N'Administración', N'Gestión administrativa.'),
        (N'Gestión de inventario', N'Control de insumos, medicamentos y recursos.'),
        (N'Finanzas', N'Gestión financiera y contable básica.');

    INSERT INTO staff_tbl_specialties
        (name, description, is_active, deleted, created_at)
    SELECT
        s.name,
        s.description,
        1,
        0,
        SYSDATETIME()
    FROM @staff_specialties s
    WHERE NOT EXISTS (
        SELECT 1
        FROM staff_tbl_specialties t
        WHERE t.name = s.name
    );

    ---------------------------------------------------------------------------
    -- Base de inventario
    ---------------------------------------------------------------------------

    DECLARE @inventory_categories TABLE
    (
        name nvarchar(150) NOT NULL,
        description nvarchar(500) NULL
    );

    INSERT INTO @inventory_categories (name, description)
    VALUES
        (N'Medicamentos', N'Medicamentos de uso clínico o paliativo.'),
        (N'Insumos médicos', N'Insumos consumibles para atención médica o de enfermería.'),
        (N'Material de curación', N'Gasas, apósitos, vendas y material similar.'),
        (N'Equipo médico', N'Equipos disponibles para uso, préstamo o alquiler.'),
        (N'Higiene y cuidado personal', N'Productos de higiene, confort y cuidado del paciente.'),
        (N'Oficina y administración', N'Insumos administrativos.'),
        (N'Alimentos y suplementos', N'Alimentos, fórmulas o suplementos nutricionales.'),
        (N'Otros', N'Otros recursos no clasificados.');

    INSERT INTO inventory_tbl_categories
        (name, description, is_active, deleted, created_at)
    SELECT
        c.name,
        c.description,
        1,
        0,
        SYSDATETIME()
    FROM @inventory_categories c
    WHERE NOT EXISTS (
        SELECT 1
        FROM inventory_tbl_categories t
        WHERE t.name = c.name
    );

    DECLARE @inventory_units TABLE
    (
        name nvarchar(100) NOT NULL,
        abbreviation nvarchar(20) NULL
    );

    INSERT INTO @inventory_units (name, abbreviation)
    VALUES
        (N'Unidad', N'unid'),
        (N'Caja', N'caja'),
        (N'Paquete', N'paq'),
        (N'Frasco', N'frasco'),
        (N'Botella', N'bot'),
        (N'Bolsa', N'bolsa'),
        (N'Par', N'par'),
        (N'Rollo', N'rollo'),
        (N'Mililitro', N'ml'),
        (N'Litro', N'l'),
        (N'Miligramo', N'mg'),
        (N'Gramo', N'g'),
        (N'Kilogramo', N'kg');

    INSERT INTO inventory_tbl_units
        (name, abbreviation, is_active, deleted, created_at)
    SELECT
        u.name,
        u.abbreviation,
        1,
        0,
        SYSDATETIME()
    FROM @inventory_units u
    WHERE NOT EXISTS (
        SELECT 1
        FROM inventory_tbl_units t
        WHERE t.name = u.name
    );

    ---------------------------------------------------------------------------
    -- Base financiera
    ---------------------------------------------------------------------------

    DECLARE @financial_categories TABLE
    (
        name nvarchar(150) NOT NULL,
        transaction_type nvarchar(20) NOT NULL,
        description nvarchar(500) NULL
    );

    INSERT INTO @financial_categories (name, transaction_type, description)
    VALUES
        (N'Donación monetaria', N'income', N'Aportes económicos recibidos.'),
        (N'Pago de factura', N'income', N'Ingresos por facturas emitidas.'),
        (N'Actividad de recaudación', N'income', N'Ingresos por actividades institucionales.'),
        (N'Alquiler de equipo', N'income', N'Ingresos por alquiler de equipo.'),
        (N'Compra de medicamentos', N'expense', N'Egresos por compra de medicamentos.'),
        (N'Compra de insumos', N'expense', N'Egresos por compra de insumos médicos.'),
        (N'Gasto operativo', N'expense', N'Gastos generales de operación.'),
        (N'Gasto administrativo', N'expense', N'Gastos administrativos.'),
        (N'Transporte', N'expense', N'Gastos de transporte para visitas o gestiones.'),
        (N'Ajuste financiero', N'adjustment', N'Ajustes o correcciones financieras.');

    INSERT INTO financial_tbl_categories
        (name, transaction_type, description, is_active, deleted, created_at)
    SELECT
        c.name,
        c.transaction_type,
        c.description,
        1,
        0,
        SYSDATETIME()
    FROM @financial_categories c
    WHERE NOT EXISTS (
        SELECT 1
        FROM financial_tbl_categories t
        WHERE t.name = c.name
    );

    DECLARE @payment_methods TABLE
    (
        name nvarchar(100) NOT NULL,
        description nvarchar(500) NULL
    );

    INSERT INTO @payment_methods (name, description)
    VALUES
        (N'Efectivo', N'Pago o movimiento en efectivo.'),
        (N'Transferencia bancaria', N'Transferencia bancaria o SINPE.'),
        (N'Tarjeta', N'Pago con tarjeta.'),
        (N'Cheque', N'Pago con cheque.'),
        (N'Depósito bancario', N'Depósito bancario.'),
        (N'Otro', N'Otro método de pago.');

    INSERT INTO financial_tbl_payment_methods
        (name, description, is_active, deleted, created_at)
    SELECT
        p.name,
        p.description,
        1,
        0,
        SYSDATETIME()
    FROM @payment_methods p
    WHERE NOT EXISTS (
        SELECT 1
        FROM financial_tbl_payment_methods t
        WHERE t.name = p.name
    );

    ---------------------------------------------------------------------------
    -- Base médica
    ---------------------------------------------------------------------------

    DECLARE @medical_conditions TABLE
    (
        name nvarchar(150) NOT NULL,
        description nvarchar(500) NULL
    );

    INSERT INTO @medical_conditions (name, description)
    VALUES
        (N'Cáncer', N'Enfermedad oncológica.'),
        (N'Insuficiencia cardíaca', N'Condición cardíaca avanzada.'),
        (N'Enfermedad pulmonar obstructiva crónica', N'Condición respiratoria crónica.'),
        (N'Insuficiencia renal crónica', N'Condición renal crónica.'),
        (N'Demencia', N'Deterioro cognitivo progresivo.'),
        (N'Diabetes mellitus', N'Condición metabólica crónica.'),
        (N'Hipertensión arterial', N'Presión arterial elevada.'),
        (N'Dolor crónico', N'Dolor persistente que requiere seguimiento.'),
        (N'Otra', N'Condición no clasificada.');

    INSERT INTO medical_tbl_conditions
        (name, description, is_active, deleted, created_at)
    SELECT
        c.name,
        c.description,
        1,
        0,
        SYSDATETIME()
    FROM @medical_conditions c
    WHERE NOT EXISTS (
        SELECT 1
        FROM medical_tbl_conditions t
        WHERE t.name = c.name
    );

    DECLARE @medical_allergies TABLE
    (
        name nvarchar(150) NOT NULL,
        description nvarchar(500) NULL
    );

    INSERT INTO @medical_allergies (name, description)
    VALUES
        (N'Penicilina', N'Alergia a penicilina o derivados.'),
        (N'AINEs', N'Alergia o sensibilidad a antiinflamatorios no esteroideos.'),
        (N'Opioides', N'Alergia o reacción adversa a opioides.'),
        (N'Látex', N'Alergia al látex.'),
        (N'Alimentos', N'Alergias alimentarias.'),
        (N'Otra', N'Otra alergia no clasificada.'),
        (N'Desconocida', N'No se conoce alergia específica.');

    INSERT INTO medical_tbl_allergies
        (name, description, is_active, deleted, created_at)
    SELECT
        a.name,
        a.description,
        1,
        0,
        SYSDATETIME()
    FROM @medical_allergies a
    WHERE NOT EXISTS (
        SELECT 1
        FROM medical_tbl_allergies t
        WHERE t.name = a.name
    );

    DECLARE @medical_medications TABLE
    (
        name nvarchar(150) NOT NULL,
        description nvarchar(500) NULL
    );

    INSERT INTO @medical_medications (name, description)
    VALUES
        (N'Morfina', N'Analgésico opioide de uso paliativo.'),
        (N'Tramadol', N'Analgésico opioide.'),
        (N'Paracetamol', N'Analgésico y antipirético.'),
        (N'Ibuprofeno', N'Antiinflamatorio no esteroideo.'),
        (N'Metoclopramida', N'Antiemético/procinético.'),
        (N'Omeprazol', N'Protector gástrico.'),
        (N'Lactulosa', N'Laxante.'),
        (N'Haloperidol', N'Antipsicótico/antiemético en contexto paliativo.'),
        (N'Midazolam', N'Benzodiacepina.'),
        (N'Otro', N'Medicamento no clasificado.');

    INSERT INTO medical_tbl_medications
        (name, description, is_active, deleted, created_at)
    SELECT
        m.name,
        m.description,
        1,
        0,
        SYSDATETIME()
    FROM @medical_medications m
    WHERE NOT EXISTS (
        SELECT 1
        FROM medical_tbl_medications t
        WHERE t.name = m.name
    );

    ---------------------------------------------------------------------------
    -- Servicios
    ---------------------------------------------------------------------------

    DECLARE @services TABLE
    (
        name nvarchar(150) NOT NULL,
        description nvarchar(500) NULL,
        is_billable bit NOT NULL,
        default_price decimal(18,2) NULL
    );

    INSERT INTO @services (name, description, is_billable, default_price)
    VALUES
        (N'Consulta médica', N'Atención médica presencial o programada.', 0, NULL),
        (N'Visita domiciliar', N'Seguimiento en domicilio del paciente.', 0, NULL),
        (N'Control de signos vitales', N'Registro y revisión de signos vitales.', 0, NULL),
        (N'Curación', N'Atención de heridas o cambio de apósitos.', 0, NULL),
        (N'Entrega de medicamentos', N'Entrega controlada de medicamentos al paciente.', 0, NULL),
        (N'Apoyo psicológico', N'Acompañamiento psicológico.', 0, NULL),
        (N'Apoyo social', N'Gestión social o familiar.', 0, NULL),
        (N'Alquiler de equipo médico', N'Alquiler de equipo disponible.', 1, 0),
        (N'Préstamo de equipo médico', N'Préstamo sin cobro de equipo disponible.', 0, NULL),
        (N'Otro servicio', N'Servicio no clasificado.', 0, NULL);

    INSERT INTO service_tbl_services
        (name, description, is_billable, default_price, is_active, deleted, created_at)
    SELECT
        s.name,
        s.description,
        s.is_billable,
        s.default_price,
        1,
        0,
        SYSDATETIME()
    FROM @services s
    WHERE NOT EXISTS (
        SELECT 1
        FROM service_tbl_services t
        WHERE t.name = s.name
    );

    ---------------------------------------------------------------------------
    -- Tipos de documento
    ---------------------------------------------------------------------------

    DECLARE @document_types TABLE
    (
        name nvarchar(150) NOT NULL,
        description nvarchar(500) NULL
    );

    INSERT INTO @document_types (name, description)
    VALUES
        (N'Identificación', N'Cédula, documento de identidad o pasaporte.'),
        (N'Receta médica', N'Receta o indicación farmacológica.'),
        (N'Resultado de laboratorio', N'Resultados de laboratorio clínico.'),
        (N'Epicrisis', N'Resumen clínico o documento de egreso.'),
        (N'Consentimiento informado', N'Documento de autorización o consentimiento.'),
        (N'Nota clínica externa', N'Documento clínico emitido fuera de la institución.'),
        (N'Comprobante financiero', N'Respaldo de pago, ingreso o egreso.'),
        (N'Factura o recibo', N'Documento tributario o comprobante.'),
        (N'Imagen médica', N'Imagen, fotografía clínica o estudio visual.'),
        (N'Otro', N'Documento no clasificado.');

    INSERT INTO config_tbl_document_types
        (name, description, is_active, deleted, created_at)
    SELECT
        d.name,
        d.description,
        1,
        0,
        SYSDATETIME()
    FROM @document_types d
    WHERE NOT EXISTS (
        SELECT 1
        FROM config_tbl_document_types t
        WHERE t.name = d.name
    );

    ---------------------------------------------------------------------------
    -- Ubicaciones: base mínima para Costa Rica y sedes iniciales
    ---------------------------------------------------------------------------

    DECLARE @provinces TABLE (name nvarchar(100) NOT NULL);

    INSERT INTO @provinces (name)
    VALUES
        (N'San José'),
        (N'Alajuela'),
        (N'Cartago'),
        (N'Heredia'),
        (N'Guanacaste'),
        (N'Puntarenas'),
        (N'Limón');

    INSERT INTO location_tbl_provinces (name)
    SELECT p.name
    FROM @provinces p
    WHERE NOT EXISTS (
        SELECT 1
        FROM location_tbl_provinces t
        WHERE t.name = p.name
    );

    -- Geografía mínima para que los formularios puedan probarse.
    -- La carga completa de cantones y distritos conviene hacerla luego
    -- con una fuente oficial.
    DECLARE @san_jose_province_id int;
    SELECT @san_jose_province_id = id
    FROM location_tbl_provinces
    WHERE name = N'San José';

    IF @san_jose_province_id IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM location_tbl_cantons
           WHERE location_province_id = @san_jose_province_id
             AND name = N'San José'
       )
    BEGIN
        INSERT INTO location_tbl_cantons (location_province_id, name)
        VALUES (@san_jose_province_id, N'San José');
    END;

    DECLARE @san_jose_canton_id int;
    SELECT @san_jose_canton_id = id
    FROM location_tbl_cantons
    WHERE location_province_id = @san_jose_province_id
      AND name = N'San José';

    IF @san_jose_canton_id IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM location_tbl_districts
           WHERE location_canton_id = @san_jose_canton_id
             AND name = N'Carmen'
       )
    BEGIN
        INSERT INTO location_tbl_districts (location_canton_id, name)
        VALUES
            (@san_jose_canton_id, N'Carmen'),
            (@san_jose_canton_id, N'Merced'),
            (@san_jose_canton_id, N'Hospital'),
            (@san_jose_canton_id, N'Catedral'),
            (@san_jose_canton_id, N'Zapote'),
            (@san_jose_canton_id, N'San Francisco de Dos Ríos'),
            (@san_jose_canton_id, N'Uruca'),
            (@san_jose_canton_id, N'Mata Redonda'),
            (@san_jose_canton_id, N'Pavas'),
            (@san_jose_canton_id, N'Hatillo'),
            (@san_jose_canton_id, N'San Sebastián');
    END;

    DECLARE @default_district_id int;
    SELECT TOP (1) @default_district_id = id
    FROM location_tbl_districts
    WHERE name = N'Carmen'
    ORDER BY id;

    IF @default_district_id IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM location_tbl_addresses
           WHERE address_line = N'Dirección institucional pendiente de configurar'
       )
    BEGIN
        INSERT INTO location_tbl_addresses
            (location_district_id, address_line, reference, is_active, deleted, created_at)
        VALUES
            (@default_district_id, N'Dirección institucional pendiente de configurar', N'Dato inicial para configuración de sede.', 1, 0, SYSDATETIME());
    END;

    DECLARE @default_address_id int;
    SELECT TOP (1) @default_address_id = id
    FROM location_tbl_addresses
    WHERE address_line = N'Dirección institucional pendiente de configurar'
    ORDER BY id;

    IF @default_address_id IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM location_tbl_locations
           WHERE name = N'Sede principal'
       )
    BEGIN
        INSERT INTO location_tbl_locations
            (name, description, address_id, is_active, deleted, created_at)
        VALUES
            (N'Sede principal', N'Ubicación principal de la organización.', @default_address_id, 1, 0, SYSDATETIME()),
            (N'Bodega principal', N'Almacenamiento principal de inventario.', @default_address_id, 1, 0, SYSDATETIME()),
            (N'Consultorio', N'Espacio para atención presencial.', @default_address_id, 1, 0, SYSDATETIME());
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;

SET NOCOUNT OFF;
