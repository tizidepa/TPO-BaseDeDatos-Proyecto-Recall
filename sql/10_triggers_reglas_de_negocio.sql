-- 10_triggers_reglas_de_negocio: Centralizar validaciones, estados y contadores.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE TRIGGER dbo.tr_Horario_Validar ON dbo.Horario WITH EXECUTE AS OWNER AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted i JOIN dbo.Horario h WITH(UPDLOCK,HOLDLOCK)
 ON h.SucursalId=i.SucursalId AND h.DiaSemana=i.DiaSemana AND h.HoraDesde<>i.HoraDesde
 WHERE i.HoraDesde<h.HoraHasta AND h.HoraDesde<i.HoraHasta)
 THROW 51002,'Los horarios de una sucursal no pueden superponerse.',1;
END;
GO
CREATE TRIGGER dbo.tr_Titularidad_Validar ON dbo.Titularidad WITH EXECUTE AS OWNER AFTER INSERT,UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted i JOIN dbo.Titularidad t WITH(UPDLOCK,HOLDLOCK)
 ON t.Dominio=i.Dominio AND t.CUIT=i.CUIT AND t.TitularidadId<>i.TitularidadId
 WHERE i.Desde<COALESCE(t.Hasta,CONVERT(datetime2(0),'99991231'))
 AND t.Desde<COALESCE(i.Hasta,CONVERT(datetime2(0),'99991231')))
 THROW 51003,'Los períodos de una misma titularidad no pueden superponerse.',1;
 DELETE t FROM dbo.Top5 t WHERE EXISTS(SELECT 1 FROM inserted i WHERE i.Dominio=t.Dominio)
 OR EXISTS(SELECT 1 FROM deleted d WHERE d.Dominio=t.Dominio);
END;
GO
CREATE TRIGGER dbo.tr_Telefono_Maximo ON dbo.Telefono WITH EXECUTE AS OWNER AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT t.CUIT FROM dbo.Telefono t WITH(UPDLOCK,HOLDLOCK)
 WHERE t.Activo=1 AND t.CUIT IN (SELECT CUIT FROM inserted) GROUP BY t.CUIT HAVING COUNT(*)>5)
 THROW 51004,'Un titular no puede tener más de cinco teléfonos activos.',1;
END;
GO
CREATE TRIGGER dbo.tr_Concesionaria_NoEliminar ON dbo.Concesionaria INSTEAD OF DELETE AS
 THROW 51005,'Las concesionarias no se eliminan: se pausan.',1;
GO
CREATE TRIGGER dbo.tr_Sucursal_NoEliminar ON dbo.Sucursal INSTEAD OF DELETE AS
 THROW 51006,'Las sucursales no se eliminan: se pausan.',1;
GO
CREATE TRIGGER dbo.tr_Vehiculo_Historial ON dbo.Vehiculo WITH EXECUTE AS OWNER AFTER UPDATE AS
BEGIN
 SET NOCOUNT ON;
 INSERT dbo.HistorialVehiculo(Dominio,EstadoAnterior,EstadoNuevo)
 SELECT i.Dominio,d.Estado,i.Estado FROM inserted i JOIN deleted d ON d.Dominio=i.Dominio WHERE i.Estado<>d.Estado;
END;
GO
CREATE TRIGGER dbo.tr_Llamado_Registrar ON dbo.Llamado WITH EXECUTE AS OWNER AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted i JOIN dbo.Vehiculo v ON v.Dominio=i.Dominio
 JOIN dbo.Titular t ON t.CUIT=i.CUIT JOIN dbo.Telefono f ON f.CUIT=i.CUIT AND f.Numero=i.Numero
 JOIN dbo.Gestion g ON g.GestionId=v.GestionId JOIN dbo.Marca m ON m.MarcaId=v.MarcaId
 WHERE t.Tipo<>'P' OR f.Activo=0 OR v.Estado NOT IN ('pendiente','trabajando') OR g.Activa=0 OR m.Activa=0
 OR NOT EXISTS(SELECT 1 FROM dbo.Titularidad x WHERE x.Dominio=i.Dominio AND x.CUIT=i.CUIT AND x.Hasta IS NULL))
 THROW 51007,'El llamado requiere persona, teléfono activo, titularidad vigente y vehículo disponible.',1;
 UPDATE t SET Intentos=Intentos+x.Cantidad FROM dbo.Titular t
 JOIN(SELECT CUIT,COUNT_BIG(*) Cantidad FROM inserted GROUP BY CUIT)x ON x.CUIT=t.CUIT;
 UPDATE v SET Estado='trabajando' FROM dbo.Vehiculo v
 WHERE v.Estado='pendiente' AND EXISTS(SELECT 1 FROM inserted i WHERE i.Dominio=v.Dominio AND i.Resultado='efectivo');
END;
GO
CREATE TRIGGER dbo.tr_Turno_Reglas ON dbo.Turno WITH EXECUTE AS OWNER AFTER INSERT,UPDATE AS
BEGIN
 SET NOCOUNT ON;
 IF TRIGGER_NESTLEVEL(OBJECT_ID('dbo.tr_Turno_Reglas'))>1 RETURN;
 -- Un turno conserva su identidad, vehículo, creador y fecha de creación.
 IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.TurnoId=i.TurnoId
 WHERE i.Dominio<>d.Dominio OR i.UsuarioId<>d.UsuarioId OR i.FechaCreacion<>d.FechaCreacion)
 THROW 51008,'No se puede cambiar el vehículo ni la autoría de un turno.',1;
 IF EXISTS(SELECT 1 FROM inserted i JOIN deleted d ON d.TurnoId=i.TurnoId
 WHERE (d.Estado='realizado' AND i.Estado<>'realizado')
 OR (d.Estado='facturado' AND i.Estado NOT IN ('facturado','realizado')))
 THROW 51009,'El estado no puede retroceder desde facturado o realizado.',1;
 -- Sólo validar disponibilidad al reservar o modificar una reserva; pausar la red no cancela las anteriores.
 DECLARE @validar TABLE(TurnoId bigint PRIMARY KEY);
 INSERT @validar SELECT i.TurnoId FROM inserted i LEFT JOIN deleted d ON d.TurnoId=i.TurnoId
 WHERE i.Estado IN ('preturno','creado') AND (d.TurnoId IS NULL OR d.Estado NOT IN ('preturno','creado')
 OR i.SucursalId<>d.SucursalId OR ISNULL(i.Fecha,'19000101')<>ISNULL(d.Fecha,'19000101')
 OR ISNULL(i.Hora,'00:00')<>ISNULL(d.Hora,'00:00'));
 IF EXISTS(SELECT 1 FROM @validar a JOIN inserted i ON i.TurnoId=a.TurnoId
 JOIN dbo.Vehiculo v ON v.Dominio=i.Dominio JOIN dbo.Gestion g ON g.GestionId=v.GestionId
 JOIN dbo.Marca m ON m.MarcaId=v.MarcaId JOIN dbo.Sucursal s ON s.SucursalId=i.SucursalId
 JOIN dbo.Concesionaria c ON c.ConcesionariaId=s.ConcesionariaId
 WHERE v.Estado NOT IN ('pendiente','trabajando','turno') OR g.Activa=0 OR m.Activa=0 OR s.Activa=0 OR c.Activa=0
 OR NOT EXISTS(SELECT 1 FROM dbo.SucursalMarca sm WHERE sm.SucursalId=s.SucursalId AND sm.MarcaId=v.MarcaId)
 OR NOT EXISTS(SELECT 1 FROM dbo.GestionConcesionaria gc WHERE gc.GestionId=v.GestionId AND gc.ConcesionariaId=c.ConcesionariaId)
 OR NOT EXISTS(SELECT 1 FROM dbo.Titularidad x JOIN dbo.Titular t ON t.CUIT=x.CUIT
 WHERE x.Dominio=v.Dominio AND x.Hasta IS NULL AND x.EsPrincipal=1 AND t.Tipo='P'))
 THROW 51010,'Vehículo, titular principal o red de atención no disponibles para agendar.',1;
 IF EXISTS(SELECT 1 FROM @validar a JOIN inserted i ON i.TurnoId=a.TurnoId WHERE i.Fecha IS NOT NULL AND
 (DATEADD(second,DATEDIFF(second,CONVERT(time(0),'00:00'),i.Hora),CONVERT(datetime2(0),i.Fecha))<DATEADD(hour,-3,SYSUTCDATETIME()) OR NOT EXISTS(
 SELECT 1 FROM dbo.Horario h WHERE h.SucursalId=i.SucursalId
 AND h.DiaSemana=((DATEDIFF(day,CONVERT(date,'19000101'),i.Fecha)%7+7)%7)+1
 AND i.Hora>=h.HoraDesde AND DATEADD(minute,30,i.Hora)<=h.HoraHasta)))
 THROW 51011,'El turno debe estar en una fecha vigente y dentro de un horario de 30 minutos.',1;
 IF EXISTS(SELECT 1 FROM @validar a JOIN inserted i ON i.TurnoId=a.TurnoId
 JOIN dbo.Sucursal s ON s.SucursalId=i.SucursalId WHERE i.Fecha IS NOT NULL
 AND (SELECT COUNT_BIG(*) FROM dbo.Turno t WITH(UPDLOCK,HOLDLOCK)
 WHERE t.SucursalId=i.SucursalId AND t.Fecha=i.Fecha AND t.Hora=i.Hora
 AND t.Estado IN ('preturno','creado','facturado','realizado'))>s.CapacidadSimultanea)
 THROW 51012,'Se superó la capacidad simultánea de la sucursal.',1;
 IF EXISTS(SELECT 1 FROM @validar a JOIN inserted i ON i.TurnoId=a.TurnoId
 JOIN dbo.Sucursal s ON s.SucursalId=i.SucursalId WHERE i.Fecha IS NOT NULL
 AND (SELECT COUNT_BIG(*) FROM dbo.Turno t WITH(UPDLOCK,HOLDLOCK)
 WHERE t.SucursalId=i.SucursalId AND t.Fecha>=DATEFROMPARTS(YEAR(i.Fecha),MONTH(i.Fecha),1)
 AND t.Fecha<DATEADD(month,1,DATEFROMPARTS(YEAR(i.Fecha),MONTH(i.Fecha),1))
 AND t.Estado IN ('preturno','creado','no_se_presento','facturado','realizado'))>s.MaximoMensual)
 THROW 51013,'Se superó el máximo mensual de la sucursal.',1;
 UPDATE t SET Estado=CASE WHEN i.Estado='preturno' AND i.Fecha IS NOT NULL THEN 'creado' ELSE i.Estado END,
 Reprogramaciones=CASE WHEN d.TurnoId IS NOT NULL AND d.Fecha IS NOT NULL
 AND (i.Fecha<>d.Fecha OR i.Hora<>d.Hora) THEN d.Reprogramaciones+1 ELSE COALESCE(d.Reprogramaciones,0) END,
 FechaReprogramacion=CASE WHEN d.TurnoId IS NOT NULL AND d.Fecha IS NOT NULL
 AND (i.Fecha<>d.Fecha OR i.Hora<>d.Hora) THEN SYSUTCDATETIME() ELSE d.FechaReprogramacion END
 FROM dbo.Turno t JOIN inserted i ON i.TurnoId=t.TurnoId LEFT JOIN deleted d ON d.TurnoId=i.TurnoId;
 INSERT dbo.HistorialTurno(TurnoId,EstadoAnterior,EstadoNuevo,FechaAnterior,HoraAnterior,FechaNueva,HoraNueva)
 SELECT t.TurnoId,d.Estado,t.Estado,d.Fecha,d.Hora,t.Fecha,t.Hora FROM inserted i
 JOIN dbo.Turno t ON t.TurnoId=i.TurnoId LEFT JOIN deleted d ON d.TurnoId=i.TurnoId
 WHERE d.TurnoId IS NULL OR d.Estado<>t.Estado OR ISNULL(d.Fecha,'19000101')<>ISNULL(t.Fecha,'19000101')
 OR ISNULL(d.Hora,'00:00')<>ISNULL(t.Hora,'00:00');
 UPDATE v SET Estado=CASE WHEN t.Estado IN ('facturado','realizado') THEN 'turno_realizado'
 WHEN t.Estado IN ('preturno','creado') THEN 'turno'
 WHEN t.Estado IN ('cancelado','no_se_presento') AND v.Estado='turno' THEN 'trabajando' ELSE v.Estado END
 FROM dbo.Vehiculo v JOIN dbo.Turno t ON t.Dominio=v.Dominio
 WHERE t.TurnoId IN(SELECT TurnoId FROM inserted)
 AND t.TurnoId=(SELECT TOP(1) u.TurnoId FROM dbo.Turno u WHERE u.Dominio=v.Dominio ORDER BY u.FechaCreacion DESC,u.TurnoId DESC);
END;
GO
