# API REST — Coladera Inteligente (HC-SR04 + LED)

## Arquitectura
NodeMCU ESP8266 -> Wi-Fi -> API REST Node.js -> MySQL local. El microcontrolador nunca se conecta directamente a MySQL.

## Archivos
- `RestApi-EquipoX-Matricula.js`: servidor REST.
- `ScriptCreacionBaseDatos_iot_EquipoX_MySQL.sql`: esquema limpio, sin registros ficticios.
- `Migracion_Limpiar_PIR_y_Datos_Prueba.sql`: limpia la instalación actual y conserva la coladera, NodeMCU, HC-SR04 y LED.
- `RegistroInicial_Hardware.sql`: registra los elementos del prototipo al comenzar la prueba física; ajustar ubicación y distancias reales.

## Preparar la instalación actual
1. Hacer respaldo: `mysqldump -u root coladera_inteligente > respaldo_coladera.sql`
2. Ejecutar una sola vez la migración: `mysql -u root < Migracion_Limpiar_PIR_y_Datos_Prueba.sql`
3. Verificar: `mysql -u root -e "USE coladera_inteligente; SELECT * FROM Sensor; SELECT * FROM Actuador; SELECT * FROM Medicion; SELECT * FROM Alerta; SELECT * FROM AccionLimpieza;"`

No ejecutes el script de creación encima de la base existente: es para crear desde cero. La migración vacía las ocho tablas y quita la restricción heredada que no permitía registrar el apagado del LED. Ejecútala una sola vez.

## Configuración API
Requiere Node.js 20+ y MySQL local.

```bash
npm install
cp .env.example .env
```

Edita `.env` con tu contraseña MySQL y un token aleatorio largo. Si root no tiene contraseña local, deja `DB_PASSWORD=` vacío para pruebas locales; para una configuración final se recomienda un usuario MySQL dedicado con permisos solo sobre `coladera_inteligente`.

Cuando se vaya a probar el circuito, calibra y ejecuta `RegistroInicial_Hardware.sql` una sola vez. Luego inicia:

```bash
npm start
```

## Endpoints
- `GET /api/health` — comprueba API y MySQL (sin token).
- `GET /api/config` — devuelve umbral (requiere `x-api-key`).
- `GET /api/mediciones/ultimas?limit=20` — últimas lecturas (requiere token).
- `POST /api/mediciones` — almacena medición y genera alerta/evento de cambio de estado (requiere token).

Cabecera: `x-api-key: valor_de_API_TOKEN`.

Ejemplo JSON POST:
```json
{"sensorCode":"US-001","variableName":"distancia_residuos","value":12.5}
```

`AccionLimpieza` registra cambios del LED indicador, que representa la futura activación del servomotor; no significa que se haya realizado una limpieza física.
