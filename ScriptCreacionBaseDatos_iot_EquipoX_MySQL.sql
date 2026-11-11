-- Coladera Inteligente | MySQL 8.0.16+
-- Esquema limpio: NO inserta dispositivos ni mediciones ficticias.
-- Los registros de instalación se agregan después de conectar el hardware.
CREATE DATABASE IF NOT EXISTS coladera_inteligente CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE coladera_inteligente;

CREATE TABLE Coladera (
 id_coladera BIGINT AUTO_INCREMENT PRIMARY KEY,
 codigo VARCHAR(50) NOT NULL UNIQUE,
 calle VARCHAR(150) NOT NULL,
 colonia VARCHAR(100) NOT NULL,
 municipio VARCHAR(100) NOT NULL,
 estado_operativo VARCHAR(30) NOT NULL DEFAULT 'ACTIVA',
 distancia_referencia_cm DECIMAL(8,2) NOT NULL,
 umbral_obstruccion_cm DECIMAL(8,2) NOT NULL,
 fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT ck_coladera_estado CHECK (estado_operativo IN ('ACTIVA','MANTENIMIENTO','FUERA_SERVICIO')),
 CONSTRAINT ck_coladera_distancia CHECK (distancia_referencia_cm > 0 AND umbral_obstruccion_cm > 0)
) ENGINE=InnoDB;

CREATE TABLE Dispositivo (
 id_dispositivo BIGINT AUTO_INCREMENT PRIMARY KEY,
 numero_serie VARCHAR(100) NOT NULL UNIQUE,
 modelo VARCHAR(100) NOT NULL,
 estado_conexion VARCHAR(30) NOT NULL DEFAULT 'DESCONOCIDO',
 fecha_instalacion TIMESTAMP NULL,
 id_coladera BIGINT NOT NULL,
 CONSTRAINT fk_dispositivo_coladera FOREIGN KEY (id_coladera) REFERENCES Coladera(id_coladera)
) ENGINE=InnoDB;

CREATE TABLE Sensor (
 id_sensor BIGINT AUTO_INCREMENT PRIMARY KEY,
 codigo_sensor VARCHAR(50) NOT NULL UNIQUE,
 tipo_sensor VARCHAR(50) NOT NULL,
 modelo VARCHAR(100),
 estado_sensor VARCHAR(30) NOT NULL DEFAULT 'ACTIVO',
 id_dispositivo BIGINT NOT NULL,
 CONSTRAINT fk_sensor_dispositivo FOREIGN KEY (id_dispositivo) REFERENCES Dispositivo(id_dispositivo),
 CONSTRAINT ck_sensor_tipo CHECK (tipo_sensor IN ('ULTRASONICO','OTRO'))
) ENGINE=InnoDB;

CREATE TABLE TipoVariable (
 id_tipo_variable BIGINT AUTO_INCREMENT PRIMARY KEY,
 nombre_variable VARCHAR(80) NOT NULL UNIQUE,
 unidad_medida VARCHAR(30) NOT NULL,
 descripcion TEXT
) ENGINE=InnoDB;

CREATE TABLE Medicion (
 id_medicion BIGINT AUTO_INCREMENT PRIMARY KEY,
 valor DECIMAL(12,4) NOT NULL,
 fecha_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 calidad_dato VARCHAR(30) NOT NULL DEFAULT 'VALIDO',
 id_sensor BIGINT NOT NULL,
 id_tipo_variable BIGINT NOT NULL,
 CONSTRAINT fk_medicion_sensor FOREIGN KEY (id_sensor) REFERENCES Sensor(id_sensor),
 CONSTRAINT fk_medicion_variable FOREIGN KEY (id_tipo_variable) REFERENCES TipoVariable(id_tipo_variable),
 CONSTRAINT ck_medicion_calidad CHECK (calidad_dato IN ('VALIDO','SOSPECHOSO','PRUEBA_SIMULADA'))
) ENGINE=InnoDB;

CREATE TABLE Actuador (
 id_actuador BIGINT AUTO_INCREMENT PRIMARY KEY,
 codigo_actuador VARCHAR(50) NOT NULL UNIQUE,
 tipo_actuador VARCHAR(50) NOT NULL,
 estado_actual VARCHAR(30) NOT NULL DEFAULT 'INACTIVO',
 id_dispositivo BIGINT NOT NULL,
 CONSTRAINT fk_actuador_dispositivo FOREIGN KEY (id_dispositivo) REFERENCES Dispositivo(id_dispositivo)
) ENGINE=InnoDB;

CREATE TABLE Alerta (
 id_alerta BIGINT AUTO_INCREMENT PRIMARY KEY,
 tipo_alerta VARCHAR(60) NOT NULL,
 nivel_prioridad VARCHAR(30) NOT NULL,
 estado_alerta VARCHAR(30) NOT NULL DEFAULT 'ABIERTA',
 fecha_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 descripcion TEXT,
 id_medicion BIGINT NOT NULL,
 CONSTRAINT fk_alerta_medicion FOREIGN KEY (id_medicion) REFERENCES Medicion(id_medicion)
) ENGINE=InnoDB;

CREATE TABLE AccionLimpieza (
 id_accion BIGINT AUTO_INCREMENT PRIMARY KEY,
 fecha_inicio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 fecha_fin TIMESTAMP NULL,
 resultado VARCHAR(50) NOT NULL DEFAULT 'PENDIENTE',
 id_actuador BIGINT NOT NULL,
 id_alerta BIGINT NULL,
 obstruccion_detectada TINYINT(1) NOT NULL,
 CONSTRAINT fk_accion_actuador FOREIGN KEY (id_actuador) REFERENCES Actuador(id_actuador),
 CONSTRAINT fk_accion_alerta FOREIGN KEY (id_alerta) REFERENCES Alerta(id_alerta) ON DELETE SET NULL,
 CONSTRAINT ck_accion_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
) ENGINE=InnoDB;

CREATE INDEX idx_dispositivo_coladera ON Dispositivo(id_coladera);
CREATE INDEX idx_sensor_dispositivo ON Sensor(id_dispositivo);
CREATE INDEX idx_medicion_sensor_fecha ON Medicion(id_sensor,fecha_hora);
CREATE INDEX idx_medicion_variable_fecha ON Medicion(id_tipo_variable,fecha_hora);
CREATE INDEX idx_actuador_dispositivo ON Actuador(id_dispositivo);
CREATE INDEX idx_alerta_medicion_fecha ON Alerta(id_medicion,fecha_hora);
CREATE INDEX idx_accion_actuador_fecha ON AccionLimpieza(id_actuador,fecha_inicio);
CREATE INDEX idx_accion_alerta ON AccionLimpieza(id_alerta);
