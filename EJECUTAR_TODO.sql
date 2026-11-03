:ON ERROR EXIT
-- sqlcmd: ejecutar desde la raíz del repositorio.
-- SSMS: activar Modo SQLCMD y reemplazar . por la ruta absoluta del repositorio.
:setvar Carpeta "."

:r "$(Carpeta)/sql/00_crear_base_y_esquemas.sql"
:r "$(Carpeta)/sql/01_funciones_validacion_y_distancia.sql"
:r "$(Carpeta)/sql/02_provincias_marcas_gestiones.sql"
:r "$(Carpeta)/sql/03_red_de_atencion.sql"
:r "$(Carpeta)/sql/04_vehiculos_titulares_telefonos.sql"
:r "$(Carpeta)/sql/05_tablas_usuarios_roles.sql"
:r "$(Carpeta)/sql/06_tabla_llamados.sql"
:r "$(Carpeta)/sql/07_turnos_e_historiales.sql"
:r "$(Carpeta)/sql/08_top5_y_tablas_de_carga.sql"
:r "$(Carpeta)/sql/09_tipos_seguridad_y_bloqueo.sql"
:r "$(Carpeta)/sql/10_triggers_reglas_de_negocio.sql"
:r "$(Carpeta)/sql/11_procedimientos_altas_y_padron.sql"
:r "$(Carpeta)/sql/12_procedimientos_telefonos_y_top5.sql"
:r "$(Carpeta)/sql/13_procedimientos_llamados_y_turnos.sql"
:r "$(Carpeta)/sql/14_procedimientos_estados_y_archivo.sql"
:r "$(Carpeta)/sql/15_vistas_y_consultas_por_periodo.sql"
:r "$(Carpeta)/sql/16_triggers_invalidacion_top5.sql"
:r "$(Carpeta)/datos/17_datos_catalogos_y_red.sql"
:r "$(Carpeta)/datos/18_usuarios_demo_y_asignaciones.sql"
:r "$(Carpeta)/datos/19_datos_vehiculos_y_titulares.sql"
:r "$(Carpeta)/datos/20_datos_operaciones_demo.sql"
:r "$(Carpeta)/sql/21_permisos.sql"

PRINT N'Instalación completa. Pruebas: pruebas/22_pruebas.sql. Consultas: consultas/23_consultas.sql.';
GO
