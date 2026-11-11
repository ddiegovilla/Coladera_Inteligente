-- Ejecutar SOLO cuando se vaya a probar el hardware real.
-- Ajustar calle, colonia, distancia de referencia y umbral después de medir la instalación.
USE coladera_inteligente;

INSERT INTO Coladera (codigo, calle, colonia, municipio, estado_operativo, distancia_referencia_cm, umbral_obstruccion_cm)
VALUES ('COL-MTY-001', 'POR DEFINIR', 'POR DEFINIR', 'Monterrey', 'ACTIVA', 40.00, 15.00);

INSERT INTO Dispositivo (numero_serie, modelo, estado_conexion, fecha_instalacion, id_coladera)
SELECT 'ESP8266-COL-001', 'NodeMCU ESP8266', 'DESCONOCIDO', NOW(), id_coladera
FROM Coladera WHERE codigo = 'COL-MTY-001';

INSERT INTO Sensor (codigo_sensor, tipo_sensor, modelo, estado_sensor, id_dispositivo)
SELECT 'US-001', 'ULTRASONICO', 'HC-SR04', 'ACTIVO', id_dispositivo
FROM Dispositivo WHERE numero_serie = 'ESP8266-COL-001';

INSERT INTO TipoVariable (nombre_variable, unidad_medida, descripcion)
VALUES ('distancia_residuos', 'cm', 'Distancia medida por HC-SR04 entre el sensor y la superficie de residuos.');

INSERT INTO Actuador (codigo_actuador, tipo_actuador, estado_actual, id_dispositivo)
SELECT 'LED-001', 'LED_INDICADOR_SERVO', 'INACTIVO', id_dispositivo
FROM Dispositivo WHERE numero_serie = 'ESP8266-COL-001';
