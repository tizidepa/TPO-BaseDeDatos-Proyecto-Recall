:ON ERROR EXIT
USE RecallsUADE;
GO
SET NOCOUNT ON;
-- Cada vista aplica el alcance de gestión del usuario. Como dbo se ven todas.

-- 1. SELECT, WHERE, ORDER BY: pendientes por provincia, sólo grupos con pendientes.
SELECT GestionId,Provincia,VehiculosPendientes FROM reporte.v_PendientesProvincia
WHERE VehiculosPendientes>0 ORDER BY VehiculosPendientes DESC,Provincia;

-- 2. JOIN: cada turno, su vehículo, marca, gestión y sucursal (consulta administrativa).
SELECT t.TurnoId,v.Dominio,g.Nombre Gestion,m.Nombre Marca,s.Nombre Sucursal,t.Fecha,t.Hora,t.Estado
FROM dbo.Turno t JOIN dbo.Vehiculo v ON v.Dominio=t.Dominio
JOIN dbo.Gestion g ON g.GestionId=v.GestionId JOIN dbo.Marca m ON m.MarcaId=v.MarcaId
JOIN dbo.Sucursal s ON s.SucursalId=t.SucursalId ORDER BY t.Fecha,t.Hora;

-- 3. GROUP BY, HAVING y agregaciones: sucursales con al menos dos turnos.
SELECT s.SucursalId,s.Nombre,COUNT_BIG(*) Cantidad,MIN(t.Fecha) PrimeraFecha,MAX(t.Fecha) UltimaFecha,
 SUM(t.Reprogramaciones) Reprogramaciones,AVG(CONVERT(decimal(10,2),t.Reprogramaciones)) Promedio
FROM dbo.Sucursal s JOIN dbo.Turno t ON t.SucursalId=s.SucursalId
GROUP BY s.SucursalId,s.Nombre HAVING COUNT_BIG(*)>=2 ORDER BY Cantidad DESC;

-- 4. Subconsulta correlacionada NOT EXISTS: pendientes que nunca tuvieron turno.
-- La subconsulta se correlaciona mediante el dominio; evita multiplicar vehículos.
SELECT v.Dominio,v.GestionId FROM dbo.Vehiculo v WHERE v.Estado IN ('pendiente','trabajando')
AND NOT EXISTS(SELECT 1 FROM dbo.Turno t WHERE t.Dominio=v.Dominio) ORDER BY v.Dominio;

-- 5. Subconsulta EXISTS: titulares con más de un vehículo vigente.
SELECT t.CUIT,t.NombreRazonSocial FROM dbo.Titular t WHERE EXISTS(
 SELECT 1 FROM dbo.Titularidad x WHERE x.CUIT=t.CUIT AND x.Hasta IS NULL
 GROUP BY x.CUIT HAVING COUNT(*)>1);

-- 6. Subconsulta escalar: pendientes con cantidad de intentos específicamente para su dominio.
SELECT v.Dominio,(SELECT COUNT_BIG(*) FROM dbo.Llamado l WHERE l.Dominio=v.Dominio) IntentosDelVehiculo
FROM dbo.Vehiculo v WHERE v.Estado IN ('pendiente','trabajando');

-- 7. Períodos: límite inicial inclusivo y final exclusivo; fecha de cita, no fecha de creación.
DECLARE @hoy date=CONVERT(date,DATEADD(hour,-3,SYSUTCDATETIME()));
DECLARE @lunes date=DATEADD(day,-(DATEDIFF(day,CONVERT(date,'19000101'),@hoy)%7),@hoy);
SELECT N'Esta semana' Periodo,* FROM reporte.fn_TurnosPeriodo(@lunes,DATEADD(day,7,@lunes));
SELECT N'Últimos 7 días' Periodo,* FROM reporte.fn_TurnosPeriodo(DATEADD(day,-6,@hoy),DATEADD(day,1,@hoy));
SELECT N'Últimos 14 días' Periodo,* FROM reporte.fn_TurnosPeriodo(DATEADD(day,-13,@hoy),DATEADD(day,1,@hoy));
SELECT N'Último mes móvil' Periodo,* FROM reporte.fn_TurnosPeriodo(DATEADD(month,-1,@hoy),DATEADD(day,1,@hoy));
SELECT GestionId,SUM(Cantidad) TodosLosTurnos FROM reporte.v_TurnosDiarios GROUP BY GestionId;

-- 8. Paneles agregados y exportación administrativa.
SELECT * FROM reporte.v_PendientesRealizados;
SELECT * FROM reporte.v_PersonasEmpresas;
SELECT * FROM reporte.v_Distancias;
SELECT * FROM reporte.v_SucursalesProvincia;
SELECT * FROM reporte.v_TurnosEstado;
SELECT * FROM reporte.v_TurnosRealizados;
SELECT * FROM reporte.v_TurnosSucursal;
SELECT * FROM reporte.v_AdminTurnosEstado;
SELECT * FROM reporte.v_AdminLlamados;
SELECT * FROM reporte.v_AdminPausados;
SELECT * FROM reporte.v_AdminDistribucionTop5;
SELECT * FROM reporte.v_AdminOcupacion;
SELECT * FROM reporte.v_AdminConversion;
SELECT * FROM reporte.v_AdminDiscador ORDER BY Dominio,Numero;

-- 9. Seguridad: mismo SELECT, distinto resultado según usuario conectado.
EXECUTE AS USER='demo_viewer';
SELECT USER_NAME() UsuarioActual,* FROM reporte.v_PendientesRealizados;
REVERT;
EXECUTE AS USER='demo_viewer_toyota';
SELECT USER_NAME() UsuarioActual,* FROM reporte.v_PendientesRealizados;
REVERT;
GO
