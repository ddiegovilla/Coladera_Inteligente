
# Coladera Inteligente — Sistema IoT de Monitoreo de Obstrucciones

Sistema IoT desarrollado para monitorear el nivel de residuos acumulados en coladeras mediante un sensor ultrasónico HC-SR04, un microcontrolador ESP8266 y una API REST conectada a una base de datos MySQL.

El sistema permite obtener mediciones de distancia en tiempo real, identificar posibles obstrucciones, activar un indicador LED y almacenar las lecturas para su consulta y seguimiento.

## 🎥 Demostración del proyecto

[Ver video de funcionamiento en YouTube](https://youtube.com/shorts/54lNVtcRsKA)

## 🚀 Arquitectura del sistema

El proyecto está compuesto por tres módulos principales:

1. **Hardware IoT:** NodeMCU ESP8266, sensor ultrasónico HC-SR04 y LED indicador.
2. **API REST:** Servidor desarrollado en Node.js que recibe las mediciones y gestiona la comunicación con MySQL.
3. **Base de datos:** MySQL para almacenar coladeras, dispositivos, sensores, variables, mediciones, alertas y acciones de limpieza.

### Flujo de funcionamiento

```text
       HC-SR04
          |
          v
     NodeMCU ESP8266
          |
          v
       Wi-Fi
          |
          v
       API REST
       Node.js
          |
          v
        MySQL
          |
          v
   Almacenamiento
    de mediciones

   ESP8266 ---> LED indicador
                (Obstrucción)
```

## 📁 Estructura del repositorio

```text
Coladera_Inteligente/
│
├── firmware/
│   ├── src/
│   │   └── main.cpp
│   ├── include/
│   ├── lib/
│   ├── test/
│   ├── platformio.ini
│   └── README.md
│
├── .env.example
├── .gitignore
├── package.json
├── package-lock.json
├── README.md
│
├── RestApi-EquipoX-Matricula.js
│
├── ScriptCreacionBaseDatos_iot_EquipoX_MySQL.sql
├── Migracion_Limpiar_PIR_y_Datos_Prueba.sql
├── RegistroInicial_Hardware.sql
│
└── respaldo_coladera.sql
```

## 🔧 Hardware utilizado

| Componente | Función |
|---|---|
| NodeMCU ESP8266 | Microcontrolador y comunicación Wi-Fi |
| HC-SR04 | Medición de distancia de los residuos |
| LED | Indicador visual de posible obstrucción |
| Protoboard | Montaje del circuito |
| Cables jumper | Conexiones eléctricas |

### Conexiones

| Componente | Pin ESP8266 |
|---|---|
| HC-SR04 VCC | VIN / 5V |
| HC-SR04 GND | GND |
| HC-SR04 TRIG | D6 |
| HC-SR04 ECHO | D7 (con adaptación de nivel a 3.3V) |
| LED ánodo | D1 (con resistencia de 220–330 Ω en serie) |
| LED cátodo | GND |

**Importante:** El pin ECHO del HC-SR04 trabaja a 5V. Se debe adaptar su señal antes de conectarla al ESP8266, cuyos GPIO trabajan a 3.3V.

## 🗄️ Base de datos MySQL

Nombre de la base de datos:

`coladera_inteligente`

La base de datos contiene las siguientes tablas:

- `Coladera`: información y ubicación de cada coladera.
- `Dispositivo`: dispositivos IoT instalados.
- `Sensor`: sensores asociados a cada dispositivo.
- `TipoVariable`: variables que pueden medirse.
- `Medicion`: registros históricos de las mediciones.
- `Actuador`: dispositivos de salida.
- `Alerta`: alertas generadas por el sistema.
- `AccionLimpieza`: registro de acciones de limpieza.

La variable principal del proyecto es:

| Variable | Unidad | Descripción |
|---|---|---|
| distancia_residuos | cm | Distancia entre el sensor y la superficie de residuos |

## ⚙️ Instalación y configuración

### 1. Requisitos

- MySQL Server
- Node.js 20 o superior
- npm
- Visual Studio Code
- PlatformIO IDE
- Placa NodeMCU ESP8266
- Arduino framework para ESP8266

### 2. Configurar MySQL

Crear la base de datos ejecutando:

```bash
mysql -u root < ScriptCreacionBaseDatos_iot_EquipoX_MySQL.sql
```

Ejecutar la migración para adaptar la estructura al sensor ultrasónico y limpiar los datos de prueba:

```bash
mysql -u root < Migracion_Limpiar_PIR_y_Datos_Prueba.sql
```

Registrar el hardware inicial:

```bash
mysql -u root < RegistroInicial_Hardware.sql
```

**Nota:** La migración elimina registros existentes y modifica la estructura de acciones de limpieza. Ejecutarla únicamente durante la preparación inicial, antes de registrar el hardware.

### 3. Configurar la API REST

Instalar las dependencias:

```bash
npm install
```

Crear el archivo de configuración:

```bash
cp .env.example .env
```

Configurar las variables de entorno:

```env
PORT=3000

DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=TU_PASSWORD
DB_NAME=coladera_inteligente

API_TOKEN=TU_TOKEN_SEGURO

COLADERA_CODE=COL-MTY-001
SENSOR_CODE=US-001
ACTUATOR_CODE=LED-001
```

Iniciar el servidor:

```bash
npm start
```

Para desarrollo:

```bash
npm run dev
```

La API estará disponible en:

`http://localhost:3000`

### 4. Configurar el firmware ESP8266

Abrir la carpeta `firmware` con Visual Studio Code y PlatformIO.

Editar `firmware/src/main.cpp` y configurar:

- Nombre de la red Wi-Fi.
- Contraseña de la red.
- Dirección IP local de la computadora donde se ejecuta la API.
- Token de autenticación de la API.

Ejemplo:

```cpp
const char* WIFI_SSID = "TU_WIFI";
const char* WIFI_PASSWORD = "TU_PASSWORD";

const char* API_BASE_URL = "http://IP_DE_TU_COMPUTADORA:3000";
const char* API_TOKEN = "TU_TOKEN_SEGURO";
```

La dirección IP debe ser la de la computadora en la red local, no `localhost`.

Compilar y cargar el firmware mediante PlatformIO.

Para abrir el monitor serial:

```bash
pio device monitor -b 115200
```

## 🔌 API REST

La comunicación entre el ESP8266 y el servidor se realiza mediante solicitudes HTTP y respuestas JSON.

Las rutas principales son:

| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/api/health` | Verificar el estado del servidor y MySQL |
| GET | `/api/config` | Obtener la configuración de la coladera |
| GET | `/api/mediciones/ultimas` | Consultar las últimas mediciones |
| POST | `/api/mediciones` | Registrar una nueva medición |

Las rutas protegidas requieren el encabezado:

```http
x-api-key: TU_TOKEN_SEGURO
```

### Ejemplo de registro de medición

Solicitud POST:

```json
{
  "sensorCode": "US-001",
  "variableName": "distancia_residuos",
  "value": 12.5
}
```

### Consultar las últimas mediciones

```bash
curl -H "x-api-key: TU_TOKEN_SEGURO" \
http://localhost:3000/api/mediciones/ultimas
```

## 📊 Lógica de detección de obstrucciones

El sensor ultrasónico mide la distancia entre su posición y la superficie de los residuos acumulados.

El sistema compara la lectura con un umbral de obstrucción configurable.

- **Distancia mayor al umbral:** La tubería se considera despejada.
- **Distancia menor o igual al umbral:** Se identifica una posible obstrucción y se enciende el LED indicador.

El umbral inicial configurado es de 15 cm y puede modificarse desde la configuración de la coladera en MySQL.

El LED funciona como representación del futuro mecanismo de accionamiento mediante un servomotor.

## 🔐 Seguridad

- Las credenciales se configuran mediante variables de entorno.
- El archivo `.env` no debe subirse a GitHub.
- Las rutas protegidas utilizan autenticación mediante API Token.
- El firmware utiliza el token para autenticarse ante la API.
- No se deben publicar contraseñas Wi-Fi ni credenciales de acceso.

## 🛠️ Tecnologías utilizadas

| Tecnología | Aplicación |
|---|---|
| C++ | Firmware del ESP8266 |
| Arduino Framework | Programación del microcontrolador |
| PlatformIO | Compilación y carga del firmware |
| Node.js | Servidor backend |
| JavaScript | Desarrollo de la API REST |
| MySQL | Gestión de la base de datos |
| SQL | Creación y administración del esquema |
| HTTP / JSON | Comunicación entre dispositivos y servidor |
| Wi-Fi | Conectividad IoT |

## 👥 Proyecto

**Coladera Inteligente**

Proyecto de integración de dispositivos IoT a una base de datos mediante API REST.

Repositorio: [Coladera_Inteligente](https://github.com/ddiegovilla/Coladera_Inteligente)

Demostración: [Video en YouTube](https://youtube.com/shorts/54lNVtcRsKA)
