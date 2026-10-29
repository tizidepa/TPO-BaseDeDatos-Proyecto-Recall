-- 02_provincias_marcas_gestiones: Crear los catálogos iniciales.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE TABLE dbo.Provincia(
 ProvinciaId smallint NOT NULL CONSTRAINT PK_Provincia PRIMARY KEY,
 Nombre nvarchar(80) NOT NULL CONSTRAINT UQ_Provincia_Nombre UNIQUE);
CREATE TABLE dbo.Gestion(
 GestionId int IDENTITY CONSTRAINT PK_Gestion PRIMARY KEY,
 Nombre nvarchar(120) NOT NULL CONSTRAINT UQ_Gestion_Nombre UNIQUE,
 Activa bit NOT NULL CONSTRAINT DF_Gestion_Activa DEFAULT 1,
 FechaPausa datetime2(0) NULL,
 CONSTRAINT CK_Gestion_Pausa CHECK((Activa=1 AND FechaPausa IS NULL) OR (Activa=0 AND FechaPausa IS NOT NULL)));
CREATE TABLE dbo.Marca(
 MarcaId int IDENTITY CONSTRAINT PK_Marca PRIMARY KEY,
 Nombre nvarchar(80) NOT NULL CONSTRAINT UQ_Marca_Nombre UNIQUE,
 Activa bit NOT NULL CONSTRAINT DF_Marca_Activa DEFAULT 1, FechaPausa datetime2(0) NULL,
 CONSTRAINT CK_Marca_Pausa CHECK((Activa=1 AND FechaPausa IS NULL) OR (Activa=0 AND FechaPausa IS NOT NULL)));
CREATE TABLE dbo.GestionMarca(
 GestionId int NOT NULL REFERENCES dbo.Gestion(GestionId),
 MarcaId int NOT NULL REFERENCES dbo.Marca(MarcaId),
 CONSTRAINT PK_GestionMarca PRIMARY KEY(GestionId,MarcaId));
GO
