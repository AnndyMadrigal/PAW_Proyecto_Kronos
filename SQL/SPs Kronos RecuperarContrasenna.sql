--Validar que el correo si exista en la base de datos

USE Kronos
GO

CREATE PROCEDURE spValidateEmail 

	@email nvarchar(256)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT id, email, full_name from dbo.access_tbl_users
	where @email = email

END
GO

--Procedimiento almacenado para actualizar la contraseña del usuario

CREATE PROCEDURE spUpdatePassword 
	@id int,
	@password nvarchar(500)

AS
Begin

	UPDATE dbo.access_tbl_users
	SET password = @password
	WHERE id = @id

END	

select * from dbo.access_tbl_users