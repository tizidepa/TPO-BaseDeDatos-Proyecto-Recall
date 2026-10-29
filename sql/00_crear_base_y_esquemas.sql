-- 00_crear_base_y_esquemas: Crear la base y los esquemas.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
/* TPO UADE — Gestión de recalls. SQL Server 2019+.
   Ejecutar en MODO SQLCMD de SSMS, o con sqlcmd -E -S servidor -b -i archivo.
   Crea una base NUEVA. Nunca elimina ni reemplaza una base existente.
   Fechas de negocio: Argentina (UTC-3); auditoría: UTC.
   Las operaciones autorizadas se exponen por procedimientos, no por DML directo.
*/
USE master;
GO
IF DB_ID(N'RecallsUADE') IS NOT NULL
    THROW 51000, 'RecallsUADE ya existe. No se modificó. Use otra instancia/base de pruebas.', 1;
GO
CREATE DATABASE RecallsUADE;
GO
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE SCHEMA seguridad AUTHORIZATION dbo;
GO
CREATE SCHEMA api AUTHORIZATION dbo;
GO
CREATE SCHEMA reporte AUTHORIZATION dbo;
GO
CREATE SCHEMA carga AUTHORIZATION dbo;
GO
