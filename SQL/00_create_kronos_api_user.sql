/*
    Ejecutar como administrador de SQL Server.
    Reemplaza CAMBIA_ESTA_CONTRASENA antes de ejecutar.
*/

USE [master]
GO

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'KronosApi')
BEGIN
    CREATE LOGIN [KronosApi]
    WITH PASSWORD = N'CAMBIA_ESTA_CONTRASENA',
         CHECK_POLICY = ON,
         CHECK_EXPIRATION = OFF
END
GO

USE [Kronos]
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'KronosApi')
BEGIN
    CREATE USER [KronosApi] FOR LOGIN [KronosApi]
END
GO

GRANT EXECUTE TO [KronosApi]
GO
