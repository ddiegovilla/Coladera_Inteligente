/*
 * COLADERA INTELIGENTE
 * NodeMCU ESP8266 + HC-SR04 + LED (representa el futuro servo)
 * Entorno: VS Code + PlatformIO
 *
 * Conexiones:
 * HC-SR04 VCC -> VIN/5V, GND -> GND
 * HC-SR04 TRIG -> D6
 * HC-SR04 ECHO -> divisor resistivo -> D7 (NUNCA 5V directo al ESP8266)
 * LED ánodo -> resistencia 220-330 ohm -> D1
 * LED cátodo -> GND
 *
 * Flujo: HC-SR04 -> ESP8266 -> Wi-Fi -> API REST -> base de datos.
 * Este firmware NO se conecta directamente a la base de datos.
 *
 * API esperada:
 * GET  /api/config
 * POST /api/mediciones
 * JSON: {"sensorCode":"US-001","variableName":"distancia_residuos","value":12.5}
 *
 * Antes de compilar, completa Wi-Fi, URL de API y token.
 */

#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClient.h>
#include <ArduinoJson.h>

// -------- CONFIGURACIÓN --------
const char* WIFI_SSID = "Deco";
const char* WIFI_PASSWORD = "Mapetech1$";

// Sustituir por la IP LAN de la Mac, NO usar localhost.
// Ejemplo: http://192.168.1.35:3000
const char* API_BASE_URL = "http://192.168.68.67:3000";
const char* API_TOKEN = "444acbe2cf806651da035ecfe05a696745882795e7eb6ae53f2942e082b3eb3f";

// Debe coincidir con el código del sensor en la base de datos/API.
const char* SENSOR_CODE = "US-001";

// Pines NodeMCU ESP8266
constexpr uint8_t PIN_TRIG = D6;
constexpr uint8_t PIN_ECHO = D7;
constexpr uint8_t PIN_LED  = D1;

// Parámetros iniciales: ajustar después de medir la tubería real.
float UMBRAL_BASURA_CM = 15.0f;
constexpr unsigned long INTERVALO_LECTURA_MS = 1000UL;
constexpr unsigned long TIMEOUT_ECHO_US = 30000UL;

WiFiClient wifiClient;
unsigned long ultimaLectura = 0;
bool estadoLedAnterior = false;

// -------- WI-FI --------
bool conectarWiFi() {
  if (WiFi.status() == WL_CONNECTED) return true;

  Serial.printf("\nConectando a Wi-Fi: %s\n", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  unsigned long inicio = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - inicio < 20000UL) {
    delay(500);
    Serial.print(".");
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWi-Fi conectado.");
    Serial.print("IP NodeMCU: ");
    Serial.println(WiFi.localIP());
    return true;
  }

  Serial.println("\nERROR: no se pudo conectar al Wi-Fi.");
  return false;
}

// -------- HTTP --------
bool peticionHttp(const char* metodo, const String& endpoint,
                  const String& payload, String& respuesta, int& codigo) {
  respuesta = "";
  codigo = -1;
  if (!conectarWiFi()) return false;

  HTTPClient http;
  String url = String(API_BASE_URL) + endpoint;

  if (!http.begin(wifiClient, url)) {
    Serial.println("ERROR: no se pudo iniciar HTTP.");
    return false;
  }

  http.setTimeout(7000);
  http.addHeader("x-api-key", API_TOKEN);
  http.addHeader("Content-Type", "application/json");

  if (strcmp(metodo, "GET") == 0) codigo = http.GET();
  else codigo = http.POST(payload);

  if (codigo > 0) {
    respuesta = http.getString();
    Serial.printf("HTTP %s -> %d\n", metodo, codigo);
    Serial.println(respuesta);
  } else {
    Serial.printf("Error HTTP: %s\n", http.errorToString(codigo).c_str());
  }

  http.end();
  return codigo >= 200 && codigo < 300;
}

// -------- CONFIGURACIÓN DESDE API --------
void obtenerUmbral() {
  String respuesta;
  int codigo;
  if (!peticionHttp("GET", "/api/config", "", respuesta, codigo)) {
    Serial.println("Se conserva umbral local de respaldo.");
    return;
  }

  JsonDocument doc;
  if (deserializeJson(doc, respuesta)) {
    Serial.println("JSON de configuración inválido.");
    return;
  }

  if (!doc["config"]["umbral_obstruccion_cm"].isNull()) {
    UMBRAL_BASURA_CM = doc["config"]["umbral_obstruccion_cm"].as<float>();
    Serial.printf("Umbral configurado: %.1f cm\n", UMBRAL_BASURA_CM);
  }
}

// -------- LECTURA HC-SR04 --------
float leerDistanciaCm() {
  digitalWrite(PIN_TRIG, LOW);
  delayMicroseconds(3);
  digitalWrite(PIN_TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(PIN_TRIG, LOW);

  unsigned long duracion = pulseIn(PIN_ECHO, HIGH, TIMEOUT_ECHO_US);
  if (duracion == 0) return -1.0f;

  return (duracion * 0.0343f) / 2.0f;
}

// -------- ENVÍO DE MEDICIÓN --------
bool enviarMedicion(float distancia) {
  JsonDocument doc;
  doc["sensorCode"] = SENSOR_CODE;
  doc["variableName"] = "distancia_residuos";
  doc["value"] = distancia;

  String payload;
  serializeJson(doc, payload);

  String respuesta;
  int codigo;
  return peticionHttp("POST", "/api/mediciones", payload, respuesta, codigo);
}

// -------- INICIALIZACIÓN --------
void setup() {
  Serial.begin(115200);
  delay(300);

  pinMode(PIN_TRIG, OUTPUT);
  pinMode(PIN_ECHO, INPUT);
  pinMode(PIN_LED, OUTPUT);
  digitalWrite(PIN_TRIG, LOW);
  digitalWrite(PIN_LED, LOW);

  Serial.println("\n=== COLADERA INTELIGENTE ===");
  conectarWiFi();
  if (WiFi.status() == WL_CONNECTED) obtenerUmbral();
}

// -------- CICLO PRINCIPAL --------
void loop() {
  if (millis() - ultimaLectura < INTERVALO_LECTURA_MS) {
    delay(20);
    return;
  }
  ultimaLectura = millis();

  float distancia = leerDistanciaCm();

  if (distancia <= 0.0f || distancia > 400.0f) {
    Serial.println("Lectura HC-SR04 inválida/timeout. Se descarta.");
    digitalWrite(PIN_LED, LOW);
    return;
  }

  Serial.printf("\nDistancia medida: %.2f cm\n", distancia);

  bool hayBasura = distancia <= UMBRAL_BASURA_CM;
  digitalWrite(PIN_LED, hayBasura ? HIGH : LOW);

  Serial.printf("Estado: %s\n", hayBasura ? "POSIBLE BASURA/OBSTRUCCION" : "TUBERIA DESPEJADA");
  Serial.printf("LED: %s\n", hayBasura ? "ENCENDIDO (representa servo)" : "APAGADO");

  // Enviar la lectura para que quede almacenada en la base.
  bool enviado = enviarMedicion(distancia);
  if (!enviado) {
    Serial.println("No se confirmó el registro de la medición en la API.");
  }

  if (hayBasura != estadoLedAnterior) {
    Serial.println("Cambio de estado detectado en el indicador LED.");
    estadoLedAnterior = hayBasura;
  }
}
