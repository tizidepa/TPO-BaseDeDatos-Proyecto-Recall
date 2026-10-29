-- 05_tablas_usuarios_roles: Crear usuarios, roles y asignaciones.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE TABLE seguridad.Usuario(
 UsuarioId int IDENTITY CONSTRAINT PK_Usuario PRIMARY KEY,
 NombreBD sysname NOT NULL CONSTRAINT UQ_Usuario_NombreBD UNIQUE,
 Nombre nvarchar(100) NOT NULL, Activo bit NOT NULL CONSTRAINT DF_Usuario_Activo DEFAULT 1);
CREATE TABLE seguridad.Rol(
 RolId tinyint NOT NULL CONSTRAINT PK_Rol PRIMARY KEY,
 Nombre varchar(10) NOT NULL CONSTRAINT UQ_Rol_Nombre UNIQUE,
 CONSTRAINT CK_Rol_Nombre CHECK(Nombre IN ('Admin','Asesor','Viewer')));
CREATE TABLE seguridad.Asignacion(
 AsignacionId int IDENTITY CONSTRAINT PK_Asignacion PRIMARY KEY,
 UsuarioId int NOT NULL REFERENCES seguridad.Usuario(UsuarioId),
 RolId tinyint NOT NULL REFERENCES seguridad.Rol(RolId),
 GestionId int NULL REFERENCES dbo.Gestion(GestionId));
CREATE UNIQUE INDEX UX_Asignacion_Especifica ON seguridad.Asignacion(UsuarioId,RolId,GestionId) WHERE GestionId IS NOT NULL;
CREATE UNIQUE INDEX UX_Asignacion_Global ON seguridad.Asignacion(UsuarioId,RolId) WHERE GestionId IS NULL;
GO
