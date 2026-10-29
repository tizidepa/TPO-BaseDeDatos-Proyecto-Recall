-- 04_vehiculos_titulares_telefonos: Crear vehículos, titulares y titularidades.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE TABLE dbo.Titular(
 CUIT varchar(11) NOT NULL CONSTRAINT PK_Titular PRIMARY KEY,
 NombreRazonSocial nvarchar(150) NOT NULL, Apellido nvarchar(100) NULL,
 Tipo AS CONVERT(char(1),CASE WHEN LEFT(CUIT,2) IN ('30','33','34') THEN 'E' ELSE 'P' END) PERSISTED,
 ProvinciaId smallint NOT NULL REFERENCES dbo.Provincia(ProvinciaId), Domicilio nvarchar(200) NOT NULL,
 Latitud decimal(9,6) NULL, Longitud decimal(9,6) NULL,
 Intentos bigint NOT NULL CONSTRAINT DF_Titular_Intentos DEFAULT 0 CONSTRAINT CK_Titular_Intentos CHECK(Intentos>=0),
 CONSTRAINT CK_Titular_CUIT CHECK(dbo.fn_CUITValido(CUIT)=1),
 CONSTRAINT CK_Titular_Coord CHECK((Latitud IS NULL AND Longitud IS NULL) OR
   (Latitud IS NOT NULL AND Longitud IS NOT NULL AND Latitud BETWEEN -90 AND 90 AND Longitud BETWEEN -180 AND 180)));
CREATE TABLE dbo.Vehiculo(
 Dominio varchar(7) COLLATE Latin1_General_100_BIN2 NOT NULL CONSTRAINT PK_Vehiculo PRIMARY KEY,
 VIN varchar(17) NULL, Modelo nvarchar(100) NOT NULL,
 GestionId int NOT NULL, MarcaId int NOT NULL,
 Estado varchar(20) NOT NULL CONSTRAINT DF_Vehiculo_Estado DEFAULT 'pendiente',
 CONSTRAINT FK_Vehiculo_GestionMarca FOREIGN KEY(GestionId,MarcaId) REFERENCES dbo.GestionMarca(GestionId,MarcaId),
 CONSTRAINT CK_Vehiculo_Dominio CHECK((LEN(Dominio)=6 AND Dominio LIKE '[A-Z][A-Z][A-Z][0-9][0-9][0-9]')
   OR (LEN(Dominio)=7 AND Dominio LIKE '[A-Z][A-Z][0-9][0-9][0-9][A-Z][A-Z]')),
 CONSTRAINT CK_Vehiculo_Estado CHECK(Estado IN ('pendiente','trabajando','turno','turno_realizado','descartado','pausado')));
CREATE INDEX IX_Vehiculo_GestionEstado ON dbo.Vehiculo(GestionId,Estado) INCLUDE(MarcaId);
CREATE TABLE dbo.CodigoRecall(
 Dominio varchar(7) COLLATE Latin1_General_100_BIN2 NOT NULL REFERENCES dbo.Vehiculo(Dominio),
 Codigo varchar(40) NOT NULL, CONSTRAINT PK_CodigoRecall PRIMARY KEY(Dominio,Codigo));
CREATE TABLE dbo.Titularidad(
 TitularidadId bigint IDENTITY CONSTRAINT PK_Titularidad PRIMARY KEY,
 Dominio varchar(7) COLLATE Latin1_General_100_BIN2 NOT NULL REFERENCES dbo.Vehiculo(Dominio),
 CUIT varchar(11) NOT NULL REFERENCES dbo.Titular(CUIT),
 Desde datetime2(0) NOT NULL, Hasta datetime2(0) NULL,
 EsPrincipal bit NOT NULL CONSTRAINT DF_Titularidad_Principal DEFAULT 0,
 CONSTRAINT UQ_Titularidad_Periodo UNIQUE(Dominio,CUIT,Desde),
 CONSTRAINT CK_Titularidad_Periodo CHECK(Hasta IS NULL OR Hasta>Desde));
CREATE UNIQUE INDEX UX_Titularidad_Vigente ON dbo.Titularidad(Dominio,CUIT) WHERE Hasta IS NULL;
CREATE UNIQUE INDEX UX_Titularidad_Principal ON dbo.Titularidad(Dominio) WHERE Hasta IS NULL AND EsPrincipal=1;
CREATE INDEX IX_Titularidad_CUIT ON dbo.Titularidad(CUIT,Hasta) INCLUDE(Dominio,EsPrincipal);
CREATE TABLE dbo.Telefono(
 CUIT varchar(11) NOT NULL REFERENCES dbo.Titular(CUIT), Numero varchar(10) NOT NULL,
 WhatsApp bit NULL, Activo bit NOT NULL CONSTRAINT DF_Telefono_Activo DEFAULT 1,
 CONSTRAINT PK_Telefono PRIMARY KEY(CUIT,Numero),
 CONSTRAINT CK_Telefono_Numero CHECK(LEN(Numero)=10 AND Numero COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^0-9]%'));
GO
