# Gestión de recalls automotores — TPO Base de Datos I

Base para SQL Server 2019 o posterior. Se mantienen los nombres del ZIP por etapas, organizados en carpetas. La lógica de negocio está en restricciones, funciones, procedimientos y triggers.

## Carpetas

- `sql/`: scripts 00 a 16, más el 21 de permisos.
- `datos/`: scripts 17 a 20 con catálogos, usuarios demo, vehículos, titulares y operaciones.
- `pruebas/22_pruebas.sql`: 43 casos funcionales y de permisos.
- `consultas/23_consultas.sql`: consultas, subconsultas y reportes explicados.
- `docs/contexto.md`: contexto que antes estaba en este README, conservado íntegro como antecedente.
- `MER.svg`: modelo existente del grupo.
- `EJECUTAR_TODO.sql`: ejecutor de los scripts 00 a 21 con sus rutas actualizadas.

El archivo vacío `docs/archivo` preexistente se conserva; no interviene en la ejecución. `origen.json` era metadato de la separación del instalador original, no es necesario y no se incluye.

## Orden de ejecución

1. `sql/00_crear_base_y_esquemas.sql`
2. `sql/01_funciones_validacion_y_distancia.sql`
3. `sql/02_provincias_marcas_gestiones.sql`
4. `sql/03_red_de_atencion.sql`
5. `sql/04_vehiculos_titulares_telefonos.sql`
6. `sql/05_tablas_usuarios_roles.sql`
7. `sql/06_tabla_llamados.sql`
8. `sql/07_turnos_e_historiales.sql`
9. `sql/08_top5_y_tablas_de_carga.sql`
10. `sql/09_tipos_seguridad_y_bloqueo.sql`
11. `sql/10_triggers_reglas_de_negocio.sql`
12. `sql/11_procedimientos_altas_y_padron.sql`
13. `sql/12_procedimientos_telefonos_y_top5.sql`
14. `sql/13_procedimientos_llamados_y_turnos.sql`
15. `sql/14_procedimientos_estados_y_archivo.sql`
16. `sql/15_vistas_y_consultas_por_periodo.sql`
17. `sql/16_triggers_invalidacion_top5.sql`
18. `datos/17_datos_catalogos_y_red.sql`
19. `datos/18_usuarios_demo_y_asignaciones.sql`
20. `datos/19_datos_vehiculos_y_titulares.sql`
21. `datos/20_datos_operaciones_demo.sql`
22. `sql/21_permisos.sql`
23. `pruebas/22_pruebas.sql`
24. `consultas/23_consultas.sql`

Ejecutar como dbo con permiso para crear bases. Cada script selecciona su base y establece sus opciones, de modo que se puede abrir en una pestaña nueva. La instalación queda incompleta hasta finalizar el 21.

El 00 crea **RecallsUADE** y se detiene si ya existe: no modifica ni elimina una base previa. Los archivos de instalación se ejecutan una sola vez; no son migraciones idempotentes. Ante un error, revisar qué objetos llegaron a crearse antes de repetir el script.

## Instalación en SSMS

Activar **Consulta → Modo SQLCMD** y ejecutar los archivos individualmente en el orden indicado arriba. Cada uno selecciona su base y establece sus opciones.

El ejecutor usa rutas relativas para ejecutarse desde la raíz del repositorio en la terminal. Si se abre en SSMS, cambiar las rutas de las líneas `:r` por rutas absolutas, conservando las comillas. No depender del directorio de trabajo de SSMS.

## Instalación por terminal

Desde la raíz del repositorio (la carpeta que contiene `EJECUTAR_TODO.sql`):

```powershell
sqlcmd -S "(localdb)\MSSQLLocalDB" -E -C -b -f 65001 -i "EJECUTAR_TODO.sql"
sqlcmd -S "(localdb)\MSSQLLocalDB" -E -C -b -f 65001 -i "pruebas/22_pruebas.sql"
sqlcmd -S "(localdb)\MSSQLLocalDB" -E -C -b -f 65001 -i "consultas/23_consultas.sql"
```

Cambiar el servidor si se utiliza otra instancia. `-C` corresponde al entorno local de demostración y `-f 65001` permite leer UTF-8. Las cuentas demo son usuarios sin login; se prueban con `EXECUTE AS USER`.

## Decisiones implementadas

El contexto histórico conserva las decisiones y pendientes del documento original. Estas aclaraciones reflejan la implementación posterior:

- Un titular principal vigente por vehículo determina el TOP5 y la precarga del asistente.
- Cada llamado identifica el vehículo al que corresponde.
- Los turnos usan franjas de 30 minutos. Un preturno bloquea otro turno activo, aunque todavía no reserve una franja.
- Facturado y realizado dejan el vehículo como reparado; realizado tiene prioridad.
- Reactivar conserva el historial y requiere cancelar antes cualquier turno activo.
- El cursor procesa teléfonos y registra rechazos individuales. Los formatos ambiguos con 15 se rechazan para corregirlos en origen.
- Las vistas y operaciones respetan las gestiones asignadas. El archivo de llamados es lógico y no libera espacio físico.

La implementación contiene 26 tablas, 15 triggers, 14 procedimientos, 18 vistas y 7 funciones. Las pruebas usan SQL dinámico mediante `sp_executesql`; no se incorporó SQL dinámico a los procedimientos del negocio.

## Validación y documentación pendiente

Los scripts de origen se validaron el 28/10/2026 en SQL Server LocalDB: 43 pruebas correctas, 0 fallidas. Esta actualización organiza los mismos archivos y corrige rutas; no modifica reglas de negocio. Las pruebas deben ejecutarse sobre los datos demo originales y revierten sus cambios. No se hizo una prueba de carga masiva.

Quedan por elaborar como documentos separados `reglas-negocio.md`, `modelo-conceptual.md`, `normalizacion.md` y `diccionario-datos.md`. No se consideran entregados por figurar en la propuesta inicial. Revisar también que el MER refleje las decisiones implementadas.

Cada integrante trabaja en su propia rama y hace contribuciones reales de implementación, pruebas o documentación. Los números indican orden de instalación; no determinan cuántos commits hacer.
