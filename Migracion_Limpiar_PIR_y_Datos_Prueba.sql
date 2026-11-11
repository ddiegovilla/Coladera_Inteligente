-- Ejecutar UNA SOLA VEZ sobre la base existente coladera_inteligente.
-- Deja las 8 tablas vacías: no habrá registros de prueba ni dispositivos
-- declarados como instalados antes de conectar el hardware real.
USE coladera_inteligente;
SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM AccionLimpieza;
DELETE FROM Alerta;
DELETE FROM Medicion;
DELETE FROM Sensor;
DELETE FROM Actuador;
DELETE FROM TipoVariable;
DELETE FROM Dispositivo;
DELETE FROM Coladera;
SET FOREIGN_KEY_CHECKS = 1;

-- La instalación actual ya tiene obstruccion_detectada y no pir_seguro.
-- Se elimina el CHECK heredado que impedía registrar el apagado del LED.
ALTER TABLE AccionLimpieza DROP CHECK ck_accion_obstruccion;

-- Verificación: las ocho tablas deben quedar vacías.
SELECT 'Coladera' AS tabla, COUNT(*) AS registros FROM Coladera
UNION ALL SELECT 'Dispositivo', COUNT(*) FROM Dispositivo
UNION ALL SELECT 'Sensor', COUNT(*) FROM Sensor
UNION ALL SELECT 'TipoVariable', COUNT(*) FROM TipoVariable
UNION ALL SELECT 'Medicion', COUNT(*) FROM Medicion
UNION ALL SELECT 'Actuador', COUNT(*) FROM Actuador
UNION ALL SELECT 'Alerta', COUNT(*) FROM Alerta
UNION ALL SELECT 'AccionLimpieza', COUNT(*) FROM AccionLimpieza;
