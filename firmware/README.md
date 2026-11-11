# Coladera Inteligente — HC-SR04 + LED (PlatformIO)

Firmware preliminar para NodeMCU ESP8266 con un HC-SR04 y un LED indicador que representa el futuro servomotor.

## Antes de compilar
Editar `src/main.cpp`:
- `WIFI_SSID`
- `WIFI_PASSWORD`
- `API_BASE_URL`: IP LAN de la Mac y puerto de API, no `localhost`.
- `API_TOKEN`
- Confirmar `SENSOR_CODE` con el código registrado en la base/API.

## Pines
- HC-SR04 TRIG D6
- HC-SR04 ECHO D7 mediante divisor resistivo 5V a 3.3V.
- LED D1 con resistencia 220–330 ohm en serie.
- HC-SR04 VCC a 5V/VIN y GND común.

## Lógica
Lectura cada 10 segundos. Si la distancia es menor o igual al umbral, el LED se enciende; si no, se apaga. El valor de distancia se envía por HTTP POST a `/api/mediciones`. El umbral se intenta recuperar por GET `/api/config`.

## Importante
El umbral de 15 cm es provisional: debe calibrarse midiendo la distancia desde la posición del sensor hasta la tubería vacía y definiendo el nivel de acumulación que se considerará obstrucción.
El backend y el esquema de base de datos deben tener el sensor `US-001`, variable `distancia_residuos` y el endpoint descrito. El proyecto previo utiliza Supabase PostgreSQL; la rúbrica original menciona MySQL localhost, así que debe resolverse la elección de motor antes de la demostración final.
