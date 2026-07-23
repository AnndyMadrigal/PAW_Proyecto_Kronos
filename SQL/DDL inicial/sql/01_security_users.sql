/*
    Kronos - 01_security_users.sql

    Crea los usuarios de SQL Server que vamos a usar para Kronos.
    SysAdKronos queda como administrador de la base.
    KronosReader queda para el API; más adelante solo se le da permiso de ejecutar SPs.

    Contraseña temporal para ambos:
    Kronos2026!
*/

SET NOCOUNT ON;

USE master;

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'SysAdKronos')
BEGIN
    CREATE LOGIN SysAdKronos
    WITH PASSWORD = 'Kronos2026!',
         CHECK_POLICY = OFF,
         CHECK_EXPIRATION = OFF;
END;

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'KronosReader')
BEGIN
    CREATE LOGIN KronosReader
    WITH PASSWORD = 'Kronos2026!',
         CHECK_POLICY = OFF,
         CHECK_EXPIRATION = OFF;
END;

USE Kronos;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'SysAdKronos')
BEGIN
    CREATE USER SysAdKronos FOR LOGIN SysAdKronos;
END;

IF IS_ROLEMEMBER(N'db_owner', N'SysAdKronos') = 0
BEGIN
    ALTER ROLE db_owner ADD MEMBER SysAdKronos;
END;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'KronosReader')
BEGIN
    CREATE USER KronosReader FOR LOGIN KronosReader;
END;

SET NOCOUNT OFF;
