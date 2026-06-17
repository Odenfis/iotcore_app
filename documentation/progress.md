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
    - **Lógica:** Realiza un `Scan` o `Query` a DynamoDB.
    - **Procesamiento:** Implementa un `DecimalEncoder` personalizado para convertir los tipos `Decimal` de DynamoDB a JSON serializable.
    - **CORS:** Configurado para permitir peticiones desde la aplicación Flutter.
- **API Gateway:** HTTP API que expone el endpoint `GET /readings` conectado a la Lambda.

### 4. Interfaz de Usuario (Capa App)
Desarrollada en **Flutter** con una arquitectura modular:
- **`lib/models/sensor_reading.dart`**: Clase de datos para mapear el JSON de la API.
- **`lib/services/iot_service.dart`**: Servicio encargado de las peticiones HTTP al API Gateway.
- **`lib/screens/dashboard_screen.dart`**: Pantalla principal que presenta:
    - **Latest Reading:** Tarjeta destacada con el dato más reciente.
    - **Historial:** Lista de lecturas recientes.
    - **Auto-Refresh:** Implementación de *Polling* cada 10 segundos para mantener los datos actualizados sin intervención del usuario.

## ✅ Avances Realizados

| Tarea | Estado | Detalle |
| :--- | :---: | :--- |
| Configuración de Thing en IoT Core | ✅ | Certificados y Políticas creadas. |
| Implementación de Simulador Python | ✅ | Envío de datos exitoso. |
| Configuración de Tabla DynamoDB | ✅ | Datos recepcionados correctamente. |
| Desarrollo de Función Lambda | ✅ | Solucionado error de serialización de Decimales. |
| Despliegue de API Gateway | ✅ | Endpoint `/readings` activo y con CORS. |
| Desarrollo de App Flutter | ✅ | UI implementada y conectada a la API. |
| Implementación de Auto-update | ✅ | Refresco automático cada 10 segundos. |

## 🛠️ Instrucciones de Ejecución

### Backend
1. Desplegar la función en `backend/lambda_function.py` en AWS Lambda.
2. Configurar el rol de IAM con permisos `dynamodb:Scan` y `dynamodb:Query`.
3. Configurar API Gateway con ruta `GET /readings` y habilitar CORS.

### Frontend
1. Configurar la URL de la API en `lib/services/iot_service.dart`.
2. Ejecutar en terminal:
   ```bash
   flutter pub get
   flutter run
   ```
