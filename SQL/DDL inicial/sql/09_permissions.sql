/*
    Kronos - 09_permissions.sql

    Permisos del usuario que usa el API.
    Se le permite ejecutar SPs, pero no se le da acceso directo a tablas.
*/

SET NOCOUNT ON;
USE Kronos;

GRANT EXECUTE TO KronosReader;

DENY ALTER TO KronosReader;
DENY CONTROL TO KronosReader;

SET NOCOUNT OFF;
