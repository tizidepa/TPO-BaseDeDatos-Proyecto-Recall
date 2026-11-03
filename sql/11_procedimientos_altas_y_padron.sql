-- 11_procedimientos_altas_y_padron: Implementar altas y actualización del padrón.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE api.sp_AltaTitular
 @CUIT varchar(11),@Nombre nvarchar(150),@Apellido nvarchar(100),@ProvinciaId smallint,
 @Domicilio nvarchar(200),@Latitud decimal(9,6)=NULL,@Longitud decimal(9,6)=NULL
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF seguridad.fn_EsAdmin()=0 THROW 51100,'Sólo un administrador global puede cargar titulares.',1;
 BEGIN TRY
 BEGIN TRAN; EXEC api.sp_Bloquear;
 INSERT dbo.Titular(CUIT,NombreRazonSocial,Apellido,ProvinciaId,Domicilio,Latitud,Longitud)
 VALUES(@CUIT,@Nombre,@Apellido,@ProvinciaId,@Domicilio,@Latitud,@Longitud);
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE PROCEDURE api.sp_AltaVehiculo
 @Dominio varchar(7),@Modelo nvarchar(100),@GestionId int,@MarcaId int,@VIN varchar(17)=NULL
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF seguridad.fn_EsAdmin()=0 THROW 51101,'Sólo un administrador global puede cargar vehículos.',1;
 BEGIN TRY
 BEGIN TRAN; EXEC api.sp_Bloquear;
 INSERT dbo.Vehiculo(Dominio,Modelo,GestionId,MarcaId,VIN) VALUES(@Dominio,@Modelo,@GestionId,@MarcaId,@VIN);
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
CREATE PROCEDURE api.sp_ActualizarPadron
 @GestionId int,@Alcance dbo.ListaDominios READONLY,@Datos dbo.Padron READONLY,
 @Fecha datetime2(0)=NULL
AS BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF seguridad.fn_EsAdmin()=0 THROW 51102,'Sólo un administrador global puede actualizar el padrón.',1;
 SET @Fecha=COALESCE(@Fecha,SYSUTCDATETIME());
 IF @Fecha>CONVERT(datetime2(0),SYSUTCDATETIME()) THROW 51103,'La fecha del padrón no puede ser futura.',1;
 BEGIN TRY
 BEGIN TRAN; EXEC api.sp_Bloquear;
 IF EXISTS(SELECT 1 FROM @Alcance a LEFT JOIN dbo.Vehiculo v ON v.Dominio=a.Dominio
 WHERE v.Dominio IS NULL OR v.GestionId<>@GestionId)
 THROW 51104,'El alcance contiene vehículos inexistentes o de otra gestión.',1;
 IF EXISTS(SELECT 1 FROM @Datos d WHERE NOT EXISTS(SELECT 1 FROM @Alcance a WHERE a.Dominio=d.Dominio))
 THROW 51105,'El padrón contiene vehículos fuera del alcance explícito.',1;
 IF EXISTS(SELECT 1 FROM @Datos d WHERE NOT EXISTS(SELECT 1 FROM dbo.Titular t WHERE t.CUIT=d.CUIT))
 THROW 51106,'Primero deben cargarse los titulares del padrón.',1;
 IF EXISTS(SELECT Dominio FROM @Datos GROUP BY Dominio HAVING SUM(CONVERT(int,EsPrincipal))<>1)
 THROW 51107,'Cada vehículo con titulares debe tener exactamente un principal.',1;
 IF EXISTS(SELECT 1 FROM dbo.Titularidad t JOIN @Alcance a ON a.Dominio=t.Dominio
 WHERE t.Hasta IS NULL AND t.Desde>=@Fecha)
 THROW 51108,'La fecha de actualización debe ser posterior al inicio de las titularidades vigentes.',1;
 -- Sólo se cierran ausencias dentro de @Alcance: una carga parcial no afecta otros vehículos.
 UPDATE t SET Hasta=@Fecha,EsPrincipal=0 FROM dbo.Titularidad t JOIN @Alcance a ON a.Dominio=t.Dominio
 WHERE t.Hasta IS NULL AND NOT EXISTS(SELECT 1 FROM @Datos d WHERE d.Dominio=t.Dominio AND d.CUIT=t.CUIT);
 UPDATE t SET EsPrincipal=0 FROM dbo.Titularidad t JOIN @Alcance a ON a.Dominio=t.Dominio WHERE t.Hasta IS NULL;
 INSERT dbo.Titularidad(Dominio,CUIT,Desde,EsPrincipal)
 SELECT d.Dominio,d.CUIT,@Fecha,0 FROM @Datos d
 WHERE NOT EXISTS(SELECT 1 FROM dbo.Titularidad t WHERE t.Dominio=d.Dominio AND t.CUIT=d.CUIT AND t.Hasta IS NULL);
 UPDATE t SET EsPrincipal=d.EsPrincipal FROM dbo.Titularidad t JOIN @Datos d ON d.Dominio=t.Dominio AND d.CUIT=t.CUIT
 WHERE t.Hasta IS NULL;
 COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;
END;
GO
