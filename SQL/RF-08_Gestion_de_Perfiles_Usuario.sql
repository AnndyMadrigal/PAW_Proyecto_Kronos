

/* RF-08. Ejecutar una vez en la base de datos Kronos. */
SET NOCOUNT ON;
GO

/* Perfiles solicitados. No modifica perfiles existentes. */
IF NOT EXISTS (SELECT 1 FROM dbo.access_tbl_roles WHERE name = N'Colaborador')
    INSERT INTO dbo.access_tbl_roles (name, description, is_active, deleted, created_at)
    VALUES (N'Colaborador', N'Perfil operativo para colaboradores.', 1, 0, SYSDATETIME());
GO


IF NOT EXISTS (SELECT 1 FROM dbo.access_tbl_roles WHERE name = N'Paciente')
    INSERT INTO dbo.access_tbl_roles (name, description, is_active, deleted, created_at)
    VALUES (N'Paciente', N'Perfil de acceso para pacientes.', 1, 0, SYSDATETIME());
GO



CREATE OR ALTER PROCEDURE dbo.access_sp_auth_session_create
    @user_id int, @token_id nvarchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.access_tbl_user_sessions (user_id, login_at, token_id, is_revoked, is_active, deleted, created_at)
    VALUES (@user_id, SYSDATETIME(), @token_id, 0, 1, 0, SYSDATETIME());
END;
GO

CREATE OR ALTER PROCEDURE dbo.access_sp_users_create_by_admin
    @administrator_user_id int,
    @username nvarchar(100),
    @email nvarchar(256),
    @password nvarchar(500),
    @full_name nvarchar(200),
    @phone nvarchar(30) = NULL,
    @role_id int
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @new_user_id int
    DECLARE @role_name nvarchar(100)

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.access_tbl_users au
        INNER JOIN dbo.access_tbl_user_roles aur ON aur.user_id = au.id
        INNER JOIN dbo.access_tbl_roles ar ON ar.id = aur.role_id
        WHERE au.id = @administrator_user_id AND au.is_active = 1 AND au.deleted = 0
          AND ar.name = N'Administrador' AND ar.is_active = 1 AND ar.deleted = 0
    )
    BEGIN
        SELECT CAST(0 AS bit) AS success, N'La operacion requiere un administrador activo.' AS message
        RETURN
    END

    SELECT @role_name = name
    FROM dbo.access_tbl_roles
    WHERE id = @role_id AND name IN (N'Administrador', N'Colaborador', N'Paciente')
      AND is_active = 1 AND deleted = 0

    IF @role_name IS NULL
    BEGIN
        SELECT CAST(0 AS bit) AS success, N'El perfil seleccionado no esta disponible.' AS message
        RETURN
    END

    IF EXISTS (SELECT 1 FROM dbo.access_tbl_users WHERE email = @email OR username = @username)
    BEGIN
        SELECT CAST(0 AS bit) AS success, N'El correo o nombre de usuario ya esta registrado.' AS message
        RETURN
    END

    BEGIN TRANSACTION
        INSERT INTO dbo.access_tbl_users
            (username, email, password, full_name, phone, failed_login_attempts,
             lockout_until, last_login_at, is_active, deleted, created_at, updated_at)
        VALUES
            (@username, @email, @password, @full_name, @phone, 0,
             NULL, NULL, 1, 0, SYSDATETIME(), NULL)

        SET @new_user_id = SCOPE_IDENTITY()

        INSERT INTO dbo.access_tbl_user_roles (user_id, role_id, created_at)
        VALUES (@new_user_id, @role_id, SYSDATETIME())

        INSERT INTO dbo.access_tbl_audit_logs
            (user_id, action, entity_name, entity_id, new_value, created_at)
        VALUES
            (@administrator_user_id, N'create_user', N'access_tbl_users', @new_user_id,
             CONCAT(N'{"role":"', @role_name, N'"}'), SYSDATETIME())
    COMMIT TRANSACTION

    SELECT CAST(1 AS bit) AS success, N'Usuario creado correctamente.' AS message, @role_name AS role_name
END
GO



CREATE OR ALTER PROCEDURE dbo.access_sp_auth_validate_token
    @user_id int, @token_id nvarchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(CASE WHEN EXISTS (
        SELECT 1 FROM dbo.access_tbl_users u
        INNER JOIN dbo.access_tbl_user_sessions s ON s.user_id = u.id
        WHERE u.id = @user_id AND u.is_active = 1 AND u.deleted = 0
          AND s.token_id = @token_id AND s.is_active = 1 AND s.is_revoked = 0 AND s.deleted = 0
    ) THEN 1 ELSE 0 END AS bit) AS is_valid
END;
GO




CREATE OR ALTER PROCEDURE dbo.access_sp_roles_list
AS
BEGIN
    SET NOCOUNT ON;
    SELECT id, name FROM dbo.access_tbl_roles
    WHERE name IN (N'Administrador', N'Colaborador', N'Paciente') AND is_active = 1 AND deleted = 0
    ORDER BY CASE name WHEN N'Administrador' THEN 1 WHEN N'Colaborador' THEN 2 WHEN N'Paciente' THEN 3 END
END;
GO


CREATE OR ALTER PROCEDURE dbo.access_sp_users_search
    @search nvarchar(256) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @search = NULLIF(LTRIM(RTRIM(@search)), N'');
    SELECT u.id, u.username, u.email, u.full_name, u.phone, u.is_active, role_info.role_id, role_info.role_name
    FROM dbo.access_tbl_users u
    OUTER APPLY (SELECT TOP (1) ur.role_id, r.name AS role_name FROM dbo.access_tbl_user_roles ur INNER JOIN dbo.access_tbl_roles r ON r.id = ur.role_id WHERE ur.user_id = u.id ORDER BY ur.created_at DESC) role_info
    WHERE u.deleted = 0 AND (@search IS NULL OR u.email LIKE N'%' + @search + N'%' OR u.username LIKE N'%' + @search + N'%' OR u.full_name LIKE N'%' + @search + N'%')
    ORDER BY u.full_name, u.username;
END;
GO




CREATE OR ALTER PROCEDURE dbo.access_sp_users_get_by_id
    @user_id int
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.id, u.username, u.email, u.full_name, u.phone, u.is_active, role_info.role_id, role_info.role_name
    FROM dbo.access_tbl_users u
    OUTER APPLY (SELECT TOP (1) ur.role_id, r.name AS role_name FROM dbo.access_tbl_user_roles ur INNER JOIN dbo.access_tbl_roles r ON r.id = ur.role_id WHERE ur.user_id = u.id ORDER BY ur.created_at DESC) role_info
    WHERE u.id = @user_id AND u.deleted = 0;
END;
GO




CREATE OR ALTER PROCEDURE dbo.access_sp_users_manage_profile
    @administrator_user_id int,
    @user_id int,
    @role_id int,
    @is_active bit,
    @confirm_pending_appointments bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @current_role_id int, @current_role_name nvarchar(100), @new_role_name nvarchar(100), @pending_appointment_count int = 0;
    DECLARE @current_is_active bit, @email nvarchar(256), @full_name nvarchar(200), @role_changed bit = 0, @status_changed bit = 0;

    IF NOT EXISTS (SELECT 1 FROM dbo.access_tbl_users au INNER JOIN dbo.access_tbl_user_roles aur ON aur.user_id = au.id INNER JOIN dbo.access_tbl_roles ar ON ar.id = aur.role_id WHERE au.id = @administrator_user_id AND au.is_active = 1 AND au.deleted = 0 AND ar.name = N'Administrador' AND ar.is_active = 1 AND ar.deleted = 0)
    BEGIN
        SELECT CAST(0 AS bit) success, CAST(0 AS bit) requires_confirmation, N'La operacion requiere un administrador activo.' message, 0 pending_appointment_count, CAST(0 AS bit) role_changed, CAST(0 AS bit) status_changed;
        RETURN;
    END;

    SELECT @current_is_active = is_active, @email = email, @full_name = full_name FROM dbo.access_tbl_users WHERE id = @user_id AND deleted = 0;
    IF @email IS NULL
    BEGIN
        SELECT CAST(0 AS bit) success, CAST(0 AS bit) requires_confirmation, N'El usuario indicado no existe.' message, 0 pending_appointment_count, CAST(0 AS bit) role_changed, CAST(0 AS bit) status_changed;
        RETURN;
    END;

    SELECT TOP (1) @current_role_id = ur.role_id, @current_role_name = r.name FROM dbo.access_tbl_user_roles ur INNER JOIN dbo.access_tbl_roles r ON r.id = ur.role_id WHERE ur.user_id = @user_id ORDER BY ur.created_at DESC;
    SELECT @new_role_name = name FROM dbo.access_tbl_roles WHERE id = @role_id AND name IN (N'Administrador', N'Colaborador', N'Paciente') AND is_active = 1 AND deleted = 0;
    IF @new_role_name IS NULL
    BEGIN
        SELECT CAST(0 AS bit) success, CAST(0 AS bit) requires_confirmation, N'El perfil seleccionado no esta disponible.' message, 0 pending_appointment_count, CAST(0 AS bit) role_changed, CAST(0 AS bit) status_changed;
        RETURN;
    END;

    IF @current_role_name = N'Administrador' AND (@is_active = 0 OR @new_role_name <> N'Administrador') AND 1 = (SELECT COUNT(DISTINCT ur.user_id) FROM dbo.access_tbl_user_roles ur INNER JOIN dbo.access_tbl_roles r ON r.id = ur.role_id INNER JOIN dbo.access_tbl_users u ON u.id = ur.user_id WHERE r.name = N'Administrador' AND r.is_active = 1 AND r.deleted = 0 AND u.is_active = 1 AND u.deleted = 0)
    BEGIN
        SELECT CAST(0 AS bit) success, CAST(0 AS bit) requires_confirmation, N'No se puede desactivar ni cambiar el perfil de la unica cuenta de Administrador activa.' message, 0 pending_appointment_count, CAST(0 AS bit) role_changed, CAST(0 AS bit) status_changed;
        RETURN;
    END;

    IF @is_active = 0
    BEGIN
        SELECT @pending_appointment_count = COUNT(DISTINCT e.id)
        FROM dbo.service_tbl_events e
        INNER JOIN dbo.staff_tbl_members sm ON sm.id = e.main_staff_member_id
        INNER JOIN dbo.config_tbl_catalog_items status_item ON status_item.id = e.status_id
        WHERE sm.user_id = @user_id AND e.deleted = 0 AND e.is_active = 1 AND status_item.value NOT IN (N'cancelled', N'completed');
        IF @pending_appointment_count > 0 AND @confirm_pending_appointments = 0
        BEGIN
            SELECT CAST(0 AS bit) success, CAST(1 AS bit) requires_confirmation, N'El usuario tiene citas pendientes. Confirma la desactivacion para continuar.' message, @pending_appointment_count pending_appointment_count, CAST(0 AS bit) role_changed, CAST(0 AS bit) status_changed;
            RETURN;
        END;
    END;

    SET @role_changed = CASE WHEN ISNULL(@current_role_id, 0) <> @role_id THEN 1 ELSE 0 END
    SET @status_changed = CASE WHEN @current_is_active <> @is_active THEN 1 ELSE 0 END
    IF @role_changed = 1 OR @status_changed = 1
    BEGIN
        BEGIN TRANSACTION;
            DELETE FROM dbo.access_tbl_user_roles WHERE user_id = @user_id;
            INSERT INTO dbo.access_tbl_user_roles (user_id, role_id, created_at) VALUES (@user_id, @role_id, SYSDATETIME());
            UPDATE dbo.access_tbl_users SET is_active = @is_active, updated_at = SYSDATETIME() WHERE id = @user_id;
            UPDATE dbo.access_tbl_user_sessions SET is_revoked = 1, is_active = 0, logout_at = SYSDATETIME() WHERE user_id = @user_id AND is_active = 1 AND is_revoked = 0 AND deleted = 0;
            INSERT INTO dbo.access_tbl_audit_logs (user_id, action, entity_name, entity_id, old_value, new_value, created_at)
            VALUES (@administrator_user_id, N'manage_profile', N'access_tbl_users', @user_id, CONCAT(N'{"role":"', ISNULL(@current_role_name, N''), N'","is_active":', @current_is_active, N'}'), CONCAT(N'{"role":"', @new_role_name, N'","is_active":', @is_active, N'}'), SYSDATETIME());
        COMMIT TRANSACTION;
    END
    SELECT CAST(1 AS bit) success, CAST(0 AS bit) requires_confirmation, N'Perfil actualizado correctamente.' message, @pending_appointment_count pending_appointment_count, @role_changed role_changed, @status_changed status_changed, @email email, @full_name full_name, @new_role_name role_name, @is_active is_active
END;
GO
