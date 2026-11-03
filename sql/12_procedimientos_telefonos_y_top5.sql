-- 12_procedimientos_telefonos_y_top5: Implementar carga de teléfonos con cursor y cálculo TOP5.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE api.sp_CargarTelefonos @Lote uniqueidentifier AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF seguridad.fn_EsAdmin()=0 THROW 51109,'Sólo un administrador global puede cargar teléfonos.',1;
 DECLARE @cuit varchar(20),@raw varchar(100),@wa bit,@numero varchar(10),@error nvarchar(2048);
 BEGIN TRY
 BEGIN TRAN; EXEC api.sp_Bloquear;
 -- Cursor justificado: validación por ítem, cupo de cinco y rechazo individual sin perder el lote.
 -- La importación de Excel queda en staging; la transformación y las decisiones están en SQL.
 DECLARE telefonos CURSOR LOCAL FAST_FORWARD FOR
 SELECT s.CUIT,x.Numero,x.WA FROM carga.TelefonoStaging s
 CROSS APPLY(VALUES(1,s.Telefono1,s.WhatsApp1),(2,s.Telefono2,s.WhatsApp2),(3,s.Telefono3,s.WhatsApp3),
 (4,s.Telefono4,s.WhatsApp4),(5,s.Telefono5,s.WhatsApp5))x(Posicion,Numero,WA)
 WHERE s.Lote=@Lote AND s.Procesado=0 AND NULLIF(LTRIM(RTRIM(x.Numero)),'') IS NOT NULL
 ORDER BY s.FilaId,x.Posicion;
 OPEN telefonos; FETCH NEXT FROM telefonos INTO @cuit,@raw,@wa;
 WHILE @@FETCH_STATUS=0 BEGIN
 SET @numero=dbo.fn_NormalizarCelular(@raw); SET @error=NULL;
 IF NOT EXISTS(SELECT 1 FROM dbo.Titular WHERE CUIT=@cuit) SET @error=N'Titular inexistente.';
 ELSE IF @numero IS NULL SET @error=N'Número inválido o ambiguo: corregir código de área/prefijo 15 en origen.';
 ELSE IF NOT EXISTS(SELECT 1 FROM dbo.Telefono WHERE CUIT=@cuit AND Numero=@numero AND Activo=1)
 AND (SELECT COUNT(*) FROM dbo.Telefono WHERE CUIT=@cuit AND Activo=1)>=5 SET @error=N'Se exceden cinco teléfonos activos.';
 IF @error IS NOT NULL INSERT carga.ErrorProceso(Lote,Proceso,Referencia,Mensaje)
 VALUES(@Lote,'telefonos',LEFT(CONCAT(@cuit,' / ',@raw),100),@error);
 ELSE IF EXISTS(SELECT 1 FROM dbo.Telefono WHERE CUIT=@cuit AND Numero=@numero)
 UPDATE dbo.Telefono SET Activo=1,WhatsApp=COALESCE(@wa,WhatsApp) WHERE CUIT=@cuit AND Numero=@numero;
 ELSE INSERT dbo.Telefono(CUIT,Numero,WhatsApp) VALUES(@cuit,@numero,@wa);
 FETCH NEXT FROM telefonos INTO @cuit,@raw,@wa;
 END;
 CLOSE telefonos; DEALLOCATE telefonos;
 UPDATE carga.TelefonoStaging SET Procesado=1 WHERE Lote=@Lote AND Procesado=0;
 COMMIT;
 SELECT ErrorId,Referencia,Mensaje FROM carga.ErrorProceso WHERE Lote=@Lote AND Proceso='telefonos';
 END TRY BEGIN CATCH
 IF CURSOR_STATUS('local','telefonos')>=0 CLOSE telefonos;
 IF CURSOR_STATUS('local','telefonos')>=-1 DEALLOCATE telefonos;
 IF @@TRANCOUNT>0 ROLLBACK; THROW;
 END CATCH;
END;
GO
CREATE PROCEDURE api.sp_CalcularTop5 @GestionId int=NULL AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF seguridad.fn_EsAdmin()=0 THROW 51110,'Sólo un administrador global puede recalcular TOP5.',1;
 DECLARE @lote uniqueidentifier=NEWID();
 BEGIN TRY
 BEGIN TRAN; EXEC api.sp_Bloquear;
 IF @GestionId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.Gestion WHERE GestionId=@GestionId)
 THROW 51111,'Gestión inexistente.',1;
 DELETE t FROM dbo.Top5 t JOIN dbo.Vehiculo v ON v.Dominio=t.Dominio WHERE @GestionId IS NULL OR v.GestionId=@GestionId;
 INSERT carga.ErrorProceso(Lote,Proceso,Referencia,Mensaje)
 SELECT @lote,'top5',v.Dominio,N'Falta titular principal vigente o coordenadas del titular.'
 FROM dbo.Vehiculo v LEFT JOIN dbo.Titularidad x ON x.Dominio=v.Dominio AND x.Hasta IS NULL AND x.EsPrincipal=1
 LEFT JOIN dbo.Titular t ON t.CUIT=x.CUIT WHERE (@GestionId IS NULL OR v.GestionId=@GestionId)
 AND (x.CUIT IS NULL OR (t.Tipo='P' AND t.Latitud IS NULL));
 INSERT carga.ErrorProceso(Lote,Proceso,Referencia,Mensaje)
 SELECT @lote,'top5',CONVERT(nvarchar(100),s.SucursalId),N'Sucursal activa sin coordenadas; excluida del cálculo.'
 FROM dbo.Sucursal s JOIN dbo.Concesionaria c ON c.ConcesionariaId=s.ConcesionariaId
 WHERE s.Activa=1 AND c.Activa=1 AND s.Latitud IS NULL AND EXISTS(
 SELECT 1 FROM dbo.GestionConcesionaria gc WHERE gc.ConcesionariaId=c.ConcesionariaId
 AND (@GestionId IS NULL OR gc.GestionId=@GestionId));
 ;WITH Candidatas AS(
 SELECT v.Dominio,s.SucursalId,t.CUIT,
 dbo.fn_DistanciaKm(t.Latitud,t.Longitud,s.Latitud,s.Longitud) Km
 FROM dbo.Vehiculo v JOIN dbo.Gestion g ON g.GestionId=v.GestionId
 JOIN dbo.Marca m ON m.MarcaId=v.MarcaId
 JOIN dbo.Titularidad x ON x.Dominio=v.Dominio AND x.Hasta IS NULL AND x.EsPrincipal=1
 JOIN dbo.Titular t ON t.CUIT=x.CUIT AND t.Tipo='P' AND t.Latitud IS NOT NULL
 JOIN dbo.Sucursal s ON s.ProvinciaId=t.ProvinciaId AND s.Activa=1 AND s.Latitud IS NOT NULL
 JOIN dbo.Concesionaria c ON c.ConcesionariaId=s.ConcesionariaId AND c.Activa=1
 JOIN dbo.SucursalMarca sm ON sm.SucursalId=s.SucursalId AND sm.MarcaId=v.MarcaId
 JOIN dbo.GestionConcesionaria gc ON gc.GestionId=v.GestionId AND gc.ConcesionariaId=c.ConcesionariaId
 WHERE (@GestionId IS NULL OR v.GestionId=@GestionId) AND g.Activa=1 AND m.Activa=1),
 Ordenadas AS(SELECT *,ROW_NUMBER() OVER(PARTITION BY Dominio ORDER BY Km,SucursalId) Posicion FROM Candidatas)
 INSERT dbo.Top5(Dominio,Posicion,SucursalId,CUITPrincipal,Km)
 SELECT Dominio,CONVERT(tinyint,Posicion),SucursalId,CUIT,Km FROM Ordenadas WHERE Posicion<=5;
 COMMIT;
 SELECT @lote Lote,ErrorId,Referencia,Mensaje FROM carga.ErrorProceso WHERE Lote=@lote;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
