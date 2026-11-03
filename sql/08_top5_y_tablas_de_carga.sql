-- 08_top5_y_tablas_de_carga: Crear TOP5, staging y errores.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE TABLE dbo.Top5(
 Dominio varchar(7) COLLATE Latin1_General_100_BIN2 NOT NULL REFERENCES dbo.Vehiculo(Dominio),
 Posicion tinyint NOT NULL CONSTRAINT CK_Top5_Posicion CHECK(Posicion BETWEEN 1 AND 5),
 SucursalId int NOT NULL REFERENCES dbo.Sucursal(SucursalId),
 CUITPrincipal varchar(11) NOT NULL REFERENCES dbo.Titular(CUIT),
 Km decimal(10,3) NOT NULL CONSTRAINT CK_Top5_Km CHECK(Km>=0),
 FechaCalculo datetime2(0) NOT NULL CONSTRAINT DF_Top5_Fecha DEFAULT SYSUTCDATETIME(),
 CONSTRAINT PK_Top5 PRIMARY KEY(Dominio,Posicion),
 CONSTRAINT UQ_Top5_Sucursal UNIQUE(Dominio,SucursalId));
CREATE TABLE carga.ErrorProceso(
 ErrorId bigint IDENTITY CONSTRAINT PK_ErrorProceso PRIMARY KEY,
 Lote uniqueidentifier NOT NULL, Proceso varchar(40) NOT NULL,
 Referencia nvarchar(100) NULL, Mensaje nvarchar(2048) NOT NULL,
 Fecha datetime2(0) NOT NULL CONSTRAINT DF_ErrorProceso_Fecha DEFAULT SYSUTCDATETIME());
CREATE TABLE carga.TelefonoStaging(
 FilaId bigint IDENTITY CONSTRAINT PK_TelefonoStaging PRIMARY KEY,
 Lote uniqueidentifier NOT NULL, CUIT varchar(20) NOT NULL,
 Telefono1 varchar(100) NULL, Telefono2 varchar(100) NULL, Telefono3 varchar(100) NULL,
 Telefono4 varchar(100) NULL, Telefono5 varchar(100) NULL,
 WhatsApp1 bit NULL, WhatsApp2 bit NULL, WhatsApp3 bit NULL, WhatsApp4 bit NULL, WhatsApp5 bit NULL,
 Procesado bit NOT NULL CONSTRAINT DF_Staging_Procesado DEFAULT 0);
CREATE INDEX IX_Staging_Lote ON carga.TelefonoStaging(Lote,Procesado);
GO
