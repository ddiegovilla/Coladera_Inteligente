-- MySQL dump 10.13  Distrib 26.10.0, for macos27.0 (arm64)
--
-- Host: localhost    Database: coladera_inteligente
-- ------------------------------------------------------
-- Server version	26.10.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ 'eedc1668-dd53-11f1-8d07-943f80c24f43:1-35';

--
-- Table structure for table `AccionLimpieza`
--

DROP TABLE IF EXISTS `AccionLimpieza`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `AccionLimpieza` (
  `id_accion` bigint NOT NULL AUTO_INCREMENT,
  `fecha_inicio` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_fin` timestamp NULL DEFAULT NULL,
  `resultado` varchar(50) NOT NULL DEFAULT 'PENDIENTE',
  `id_actuador` bigint NOT NULL,
  `id_alerta` bigint DEFAULT NULL,
  `obstruccion_detectada` tinyint(1) NOT NULL,
  PRIMARY KEY (`id_accion`),
  KEY `idx_accion_actuador_fecha` (`id_actuador`,`fecha_inicio`),
  KEY `idx_accion_alerta` (`id_alerta`),
  CONSTRAINT `fk_accion_actuador` FOREIGN KEY (`id_actuador`) REFERENCES `Actuador` (`id_actuador`),
  CONSTRAINT `fk_accion_alerta` FOREIGN KEY (`id_alerta`) REFERENCES `Alerta` (`id_alerta`) ON DELETE SET NULL,
  CONSTRAINT `ck_accion_fechas` CHECK (((`fecha_fin` is null) or (`fecha_fin` >= `fecha_inicio`))),
  CONSTRAINT `ck_accion_obstruccion` CHECK (((`obstruccion_detectada` = true) or (`resultado` = _utf8mb4'CANCELADA')))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `AccionLimpieza`
--

LOCK TABLES `AccionLimpieza` WRITE;
/*!40000 ALTER TABLE `AccionLimpieza` DISABLE KEYS */;
/*!40000 ALTER TABLE `AccionLimpieza` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Actuador`
--

DROP TABLE IF EXISTS `Actuador`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Actuador` (
  `id_actuador` bigint NOT NULL AUTO_INCREMENT,
  `codigo_actuador` varchar(50) NOT NULL,
  `tipo_actuador` varchar(50) NOT NULL,
  `estado_actual` varchar(30) NOT NULL DEFAULT 'INACTIVO',
  `id_dispositivo` bigint NOT NULL,
  PRIMARY KEY (`id_actuador`),
  UNIQUE KEY `codigo_actuador` (`codigo_actuador`),
  KEY `idx_actuador_dispositivo` (`id_dispositivo`),
  CONSTRAINT `fk_actuador_dispositivo` FOREIGN KEY (`id_dispositivo`) REFERENCES `Dispositivo` (`id_dispositivo`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Actuador`
--

LOCK TABLES `Actuador` WRITE;
/*!40000 ALTER TABLE `Actuador` DISABLE KEYS */;
INSERT INTO `Actuador` VALUES (1,'SERVO-001','SERVOMOTOR','INACTIVO',1),(2,'LED-001','LED','INACTIVO',1);
/*!40000 ALTER TABLE `Actuador` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Alerta`
--

DROP TABLE IF EXISTS `Alerta`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Alerta` (
  `id_alerta` bigint NOT NULL AUTO_INCREMENT,
  `tipo_alerta` varchar(60) NOT NULL,
  `nivel_prioridad` varchar(30) NOT NULL,
  `estado_alerta` varchar(30) NOT NULL DEFAULT 'ABIERTA',
  `fecha_hora` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `descripcion` text,
  `id_medicion` bigint NOT NULL,
  PRIMARY KEY (`id_alerta`),
  KEY `idx_alerta_medicion_fecha` (`id_medicion`,`fecha_hora`),
  CONSTRAINT `fk_alerta_medicion` FOREIGN KEY (`id_medicion`) REFERENCES `Medicion` (`id_medicion`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Alerta`
--

LOCK TABLES `Alerta` WRITE;
/*!40000 ALTER TABLE `Alerta` DISABLE KEYS */;
/*!40000 ALTER TABLE `Alerta` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Coladera`
--

DROP TABLE IF EXISTS `Coladera`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Coladera` (
  `id_coladera` bigint NOT NULL AUTO_INCREMENT,
  `codigo` varchar(50) NOT NULL,
  `calle` varchar(150) NOT NULL,
  `colonia` varchar(100) NOT NULL,
  `municipio` varchar(100) NOT NULL,
  `estado_operativo` varchar(30) NOT NULL DEFAULT 'ACTIVA',
  `distancia_referencia_cm` decimal(8,2) NOT NULL,
  `umbral_obstruccion_cm` decimal(8,2) NOT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_coladera`),
  UNIQUE KEY `codigo` (`codigo`),
  CONSTRAINT `ck_coladera_distancia` CHECK (((`distancia_referencia_cm` > 0) and (`umbral_obstruccion_cm` > 0))),
  CONSTRAINT `ck_coladera_estado` CHECK ((`estado_operativo` in (_utf8mb4'ACTIVA',_utf8mb4'MANTENIMIENTO',_utf8mb4'FUERA_SERVICIO')))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Coladera`
--

LOCK TABLES `Coladera` WRITE;
/*!40000 ALTER TABLE `Coladera` DISABLE KEYS */;
INSERT INTO `Coladera` VALUES (1,'COL-MTY-001','Ubicacion de prueba','Por confirmar','Monterrey','ACTIVA',40.00,15.00,'2026-11-10 22:16:38');
/*!40000 ALTER TABLE `Coladera` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Dispositivo`
--

DROP TABLE IF EXISTS `Dispositivo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Dispositivo` (
  `id_dispositivo` bigint NOT NULL AUTO_INCREMENT,
  `numero_serie` varchar(100) NOT NULL,
  `modelo` varchar(100) NOT NULL,
  `estado_conexion` varchar(30) NOT NULL DEFAULT 'DESCONOCIDO',
  `fecha_instalacion` timestamp NULL DEFAULT NULL,
  `id_coladera` bigint NOT NULL,
  PRIMARY KEY (`id_dispositivo`),
  UNIQUE KEY `numero_serie` (`numero_serie`),
  KEY `idx_dispositivo_coladera` (`id_coladera`),
  CONSTRAINT `fk_dispositivo_coladera` FOREIGN KEY (`id_coladera`) REFERENCES `Coladera` (`id_coladera`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Dispositivo`
--

LOCK TABLES `Dispositivo` WRITE;
/*!40000 ALTER TABLE `Dispositivo` DISABLE KEYS */;
INSERT INTO `Dispositivo` VALUES (1,'ESP8266-COL-001','NodeMCU ESP8266','DESCONOCIDO','2026-11-10 22:16:38',1);
/*!40000 ALTER TABLE `Dispositivo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Medicion`
--

DROP TABLE IF EXISTS `Medicion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Medicion` (
  `id_medicion` bigint NOT NULL AUTO_INCREMENT,
  `valor` decimal(12,4) NOT NULL,
  `fecha_hora` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `calidad_dato` varchar(30) NOT NULL DEFAULT 'VALIDO',
  `id_sensor` bigint NOT NULL,
  `id_tipo_variable` bigint NOT NULL,
  PRIMARY KEY (`id_medicion`),
  UNIQUE KEY `uq_medicion_sensor_variable_fecha` (`id_sensor`,`id_tipo_variable`,`fecha_hora`),
  KEY `idx_medicion_sensor_fecha` (`id_sensor`,`fecha_hora`),
  KEY `idx_medicion_variable_fecha` (`id_tipo_variable`,`fecha_hora`),
  CONSTRAINT `fk_medicion_sensor` FOREIGN KEY (`id_sensor`) REFERENCES `Sensor` (`id_sensor`),
  CONSTRAINT `fk_medicion_variable` FOREIGN KEY (`id_tipo_variable`) REFERENCES `TipoVariable` (`id_tipo_variable`),
  CONSTRAINT `ck_medicion_calidad` CHECK ((`calidad_dato` in (_utf8mb4'VALIDO',_utf8mb4'SOSPECHOSO',_utf8mb4'PRUEBA_SIMULADA')))
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Medicion`
--

LOCK TABLES `Medicion` WRITE;
/*!40000 ALTER TABLE `Medicion` DISABLE KEYS */;
INSERT INTO `Medicion` VALUES (1,1.0000,'2026-11-10 22:06:38','PRUEBA_SIMULADA',1,1),(2,12.5000,'2026-11-10 22:07:38','PRUEBA_SIMULADA',2,2),(3,0.0000,'2026-11-10 22:11:38','PRUEBA_SIMULADA',1,1),(4,28.0000,'2026-11-10 22:12:38','PRUEBA_SIMULADA',2,2);
/*!40000 ALTER TABLE `Medicion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Sensor`
--

DROP TABLE IF EXISTS `Sensor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Sensor` (
  `id_sensor` bigint NOT NULL AUTO_INCREMENT,
  `codigo_sensor` varchar(50) NOT NULL,
  `tipo_sensor` varchar(50) NOT NULL,
  `modelo` varchar(100) DEFAULT NULL,
  `estado_sensor` varchar(30) NOT NULL DEFAULT 'ACTIVO',
  `id_dispositivo` bigint NOT NULL,
  PRIMARY KEY (`id_sensor`),
  UNIQUE KEY `codigo_sensor` (`codigo_sensor`),
  KEY `idx_sensor_dispositivo` (`id_dispositivo`),
  CONSTRAINT `fk_sensor_dispositivo` FOREIGN KEY (`id_dispositivo`) REFERENCES `Dispositivo` (`id_dispositivo`),
  CONSTRAINT `ck_sensor_tipo` CHECK ((`tipo_sensor` in (_utf8mb4'ULTRASONICO',_utf8mb4'PIR',_utf8mb4'DHT',_utf8mb4'LDR',_utf8mb4'LLUVIA',_utf8mb4'OTRO')))
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Sensor`
--

LOCK TABLES `Sensor` WRITE;
/*!40000 ALTER TABLE `Sensor` DISABLE KEYS */;
INSERT INTO `Sensor` VALUES (1,'PIR-001','PIR','HC-SR501 / confirmar modelo','ACTIVO',1),(2,'US-001','ULTRASONICO','HC-SR04','ACTIVO',1);
/*!40000 ALTER TABLE `Sensor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `TipoVariable`
--

DROP TABLE IF EXISTS `TipoVariable`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TipoVariable` (
  `id_tipo_variable` bigint NOT NULL AUTO_INCREMENT,
  `nombre_variable` varchar(80) NOT NULL,
  `unidad_medida` varchar(30) NOT NULL,
  `descripcion` text,
  PRIMARY KEY (`id_tipo_variable`),
  UNIQUE KEY `nombre_variable` (`nombre_variable`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `TipoVariable`
--

LOCK TABLES `TipoVariable` WRITE;
/*!40000 ALTER TABLE `TipoVariable` DISABLE KEYS */;
INSERT INTO `TipoVariable` VALUES (1,'movimiento','booleano','PIR: 1 movimiento; 0 sin movimiento'),(2,'distancia_residuos','cm','Distancia HC-SR04 a residuos'),(3,'temperatura','°C','Temperatura, si se integra DHT'),(4,'humedad','%','Humedad, si se integra DHT'),(5,'iluminacion','ADC','Lectura LDR, si se integra'),(6,'lluvia','ADC','Lectura sensor lluvia, si se integra');
/*!40000 ALTER TABLE `TipoVariable` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-10 16:39:47
