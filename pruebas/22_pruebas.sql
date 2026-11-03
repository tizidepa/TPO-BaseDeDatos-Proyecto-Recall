:ON ERROR EXIT
USE RecallsUADE;
GO
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
-- Ejecutar como dbo sobre los datos de demostración originales.
-- Cada caso revierte sus cambios. Las identidades pueden dejar huecos, lo cual es normal.
CREATE TABLE #Resultados(Caso nvarchar(160),Correcto bit,Detalle nvarchar(2048));
GO
CREATE PROCEDURE #Probar @Caso nvarchar(160),@SQL nvarchar(max),@ErrorEsperado int=NULL AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @error int=NULL,@detalle nvarchar(2048)=N'OK';
 BEGIN TRY
 BEGIN TRAN;
 EXEC sys.sp_executesql @SQL;
 IF USER_NAME()<>'dbo' REVERT;
 IF @@TRANCOUNT>0 ROLLBACK;
 END TRY BEGIN CATCH
 SET @error=ERROR_NUMBER(); SET @detalle=ERROR_MESSAGE();
 IF USER_NAME()<>'dbo' REVERT;
 IF @@TRANCOUNT>0 ROLLBACK;
 END CATCH;
 INSERT #Resultados VALUES(@Caso,
 CASE WHEN @ErrorEsperado IS NULL AND @error IS NULL THEN 1 WHEN @ErrorEsperado=@error THEN 1 ELSE 0 END,
 CONCAT('Esperado: ',COALESCE(CONVERT(varchar(12),@ErrorEsperado),'sin error'),'; obtenido: ',COALESCE(CONVERT(varchar(12),@error),'sin error'),'; ',@detalle));
END;
GO
EXEC #Probar N'01. CUIT, celular internacional y celular ambiguo',N'
 IF dbo.fn_CUITValido(''20123456786'')<>1 THROW 51999,''CUIT válido rechazado.'',1;
 IF dbo.fn_CUITValido(''20123456780'')<>0 THROW 51999,''CUIT inválido aceptado.'',1;
 IF dbo.fn_NormalizarCelular(''+54 9 11 5555-0001'')<>''1155550001'' THROW 51999,''Normalización incorrecta.'',1;
 IF dbo.fn_NormalizarCelular(''1537668202'') IS NOT NULL THROW 51999,''Se aceptó un teléfono ambiguo.'',1;';
EXEC #Probar N'02. Dominio inválido',N'EXEC api.sp_AltaVehiculo ''1234567'',N''Demo'',1,1;',547;
EXEC #Probar N'03. Marca ajena a la gestión',N'EXEC api.sp_AltaVehiculo ''ZZ999ZZ'',N''Demo'',1,3;',547;
EXEC #Probar N'04. Un solo titular principal vigente',N'
 UPDATE dbo.Titularidad SET EsPrincipal=1 WHERE Dominio=''AA001AA'' AND EsPrincipal=0;',2601;
EXEC #Probar N'05. Períodos de titularidad sin superposición',N'
 INSERT dbo.Titularidad(Dominio,CUIT,Desde,Hasta,EsPrincipal)
 SELECT Dominio,CUIT,DATEADD(day,-5,Desde),DATEADD(day,5,Desde),0 FROM dbo.Titularidad
 WHERE Dominio=''AA002AA'' AND Hasta IS NULL;',51003;
EXEC #Probar N'06. Máximo de cinco teléfonos activos',N'
 DECLARE @c varchar(11)=(SELECT CUIT FROM dbo.Titularidad WHERE Dominio=''AA002AA'' AND EsPrincipal=1 AND Hasta IS NULL);
 INSERT dbo.Telefono(CUIT,Numero) SELECT @c,n FROM(VALUES(''1166600001''),(''1166600002''),(''1166600003''),(''1166600004''),(''1166600005''))x(n);',51004;
EXEC #Probar N'07. No borrar concesionarias',N'DELETE dbo.Concesionaria WHERE ConcesionariaId=1;',51005;
EXEC #Probar N'08. No borrar sucursales',N'DELETE dbo.Sucursal WHERE SucursalId=1;',51006;
EXEC #Probar N'09. Horarios partidos sin solapamiento',N'
 INSERT dbo.Horario VALUES(1,1,''12:00'',''15:00'');',51002;
EXEC #Probar N'10. Preturno bloquea otro turno',N'
 EXEC api.sp_CrearTurno ''AA002AA'',1;',2601;
EXEC #Probar N'11. Asignar fecha al preturno no cuenta como reprogramar',N'
 DECLARE @t bigint=(SELECT TurnoId FROM dbo.Turno WHERE Dominio=''AA002AA'');
 DECLARE @f date=(SELECT Fecha FROM dbo.Turno WHERE Dominio=''AA001AA'');
 EXEC api.sp_ReprogramarTurno @t,@f,''11:30'';
 IF NOT EXISTS(SELECT 1 FROM dbo.Turno WHERE TurnoId=@t AND Estado=''creado'' AND Reprogramaciones=0)
 THROW 51999,''No se convirtió el preturno.'',1;';
EXEC #Probar N'12. Cambio de hora suma una reprogramación',N'
 DECLARE @t bigint=(SELECT TurnoId FROM dbo.Turno WHERE Dominio=''AA001AA''),@f date;
 SELECT @f=Fecha FROM dbo.Turno WHERE TurnoId=@t;
 EXEC api.sp_ReprogramarTurno @t,@f,''12:00'';
 IF NOT EXISTS(SELECT 1 FROM dbo.Turno WHERE TurnoId=@t AND Reprogramaciones=1 AND FechaReprogramacion IS NOT NULL)
 THROW 51999,''No se registró la reprogramación.'',1;';
EXEC #Probar N'13. Capacidad simultánea',N'
 DECLARE @f date=(SELECT Fecha FROM dbo.Turno WHERE Dominio=''AA001AA'');
 EXEC api.sp_CrearTurno ''AA013AA'',2,@f,''12:00'';
 EXEC api.sp_CrearTurno ''AA014AA'',2,@f,''12:00'';',51012;
EXEC #Probar N'14. Máximo mensual',N'
 DECLARE @f date=(SELECT Fecha FROM dbo.Turno WHERE Dominio=''AA001AA'');
 EXEC api.sp_CrearTurno ''AA013AA'',8,@f,''12:00'';
 EXEC api.sp_CrearTurno ''AA014AA'',8,@f,''12:30'';',51013;
EXEC #Probar N'15. Franjas de treinta minutos',N'
 DECLARE @f date=(SELECT Fecha FROM dbo.Turno WHERE Dominio=''AA001AA'');
 EXEC api.sp_CrearTurno ''AA013AA'',2,@f,''12:15'';',547;
EXEC #Probar N'16. Rechazar turno durante el cierre del mediodía',N'
 DECLARE @f date=(SELECT Fecha FROM dbo.Turno WHERE Dominio=''AA001AA'');
 EXEC api.sp_CrearTurno ''AA013AA'',2,@f,''13:00'';',51011;
EXEC #Probar N'17. Pausar sucursal mantiene los turnos',N'
 EXEC api.sp_EstadoRed ''sucursal'',1,0;
 IF NOT EXISTS(SELECT 1 FROM dbo.Turno WHERE Dominio=''AA001AA'' AND Estado=''creado'') THROW 51999,''Se alteró un turno existente.'',1;
 IF EXISTS(SELECT 1 FROM dbo.Top5) THROW 51999,''No se invalidaron las sugerencias.'',1;';
EXEC #Probar N'18. No crear turno en sucursal pausada',N'
 EXEC api.sp_EstadoRed ''sucursal'',2,0;
 EXEC api.sp_CrearTurno ''AA013AA'',2;',51010;
EXEC #Probar N'19. No atender una marca ajena',N'EXEC api.sp_CrearTurno ''AA017AA'',3;',51010;
EXEC #Probar N'20. No agendar empresas',N'EXEC api.sp_CrearTurno ''AA010AA'',1,NULL,NULL,N''Persona'',N''Demo'',''1155550099'';',51010;
EXEC #Probar N'21. Llamado efectivo sólo actualiza su vehículo',N'
 DECLARE @c varchar(11)=(SELECT CUIT FROM dbo.Titularidad WHERE Dominio=''AA013AA'' AND EsPrincipal=1 AND Hasta IS NULL);
 EXEC api.sp_RegistrarLlamado ''AA013AA'',@c,''1155550001'',''efectivo'';
 IF (SELECT Estado FROM dbo.Vehiculo WHERE Dominio=''AA013AA'')<>''trabajando'' THROW 51999,''No cambió el vehículo llamado.'',1;
 IF (SELECT Estado FROM dbo.Vehiculo WHERE Dominio=''AA001AA'')<>''turno'' THROW 51999,''Se alteró otro vehículo del titular.'',1;';
EXEC #Probar N'22. Trigger de intentos soporta inserción de varias filas',N'
 DECLARE @c varchar(11)=(SELECT CUIT FROM dbo.Titularidad WHERE Dominio=''AA013AA'' AND EsPrincipal=1 AND Hasta IS NULL);
 DECLARE @n bigint=(SELECT Intentos FROM dbo.Titular WHERE CUIT=@c);
 INSERT dbo.Llamado(Dominio,CUIT,Numero,Resultado) VALUES(''AA013AA'',@c,''1155550001'',''no_efectivo''),(''AA013AA'',@c,''1155550001'',''no_efectivo'');
 IF (SELECT Intentos FROM dbo.Titular WHERE CUIT=@c)<>@n+2 THROW 51999,''Contador incorrecto.'',1;';
EXEC #Probar N'23. Rechazar llamado a dominio descartado',N'
 DECLARE @c varchar(11)=(SELECT CUIT FROM dbo.Titularidad WHERE Dominio=''AA008AA'' AND EsPrincipal=1 AND Hasta IS NULL);
 EXEC api.sp_RegistrarLlamado ''AA008AA'',@c,''1155550008'',''efectivo'';',51007;
EXEC #Probar N'24. Facturado y realizado cierran vehículo',N'
 IF EXISTS(SELECT 1 FROM dbo.Vehiculo WHERE Dominio IN(''AA003AA'',''AA004AA'') AND Estado<>''turno_realizado'')
 THROW 51999,''La reparación no cerró el vehículo.'',1;';
EXEC #Probar N'25. Carga tardía facturado no hace retroceder realizado',N'
 DECLARE @l dbo.ListaDominios; INSERT @l VALUES(''AA004AA''); EXEC api.sp_CargarResultado @l,''facturado'';
 IF (SELECT Estado FROM dbo.Turno WHERE Dominio=''AA004AA'')<>''realizado'' THROW 51999,''Retrocedió el estado.'',1;';
EXEC #Probar N'26. Trigger impide retroceso directo',N'UPDATE dbo.Turno SET Estado=''creado'' WHERE Dominio=''AA004AA'';',51009;
EXEC #Probar N'27. Reactivación conserva turnos anteriores',N'
 DECLARE @n int=(SELECT COUNT(*) FROM dbo.Turno WHERE Dominio=''AA004AA'');
 DECLARE @l dbo.ListaDominios; INSERT @l VALUES(''AA004AA''); EXEC api.sp_CambiarEstadoVehiculos @l,''reactivar'';
 IF (SELECT Estado FROM dbo.Vehiculo WHERE Dominio=''AA004AA'')<>''pendiente'' OR
 (SELECT COUNT(*) FROM dbo.Turno WHERE Dominio=''AA004AA'')<>@n THROW 51999,''Reactivación incorrecta.'',1;';
EXEC #Probar N'28. No reactivar con preturno pendiente',N'
 DECLARE @l dbo.ListaDominios; INSERT @l VALUES(''AA002AA''); EXEC api.sp_CambiarEstadoVehiculos @l,''reactivar'';',51129;
EXEC #Probar N'29. TOP5 respeta provincia, marca, principal y máximo cinco',N'
 EXEC api.sp_CalcularTop5;
 IF EXISTS(SELECT Dominio FROM dbo.Top5 GROUP BY Dominio HAVING COUNT(*)>5) THROW 51999,''Más de cinco sugerencias.'',1;
 IF EXISTS(SELECT 1 FROM dbo.Top5 a JOIN dbo.Vehiculo v ON v.Dominio=a.Dominio JOIN dbo.Titular t ON t.CUIT=a.CUITPrincipal
 JOIN dbo.Sucursal s ON s.SucursalId=a.SucursalId WHERE t.ProvinciaId<>s.ProvinciaId OR t.Tipo<>''P''
 OR NOT EXISTS(SELECT 1 FROM dbo.SucursalMarca sm WHERE sm.SucursalId=s.SucursalId AND sm.MarcaId=v.MarcaId))
 THROW 51999,''Sugerencia inválida.'',1;
 IF EXISTS(SELECT 1 FROM dbo.Top5 WHERE Dominio=''AA011AA'') THROW 51999,''Se calculó sin coordenadas.'',1;';
EXEC #Probar N'30. Discador excluye empresa, distancia y estados bloqueados',N'
 IF EXISTS(SELECT 1 FROM reporte.v_AdminDiscador WHERE Dominio IN(''AA007AA'',''AA008AA'',''AA009AA'',''AA010AA''))
 THROW 51999,''El discador incluye un vehículo apartado.'',1;';
EXEC #Probar N'31. Viewer limitado a su gestión',N'
 EXECUTE AS USER=''demo_viewer'';
 IF NOT EXISTS(SELECT 1 FROM reporte.v_PendientesRealizados WHERE GestionId=1) THROW 51999,''Falta su gestión.'',1;
 IF EXISTS(SELECT 1 FROM reporte.v_PendientesRealizados WHERE GestionId<>1) THROW 51999,''Filtración de otra gestión.'',1;
 REVERT;';
EXEC #Probar N'32. Viewer Toyota no ve Stellantis',N'
 EXECUTE AS USER=''demo_viewer_toyota'';
 IF EXISTS(SELECT 1 FROM reporte.v_PendientesRealizados WHERE GestionId<>2) THROW 51999,''Filtración de otra gestión.'',1;
 REVERT;';
EXEC #Probar N'33. Viewer sin acceso a datos personales',N'EXECUTE AS USER=''demo_viewer''; SELECT * FROM reporte.v_AdminDiscador;',229;
EXEC #Probar N'34. Viewer sin acceso a tablas base',N'EXECUTE AS USER=''demo_viewer''; SELECT * FROM dbo.Vehiculo;',229;
EXEC #Probar N'35. Viewer sin permiso de crear turnos',N'EXECUTE AS USER=''demo_viewer''; EXEC api.sp_CrearTurno ''AA013AA'',1;',229;
EXEC #Probar N'36. Asesor no opera otra gestión',N'EXECUTE AS USER=''demo_asesor''; EXEC api.sp_CrearTurno ''AA017AA'',1;',51114;
EXEC #Probar N'37. Asesor crea turno en su gestión',N'
 EXECUTE AS USER=''demo_asesor''; EXEC api.sp_CrearTurno ''AA013AA'',2; REVERT;
 IF NOT EXISTS(SELECT 1 FROM dbo.Turno t JOIN seguridad.Usuario u ON u.UsuarioId=t.UsuarioId
 WHERE t.Dominio=''AA013AA'' AND u.NombreBD=''demo_asesor'') THROW 51999,''Autoría incorrecta.'',1;';
EXEC #Probar N'38. Asesor no ve desglose facturado/realizado',N'EXECUTE AS USER=''demo_asesor''; SELECT * FROM reporte.v_AdminTurnosEstado;',229;
EXEC #Probar N'39. Admin accede a todas las gestiones',N'
 EXECUTE AS USER=''demo_admin'';
 IF (SELECT COUNT(*) FROM reporte.v_PendientesRealizados)<>2 THROW 51999,''Admin no ve todas las gestiones.'',1;
 SELECT TOP(1) Dominio FROM reporte.v_AdminVehiculos; REVERT;';
EXEC #Probar N'40. Carga sin turno produce error individual',N'
 DECLARE @l dbo.ListaDominios; INSERT @l VALUES(''AA013AA''); EXEC api.sp_CargarResultado @l,''realizado'';
 IF NOT EXISTS(SELECT 1 FROM carga.ErrorProceso WHERE Proceso=''resultados'' AND Referencia=''AA013AA'')
 THROW 51999,''No se informó el rechazo.'',1;';
EXEC #Probar N'41. Cambio de titular principal invalida TOP5',N'
 DECLARE @a dbo.ListaDominios,@p dbo.Padron;
 INSERT @a VALUES(''AA001AA'');
 INSERT @p SELECT Dominio,CUIT,IIF(EsPrincipal=1,0,1) FROM dbo.Titularidad WHERE Dominio=''AA001AA'' AND Hasta IS NULL;
 EXEC api.sp_ActualizarPadron 1,@a,@p;
 IF EXISTS(SELECT 1 FROM dbo.Top5 WHERE Dominio=''AA001AA'') THROW 51999,''TOP5 obsoleto.'',1;
 IF (SELECT COUNT(*) FROM dbo.Titularidad WHERE Dominio=''AA001AA'' AND Hasta IS NULL AND EsPrincipal=1)<>1
 THROW 51999,''Principal incorrecto.'',1;';
EXEC #Probar N'42. Archivo lógico conserva el total de intentos',N'
 DECLARE @c varchar(11)=(SELECT CUIT FROM dbo.Titularidad WHERE Dominio=''AA013AA'' AND Hasta IS NULL AND EsPrincipal=1);
 EXEC api.sp_RegistrarLlamado ''AA013AA'',@c,''1155550001'',''efectivo'';
 EXEC api.sp_CrearTurno ''AA013AA'',1;
 DECLARE @l dbo.ListaDominios; INSERT @l VALUES(''AA013AA''); EXEC api.sp_CargarResultado @l,''realizado'';
 DECLARE @n bigint=(SELECT SUM(Intentos) FROM dbo.Titular);
 DECLARE @f datetime2(0)=DATEADD(day,1,SYSUTCDATETIME()); EXEC api.sp_ArchivarLlamados @f;
 IF (SELECT SUM(Intentos) FROM dbo.Titular)<>@n THROW 51999,''El archivo cambió el contador.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Llamado WHERE Dominio=''AA013AA'' AND Archivado=1) THROW 51999,''No se archivó el llamado.'',1;';
EXEC #Probar N'43. Un teléfono demasiado largo se rechaza sin abortar el lote',N'
 DECLARE @l uniqueidentifier=NEWID(),@c varchar(11)=(SELECT CUIT FROM dbo.Titularidad WHERE Dominio=''AA013AA'' AND Hasta IS NULL AND EsPrincipal=1);
 INSERT carga.TelefonoStaging(Lote,CUIT,Telefono1,Telefono2) VALUES(@l,@c,REPLICATE(''9'',100),''1166699999'');
 EXEC api.sp_CargarTelefonos @l;
 IF NOT EXISTS(SELECT 1 FROM carga.ErrorProceso WHERE Lote=@l AND Proceso=''telefonos'') THROW 51999,''No se registró el rechazo.'',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.Telefono WHERE CUIT=@c AND Numero=''1166699999'') THROW 51999,''Se perdió el teléfono válido.'',1;';
GO
SELECT Caso,Correcto,Detalle FROM #Resultados ORDER BY Caso;
SELECT COUNT(*) Casos,SUM(CONVERT(int,Correcto)) Correctos,SUM(IIF(Correcto=0,1,0)) Fallidos FROM #Resultados;
IF EXISTS(SELECT 1 FROM #Resultados WHERE Correcto=0) THROW 51998,'Hay pruebas fallidas. Revisar el detalle.',1;
PRINT N'Todas las pruebas pasaron.';
GO
