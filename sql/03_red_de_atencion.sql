-- 03_red_de_atencion: Crear concesionarias, sucursales, horarios y contactos.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE TABLE dbo.Concesionaria(
 ConcesionariaId int IDENTITY CONSTRAINT PK_Concesionaria PRIMARY KEY,
 Nombre nvarchar(120) NOT NULL CONSTRAINT UQ_Concesionaria_Nombre UNIQUE,
 Activa bit NOT NULL CONSTRAINT DF_Concesionaria_Activa DEFAULT 1, FechaPausa datetime2(0) NULL,
 CONSTRAINT CK_Concesionaria_Pausa CHECK((Activa=1 AND FechaPausa IS NULL) OR (Activa=0 AND FechaPausa IS NOT NULL)));
CREATE TABLE dbo.GestionConcesionaria(
 GestionId int NOT NULL REFERENCES dbo.Gestion(GestionId),
 ConcesionariaId int NOT NULL REFERENCES dbo.Concesionaria(ConcesionariaId),
 CONSTRAINT PK_GestionConcesionaria PRIMARY KEY(GestionId,ConcesionariaId));
CREATE TABLE dbo.Sucursal(
 SucursalId int IDENTITY CONSTRAINT PK_Sucursal PRIMARY KEY,
 ConcesionariaId int NOT NULL REFERENCES dbo.Concesionaria(ConcesionariaId),
 ProvinciaId smallint NOT NULL REFERENCES dbo.Provincia(ProvinciaId),
 Nombre nvarchar(120) NOT NULL, Domicilio nvarchar(200) NOT NULL,
 Latitud decimal(9,6) NULL, Longitud decimal(9,6) NULL,
 MaximoMensual int NOT NULL CONSTRAINT CK_Sucursal_Maximo CHECK(MaximoMensual>0),
 CapacidadSimultanea smallint NOT NULL CONSTRAINT DF_Sucursal_Capacidad DEFAULT 1
    CONSTRAINT CK_Sucursal_Capacidad CHECK(CapacidadSimultanea>0),
 Activa bit NOT NULL CONSTRAINT DF_Sucursal_Activa DEFAULT 1, FechaPausa datetime2(0) NULL,
 CONSTRAINT UQ_Sucursal UNIQUE(ConcesionariaId,Nombre),
 CONSTRAINT CK_Sucursal_Coord CHECK((Latitud IS NULL AND Longitud IS NULL) OR
   (Latitud IS NOT NULL AND Longitud IS NOT NULL AND Latitud BETWEEN -90 AND 90 AND Longitud BETWEEN -180 AND 180)),
 CONSTRAINT CK_Sucursal_Pausa CHECK((Activa=1 AND FechaPausa IS NULL) OR (Activa=0 AND FechaPausa IS NOT NULL)));
CREATE TABLE dbo.SucursalMarca(
 SucursalId int NOT NULL REFERENCES dbo.Sucursal(SucursalId),
 MarcaId int NOT NULL REFERENCES dbo.Marca(MarcaId),
 CONSTRAINT PK_SucursalMarca PRIMARY KEY(SucursalId,MarcaId));
CREATE TABLE dbo.Horario(
 SucursalId int NOT NULL REFERENCES dbo.Sucursal(SucursalId),
 DiaSemana tinyint NOT NULL CONSTRAINT CK_Horario_Dia CHECK(DiaSemana BETWEEN 1 AND 7), -- lunes=1
 HoraDesde time(0) NOT NULL, HoraHasta time(0) NOT NULL,
 CONSTRAINT PK_Horario PRIMARY KEY(SucursalId,DiaSemana,HoraDesde),
 CONSTRAINT CK_Horario_Rango CHECK(HoraDesde<HoraHasta AND DATEPART(minute,HoraDesde)%30=0
   AND DATEPART(second,HoraDesde)=0 AND DATEPART(minute,HoraHasta)%30=0 AND DATEPART(second,HoraHasta)=0));
CREATE TABLE dbo.Contacto(
 ContactoId int IDENTITY CONSTRAINT PK_Contacto PRIMARY KEY,
 Nombre nvarchar(80) NOT NULL, Apellido nvarchar(80) NOT NULL,
 Tipo varchar(25) NOT NULL CONSTRAINT CK_Contacto_Tipo CHECK(Tipo IN
 ('zonal_posventa','zonal_comercial','gerente_posventa','dealer_coach','agendador')),
 Telefono varchar(30) NULL, Email nvarchar(254) NULL);
CREATE TABLE dbo.SucursalContacto(
 SucursalId int NOT NULL REFERENCES dbo.Sucursal(SucursalId),
 ContactoId int NOT NULL REFERENCES dbo.Contacto(ContactoId),
 CONSTRAINT PK_SucursalContacto PRIMARY KEY(SucursalId,ContactoId));
GO
