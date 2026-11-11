// API REST local: NodeMCU ESP8266 -> Node.js -> MySQL.
// El NodeMCU nunca se conecta directamente a MySQL.
import http from 'node:http';
import mysql from 'mysql2/promise';
import 'dotenv/config';

const required = ['DB_HOST', 'DB_USER', 'DB_NAME', 'API_TOKEN'];
for (const key of required) {
  if (!process.env[key]) throw new Error(`Falta configurar ${key} en .env`);
}

const PORT = Number(process.env.PORT || 3000);
const COLADERA_CODE = process.env.COLADERA_CODE || 'COL-MTY-001';
const SENSOR_CODE = process.env.SENSOR_CODE || 'US-001';
const ACTUATOR_CODE = process.env.ACTUATOR_CODE || 'LED-001';
const API_TOKEN = process.env.API_TOKEN;

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  timezone: 'Z',
  decimalNumbers: true
});

function send(res, status, payload) {
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, x-api-key',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
  });
  res.end(JSON.stringify(payload));
}

async function readBody(req) {
  let raw = '';
  for await (const chunk of req) {
    raw += chunk;
    if (raw.length > 12000) throw Object.assign(new Error('Payload demasiado grande'), { status: 413 });
  }
  try { return raw ? JSON.parse(raw) : {}; }
  catch { throw Object.assign(new Error('JSON inválido'), { status: 400 }); }
}

async function getConfig(conn = pool) {
  const [rows] = await conn.execute(
    'SELECT codigo, distancia_referencia_cm, umbral_obstruccion_cm FROM Coladera WHERE codigo = ?',
    [COLADERA_CODE]
  );
  return rows[0] || null;
}

async function route(req, res) {
  if (req.method === 'OPTIONS') return send(res, 204, {});
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const path = url.pathname;

  if (req.method === 'GET' && path === '/api/health') {
    try {
      await pool.query('SELECT 1');
      return send(res, 200, { ok: true, service: 'Coladera Inteligente REST API', database: 'MySQL conectado', timestamp: new Date().toISOString() });
    } catch (error) {
      console.error(error);
      return send(res, 503, { ok: false, error: 'MySQL no disponible' });
    }
  }

  if (!path.startsWith('/api/')) return send(res, 404, { ok: false, error: 'Ruta no encontrada' });
  if (req.headers['x-api-key'] !== API_TOKEN) return send(res, 401, { ok: false, error: 'API key inválida o ausente' });

  try {
    if (req.method === 'GET' && path === '/api/config') {
      const config = await getConfig();
      if (!config) return send(res, 409, { ok: false, error: 'Falta registrar la coladera. Ejecuta RegistroInicial_Hardware.sql y configura sus valores.' });
      return send(res, 200, { ok: true, config });
    }

    if (req.method === 'GET' && path === '/api/mediciones/ultimas') {
      const requested = Number(url.searchParams.get('limit') || 20);
      const limit = Math.min(Math.max(Number.isInteger(requested) ? requested : 20, 1), 100);
      const [rows] = await pool.execute(
        `SELECT m.id_medicion, m.valor, m.fecha_hora, m.calidad_dato,
                s.codigo_sensor, tv.nombre_variable, tv.unidad_medida
         FROM Medicion m
         JOIN Sensor s ON s.id_sensor = m.id_sensor
         JOIN TipoVariable tv ON tv.id_tipo_variable = m.id_tipo_variable
         WHERE s.codigo_sensor = ? AND tv.nombre_variable = 'distancia_residuos'
         ORDER BY m.fecha_hora DESC LIMIT ${limit}`,
        [SENSOR_CODE]
      );
      return send(res, 200, { ok: true, data: rows });
    }

    if (req.method === 'POST' && path === '/api/mediciones') {
      const body = await readBody(req);
      const sensorCode = body.sensorCode;
      const variableName = body.variableName;
      const value = Number(body.value);
      if (sensorCode !== SENSOR_CODE || variableName !== 'distancia_residuos' || body.value === undefined || body.value === null || body.value === '' || !Number.isFinite(value)) {
        return send(res, 400, { ok: false, error: `Se requiere sensorCode ${SENSOR_CODE}, variableName distancia_residuos y value numérico.` });
      }
      if (value <= 0 || value > 400) return send(res, 400, { ok: false, error: 'Distancia fuera del rango válido del HC-SR04 (0, 400] cm.' });

      const conn = await pool.getConnection();
      try {
        await conn.beginTransaction();
        const config = await getConfig(conn);
        if (!config) throw Object.assign(new Error('Coladera no registrada; falta ejecutar RegistroInicial_Hardware.sql.'), { status: 409 });
        const [sensorRows] = await conn.execute('SELECT id_sensor FROM Sensor WHERE codigo_sensor = ? AND estado_sensor = \'ACTIVO\'', [sensorCode]);
        const [variableRows] = await conn.execute('SELECT id_tipo_variable FROM TipoVariable WHERE nombre_variable = ? AND unidad_medida = \'cm\'', [variableName]);
        const [actuatorRows] = await conn.execute('SELECT id_actuador, estado_actual FROM Actuador WHERE codigo_actuador = ? FOR UPDATE', [ACTUATOR_CODE]);
        if (!sensorRows.length || !variableRows.length || !actuatorRows.length) {
          throw Object.assign(new Error('Falta registrar HC-SR04, distancia_residuos o LED. Revisa RegistroInicial_Hardware.sql.'), { status: 409 });
        }

        const [measurementResult] = await conn.execute(
          `INSERT INTO Medicion (valor, calidad_dato, id_sensor, id_tipo_variable) VALUES (?, 'VALIDO', ?, ?)`,
          [value, sensorRows[0].id_sensor, variableRows[0].id_tipo_variable]
        );
        const measurementId = measurementResult.insertId;
        const obstruction = value <= Number(config.umbral_obstruccion_cm);
        const newLedState = obstruction ? 'ENCENDIDO' : 'APAGADO';
        const oldLedState = String(actuatorRows[0].estado_actual).toUpperCase();
        let alertId = null;

        // Se genera una alerta solo al entrar en una nueva condición de obstrucción.
        if (obstruction && oldLedState !== 'ENCENDIDO') {
          const [alertResult] = await conn.execute(
            `INSERT INTO Alerta (tipo_alerta, nivel_prioridad, estado_alerta, descripcion, id_medicion)
             VALUES ('POSIBLE_OBSTRUCCION', 'ALTA', 'ABIERTA', ?, ?)`,
            [`Distancia detectada: ${value.toFixed(2)} cm; umbral: ${Number(config.umbral_obstruccion_cm).toFixed(2)} cm.`, measurementId]
          );
          alertId = alertResult.insertId;
        }

        // AccionLimpieza registra el evento del actuador indicador (LED), no una limpieza física.
        const stateChanged = oldLedState !== newLedState;
        if (stateChanged) {
          await conn.execute('UPDATE Actuador SET estado_actual = ? WHERE id_actuador = ?', [newLedState, actuatorRows[0].id_actuador]);
          await conn.execute(
            `INSERT INTO AccionLimpieza (resultado, id_actuador, id_alerta, obstruccion_detectada)
             VALUES (?, ?, ?, ?)`,
            [`LED_${newLedState}`, actuatorRows[0].id_actuador, alertId, obstruction ? 1 : 0]
          );
        }

        await conn.commit();
        return send(res, 201, {
          ok: true,
          measurement: { id_medicion: measurementId, valor: value, unidad: 'cm' },
          obstruction,
          thresholdCm: Number(config.umbral_obstruccion_cm),
          ledState: newLedState,
          stateChanged,
          alertId
        });
      } catch (error) {
        await conn.rollback();
        throw error;
      } finally {
        conn.release();
      }
    }

    return send(res, 404, { ok: false, error: 'Endpoint no encontrado' });
  } catch (error) {
    console.error(error);
    return send(res, error.status || 500, { ok: false, error: error.message || 'Error interno' });
  }
}

const server = http.createServer((req, res) => {
  route(req, res).catch(error => {
    console.error(error);
    send(res, 500, { ok: false, error: 'Error interno inesperado' });
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Coladera REST API escuchando en puerto ${PORT}`);
  console.log('GET /api/health | GET /api/config | GET /api/mediciones/ultimas | POST /api/mediciones');
});

process.on('SIGINT', async () => {
  await pool.end();
  process.exit(0);
});
