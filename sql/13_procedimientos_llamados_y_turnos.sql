-- 13_procedimientos_llamados_y_turnos: Implementar llamados, creación y reprogramación de turnos.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE api.sp_RegistrarLlamado
 @Dominio varchar(7),@CUIT varchar(11),@Telefono varchar(100),@Resultado varchar(12)
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
 BEGIN TRAN; EXEC api.sp_Bloquear;
 DECLARE @g int=(SELECT GestionId FROM dbo.Vehiculo WHERE Dominio=@Dominio),@n varchar(10)=dbo.fn_NormalizarCelular(@Telefono);
 IF @g IS NULL OR seguridad.fn_PuedeOperar(@g)=0 THROW 51112,'Vehículo inexistente o sin permiso de operación.',1;
 IF @n IS NULL THROW 51113,'Teléfono inválido o ambiguo.',1;
 INSERT dbo.Llamado(Dominio,CUIT,Numero,Resultado) VALUES(@Dominio,@CUIT,@n,@Resultado);
 DECLARE @id bigint=SCOPE_IDENTITY(); COMMIT; SELECT @id LlamadoId;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE PROCEDURE api.sp_CrearTurno
 @Dominio varchar(7),@SucursalId int,@Fecha date=NULL,@Hora time(0)=NULL,
 @Nombre nvarchar(100)=NULL,@Apellido nvarchar(100)=NULL,@Telefono varchar(100)=NULL
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
 BEGIN TRAN; EXEC api.sp_Bloquear;
 DECLARE @g int=(SELECT GestionId FROM dbo.Vehiculo WHERE Dominio=@Dominio),@u int;
 IF @g IS NULL OR seguridad.fn_PuedeOperar(@g)=0 THROW 51114,'Vehículo inexistente o sin permiso de operación.',1;
 SELECT @u=UsuarioId FROM seguridad.Usuario WHERE NombreBD=USER_NAME() AND Activo=1;
 IF @u IS NULL THROW 51115,'El usuario de base debe estar registrado y activo.',1;
 SELECT @Nombre=COALESCE(@Nombre,t.NombreRazonSocial),@Apellido=COALESCE(@Apellido,t.Apellido),
 @Telefono=COALESCE(@Telefono,(SELECT TOP(1) Numero FROM dbo.Telefono WHERE CUIT=t.CUIT AND Activo=1 ORDER BY Numero))
 FROM dbo.Titularidad x JOIN dbo.Titular t ON t.CUIT=x.CUIT
 WHERE x.Dominio=@Dominio AND x.Hasta IS NULL AND x.EsPrincipal=1 AND t.Tipo='P';
 DECLARE @n varchar(10)=dbo.fn_NormalizarCelular(@Telefono);
 IF NULLIF(LTRIM(RTRIM(@Nombre)),'') IS NULL OR NULLIF(LTRIM(RTRIM(@Apellido)),'') IS NULL OR @n IS NULL
 THROW 51116,'Faltan nombre, apellido o teléfono válido del asistente.',1;
 INSERT dbo.Turno(Dominio,SucursalId,UsuarioId,Fecha,Hora,Estado,NombreAsistente,ApellidoAsistente,TelefonoAsistente)
 VALUES(@Dominio,@SucursalId,@u,@Fecha,@Hora,IIF(@Fecha IS NULL,'preturno','creado'),@Nombre,@Apellido,@n);
 DECLARE @id bigint=SCOPE_IDENTITY(); COMMIT; SELECT @id TurnoId;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE PROCEDURE api.sp_ReprogramarTurno @TurnoId bigint,@Fecha date,@Hora time(0),@SucursalId int=NULL AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY
 BEGIN TRAN; EXEC api.sp_Bloquear;
 DECLARE @g int=(SELECT v.GestionId FROM dbo.Turno t JOIN dbo.Vehiculo v ON v.Dominio=t.Dominio WHERE t.TurnoId=@TurnoId);
 IF @g IS NULL OR seguridad.fn_PuedeOperar(@g)=0 THROW 51117,'Turno inexistente o sin permiso.',1;
 IF @Fecha IS NULL OR @Hora IS NULL THROW 51118,'Debe indicar fecha y hora.',1;
 UPDATE dbo.Turno SET Fecha=@Fecha,Hora=@Hora,SucursalId=COALESCE(@SucursalId,SucursalId)
 WHERE TurnoId=@TurnoId AND Estado IN ('preturno','creado');
 IF @@ROWCOUNT=0 THROW 51119,'Sólo se reprograman preturnos o turnos creados.',1;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE PROCEDURE api.sp_CerrarTurno @TurnoId bigint,@Estado varchar(20) AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @Estado NOT IN ('cancelado','no_se_presento') THROW 51120,'Use cancelado o no_se_presento; las reparaciones se cargan por lista.',1;
 BEGIN TRY
 BEGIN TRAN; EXEC api.sp_Bloquear;
 DECLARE @g int=(SELECT v.GestionId FROM dbo.Turno t JOIN dbo.Vehiculo v ON v.Dominio=t.Dominio WHERE t.TurnoId=@TurnoId);
 IF @g IS NULL OR seguridad.fn_PuedeOperar(@g)=0 THROW 51121,'Turno inexistente o sin permiso.',1;
 IF @Estado='no_se_presento' AND EXISTS(SELECT 1 FROM dbo.Turno WHERE TurnoId=@TurnoId AND
 (Fecha IS NULL OR DATEADD(second,DATEDIFF(second,CONVERT(time(0),'00:00'),Hora),CONVERT(datetime2(0),Fecha))>DATEADD(hour,-3,SYSUTCDATETIME())))
 THROW 51122,'No se puede marcar ausencia antes del turno o en un preturno.',1;
 UPDATE dbo.Turno SET Estado=@Estado WHERE TurnoId=@TurnoId AND Estado IN ('preturno','creado');
 IF @@ROWCOUNT=0 THROW 51123,'Sólo se cierran turnos activos.',1;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
