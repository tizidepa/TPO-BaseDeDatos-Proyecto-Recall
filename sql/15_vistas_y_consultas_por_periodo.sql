-- 15_vistas_y_consultas_por_periodo: Crear reportes y consulta de turnos por período.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE VIEW reporte.v_PendientesRealizados AS
 SELECT GestionId,
 SUM(CONVERT(bigint,IIF(Estado IN ('pendiente','trabajando','turno'),1,0))) Pendientes,
 SUM(CONVERT(bigint,IIF(Estado='turno_realizado',1,0))) Realizados,
 SUM(CONVERT(bigint,IIF(Estado='pausado',1,0))) Pausados,
 SUM(CONVERT(bigint,IIF(Estado='descartado',1,0))) Descartados
 FROM dbo.Vehiculo GROUP BY GestionId;
GO
CREATE VIEW reporte.v_PendientesProvincia AS
 SELECT v.GestionId,p.ProvinciaId,p.Nombre Provincia,COUNT_BIG(*) VehiculosPendientes
 FROM dbo.Vehiculo v JOIN dbo.Titularidad x ON x.Dominio=v.Dominio AND x.Hasta IS NULL AND x.EsPrincipal=1
 JOIN dbo.Titular t ON t.CUIT=x.CUIT AND t.Tipo='P' JOIN dbo.Provincia p ON p.ProvinciaId=t.ProvinciaId
 WHERE v.Estado IN ('pendiente','trabajando','turno') GROUP BY v.GestionId,p.ProvinciaId,p.Nombre;
GO
CREATE VIEW reporte.v_PersonasEmpresas AS
 SELECT v.GestionId,COALESCE(t.Tipo,'?') TipoTitularPrincipal,COUNT_BIG(*) Vehiculos,
 COUNT(DISTINCT t.CUIT) TitularesDistintos
 FROM dbo.Vehiculo v LEFT JOIN dbo.Titularidad x ON x.Dominio=v.Dominio AND x.Hasta IS NULL AND x.EsPrincipal=1
 LEFT JOIN dbo.Titular t ON t.CUIT=x.CUIT GROUP BY v.GestionId,t.Tipo;
GO
CREATE VIEW reporte.v_Distancias AS
 SELECT v.GestionId,CASE WHEN top1.Km IS NULL THEN 'sin_sugerencia'
 WHEN top1.Km<=60 THEN 'hasta_60_km' ELSE 'mas_de_60_km' END Rango,COUNT_BIG(*) Vehiculos
 FROM dbo.Vehiculo v JOIN dbo.Titularidad x ON x.Dominio=v.Dominio AND x.Hasta IS NULL AND x.EsPrincipal=1
 JOIN dbo.Titular t ON t.CUIT=x.CUIT AND t.Tipo='P'
 LEFT JOIN dbo.Top5 top1 ON top1.Dominio=v.Dominio AND top1.Posicion=1 AND top1.CUITPrincipal=t.CUIT
 GROUP BY v.GestionId,CASE WHEN top1.Km IS NULL THEN 'sin_sugerencia' WHEN top1.Km<=60 THEN 'hasta_60_km' ELSE 'mas_de_60_km' END;
GO
CREATE VIEW reporte.v_SucursalesProvincia AS
 SELECT g.GestionId,s.ProvinciaId,sm.MarcaId,COUNT_BIG(*) Sucursales,
 SUM(CONVERT(bigint,IIF(s.Activa=1 AND c.Activa=1,1,0))) Activas
 FROM dbo.Gestion g JOIN dbo.GestionConcesionaria gc ON gc.GestionId=g.GestionId
 JOIN dbo.Concesionaria c ON c.ConcesionariaId=gc.ConcesionariaId JOIN dbo.Sucursal s ON s.ConcesionariaId=c.ConcesionariaId
 JOIN dbo.SucursalMarca sm ON sm.SucursalId=s.SucursalId
 JOIN dbo.GestionMarca gm ON gm.GestionId=g.GestionId AND gm.MarcaId=sm.MarcaId
 GROUP BY g.GestionId,s.ProvinciaId,sm.MarcaId;
GO
CREATE VIEW reporte.v_TurnosDiarios AS
 -- Se cuenta por fecha de cita; los preturnos sin fecha aparecen con Fecha NULL.
 SELECT v.GestionId,t.Fecha,COUNT_BIG(*) Cantidad FROM dbo.Turno t
 JOIN dbo.Vehiculo v ON v.Dominio=t.Dominio GROUP BY v.GestionId,t.Fecha;
GO
CREATE VIEW reporte.v_TurnosEstado AS
 -- Viewer/Asesor ven reparados combinados; el desglose es exclusivo del Admin.
 SELECT v.GestionId,CASE WHEN t.Estado IN ('facturado','realizado') THEN 'reparado' ELSE t.Estado END Estado,
 COUNT_BIG(*) Cantidad FROM dbo.Turno t JOIN dbo.Vehiculo v ON v.Dominio=t.Dominio
 GROUP BY v.GestionId,CASE WHEN t.Estado IN ('facturado','realizado') THEN 'reparado' ELSE t.Estado END;
GO
CREATE VIEW reporte.v_TurnosRealizados AS
 SELECT v.GestionId,COUNT_BIG(*) Cantidad FROM dbo.Turno t JOIN dbo.Vehiculo v ON v.Dominio=t.Dominio
 WHERE t.Estado IN ('facturado','realizado') GROUP BY v.GestionId;
GO
CREATE VIEW reporte.v_TurnosSucursal AS
 SELECT v.GestionId,t.SucursalId,t.Fecha,COUNT_BIG(*) Cantidad
 FROM dbo.Turno t JOIN dbo.Vehiculo v ON v.Dominio=t.Dominio GROUP BY v.GestionId,t.SucursalId,t.Fecha;
GO
CREATE VIEW reporte.v_AdminTurnosEstado AS
 SELECT v.GestionId,t.Estado,COUNT_BIG(*) Cantidad FROM dbo.Turno t JOIN dbo.Vehiculo v ON v.Dominio=t.Dominio
 GROUP BY v.GestionId,t.Estado;
GO
CREATE VIEW reporte.v_AdminLlamados AS
 SELECT v.GestionId,l.Resultado,COUNT_BIG(*) Total,
 SUM(CONVERT(bigint,IIF(l.Fecha>=DATEADD(month,-1,SYSUTCDATETIME()),1,0))) UltimoMes
 FROM dbo.Llamado l JOIN dbo.Vehiculo v ON v.Dominio=l.Dominio GROUP BY v.GestionId,l.Resultado;
GO
CREATE VIEW reporte.v_AdminPausados AS
 SELECT 'vehiculo' Entidad,CONVERT(nvarchar(100),Dominio) Identificador,CAST(NULL AS datetime2(0)) FechaPausa
 FROM dbo.Vehiculo WHERE Estado='pausado'
 UNION ALL SELECT 'gestion',CONVERT(nvarchar(100),GestionId),FechaPausa FROM dbo.Gestion WHERE Activa=0
 UNION ALL SELECT 'marca',CONVERT(nvarchar(100),MarcaId),FechaPausa FROM dbo.Marca WHERE Activa=0
 UNION ALL SELECT 'concesionaria',CONVERT(nvarchar(100),ConcesionariaId),FechaPausa FROM dbo.Concesionaria WHERE Activa=0
 UNION ALL SELECT 'sucursal',CONVERT(nvarchar(100),SucursalId),FechaPausa FROM dbo.Sucursal WHERE Activa=0;
GO
CREATE VIEW reporte.v_AdminDistribucionTop5 AS
 SELECT v.GestionId,s.ConcesionariaId,t.Posicion,COUNT_BIG(*) Apariciones
 FROM dbo.Top5 t JOIN dbo.Vehiculo v ON v.Dominio=t.Dominio JOIN dbo.Sucursal s ON s.SucursalId=t.SucursalId
 GROUP BY v.GestionId,s.ConcesionariaId,t.Posicion;
GO
CREATE VIEW reporte.v_AdminOcupacion AS
 SELECT s.SucursalId,s.Nombre,s.MaximoMensual,s.CapacidadSimultanea,
 COUNT_BIG(t.TurnoId) TurnosMes,
 CONVERT(decimal(7,2),100.0*COUNT_BIG(t.TurnoId)/s.MaximoMensual) PorcentajeMensual
 FROM dbo.Sucursal s LEFT JOIN dbo.Turno t ON t.SucursalId=s.SucursalId
 AND t.Fecha>=DATEFROMPARTS(YEAR(DATEADD(hour,-3,SYSUTCDATETIME())),MONTH(DATEADD(hour,-3,SYSUTCDATETIME())),1)
 AND t.Fecha<DATEADD(month,1,DATEFROMPARTS(YEAR(DATEADD(hour,-3,SYSUTCDATETIME())),MONTH(DATEADD(hour,-3,SYSUTCDATETIME())),1))
 AND t.Estado IN ('creado','no_se_presento','facturado','realizado')
 GROUP BY s.SucursalId,s.Nombre,s.MaximoMensual,s.CapacidadSimultanea;
GO
CREATE VIEW reporte.v_AdminConversion AS
 -- Unidad: vehículo con al menos un llamado efectivo, no cantidad de intentos.
 WITH Efectivos AS(SELECT Dominio,MIN(Fecha) PrimerEfectivo FROM dbo.Llamado WHERE Resultado='efectivo' GROUP BY Dominio),
 Conversiones AS(SELECT e.Dominio,CONVERT(bigint,CASE WHEN EXISTS(SELECT 1 FROM dbo.Turno t
 WHERE t.Dominio=e.Dominio AND t.FechaCreacion>=e.PrimerEfectivo) THEN 1 ELSE 0 END) ConTurno
 FROM Efectivos e)
 SELECT v.GestionId,COUNT_BIG(*) VehiculosContactados,SUM(c.ConTurno) VehiculosConTurno,
 CONVERT(decimal(7,2),100.0*SUM(c.ConTurno)/COUNT_BIG(*)) Porcentaje
 FROM Conversiones c JOIN dbo.Vehiculo v ON v.Dominio=c.Dominio GROUP BY v.GestionId;
GO
CREATE VIEW reporte.v_AdminDiscador AS
 SELECT v.GestionId,v.Dominio,t.CUIT,t.NombreRazonSocial,t.Apellido,f.Numero,
 MAX(CASE WHEN top5.Posicion=1 THEN s.Nombre END) Sucursal1,MAX(CASE WHEN top5.Posicion=1 THEN top5.Km END) Km1,
 MAX(CASE WHEN top5.Posicion=2 THEN s.Nombre END) Sucursal2,MAX(CASE WHEN top5.Posicion=2 THEN top5.Km END) Km2,
 MAX(CASE WHEN top5.Posicion=3 THEN s.Nombre END) Sucursal3,MAX(CASE WHEN top5.Posicion=3 THEN top5.Km END) Km3,
 MAX(CASE WHEN top5.Posicion=4 THEN s.Nombre END) Sucursal4,MAX(CASE WHEN top5.Posicion=4 THEN top5.Km END) Km4,
 MAX(CASE WHEN top5.Posicion=5 THEN s.Nombre END) Sucursal5,MAX(CASE WHEN top5.Posicion=5 THEN top5.Km END) Km5
 FROM dbo.Vehiculo v JOIN dbo.Gestion g ON g.GestionId=v.GestionId AND g.Activa=1
 JOIN dbo.Marca m ON m.MarcaId=v.MarcaId AND m.Activa=1
 JOIN dbo.Titularidad x ON x.Dominio=v.Dominio AND x.Hasta IS NULL AND x.EsPrincipal=1
 JOIN dbo.Titular t ON t.CUIT=x.CUIT AND t.Tipo='P' JOIN dbo.Telefono f ON f.CUIT=t.CUIT AND f.Activo=1
 JOIN dbo.Top5 top5 ON top5.Dominio=v.Dominio AND top5.CUITPrincipal=t.CUIT
 JOIN dbo.Sucursal s ON s.SucursalId=top5.SucursalId AND s.Activa=1 AND s.ProvinciaId=t.ProvinciaId
 JOIN dbo.Concesionaria c ON c.ConcesionariaId=s.ConcesionariaId AND c.Activa=1
 WHERE v.Estado IN ('pendiente','trabajando') AND EXISTS(SELECT 1 FROM dbo.Top5 a
 WHERE a.Dominio=v.Dominio AND a.Posicion=1 AND a.Km<=60)
 GROUP BY v.GestionId,v.Dominio,t.CUIT,t.NombreRazonSocial,t.Apellido,f.Numero;
GO
CREATE VIEW reporte.v_AdminVehiculos AS
 SELECT v.*,x.CUIT CUITPrincipal,t.NombreRazonSocial,t.Apellido,t.ProvinciaId
 FROM dbo.Vehiculo v LEFT JOIN dbo.Titularidad x ON x.Dominio=v.Dominio AND x.Hasta IS NULL AND x.EsPrincipal=1
 LEFT JOIN dbo.Titular t ON t.CUIT=x.CUIT;
GO
CREATE VIEW reporte.v_AdminSucursales AS
 SELECT s.*,c.Nombre Concesionaria,p.Nombre Provincia FROM dbo.Sucursal s
 JOIN dbo.Concesionaria c ON c.ConcesionariaId=s.ConcesionariaId JOIN dbo.Provincia p ON p.ProvinciaId=s.ProvinciaId;
GO
CREATE FUNCTION reporte.fn_TurnosPeriodo(@Desde date,@Hasta date)
RETURNS TABLE AS RETURN
 SELECT v.GestionId,COUNT_BIG(*) Cantidad FROM dbo.Turno t JOIN dbo.Vehiculo v ON v.Dominio=t.Dominio
 WHERE t.Fecha>=@Desde AND t.Fecha<@Hasta GROUP BY v.GestionId;
GO
