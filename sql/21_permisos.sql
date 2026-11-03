-- 21_permisos: Otorgar permisos a Admin, Asesor y Viewer.
-- Ejecutar después de todos los archivos con número menor. Modo SQLCMD.
:ON ERROR EXIT
USE RecallsUADE;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
-- Seguridad: sin db_datareader, db_datawriter ni DML sobre tablas operativas.
GRANT SELECT ON reporte.v_PendientesRealizados TO rol_recalls_admin;
GRANT SELECT ON reporte.v_PendientesProvincia TO rol_recalls_admin;
GRANT SELECT ON reporte.v_PersonasEmpresas TO rol_recalls_admin;
GRANT SELECT ON reporte.v_Distancias TO rol_recalls_admin;
GRANT SELECT ON reporte.v_SucursalesProvincia TO rol_recalls_admin;
GRANT SELECT ON reporte.v_TurnosDiarios TO rol_recalls_admin;
GRANT SELECT ON reporte.v_TurnosEstado TO rol_recalls_admin;
GRANT SELECT ON reporte.v_TurnosRealizados TO rol_recalls_admin;
GRANT SELECT ON reporte.v_TurnosSucursal TO rol_recalls_admin;
GRANT SELECT ON reporte.v_PendientesRealizados TO rol_recalls_asesor;
GRANT SELECT ON reporte.v_PendientesProvincia TO rol_recalls_asesor;
GRANT SELECT ON reporte.v_PersonasEmpresas TO rol_recalls_asesor;
GRANT SELECT ON reporte.v_Distancias TO rol_recalls_asesor;
GRANT SELECT ON reporte.v_SucursalesProvincia TO rol_recalls_asesor;
GRANT SELECT ON reporte.v_TurnosDiarios TO rol_recalls_asesor;
GRANT SELECT ON reporte.v_TurnosEstado TO rol_recalls_asesor;
GRANT SELECT ON reporte.v_TurnosRealizados TO rol_recalls_asesor;
GRANT SELECT ON reporte.v_TurnosSucursal TO rol_recalls_asesor;
GRANT SELECT ON reporte.v_PendientesRealizados TO rol_recalls_viewer;
GRANT SELECT ON reporte.v_PendientesProvincia TO rol_recalls_viewer;
GRANT SELECT ON reporte.v_PersonasEmpresas TO rol_recalls_viewer;
GRANT SELECT ON reporte.v_Distancias TO rol_recalls_viewer;
GRANT SELECT ON reporte.v_SucursalesProvincia TO rol_recalls_viewer;
GRANT SELECT ON reporte.v_TurnosDiarios TO rol_recalls_viewer;
GRANT SELECT ON reporte.v_TurnosEstado TO rol_recalls_viewer;
GRANT SELECT ON reporte.v_TurnosRealizados TO rol_recalls_viewer;
GRANT SELECT ON reporte.v_TurnosSucursal TO rol_recalls_viewer;
GRANT SELECT ON reporte.fn_TurnosPeriodo TO rol_recalls_admin;
GRANT SELECT ON reporte.fn_TurnosPeriodo TO rol_recalls_asesor;
GRANT SELECT ON reporte.fn_TurnosPeriodo TO rol_recalls_viewer;
GRANT SELECT ON reporte.v_AdminTurnosEstado TO rol_recalls_admin;
GRANT SELECT ON reporte.v_AdminLlamados TO rol_recalls_admin;
GRANT SELECT ON reporte.v_AdminPausados TO rol_recalls_admin;
GRANT SELECT ON reporte.v_AdminDistribucionTop5 TO rol_recalls_admin;
GRANT SELECT ON reporte.v_AdminOcupacion TO rol_recalls_admin;
GRANT SELECT ON reporte.v_AdminConversion TO rol_recalls_admin;
GRANT SELECT ON reporte.v_AdminDiscador TO rol_recalls_admin;
GRANT SELECT ON reporte.v_AdminVehiculos TO rol_recalls_admin;
GRANT SELECT ON reporte.v_AdminSucursales TO rol_recalls_admin;
GRANT EXECUTE ON api.sp_RegistrarLlamado TO rol_recalls_admin;
GRANT EXECUTE ON api.sp_RegistrarLlamado TO rol_recalls_asesor;
GRANT EXECUTE ON api.sp_CrearTurno TO rol_recalls_admin;
GRANT EXECUTE ON api.sp_CrearTurno TO rol_recalls_asesor;
GRANT EXECUTE ON api.sp_ReprogramarTurno TO rol_recalls_admin;
GRANT EXECUTE ON api.sp_ReprogramarTurno TO rol_recalls_asesor;
GRANT EXECUTE ON api.sp_CerrarTurno TO rol_recalls_admin;
GRANT EXECUTE ON api.sp_CerrarTurno TO rol_recalls_asesor;
GRANT EXECUTE ON api.sp_AltaTitular TO rol_recalls_admin;
GRANT EXECUTE ON api.sp_AltaVehiculo TO rol_recalls_admin;
GRANT EXECUTE ON api.sp_ActualizarPadron TO rol_recalls_admin;
GRANT EXECUTE ON api.sp_CargarTelefonos TO rol_recalls_admin;
GRANT EXECUTE ON api.sp_CalcularTop5 TO rol_recalls_admin;
GRANT EXECUTE ON api.sp_CargarResultado TO rol_recalls_admin;
GRANT EXECUTE ON api.sp_CambiarEstadoVehiculos TO rol_recalls_admin;
GRANT EXECUTE ON api.sp_EstadoRed TO rol_recalls_admin;
GRANT EXECUTE ON api.sp_ArchivarLlamados TO rol_recalls_admin;
GRANT EXECUTE,REFERENCES ON TYPE::dbo.ListaDominios TO rol_recalls_admin;
GRANT EXECUTE,REFERENCES ON TYPE::dbo.Padron TO rol_recalls_admin;
GRANT SELECT,INSERT ON carga.TelefonoStaging TO rol_recalls_admin;
GRANT SELECT ON carga.ErrorProceso TO rol_recalls_admin;
-- Catálogos: mantenimiento del Admin sujeto a FK, CHECK y triggers.
GRANT SELECT,INSERT,UPDATE ON dbo.Provincia TO rol_recalls_admin;
GRANT SELECT,INSERT,UPDATE ON dbo.Gestion TO rol_recalls_admin;
GRANT SELECT,INSERT,UPDATE ON dbo.Marca TO rol_recalls_admin;
GRANT SELECT,INSERT,UPDATE ON dbo.GestionMarca TO rol_recalls_admin;
GRANT SELECT,INSERT,UPDATE ON dbo.Concesionaria TO rol_recalls_admin;
GRANT SELECT,INSERT,UPDATE ON dbo.GestionConcesionaria TO rol_recalls_admin;
GRANT SELECT,INSERT,UPDATE ON dbo.Sucursal TO rol_recalls_admin;
GRANT SELECT,INSERT,UPDATE ON dbo.SucursalMarca TO rol_recalls_admin;
GRANT SELECT,INSERT,UPDATE ON dbo.Horario TO rol_recalls_admin;
GRANT SELECT,INSERT,UPDATE ON dbo.Contacto TO rol_recalls_admin;
GRANT SELECT,INSERT,UPDATE ON dbo.SucursalContacto TO rol_recalls_admin;
GRANT SELECT,INSERT,UPDATE ON dbo.CodigoRecall TO rol_recalls_admin;
GO
PRINT N'Instalación finalizada. Ejecutar pruebas/22_pruebas.sql y luego consultas/23_consultas.sql.';
GO

