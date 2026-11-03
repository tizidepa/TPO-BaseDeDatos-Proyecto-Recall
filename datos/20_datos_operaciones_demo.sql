-- 20_datos_operaciones_demo: Cargar teléfonos, llamados, turnos y resultados de ejemplo.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
DECLARE @lote uniqueidentifier=NEWID();
INSERT carga.TelefonoStaging(Lote,CUIT,Telefono1,WhatsApp1) VALUES(@lote,'20900000015','+54 9 11 5555-0001',NULL);
INSERT carga.TelefonoStaging(Lote,CUIT,Telefono1,WhatsApp1) VALUES(@lote,'20900000023','+54 9 11 5555-0002',1);
INSERT carga.TelefonoStaging(Lote,CUIT,Telefono1,WhatsApp1) VALUES(@lote,'20900000031','+54 9 11 5555-0003',0);
INSERT carga.TelefonoStaging(Lote,CUIT,Telefono1,WhatsApp1) VALUES(@lote,'20900000049','+54 9 11 5555-0004',NULL);
INSERT carga.TelefonoStaging(Lote,CUIT,Telefono1,WhatsApp1) VALUES(@lote,'20900000058','+54 9 11 5555-0005',0);
INSERT carga.TelefonoStaging(Lote,CUIT,Telefono1,WhatsApp1) VALUES(@lote,'20900000066','+54 9 11 5555-0006',1);
INSERT carga.TelefonoStaging(Lote,CUIT,Telefono1,WhatsApp1) VALUES(@lote,'20900000074','+54 9 11 5555-0007',NULL);
INSERT carga.TelefonoStaging(Lote,CUIT,Telefono1,WhatsApp1) VALUES(@lote,'20900000082','+54 9 11 5555-0008',1);
INSERT carga.TelefonoStaging(Lote,CUIT,Telefono1,WhatsApp1) VALUES(@lote,'20900000090','+54 9 11 5555-0009',0);
INSERT carga.TelefonoStaging(Lote,CUIT,Telefono1,WhatsApp1) VALUES(@lote,'30900000109','+54 9 11 5555-0010',NULL);
INSERT carga.TelefonoStaging(Lote,CUIT,Telefono1,WhatsApp1) VALUES(@lote,'20900000112','+54 9 11 5555-0011',0);
INSERT carga.TelefonoStaging(Lote,CUIT,Telefono1,WhatsApp1) VALUES(@lote,'20900000120','+54 9 11 5555-0012',1);
INSERT carga.TelefonoStaging(Lote,CUIT,Telefono1) VALUES(@lote,'20900000015','1537668202');
EXEC api.sp_CargarTelefonos @lote;
EXEC api.sp_RegistrarLlamado 'AA001AA','20900000015','1155550001','no_efectivo';
EXEC api.sp_RegistrarLlamado 'AA001AA','20900000015','1155550001','efectivo';
EXEC api.sp_RegistrarLlamado 'AA002AA','20900000023','1155550002','efectivo';
DECLARE @lunes date=DATEADD(day,7-(DATEDIFF(day,CONVERT(date,'19000101'),CONVERT(date,DATEADD(hour,-3,SYSUTCDATETIME())))%7),CONVERT(date,DATEADD(hour,-3,SYSUTCDATETIME())));
EXEC api.sp_CrearTurno 'AA001AA',1,@lunes,'09:00';
EXEC api.sp_CrearTurno 'AA002AA',1;
EXEC api.sp_CrearTurno 'AA003AA',1,@lunes,'09:30';
EXEC api.sp_CrearTurno 'AA004AA',1,@lunes,'10:00';
EXEC api.sp_CrearTurno 'AA005AA',1,@lunes,'10:30';
DECLARE @id bigint=(SELECT TurnoId FROM dbo.Turno WHERE Dominio='AA005AA');
EXEC api.sp_CerrarTurno @id,'cancelado';
-- Antecedente histórico: cargado directamente sólo por el instalador dbo.
INSERT dbo.Turno(Dominio,SucursalId,UsuarioId,Fecha,Hora,Estado,NombreAsistente,ApellidoAsistente,TelefonoAsistente)
VALUES('AA006AA',1,1,DATEADD(day,-7,@lunes),'11:00','no_se_presento',N'Asistente',N'Demo','1155550006');
DECLARE @lista dbo.ListaDominios;
INSERT @lista VALUES('AA003AA'); EXEC api.sp_CargarResultado @lista,'facturado';
DELETE @lista; INSERT @lista VALUES('AA004AA'); EXEC api.sp_CargarResultado @lista,'realizado';
DELETE @lista; INSERT @lista VALUES('AA007AA'); EXEC api.sp_CambiarEstadoVehiculos @lista,'pausar';
DELETE @lista; INSERT @lista VALUES('AA008AA'); EXEC api.sp_CambiarEstadoVehiculos @lista,'descartar';
EXEC api.sp_CalcularTop5;
GO
