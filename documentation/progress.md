# Proyecto: IoT Core App - Documentación de Progreso

Este documento detalla el diseño, la arquitectura y los pasos de implementación realizados para la creación de la aplicación de monitoreo de sensores IoT.

## 🎯 Objetivo
Construir un flujo completo de datos desde un dispositivo simulado hasta una aplicación móvil en Flutter, utilizando la infraestructura de AWS para la ingesta, almacenamiento y exposición de los datos.

## 🏗️ Arquitectura del Sistema

El flujo de datos sigue este camino:
`Dispositivo (Python)` $\rightarrow$ `AWS IoT Core` $\rightarrow$ `IoT Rule` $\rightarrow$ `DynamoDB` $\rightarrow$ `AWS Lambda` $\rightarrow$ `API Gateway` $\rightarrow$ `App Flutter`

### 1. Ingesta de Datos (Capa Dispositivo)
- **Simulador:** Script de Python que utiliza el SDK de AWS IoT.
- **Protocolo:** MQTT.
- **Tópico:** `wmr/pub`.
- **Datos enviados:** `device_id`, `timestamp`, `humidity`, `temperature`.

### 2. Almacenamiento (Capa Cloud)
- **AWS IoT Core:** Recibe los mensajes MQTT.
- **IoT Rule:** Filtra los datos mediante una sentencia SQL y los redirige a DynamoDB.
- **DynamoDB:** Tabla `wmr_iot_data` con:
    - **Partition Key:** `device_id` (String).
    - **Sort Key:** `timestamp` (Number).

### 3. Exposición de Datos (Capa API)
- **AWS Lambda:** Función en Python que actúa como puente.
    - **Lógica:** Realiza un `Scan` paginado o `Query` a DynamoDB y devuelve las 20 lecturas más recientes ordenadas por `timestamp` descendente.
    - **Procesamiento:** Implementa un `DecimalEncoder` personalizado para convertir los tipos `Decimal` de DynamoDB a JSON serializable.
    - **CORS:** Configurado para permitir peticiones desde la aplicación Flutter.
- **API Gateway:** HTTP API que expone el endpoint `GET /readings` conectado a la Lambda.

### 4. Interfaz de Usuario (Capa App)
Desarrollada en **Flutter** con una arquitectura modular y un sistema visual propio (ver *Rediseño visual v2*):
- **`lib/models/sensor_reading.dart`**: Modelo de datos tolerante que normaliza la respuesta heterogénea de la API.
- **`lib/services/iot_service.dart`**: Cliente HTTP con *timeout*, errores de negocio (`ApiException`) y parseo robusto.
- **`lib/screens/dashboard_screen.dart`**: Pantalla principal basada en `CustomScrollView` con *slivers*.
- **`lib/widgets/`**: Componentes reutilizables (tarjeta hero, tarjeta de lectura, métrica, sparkline, estados).
- **`lib/theme/app_theme.dart`**: Tokens de color, tipografía y formas; temas claro y oscuro automáticos.
- **Auto-Refresh:** *Polling* cada 10 segundos con `Timer.periodic`, protegido contra `setState` tras `dispose` y solapamiento de peticiones.

---

## 🎨 Rediseño Visual v2

### Problema resuelto
La primera versión de la UI sufría dos errores de layout que se veían claramente en el dispositivo:

| Síntoma | Causa raíz | Solución |
| :--- | :--- | :--- |
| Franja amarilla `RIGHT OVERFLOWED BY 72 PIXELS` en la tarjeta *Latest Reading* | Un `Row` con dos `Column` cuyo ancho lo fijaba el texto largo del valor (`"Ambiente Caliente"`, 24 px negrita) | Cada métrica va en su propio `Expanded` y el valor se dibuja en un `FittedBox(scaleDown)` que lo reduce en lugar de desbordar |
| El UUID del dispositivo se partía carácter a carácter (`iotconso / le-890d8 / ea6-d77…`) y el timestamp se cortaba (`202 / 6-11-05`) | `ListTile` con un `trailing` de texto largo: el `trailing` recibía el ancho natural y el `title` se quedaba sin espacio | Se eliminó el `ListTile`; la tarjeta se maqueta con `Row` + `Expanded` para el nombre y `Wrap` de "pastillas" para las métricas |

Además, el modelo original guardaba todas las métricas como `String`, lo que impedía mostrar unidades, aplicar color por umbral o comparar magnitudes.

### Sistema visual
- **Tema:** Material 3 con `ColorScheme.fromSeed` (azul `#2563EB`), `ThemeMode.system` y temas claro/oscuro con tokens semánticos (`surfaceContainerLow/High`, `outlineVariant`).
- **Tarjeta principal (hero):** degradado, dos métricas con icono circular, *sparkline* de tendencia y pie con hora de actualización y tiempo relativo ("hace 49 min").
- **Tarjetas de lectura:** avatar con iniciales, nombre corto del dispositivo, fecha absoluta, tiempo relativo y *pastillas* de temperatura (color por estado: caliente / templado / frío) y humedad.
- **Estados:** esqueleto con *shimmer* durante la carga, estado vacío y estado de error con botón **Reintentar**.
- **Responsive:** una columna en móvil, 2–3 columnas en tablet, contenido centrado con ancho máximo de 1120 px.
- **Accesibilidad:** `textScaler` acotado a 1.4 y textos con `ellipsis` para que ningún ajuste de fuente del sistema genere desbordamientos.
- **Idioma:** la interfaz está en español, coherente con los datos que envía el dispositivo (`Ambiente Caliente`, `Ambiente Templado`).

### Modelo de datos tolerante
`SensorReading` normaliza la respuesta de la API sin romper el contrato:

| Entrada de la API | `*Value` | `*Label` | Estado |
| :--- | :--- | :--- | :--- |
| `1.7` (número) | `1.7` | `"1.7"` | — |
| `"Ambiente Caliente"` | `null` | `"Ambiente Caliente"` | `hot` |
| `null` o `""` | `null` | `"N/D"` | `unknown` |

El `timestamp` acepta `int`, `double` o `String` numérico y detecta si viene en milisegundos.

### Estructura de archivos
```
lib/
├── main.dart                      # MaterialApp + temas claro/oscuro
├── models/
│   └── sensor_reading.dart        # Modelo normalizado + TemperatureState
├── services/
│   └── iot_service.dart           # Cliente HTTP, ApiException, ReadingsRepository
├── screens/
│   └── dashboard_screen.dart      # Slivers, polling, estados
├── theme/
│   └── app_theme.dart             # Tokens de color, tipografía y formas
├── utils/
│   └── time_format.dart           # Tiempos relativos y formatos de fecha
└── widgets/
    ├── app_states.dart            # Skeleton shimmer, estado vacío y de error
    ├── device_avatar.dart         # Avatar con iniciales
    ├── latest_reading_card.dart   # Tarjeta hero con tendencia
    ├── metric_tile.dart           # MetricTile (hero) y MetricPill (lista)
    ├── reading_card.dart          # Tarjeta de lectura del historial
    ├── relative_time_text.dart    # "hace 2 min" auto-refrescante
    └── trend_sparkline.dart       # Sparkline con CustomPainter (sin dependencias)
```

No se ha añadido ninguna dependencia externa: el *sparkline*, el *shimmer* y los formatos de tiempo son implementaciones propias.

---

## 🐛 Correcciones de robustez (no visuales)

Además del rediseño, se corrigieron defectos que afectaban a la exactitud de los datos y a la estabilidad de la app:

| Defecto | Causa raíz | Solución |
| :--- | :--- | :--- |
| `UnsupportedError: Cannot sort a const list` | `_readings = data..sort(...)` ordenaba la lista devuelta por el repositorio, que puede ser inmutable | Se copia con `List<SensorReading>.of(...)` antes de ordenar |
| `timestamp` a `0` en silencio | `json['timestamp'] is int ? … : 0`: un `double` o un `String` numérico caía a 0 y la app mostraba 1970 | `num.tryParse` + detección automática de segundos/milisegundos |
| `use_build_context_synchronously` y `setState` tras `dispose` | `ScaffoldMessenger.of(context)` se usaba después del `await` sin comprobar `mounted`; el timer de 10 s podía disparar tras salir | Guarda de `mounted` antes de tocar el contexto y cancelación del timer en `dispose` |
| Peticiones solapadas | El polling automático podía coincidir con un refresco manual y duplicar respuestas | Bandera `_requestInFlight` que serializa las llamadas |
| `flutter test` en rojo (no compilaba) | `test/widget_test.dart` referenciaba `MyApp`, clase que no existe (la real es `IoTApp`) | Test reescrito sobre `IoTApp` con un repositorio falso |
| Lambda: `TypeError` al serializar `Decimal` | El archivo local no tenía el `DecimalEncoder` que sí usa el Lambda desplegado | `DecimalEncoder` añadido y verificado con `py_compile` |
| Lambda: "última lectura" que no era la real | `Scan(Limit=20)` devuelve 20 items **arbitrarios**, no los más recientes | `Scan` paginado completo, orden por `timestamp` descendente y `[:20]` |
| Cabecera "ÚLTIMA LECTU…" recortada | En la misma `Row`, un `Flexible` y un `Spacer` competían por el espacio libre | `Expanded` para el título y `Flexible` para el chip del dispositivo |
| Desbordamiento vertical en tablets | La rejilla usaba `SliverGrid` con `mainAxisExtent` fijo (150 px), insuficiente para textos largos | Rejilla con `Wrap`: cada tarjeta calcula su propia altura y nunca desborda |

### Capa de servicio
- `ApiException` con mensaje en español, listo para mostrar en la interfaz.
- Timeout de 10 s con mensaje propio (evita esperas indefinidas).
- Parseo tolerante: acepta tanto una lista JSON como un objeto `{"readings": [...]}`.
- Construcción de URI con `Uri.replace(queryParameters:)` en lugar de concatenar cadenas.
- Decodificación en UTF-8 (`utf8.decode(response.bodyBytes)`).

### Decisiones de arquitectura
- `ReadingsRepository` es un **contrato**; `IoTService` lo implementa y `DashboardScreen` / `IoTApp` lo reciben por inyección. Eso permite testear la UI sin red.
- `pollInterval` es configurable (`null` lo desactiva) para que los tests no dejen timers pendientes.

---

## 🧪 Tests y verificación

### Cobertura de tests (`flutter test` → 11/11)

**`test/model_test.dart` (6 tests)** — normalización del modelo:
1. Parsea el payload real de la API (`iotconsole-890d8ea6-…`, `Ambiente Caliente`, `1.7`).
2. Acepta `timestamp` numérico, decimal, textual y en milisegundos.
3. Interpreta temperaturas numéricas según los umbrales (28 °C / 18 °C).
4. Clasifica temperaturas cualitativas (`Caliente` / `Templado` / `Frío` / desconocido).
5. Gestiona métricas ausentes o vacías (`null` → `"N/D"`).
6. Expone correctamente la fecha y hora de la lectura.

**`test/widget_test.dart` (5 tests)** — comportamiento de la interfaz:
1. **Regresión anti-overflow:** monta el dashboard con el payload real a **320 px de ancho con `text-scale 2.0`** y falla si aparece cualquier `RenderFlex overflow`.
2. Muestra la lectura más reciente en la tarjeta principal.
3. Muestra el estado de error y ofrece el botón **Reintentar**.
4. Muestra el estado vacío cuando la API no devuelve lecturas.
5. Refresca los datos al pulsar el botón de actualizar.

### Verificación visual en simulador
- **Dispositivo:** iPhone 17 Pro (iOS 26.5) · **Flutter 3.47.2 / Dart 3.13.2**.
- Modo **claro** y **oscuro** comprobados con capturas reales (`xcrun simctl io … screenshot`).
- Anchos validados: 320 px (test automatizado) y 402 px lógicos (iPhone 17 Pro); en tablet, 2–3 columnas.
- Resultado: **sin franjas de overflow** y sin textos truncados en ninguna combinación probada.

### Estado de calidad
```
flutter analyze   →  No issues found!      (antes: 1 lint + 1 error)
flutter test      →  All tests passed!     (antes: no compilaba)
```

---

## ✅ Avances Realizados

| Tarea | Estado | Detalle |
| :--- | :---: | :--- |
| Configuración de Thing en IoT Core | ✅ | Certificados y Políticas creadas. |
| Implementación de Simulador Python | ✅ | Envío de datos exitoso. |
| Configuración de Tabla DynamoDB | ✅ | Datos recepcionados correctamente. |
| Desarrollo de Función Lambda | ✅ | `DecimalEncoder` + ordenación descendente y paginación del `Scan`. |
| Despliegue de API Gateway | ✅ | Endpoint `/readings` activo y con CORS. |
| Desarrollo de App Flutter | ✅ | UI implementada y conectada a la API. |
| Implementación de Auto-update | ✅ | Refresco automático cada 10 segundos. |
| Rediseño visual v2 | ✅ | Sistema de diseño nuevo, tema claro/oscuro y responsive. |
| Corrección de desbordamientos | ✅ | Test de regresión que falla si aparece cualquier `RenderFlex overflow`. |
| Robustez de datos y servicios | ✅ | Modelo tolerante, `timestamp` correcto, `ApiException`, timeout y peticiones serializadas. |
| Sincronización del Lambda local | ✅ | `DecimalEncoder` y orden por `timestamp` (requiere redespliegue). |
| Tests automatizados | ✅ | 11 tests (6 de modelo + 5 de widgets) en verde. |
| Verificación visual en simulador | ✅ | Modo claro y oscuro revisados con capturas reales. |

---

## 🛠️ Instrucciones de Ejecución

### Backend
1. Desplegar la función en `backend/lambda_function.py` en AWS Lambda.
2. Configurar el rol de IAM con permisos `dynamodb:Scan` y `dynamodb:Query`.
3. Configurar API Gateway con ruta `GET /readings` y habilitar CORS.

### Frontend
1. Configurar la URL de la API en `lib/services/iot_service.dart` (`baseUrl`).
2. Ejecutar en terminal:
   ```bash
   flutter pub get
   flutter run
   ```

### Calidad
```bash
flutter analyze   # debe terminar con "No issues found!"
flutter test      # debe terminar con "All tests passed!"
```

### Notas
- La unidad de la humedad (`%`) es la que envía el simulador; si el backend pasa a enviar otro valor, se ajusta en `lib/widgets/metric_tile.dart`.
- El backend todavía devuelve la temperatura como texto cualitativo. Si en el futuro envía un número, la app lo detecta automáticamente y muestra el valor con `°C` y color por umbral.
- El `Scan` sin filtro recorre la tabla completa para devolver las 20 lecturas más recientes; con tablas grandes conviene migrar a `Query` por dispositivo o a un índice temporal.

## ⏳ Pendiente

| Tarea | Impacto | Estado |
| :--- | :--- | :--- |
| Redesplegar `backend/lambda_function.py` en AWS Lambda | El `DecimalEncoder` y el orden descendente solo se aplican al desplegar; el frontend ya es compatible con el Lambda actual | ⬜ Pendiente |

## 📸 Resultado

| Antes | Después |
| :--- | :--- |
| Overflow horizontal de 72 px en la tarjeta principal | Tarjeta hero con degradado, métricas equilibradas y sparkline |
| UUID partido en 7 líneas dentro del `ListTile` | Tarjeta limpia con avatar, nombre corto y pastillas de métricas |
| Interfaz en inglés con datos en español | Interfaz completa en español, coherente con el dispositivo |
| Sin estados de carga/vacío/error ni tema oscuro | Skeleton, estado vacío, error con reintento y tema claro/oscuro automático |
| "Última lectura" podía no ser la más reciente | Lambda devuelve las 20 lecturas ordenadas por `timestamp` descendente |
| `flutter test` no compilaba | 11 tests en verde, incluido el test anti-overflow a 320 px |
