USE [Kronos];
GO

IF COL_LENGTH('access_tbl_users', 'profile_stamp_at') IS NULL
BEGIN
    ALTER TABLE access_tbl_users
    ADD profile_stamp_at datetime2(0) NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM access_tbl_roles WHERE name = N'Colaborador')
BEGIN
    INSERT INTO access_tbl_roles (name, description, is_active, deleted, created_at)
    VALUES (N'Colaborador', N'Perfil operativo para colaboradores de la ONG.', 1, 0, SYSDATETIME());
END
GO

IF NOT EXISTS (SELECT 1 FROM access_tbl_roles WHERE name = N'Paciente')
BEGIN
    INSERT INTO access_tbl_roles (name, description, is_active, deleted, created_at)
    VALUES (N'Paciente', N'Perfil para usuarios pacientes.', 1, 0, SYSDATETIME());
END
GO

CREATE OR ALTER PROCEDURE spUsersSearchManage
    @search_term nvarchar(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @term nvarchar(200) = LTRIM(RTRIM(ISNULL(@search_term, N'')));

    SELECT
        u.id,
        u.username,
        u.email,
        u.password,
        u.full_name,
        u.phone,
        u.is_active,
        u.deleted,
        u.profile_stamp_at,
        COALESCE(r.role_id, 0) AS role_id,
        COALESCE(r.role_name, N'Sin perfil') AS RoleName,
        COALESCE(r.role_name, N'Sin perfil') AS role_name,
        u.failed_login_attempts,
        u.lockout_until,
        u.last_login_at,
        u.created_at,
        u.updated_at
    FROM access_tbl_users u
    OUTER APPLY (
        SELECT TOP (1)
            rr.id AS role_id,
            rr.name AS role_name
        FROM access_tbl_user_roles ur
        INNER JOIN access_tbl_roles rr ON rr.id = ur.role_id
        WHERE ur.user_id = u.id
          AND rr.deleted = 0
        ORDER BY ur.created_at DESC, rr.id DESC
    ) r
    WHERE u.deleted = 0
      AND (
            @term = N''
            OR CAST(u.id AS nvarchar(20)) = @term
            OR u.email LIKE N'%' + @term + N'%'
            OR u.username LIKE N'%' + @term + N'%'
            OR u.full_name LIKE N'%' + @term + N'%'
          )
    ORDER BY u.full_name;
END
GO

CREATE OR ALTER PROCEDURE spUsersGetManageDetail
    @id int
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1)
        u.id,
        u.username,
        u.email,
        u.password,
        u.full_name,
        u.phone,
        u.is_active,
        u.deleted,
        u.profile_stamp_at,
        COALESCE(r.role_id, 0) AS role_id,
        COALESCE(r.role_name, N'Sin perfil') AS RoleName,
        COALESCE(r.role_name, N'Sin perfil') AS role_name,
        u.failed_login_attempts,
        u.lockout_until,
        u.last_login_at,
        u.created_at,
        u.updated_at,
        (
            SELECT COUNT(1)
            FROM service_tbl_events e
            INNER JOIN staff_tbl_members sm ON sm.id = e.main_staff_member_id
            INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
            INNER JOIN config_tbl_catalogs sc ON sc.id = st.catalog_id AND sc.name = N'service_event_status'
            WHERE sm.user_id = u.id
              AND e.deleted = 0
              AND e.is_active = 1
              AND st.value IN (N'scheduled', N'rescheduled', N'in_progress')
              AND e.scheduled_start_at >= SYSDATETIME()
        ) AS pending_appointments_count,
        CAST(CASE WHEN EXISTS (
            SELECT 1
            FROM service_tbl_events e
            INNER JOIN staff_tbl_members sm ON sm.id = e.main_staff_member_id
            INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
            INNER JOIN config_tbl_catalogs sc ON sc.id = st.catalog_id AND sc.name = N'service_event_status'
            WHERE sm.user_id = u.id
              AND e.deleted = 0
              AND e.is_active = 1
              AND st.value IN (N'scheduled', N'rescheduled', N'in_progress')
              AND e.scheduled_start_at >= SYSDATETIME()
        ) THEN 1 ELSE 0 END AS bit) AS has_pending_appointments,
        CAST(CASE WHEN EXISTS (
            SELECT 1
            FROM access_tbl_user_roles aur
            INNER JOIN access_tbl_roles ar ON ar.id = aur.role_id
            INNER JOIN access_tbl_users au ON au.id = aur.user_id
            WHERE ar.name = N'Administrador'
              AND au.is_active = 1
              AND au.deleted = 0
        ) AND COALESCE(r.role_name, N'') = N'Administrador' AND u.is_active = 1 THEN 1 ELSE 0 END AS bit) AS is_unique_admin,
        CAST(N'' AS nvarchar(500)) AS warning_message
    FROM access_tbl_users u
    OUTER APPLY (
        SELECT TOP (1)
            rr.id AS role_id,
            rr.name AS role_name
        FROM access_tbl_user_roles ur
        INNER JOIN access_tbl_roles rr ON rr.id = ur.role_id
        WHERE ur.user_id = u.id
          AND rr.deleted = 0
        ORDER BY ur.created_at DESC, rr.id DESC
    ) r
    WHERE u.id = @id;
END
GO

CREATE OR ALTER PROCEDURE spUsersPrecheckManage
    @id int,
    @role_name nvarchar(100),
    @is_active bit
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @pending_count int = 0;
    DECLARE @current_role_name nvarchar(100) = NULL;
    DECLARE @current_is_active bit = 0;
    DECLARE @current_stamp datetime2(0) = NULL;
    DECLARE @unique_admins int = 0;
    DECLARE @warning nvarchar(500) = N'';

    SELECT TOP (1)
        @current_role_name = COALESCE(r.role_name, N'Sin perfil'),
        @current_is_active = u.is_active,
        @current_stamp = u.profile_stamp_at
    FROM access_tbl_users u
    OUTER APPLY (
        SELECT TOP (1)
            rr.name AS role_name
        FROM access_tbl_user_roles ur
        INNER JOIN access_tbl_roles rr ON rr.id = ur.role_id
        WHERE ur.user_id = u.id
          AND rr.deleted = 0
        ORDER BY ur.created_at DESC, rr.id DESC
    ) r
    WHERE u.id = @id;

    IF @current_role_name IS NULL
    BEGIN
        RETURN;
    END

    SELECT @unique_admins = COUNT(1)
    FROM access_tbl_user_roles aur
    INNER JOIN access_tbl_roles ar ON ar.id = aur.role_id
    INNER JOIN access_tbl_users au ON au.id = aur.user_id
    WHERE ar.name = N'Administrador'
      AND au.is_active = 1
      AND au.deleted = 0;

    IF @current_role_name = N'Administrador' AND @unique_admins <= 1 AND (@is_active = 0 OR @role_name <> N'Administrador')
    BEGIN
        SET @warning = N'No se puede desactivar ni quitar el perfil de Administrador porque es la única cuenta activa con ese rol.';
    END

    SELECT
        u.id,
        u.username,
        u.email,
        u.password,
        u.full_name,
        u.phone,
        u.is_active,
        u.deleted,
        u.profile_stamp_at,
        COALESCE(r.role_id, 0) AS role_id,
        COALESCE(r.role_name, N'Sin perfil') AS RoleName,
        COALESCE(r.role_name, N'Sin perfil') AS role_name,
        u.failed_login_attempts,
        u.lockout_until,
        u.last_login_at,
        u.created_at,
        u.updated_at,
        (
            SELECT COUNT(1)
            FROM service_tbl_events e
            INNER JOIN staff_tbl_members sm ON sm.id = e.main_staff_member_id
            INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
            INNER JOIN config_tbl_catalogs sc ON sc.id = st.catalog_id AND sc.name = N'service_event_status'
            WHERE sm.user_id = u.id
              AND e.deleted = 0
              AND e.is_active = 1
              AND st.value IN (N'scheduled', N'rescheduled', N'in_progress')
              AND e.scheduled_start_at >= SYSDATETIME()
        ) AS pending_appointments_count,
        CAST(CASE WHEN EXISTS (
            SELECT 1
            FROM service_tbl_events e
            INNER JOIN staff_tbl_members sm ON sm.id = e.main_staff_member_id
            INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
            INNER JOIN config_tbl_catalogs sc ON sc.id = st.catalog_id AND sc.name = N'service_event_status'
            WHERE sm.user_id = u.id
              AND e.deleted = 0
              AND e.is_active = 1
              AND st.value IN (N'scheduled', N'rescheduled', N'in_progress')
              AND e.scheduled_start_at >= SYSDATETIME()
        ) THEN 1 ELSE 0 END AS bit) AS has_pending_appointments,
        CAST(CASE WHEN @warning <> N'' THEN 1 ELSE 0 END AS bit) AS is_unique_admin,
        @warning AS warning_message
    FROM access_tbl_users u
    OUTER APPLY (
        SELECT TOP (1)
            rr.id AS role_id,
            rr.name AS role_name
        FROM access_tbl_user_roles ur
        INNER JOIN access_tbl_roles rr ON rr.id = ur.role_id
        WHERE ur.user_id = u.id
          AND rr.deleted = 0
        ORDER BY ur.created_at DESC, rr.id DESC
    ) r
    WHERE u.id = @id;
END
GO

CREATE OR ALTER PROCEDURE spUsersUpdateProfileManage
    @id int,
    @role_name nvarchar(100),
    @is_active bit,
    @allow_pending_appointments bit = 0,
    @changed_by_user_id int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @current_role_name nvarchar(100) = NULL;
    DECLARE @current_role_id int = NULL;
    DECLARE @new_role_id int = NULL;
    DECLARE @current_is_active bit = 0;
    DECLARE @pending_count int = 0;
    DECLARE @unique_admins int = 0;
    DECLARE @old_value nvarchar(max) = NULL;
    DECLARE @new_value nvarchar(max) = NULL;

    SELECT TOP (1)
        @current_role_name = COALESCE(r.role_name, N'Sin perfil'),
        @current_role_id = COALESCE(r.role_id, 0),
        @current_is_active = u.is_active
    FROM access_tbl_users u
    OUTER APPLY (
        SELECT TOP (1)
            rr.id AS role_id,
            rr.name AS role_name
        FROM access_tbl_user_roles ur
        INNER JOIN access_tbl_roles rr ON rr.id = ur.role_id
        WHERE ur.user_id = u.id
          AND rr.deleted = 0
        ORDER BY ur.created_at DESC, rr.id DESC
    ) r
    WHERE u.id = @id;

    IF @current_role_name IS NULL
    BEGIN
        THROW 50003, 'No se encontró el usuario solicitado.', 1;
    END

    SELECT @new_role_id = id
    FROM access_tbl_roles
    WHERE name = @role_name
      AND is_active = 1
      AND deleted = 0;

    IF @new_role_id IS NULL
    BEGIN
        THROW 50003, 'El perfil seleccionado no es válido.', 1;
    END

    SELECT @unique_admins = COUNT(1)
    FROM access_tbl_user_roles aur
    INNER JOIN access_tbl_roles ar ON ar.id = aur.role_id
    INNER JOIN access_tbl_users au ON au.id = aur.user_id
    WHERE ar.name = N'Administrador'
      AND au.is_active = 1
      AND au.deleted = 0;

    IF @current_role_name = N'Administrador' AND @unique_admins <= 1 AND (@is_active = 0 OR @role_name <> N'Administrador')
    BEGIN
        THROW 50001, 'No se puede desactivar ni quitar el perfil de Administrador porque es la única cuenta activa con ese rol.', 1;
    END

    SELECT @pending_count = COUNT(1)
    FROM service_tbl_events e
    INNER JOIN staff_tbl_members sm ON sm.id = e.main_staff_member_id
    INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
    INNER JOIN config_tbl_catalogs sc ON sc.id = st.catalog_id AND sc.name = N'service_event_status'
    WHERE sm.user_id = @id
      AND e.deleted = 0
      AND e.is_active = 1
      AND st.value IN (N'scheduled', N'rescheduled', N'in_progress')
      AND e.scheduled_start_at >= SYSDATETIME();

    IF @is_active = 0 AND @pending_count > 0 AND @allow_pending_appointments = 0
    BEGIN
        THROW 50002, 'El usuario tiene citas pendientes. Confirma la acción para continuar.', 1;
    END

    BEGIN TRANSACTION;

    SET @old_value = (
        SELECT
            u.id,
            u.username,
            u.email,
            u.full_name,
            u.phone,
            u.is_active,
            @current_role_name AS role_name
        FROM access_tbl_users u
        WHERE u.id = @id
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );

    UPDATE access_tbl_users
    SET is_active = @is_active,
        updated_at = SYSDATETIME(),
        profile_stamp_at = CASE WHEN @is_active <> @current_is_active OR @role_name <> @current_role_name THEN SYSDATETIME() ELSE profile_stamp_at END
    WHERE id = @id;

    IF @role_name <> @current_role_name
    BEGIN
        DELETE FROM access_tbl_user_roles
        WHERE user_id = @id;

        INSERT INTO access_tbl_user_roles (user_id, role_id, created_at)
        VALUES (@id, @new_role_id, SYSDATETIME());
    END

    SET @new_value = (
        SELECT
            u.id,
            u.username,
            u.email,
            u.full_name,
            u.phone,
            @is_active AS is_active,
            @role_name AS role_name
        FROM access_tbl_users u
        WHERE u.id = @id
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );

    INSERT INTO access_tbl_audit_logs
        (user_id, action, entity_name, entity_id, old_value, new_value, created_at)
    VALUES
        (@changed_by_user_id, N'USER_PROFILE_UPDATE', N'access_tbl_users', @id, @old_value, @new_value, SYSDATETIME());

    COMMIT TRANSACTION;
END
GO
