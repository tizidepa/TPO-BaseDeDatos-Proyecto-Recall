:ON ERROR EXIT
-- Ejecutar con sqlcmd desde la raíz de este repositorio.
-- SSMS: usar rutas absolutas en las líneas :r o ejecutar los scripts por separado.

:r "./sql/00_crear_base_y_esquemas.sql"
:r "./sql/01_funciones_validacion_y_distancia.sql"
:r "./sql/02_provincias_marcas_gestiones.sql"
:r "./sql/03_red_de_atencion.sql"
:r "./sql/04_vehiculos_titulares_telefonos.sql"
:r "./sql/05_tablas_usuarios_roles.sql"
:r "./sql/06_tabla_llamados.sql"
:r "./sql/07_turnos_e_historiales.sql"
:r "./sql/08_top5_y_tablas_de_carga.sql"
:r "./sql/09_tipos_seguridad_y_bloqueo.sql"
:r "./sql/10_triggers_reglas_de_negocio.sql"
:r "./sql/11_procedimientos_altas_y_padron.sql"
:r "./sql/12_procedimientos_telefonos_y_top5.sql"
:r "./sql/13_procedimientos_llamados_y_turnos.sql"
:r "./sql/14_procedimientos_estados_y_archivo.sql"
:r "./sql/15_vistas_y_consultas_por_periodo.sql"
:r "./sql/16_triggers_invalidacion_top5.sql"
:r "./datos/17_datos_catalogos_y_red.sql"
:r "./datos/18_usuarios_demo_y_asignaciones.sql"
:r "./datos/19_datos_vehiculos_y_titulares.sql"
:r "./datos/20_datos_operaciones_demo.sql"
:r "./sql/21_permisos.sql"

PRINT N'Instalación completa. Pruebas: pruebas/22_pruebas.sql. Consultas: consultas/23_consultas.sql.';
GO
