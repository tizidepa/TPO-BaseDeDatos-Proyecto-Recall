-- 07_turnos_e_historiales: Crear turnos e historiales de cambios.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE TABLE dbo.Turno(
 TurnoId bigint IDENTITY CONSTRAINT PK_Turno PRIMARY KEY,
 Dominio varchar(7) COLLATE Latin1_General_100_BIN2 NOT NULL REFERENCES dbo.Vehiculo(Dominio),
 SucursalId int NOT NULL REFERENCES dbo.Sucursal(SucursalId),
 UsuarioId int NOT NULL REFERENCES seguridad.Usuario(UsuarioId),
 Fecha date NULL, Hora time(0) NULL,
 FechaCreacion datetime2(0) NOT NULL CONSTRAINT DF_Turno_Creacion DEFAULT SYSUTCDATETIME(),
 Estado varchar(20) NOT NULL,
 NombreAsistente nvarchar(100) NOT NULL, ApellidoAsistente nvarchar(100) NOT NULL,
 TelefonoAsistente varchar(10) NOT NULL,
 Reprogramaciones int NOT NULL CONSTRAINT DF_Turno_Reprogramaciones DEFAULT 0,
 FechaReprogramacion datetime2(0) NULL,
 CONSTRAINT CK_Turno_Estado CHECK(Estado IN ('preturno','creado','cancelado','no_se_presento','facturado','realizado')),
 CONSTRAINT CK_Turno_Fecha CHECK((Fecha IS NULL AND Hora IS NULL AND Estado IN ('preturno','cancelado','facturado','realizado'))
   OR (Fecha IS NOT NULL AND Hora IS NOT NULL)),
 CONSTRAINT CK_Turno_Franja CHECK(Hora IS NULL OR
   (DATEPART(minute,Hora)%30=0 AND DATEPART(second,Hora)=0 AND Hora<CONVERT(time(0),'23:30'))),
 CONSTRAINT CK_Turno_Telefono CHECK(LEN(TelefonoAsistente)=10 AND TelefonoAsistente COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^0-9]%'),
 CONSTRAINT CK_Turno_Reprogramaciones CHECK(Reprogramaciones>=0));
CREATE UNIQUE INDEX UX_Turno_Activo ON dbo.Turno(Dominio) WHERE Estado IN ('preturno','creado');
CREATE INDEX IX_Turno_Capacidad ON dbo.Turno(SucursalId,Fecha,Hora) INCLUDE(Estado,Dominio);
CREATE INDEX IX_Turno_Ultimo ON dbo.Turno(Dominio,FechaCreacion DESC,TurnoId DESC) INCLUDE(Estado);
CREATE TABLE dbo.HistorialTurno(
 HistorialId bigint IDENTITY CONSTRAINT PK_HistorialTurno PRIMARY KEY,
 TurnoId bigint NOT NULL REFERENCES dbo.Turno(TurnoId),
 EstadoAnterior varchar(20) NULL, EstadoNuevo varchar(20) NOT NULL,
 FechaAnterior date NULL, HoraAnterior time(0) NULL,
 FechaNueva date NULL, HoraNueva time(0) NULL,
 FechaEvento datetime2(0) NOT NULL CONSTRAINT DF_HistorialTurno_Fecha DEFAULT SYSUTCDATETIME());
CREATE TABLE dbo.HistorialVehiculo(
 HistorialId bigint IDENTITY CONSTRAINT PK_HistorialVehiculo PRIMARY KEY,
 Dominio varchar(7) COLLATE Latin1_General_100_BIN2 NOT NULL REFERENCES dbo.Vehiculo(Dominio),
 EstadoAnterior varchar(20) NOT NULL, EstadoNuevo varchar(20) NOT NULL,
 FechaEvento datetime2(0) NOT NULL CONSTRAINT DF_HistorialVehiculo_Fecha DEFAULT SYSUTCDATETIME());
GO
