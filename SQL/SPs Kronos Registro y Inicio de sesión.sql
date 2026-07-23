--Insert del rol usuario
INSERT INTO access_tbl_roles (name, description, is_active, deleted, created_at, updated_at)
VALUES('Usuario', 'Rol de usuario básico', 1, 0, GETDATE(), NULL)
SELECT * FROM access_tbl_roles

---Insert del rol con el que se crea el usuario en la vista de registro de usuario.

GO
CREATE PROCEDURE spRegisterBasicUser
	@username nvarchar(100),
	@email nvarchar(256),
	@password nvarchar(500),
	@full_name nvarchar(200),
	@phone nvarchar(30) = NULL
AS
BEGIN
	DECLARE @failed_login_attempts int = 0
	DECLARE @lockout_until datetime = NULL
	DECLARE @last_login_at datetime = NULL
	DECLARE @is_active bit = 1
	DECLARE @deleted bit = 0
	DECLARE @created_at datetime = GETDATE()
	DECLARE @updated_at datetime = NULL

	SET NOCOUNT OFF;

	IF NOT EXISTS (SELECT 1 FROM access_tbl_users WHERE email = @email)
	BEGIN
	--se inserta primero en la tabla de usuarios
	INSERT INTO access_tbl_users (username, email, password, full_name, phone, failed_login_attempts, lockout_until, last_login_at, is_active, deleted, created_at,updated_at)
	VALUES(@username, @email, @password, @full_name, @phone, @failed_login_attempts, @lockout_until, @last_login_at, @is_active, @deleted, @created_at, @updated_at)

	--se inserta en la tabla de roles del usuario, el rol por default es 8 (Usuario)
	INSERT INTO access_tbl_user_roles (user_id, role_id, created_at)
	VALUES(SCOPE_IDENTITY(), 8, GETDATE())
	END

END
GO

select * from access_tbl_users
select * from access_tbl_user_roles
select * from access_tbl_roles

GO

--LOGEO DE USUARIO
CREATE PROCEDURE spLoginUser
	@email nvarchar(256),
	@password nvarchar(500)
AS
BEGIN
	SET NOCOUNT ON;

	--verificamos que las credenciales sean correctas y este activo
	IF EXISTS (SELECT 1 FROM access_tbl_users WHERE email = @email AND is_active = 1)
	BEGIN
		--si es correcto, actualizamos su último login
		UPDATE access_tbl_users 
		SET last_login_at = GETDATE()
		WHERE email = @email;

		--devolvemos los datos del usuario para la sesión
		SELECT 
		U.id, 
		U.username, 
		U.email,
		U.password,
		U.full_name, 
		U.phone, 
		U.is_active, 
		UR.role_id,
		R.name AS RoleName
		FROM access_tbl_users U
		inner JOIN access_tbl_user_roles UR ON U.id = UR.user_id
		inner JOIN access_tbl_roles R ON UR.role_id = R.id
		WHERE U.email = @email;
	END

END
GO
