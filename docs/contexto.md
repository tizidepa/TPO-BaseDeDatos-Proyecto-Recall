# Contexto del proyecto: TPO Base de Datos I — Gestión de recalls

---

## 1. Qué es este proyecto

Trabajo Práctico Integrador de **Ingeniería de Datos I (Base de Datos I)**, UADE, 2.º cuatrimestre 2026. Docentes: Lic. Gustavo E. Escandell e Ing. Melinda Selles. Grupo de hasta 5 integrantes.

**Fecha límite de entrega: 5 de noviembre de 2026.**

El grupo diseña, implementa y documenta una base de datos para un dominio elegido: **la gestión de campañas de recall automotor** (convocar a los dueños de vehículos afectados, por ejemplo por los airbags Takata, para que agenden un turno de reparación).

### Qué pide el enunciado (resumen)

- Universo del Discurso (contexto, objetivo, actores, información, reglas de negocio, procesos, restricciones, relaciones).
- DER (entidades, atributos, identificadores, relaciones, cardinalidades, participación, entidades débiles).
- Normalización: dependencias funcionales, claves candidatas, 1FN, 2FN, 3FN como mínimo, más 4FN y 5FN. Explicar cómo se evitan las anomalías.
- Tablas con PK, FK, restricciones de integridad y de dominio.
- Datos de prueba suficientes para probar todo.
- Consultas (SELECT, WHERE, ORDER BY, JOIN, GROUP BY, HAVING, agregaciones), subconsultas explicadas, vistas, stored procedures, triggers, cursores (al menos uno), funciones, manejo de errores, seguridad (usuarios, roles, permisos).
- **La lógica y las reglas de negocio tienen que estar centralizadas en la base de datos.** Cada objeto tiene que tener una justificación funcional, no estar "de relleno".
- Documento final con: carátula, integrantes, descripción, UdD, reglas, DER, normalización, modelo de tablas, diccionario de datos, consultas, subconsultas, vistas, SPs, triggers, cursores, funciones, errores, seguridad, centralización y conclusiones.
- Script que reconstruya toda la base.
- Repositorio en GitHub: **cada integrante con al menos una branch propia** y contribuciones reales y verificables (se revisan commits, fechas e historial). Quien no demuestre su participación no aprueba.
- Defensa oral individual: cualquier integrante puede ser consultado sobre cualquier parte.

### Uso de IA (importante)

El enunciado prohíbe usar IA para elaborar el TP. El grupo consultó al profesor y la indicación fue: **mientras las ideas y decisiones sean del grupo, se puede usar IA para redactar mejor, ordenar o expandir temas**, siempre que en el oral sepan explicar todo.

**Por eso, la IA tiene que:**
- Ayudar a redactar, ordenar, explicar conceptos y señalar errores o huecos.
- Explicar el **porqué** de cada sugerencia, para que el grupo pueda defenderla.
- Marcar claramente lo que agrega o propone ella, para que el grupo lo revise y lo decida.
- No tomar decisiones de diseño por el grupo: proponer opciones con sus ventajas y desventajas.

El **turnero** (una aplicación web hecha con IA) se usa solo para la demostración y para facilitar las cargas. No es parte de lo evaluado y se conecta a la base únicamente a través de sus procesos (SPs y vistas).

---

## 2. El dominio: cómo funciona un recall

1. La terminal detecta un defecto y define qué vehículos están alcanzados (lista de VIN o dominios).
2. Se identifican los titulares cruzando con el padrón automotor.
3. Se los contacta por teléfono (discador) para que agenden un turno.
4. Se agenda un turno en una sucursal que atienda la marca.
5. El taller repara; la marca informa los realizados o facturados.
6. Se hace seguimiento de pendientes y se vuelve a llamar.

La empresa del caso gestiona recalls para varias marcas: Stellantis (Fiat, Citroën, Jeep, etc.), Toyota, Chevrolet y Volkswagen. Trabaja por **gestiones** (campañas).

---

## 3. Decisiones tomadas

### Vehículos y titulares
- Cada vehículo se identifica por su **dominio** (patente), aparece una sola vez y pertenece a una marca y a una gestión.
- El **modelo** es un dato del vehículo; el recall no depende del modelo.
- Algunos vehículos de Stellantis tienen **2 códigos de recall** (airbag de conductor y de acompañante): van en una tabla aparte (dominio + código, sin repetir) y se atienden en un único turno.
- **Titularidad**: relación N:M entre vehículo y titular con fecha **desde** y **hasta**. La fecha hasta se completa cuando una actualización del padrón ya no trae la combinación CUIT + dominio.
- El titular puede ser **persona o empresa**; el tipo se reconoce por el prefijo del CUIT. Se guardan los dos, pero **solo se trabajan personas**: las empresas quedan apartadas.
- **Teléfonos**: llegan en un Excel con varias columnas. Se cargan a una tabla de staging y un SP los pasa a una tabla de teléfonos (una fila por número, hasta 5 por titular, con WhatsApp sí / no / sin dato), normalizados y validados.

### Red de atención
- Gestión ↔ Marca (N:M). Gestión ↔ Concesionaria (N:M).
- Concesionaria → Sucursales (1:N). Sucursal ↔ Marca que atiende (N:M). Ejemplo: Norauto atiende Fiat y Citroën sin ser concesionaria oficial.
- La sucursal tiene horarios, máximo mensual de turnos y capacidad simultánea (por defecto 1).
- Concesionarias y sucursales **nunca se eliminan**: se pausan y se registra la fecha de pausa.
- Contactos de Stellantis (zonal de posventa, zonal comercial, gerente de posventa, dealer coach y agendadores): **una sola entidad con un atributo tipo**, relacionada N:M con sucursal y opcional.
- **Provincia** es una entidad (para titulares y sucursales).

### TOP5
- Para cada vehículo con titular persona, las 5 sucursales más cercanas **dentro de la provincia del titular** que atiendan la marca y estén activas.
- Las coordenadas se reciben ya calculadas (el geocoding queda fuera del proyecto).
- El cálculo lo hace un **SP que se ejecuta a pedido** (por ejemplo al pausar o reactivar una concesionaria).
- Se guarda **una fila por sugerencia**: vehículo, posición (1 a 5), sucursal, km. No en columnas repetidas (sería violar 1FN).
- La salida al discador es una **vista** que pasa las filas a columnas (sucursal1, km1 … sucursal5, km5) y se exporta a CSV o Excel.
- Rango aceptable: hasta 60 km. Los de más de 60 km y las empresas son **apartados**: no son tabla ni estado, son un filtro al consultar.
- Si una sucursal o un titular no tiene coordenadas, el SP lo informa como error y sigue.

### Llamados
- Entrada: CUIT + teléfono + resultado (efectivo / no efectivo).
- Efectivo → el dominio pasa a "trabajando". No efectivo → solo se registra el intento.
- Historial de llamados con fila angosta (titular/teléfono, resultado, fecha) e índice por persona y fecha.
- Un **trigger** suma 1 al contador de intentos del titular con cada llamado (redundancia controlada por rendimiento).
- Volumen estimado: ~246.000 dominios, 3 intentos por semana, 2 años → peor caso ~77 millones de filas (~7,7 GB). Los recalls cerrados se archivan.

### Turnos
- Guardan **solo ids**: vehículo, sucursal y usuario que lo creó. Concesionaria, marca y gestión se obtienen por JOIN.
- Guardan fecha, hora, fecha de creación y los datos de la persona que asiste (nombre, apellido, teléfono), precargados con el titular vigente y editables (puede ir un familiar).
- Fecha y hora pueden quedar vacías en un **preturno**. Al cargarlas, un trigger lo pasa a "creado".
- Reprogramar no es un estado: un **trigger** suma 1 al contador de reprogramaciones y registra la fecha de reprogramación cuando cambia la fecha.
- Antes de insertar se valida: horario de la sucursal, que atienda la marca, que esté activa, que el dominio esté disponible, máximo mensual y capacidad simultánea. Aplica a todas las marcas.
- Facturado y realizado llegan desde las cargas de dominios y se aplican al último turno del dominio.

### Estados
- **Dominio:** pendiente → trabajando (llamado efectivo) → turno → turno realizado. Además: **descartado** (carga especial, no se vuelve a llamar, reactivable si fue error) y **pausado** (la persona no quiere que la llamen). Solo vuelve a pendiente con la carga de **reactivación**, que no borra turnos anteriores.
- **Turno:** preturno, creado, cancelado, no se presentó, facturado, realizado.
- **Recall, marca, concesionaria, sucursal:** activo o pausado. Pausar uno **no cambia** el estado de los demás: un dominio está disponible solo si él, su recall, su marca y su sucursal están activos.
- Al pausar una sucursal, sus turnos ya agendados se mantienen, pero no se agendan nuevos.
- Cargas de realizados y facturados (VINLIST de Stellantis, bases de realizados, facturados de otras marcas): el estado **no retrocede** (realizado tiene prioridad sobre facturado), con un trigger.

### Validaciones
- **Dominio:** `AAA111` o `AA111AA`.
- **CUIT:** 11 dígitos. Personas: 20, 23, 24, 25, 26, 27. Empresas: 30, 33, 34. Último dígito verificador (módulo 11) → candidato a función.
- **Celular:** normalizado a 10 dígitos (código de área + número), tomando los 10 de la derecha. Lo que no se puede normalizar se rechaza.

### Usuarios y seguridad
| Rol | Quiénes | Qué hacen | Alcance |
|---|---|---|---|
| Admin | Equipo de datos | Todo; vistas de números y de datos | Todas las gestiones |
| Asesor | Cargan turnos | Cargan turnos; vistas de números | Una o varias gestiones |
| Viewer | Representantes de los recalls y vendedores de Insiders | Solo vistas de números | Sus gestiones |

- Tabla de **asignaciones** (usuario, rol, gestión), relación ternaria; gestión vacía = todas.
- Las vistas filtran por las gestiones del usuario conectado (**seguridad a nivel de fila**).
- Agendadores, zonales, gerentes y dealer coach **no son usuarios**.

### Vistas
Estructura fija en la base; los parámetros (gestiones, concesionarias, período) los completa el turnero al consultar. Se descargan en Excel.

| Vista | Qué muestra | Quién la ve |
|---|---|---|
| Pendientes vs. realizados | Pendientes (pendiente, trabajando, turno) y realizados, por gestión | Todos |
| Pendientes por provincia | Por provincia del titular vigente, solo personas | Todos |
| Personas vs. empresas | Cantidad de cada tipo, por gestión | Todos |
| Hasta 60 km vs. más de 60 km | Solo personas | Todos |
| Sucursales por provincia | Cantidad con desglose por marca; el admin ve también el listado | Todos (listado: admin) |
| Cantidad de turnos | Esta semana, últimos 7 días, últimas 2 semanas, último mes o todos | Todos |
| Turnos por estado | Los 6 estados | Todos |
| Turnos realizados | Facturado + realizado sumados; el admin los ve desglosados | Todos (desglose: admin) |
| Turnos por sucursal | Turnos de cada sucursal | Todos |
| Llamados | Total y último mes, efectivos y no efectivos | Admin |
| Pausados | Dominios, concesionarias, sucursales, marcas, recalls | Admin |
| Distribución del TOP5 | Por concesionaria: apariciones por posición 1 a 5 y total | Admin |
| Ocupación de sucursales | Turnos del mes vs. máximo mensual | Admin |
| Conversión | De los llamados efectivos, cuántos terminaron en turno | Admin |
| Salida al discador | Titulares con su TOP5 en una fila | Admin |

### Fuera del alcance
Geocoding · recalls de motos · recalls distintos según el modelo · varios recalls activos por vehículo (mejora futura) · tratamiento de los apartados (lo define Stellantis) · el agendador de Brisa · el contacto con los roles de Stellantis · el turnero (solo demo).

---

## 4. DER (notación Chen, con rombos)

**Entidades:** Provincia, Gestión, Marca, Vehículo, Código de recall (débil), Titular, Teléfono (débil), Llamado, Concesionaria, Sucursal, Horario (débil), Contacto Stellantis, Turno, Usuario, Rol.

| Relación | Entre | Cardinalidad | Nota |
|---|---|---|---|
| incluye | Gestión – Marca | N:M | |
| alcanza | Gestión – Vehículo | 1:N | total del lado vehículo |
| es de | Marca – Vehículo | 1:N | total del lado vehículo |
| tiene código | Vehículo – Código de recall | 1:N | identificadora |
| titularidad | Vehículo – Titular | N:M | atributos desde, hasta |
| tiene teléfono | Titular – Teléfono | 1:N | identificadora; máx. 5 por regla |
| se hace a | Teléfono – Llamado | 1:N | |
| asigna | Gestión – Concesionaria | N:M | |
| pertenece | Concesionaria – Sucursal | 1:N | |
| atiende | Sucursal – Marca | N:M | caso Norauto |
| tiene horario | Sucursal – Horario | 1:N | identificadora |
| asignado a | Sucursal – Contacto Stellantis | N:M | opcional para la sucursal |
| sugiere (TOP5) | Vehículo – Sucursal | N:M | atributos posición, km |
| tiene turno | Vehículo – Turno | 1:N | un solo turno activo por regla |
| se atiende en | Sucursal – Turno | 1:N | |
| crea | Usuario – Turno | 1:N | |
| asignación | Usuario – Rol – Gestión | ternaria | gestión opcional; útil para 4FN/5FN |
| reside en | Provincia – Titular | 1:N | |
| ubicada en | Provincia – Sucursal | 1:N | |

Puntos a revisar del DER:
- Horario con clave parcial "día" solo admite un horario por día; si hay turno partido, la clave debe incluir hora desde.
- "Intentos" del titular es un atributo derivado (se puede contar desde Llamado).
- La marca del vehículo tiene que estar entre las marcas de su gestión: no se expresa en el DER, va como regla de negocio / trigger.

---

## 5. Reglas de negocio (RN-01 a RN-36)

1. Un vehículo pertenece a una sola marca.
2. Un vehículo no puede estar en más de una gestión.
3. Un dominio no puede repetirse en la base.
4. La combinación dominio + código de recall no puede repetirse.
5. Un vehículo puede tener varios titulares y un titular varios vehículos.
6. Una titularidad se cierra cuando el padrón ya no trae CUIT + dominio.
7. Los titulares empresa se guardan pero no se trabajan.
8. Máximo 5 celulares por titular.
9. Una sucursal del TOP5 debe estar activa, en la provincia del titular y atender la marca.
10. Los vehículos a más de 60 km quedan apartados y no van al discador.
11. Sin coordenadas, el TOP5 informa error y sigue.
12. Los roles de Stellantis son opcionales en una sucursal.
13. Llamado efectivo → "trabajando"; no efectivo → solo suma intento.
14. Cada llamado suma 1 al contador de intentos.
15. Un dominio vuelve a "pendiente" solo con la carga de reactivación, sin borrar turnos.
16. Un dominio descartado no se vuelve a llamar, salvo reactivación.
17. Un vehículo solo puede tener un turno activo.
18. Estados de turno: preturno, creado, cancelado, no se presentó, facturado, realizado.
19. Un preturno puede no tener fecha ni hora; al cargarlas pasa a "creado".
20. Si cambia la fecha del turno, +1 al contador de reprogramaciones y fecha de reprogramación.
21. No hay turnos fuera del horario de la sucursal.
22. No hay turnos en sucursales que no atienden la marca.
23. No hay turnos para dominios no disponibles (completado, pausado, descartado).
24. No hay turnos si la sucursal llegó a su máximo mensual.
25. No hay turnos si la sucursal tiene ocupada su capacidad simultánea en ese horario.
26. No hay turnos en sucursales pausadas; los ya agendados se mantienen.
27. Concesionarias y sucursales no se eliminan: se pausan con fecha.
28. Pausar recall, marca, concesionaria o sucursal no cambia el estado de los demás.
29. Un dominio está disponible solo si él, su recall, su marca y su sucursal están activos.
30. El estado de un dominio no retrocede (realizado > facturado).
31. Facturado y realizado se aplican al último turno del dominio.
32. Dominio con formato AAA111 o AA111AA.
33. CUIT de 11 dígitos, prefijo válido y dígito verificador correcto.
34. Celular normalizado a 10 dígitos; si no se puede, se rechaza.
35. Cada usuario ve solo sus gestiones asignadas.
36. Solo el admin ve vistas de datos y el desglose facturado/realizado.

---

## 6. Lógica prevista dentro de la base

| Objeto | Tipo | Qué hace |
|---|---|---|
| Calcular TOP5 | SP | A pedido; sucursales activas, misma provincia, marca atendida; error si faltan coordenadas |
| Carga de teléfonos | SP | Staging → filas, normaliza y rechaza inválidos |
| Cambios de estado por lista | SP | Descartados, reactivación, pausados |
| Validar turno nuevo | SP / trigger | Horario, marca, sucursal activa, dominio disponible, máximo mensual, capacidad |
| Preturno → creado | Trigger | Al cargar fecha y hora |
| Reprogramación | Trigger | Contador + fecha de reprogramación |
| Intentos de llamado | Trigger | +1 por llamado |
| Prioridad de cargas | Trigger | El estado no retrocede |
| Validaciones de formato | Función | Dominio, CUIT con dígito verificador, celular |
| Filtro de vistas por gestión | Función (opcional) | Recibe las gestiones elegidas como parámetro |

Falta asignar al menos un **cursor** con justificación técnica.

---

## 7. Pendientes

- Celulares que traen 15 (ej. 541537668202 o 1537668202): tomar los 10 de la derecha deja el 15 en lugar del código de área. Definir el tratamiento.
- Si el asesor puede reprogramar y cancelar turnos y qué datos puede leer para agendar.
- Confirmar las participaciones totales del DER.
- Asignar el cursor.
- Próximos pasos: normalización (DF, claves candidatas, 1FN a 5FN), tablas y diccionario de datos, script, datos de prueba, SQL de vistas, SPs, triggers y funciones.

---

## 8. Archivos del proyecto

| Archivo | Qué es |
|---|---|
| `TPO_Recalls_Planificacion.docx` | Resumen del enunciado y primera idea |
| `TPO_Recalls_Idea_Inicial.docx` | Primera idea del sistema |
| `TPO_Recalls_Enunciado_Empresa_v3.docx` | Enunciado "de empresa" con todo lo definido (versión vigente) |
| `Mapa_TPO_Recalls.html` | Mapa visual del alcance, procesos, estados y vistas |
| `DER_Recalls.drawio` / `.png` / `.svg` | DER en notación Chen (editable en app.diagrams.net) |
| `CONTEXTO_IA_TPO_Recalls.md` | Este archivo |
