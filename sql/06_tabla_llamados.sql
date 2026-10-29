-- 06_tabla_llamados: Crear el historial de llamados e índices.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE TABLE dbo.Llamado(
 LlamadoId bigint IDENTITY CONSTRAINT PK_Llamado PRIMARY KEY,
 Dominio varchar(7) COLLATE Latin1_General_100_BIN2 NOT NULL REFERENCES dbo.Vehiculo(Dominio),
 CUIT varchar(11) NOT NULL, Numero varchar(10) NOT NULL,
 Resultado varchar(12) NOT NULL CONSTRAINT CK_Llamado_Resultado CHECK(Resultado IN ('efectivo','no_efectivo')),
 Fecha datetime2(0) NOT NULL CONSTRAINT DF_Llamado_Fecha DEFAULT SYSUTCDATETIME(),
 Archivado bit NOT NULL CONSTRAINT DF_Llamado_Archivado DEFAULT 0,
 CONSTRAINT FK_Llamado_Telefono FOREIGN KEY(CUIT,Numero) REFERENCES dbo.Telefono(CUIT,Numero));
CREATE INDEX IX_Llamado_TitularFecha ON dbo.Llamado(CUIT,Fecha) INCLUDE(Resultado,Dominio);
CREATE INDEX IX_Llamado_DominioFecha ON dbo.Llamado(Dominio,Fecha) INCLUDE(Resultado);
GO
