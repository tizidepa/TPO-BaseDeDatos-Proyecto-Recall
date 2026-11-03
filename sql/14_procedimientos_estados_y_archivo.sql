-- 14_procedimientos_estados_y_archivo: Implementar resultados, pausas, reactivación y archivo.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE api.sp_CargarResultado @Dominios dbo.ListaDominios READONLY,@Estado varchar(20) AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF seguridad.fn_EsAdmin()=0 THROW 51124,'Sólo un administrador global puede cargar resultados.',1;
 IF @Estado NOT IN ('facturado','realizado') THROW 51125,'Resultado inválido.',1;
 DECLARE @lote uniqueidentifier=NEWID();
 BEGIN TRY
 BEGIN TRAN; EXEC api.sp_Bloquear;
 INSERT carga.ErrorProceso(Lote,Proceso,Referencia,Mensaje)
 SELECT @lote,'resultados',d.Dominio,N'No existe vehículo o no tiene turno para aplicar el resultado.'
 FROM @Dominios d WHERE NOT EXISTS(SELECT 1 FROM dbo.Turno t WHERE t.Dominio=d.Dominio);
 ;WITH Ultimos AS(SELECT t.TurnoId,t.Estado,ROW_NUMBER() OVER(PARTITION BY t.Dominio ORDER BY t.FechaCreacion DESC,t.TurnoId DESC) rn
 FROM dbo.Turno t JOIN @Dominios d ON d.Dominio=t.Dominio)
 UPDATE t SET Estado=@Estado FROM dbo.Turno t JOIN Ultimos u ON u.TurnoId=t.TurnoId
 WHERE u.rn=1 AND u.Estado<>'realizado' AND u.Estado<>@Estado;
 COMMIT;
 SELECT @lote Lote,Referencia,Mensaje FROM carga.ErrorProceso WHERE Lote=@lote;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE PROCEDURE api.sp_CambiarEstadoVehiculos @Dominios dbo.ListaDominios READONLY,@Accion varchar(15) AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF seguridad.fn_EsAdmin()=0 THROW 51126,'Sólo un administrador global puede cargar cambios de estado.',1;
 IF @Accion NOT IN ('descartar','pausar','reactivar') THROW 51127,'Acción inválida.',1;
 BEGIN TRY
 BEGIN TRAN; EXEC api.sp_Bloquear;
 IF EXISTS(SELECT 1 FROM @Dominios d WHERE NOT EXISTS(SELECT 1 FROM dbo.Vehiculo v WHERE v.Dominio=d.Dominio))
 THROW 51128,'Hay dominios inexistentes.',1;
 IF @Accion='reactivar' AND EXISTS(SELECT 1 FROM dbo.Turno t JOIN @Dominios d ON d.Dominio=t.Dominio
 WHERE t.Estado IN ('preturno','creado')) THROW 51129,'Cancele el turno activo antes de reactivar el vehículo.',1;
 UPDATE v SET Estado=CASE @Accion WHEN 'descartar' THEN 'descartado' WHEN 'pausar' THEN 'pausado' ELSE 'pendiente' END
 FROM dbo.Vehiculo v JOIN @Dominios d ON d.Dominio=v.Dominio;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE PROCEDURE api.sp_EstadoRed @Entidad varchar(15),@Id int,@Activa bit AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF seguridad.fn_EsAdmin()=0 THROW 51130,'Sólo un administrador global puede cambiar la red.',1;
 IF @Entidad NOT IN ('gestion','marca','concesionaria','sucursal') THROW 51131,'Entidad inválida.',1;
 DECLARE @fecha datetime2(0)=IIF(@Activa=1,NULL,SYSUTCDATETIME()),@filas int=0;
 BEGIN TRY
 BEGIN TRAN; EXEC api.sp_Bloquear;
 IF @Entidad='gestion' BEGIN UPDATE dbo.Gestion SET Activa=@Activa,FechaPausa=@fecha WHERE GestionId=@Id; SET @filas=@@ROWCOUNT; END;
 IF @Entidad='marca' BEGIN UPDATE dbo.Marca SET Activa=@Activa,FechaPausa=@fecha WHERE MarcaId=@Id; SET @filas=@@ROWCOUNT; END;
 IF @Entidad='concesionaria' BEGIN UPDATE dbo.Concesionaria SET Activa=@Activa,FechaPausa=@fecha WHERE ConcesionariaId=@Id; SET @filas=@@ROWCOUNT; END;
 IF @Entidad='sucursal' BEGIN UPDATE dbo.Sucursal SET Activa=@Activa,FechaPausa=@fecha WHERE SucursalId=@Id; SET @filas=@@ROWCOUNT; END;
 IF @filas=0 THROW 51132,'Entidad inexistente.',1;
 -- Invalidar sugerencias: el recálculo a pedido vuelve a poblarlas. No modificar turnos existentes.
 DELETE FROM dbo.Top5;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE PROCEDURE api.sp_ArchivarLlamados @AnteriorA datetime2(0) AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF seguridad.fn_EsAdmin()=0 THROW 51133,'Sólo un administrador global puede archivar.',1;
 -- Archivo lógico: conserva integridad y contador. No promete liberar espacio físico.
 BEGIN TRY
 BEGIN TRAN; EXEC api.sp_Bloquear;
 UPDATE l SET Archivado=1 FROM dbo.Llamado l JOIN dbo.Vehiculo v ON v.Dominio=l.Dominio
 WHERE v.Estado='turno_realizado' AND l.Fecha<@AnteriorA AND l.Archivado=0;
 DECLARE @n int=@@ROWCOUNT; COMMIT; SELECT @n LlamadosArchivados;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
