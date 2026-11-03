-- 09_tipos_seguridad_y_bloqueo: Crear tipos de listas, filtro por gestión y bloqueo auxiliar.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE TYPE dbo.ListaDominios AS TABLE(Dominio varchar(7) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
GO
CREATE TYPE dbo.Padron AS TABLE(
 Dominio varchar(7) COLLATE Latin1_General_100_BIN2 NOT NULL,
 CUIT varchar(11) NOT NULL, EsPrincipal bit NOT NULL, PRIMARY KEY(Dominio,CUIT));
GO
CREATE FUNCTION seguridad.fn_AccesoGestion(@GestionId int)
RETURNS TABLE WITH SCHEMABINDING AS RETURN
 SELECT 1 AS Permitido WHERE USER_NAME()='dbo' OR EXISTS(
 SELECT 1 FROM seguridad.Usuario u JOIN seguridad.Asignacion a ON a.UsuarioId=u.UsuarioId
 WHERE u.NombreBD=USER_NAME() AND u.Activo=1 AND (a.GestionId=@GestionId OR a.GestionId IS NULL));
GO
CREATE FUNCTION seguridad.fn_PuedeOperar(@GestionId int) RETURNS bit
AS BEGIN
 RETURN IIF(USER_NAME()='dbo' OR EXISTS(SELECT 1 FROM seguridad.Usuario u
 JOIN seguridad.Asignacion a ON a.UsuarioId=u.UsuarioId JOIN seguridad.Rol r ON r.RolId=a.RolId
 WHERE u.NombreBD=USER_NAME() AND u.Activo=1 AND r.Nombre IN ('Admin','Asesor')
 AND (a.GestionId=@GestionId OR a.GestionId IS NULL)),1,0);
END;
GO
CREATE FUNCTION seguridad.fn_EsAdmin() RETURNS bit
AS BEGIN
 RETURN IIF(USER_NAME()='dbo' OR EXISTS(SELECT 1 FROM seguridad.Usuario u
 JOIN seguridad.Asignacion a ON a.UsuarioId=u.UsuarioId JOIN seguridad.Rol r ON r.RolId=a.RolId
 WHERE u.NombreBD=USER_NAME() AND u.Activo=1 AND r.Nombre='Admin' AND a.GestionId IS NULL),1,0);
END;
GO
CREATE SECURITY POLICY seguridad.FiltroGestion
 ADD FILTER PREDICATE seguridad.fn_AccesoGestion(GestionId) ON dbo.Vehiculo,
 ADD BLOCK PREDICATE seguridad.fn_AccesoGestion(GestionId) ON dbo.Vehiculo AFTER INSERT,
 ADD BLOCK PREDICATE seguridad.fn_AccesoGestion(GestionId) ON dbo.Vehiculo AFTER UPDATE,
 ADD FILTER PREDICATE seguridad.fn_AccesoGestion(GestionId) ON dbo.Gestion
 WITH(STATE=ON);
GO
CREATE PROCEDURE api.sp_Bloquear AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @r int;
 EXEC @r=sys.sp_getapplock @Resource='Recalls:Escritura',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
 IF @r<0 THROW 51001,'No se pudo obtener el bloqueo de operación. Reintente.',1;
END;
GO
