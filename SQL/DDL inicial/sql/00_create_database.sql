/*
    Kronos - 00_create_database.sql

    Primero se corre este archivo desde DBeaver.
    Solo crea la base de datos si todavía no existe.
*/

SET NOCOUNT ON;

IF DB_ID(N'Kronos') IS NULL
BEGIN
    CREATE DATABASE Kronos;
END;

SET NOCOUNT OFF;
