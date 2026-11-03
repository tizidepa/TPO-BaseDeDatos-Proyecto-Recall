-- 18_usuarios_demo_y_asignaciones: Crear cuentas de prueba y sus asignaciones.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
INSERT seguridad.Rol VALUES(1,'Admin'),(2,'Asesor'),(3,'Viewer');
CREATE ROLE rol_recalls_admin AUTHORIZATION dbo;
CREATE ROLE rol_recalls_asesor AUTHORIZATION dbo;
CREATE ROLE rol_recalls_viewer AUTHORIZATION dbo;
CREATE USER demo_admin WITHOUT LOGIN;
CREATE USER demo_asesor WITHOUT LOGIN;
CREATE USER demo_viewer WITHOUT LOGIN;
CREATE USER demo_viewer_toyota WITHOUT LOGIN;
ALTER ROLE rol_recalls_admin ADD MEMBER demo_admin;
ALTER ROLE rol_recalls_asesor ADD MEMBER demo_asesor;
ALTER ROLE rol_recalls_viewer ADD MEMBER demo_viewer;
ALTER ROLE rol_recalls_viewer ADD MEMBER demo_viewer_toyota;
INSERT seguridad.Usuario(NombreBD,Nombre) VALUES
('dbo',N'Instalador'),('demo_admin',N'Admin demo'),('demo_asesor',N'Asesor demo'),('demo_viewer',N'Viewer Stellantis'),('demo_viewer_toyota',N'Viewer Toyota');
INSERT seguridad.Asignacion(UsuarioId,RolId,GestionId) VALUES(1,1,NULL),(2,1,NULL),(3,2,1),(4,3,1),(5,3,2);
GO
