#include <DHT.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

/******** PIN DEFINITIONS ********/
#define DHTPIN          4
#define DHTTYPE         DHT11

#define GAS_PIN         34
#define IR_DOOR_PIN     26

#define LED_PIN         2
#define BUZZER_PIN      15

/******** SPOILAGE THRESHOLDS ********/
#define TEMP_WARNING      35
#define HUMIDITY_WARNING  70
#define GAS_WARNING       1000
#define GAS_SPOILAGE      1800

/******** WIFI ********/
const char* SSID =
"Harshu";

const char* PASSWORD =
"harshu26";

/******** FASTAPI ********/
const char* SERVER =
"http://10.168.12.204:8000/sensor";

/******** OBJECTS ********/
DHT dht(DHTPIN, DHTTYPE);

/******** CAMERA TRIGGER ********/
bool previousDoorState = false;

/************************************************/
/* WIFI CONNECT */
/************************************************/
void connectWiFi()
{
  Serial.println();
  Serial.print("Connecting to WiFi ");
  Serial.println(SSID);

  WiFi.mode(WIFI_STA);
  WiFi.begin(SSID, PASSWORD);

  int attempts = 0;

  while (WiFi.status() != WL_CONNECTED && attempts < 20)
  {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  Serial.println();

  if (WiFi.status() == WL_CONNECTED)
  {
    Serial.println("WiFi Connected");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
  }
  else
  {
    Serial.println("WiFi FAILED");
  }
}

/************************************************/
/* SEND DATA TO FASTAPI */
/************************************************/
void sendData(
  float temp,
  float hum,
  int gas,
  bool door,
  bool spoilage,
  int freshnessScore,
  String status
)
{
  if (WiFi.status() != WL_CONNECTED)
  {
    connectWiFi();
    return;
  }

  WiFiClient client;
  HTTPClient http;
  http.begin(client, SERVER);

  http.addHeader(
    "Content-Type",
    "application/json"
  );

  StaticJsonDocument<512> doc;

  doc["temperature"] = temp;
  doc["humidity"] = hum;
  doc["gas_value"] = gas;
  doc["door_open"] = door;
  doc["spoilage"] = spoilage;
  doc["freshness_score"] = freshnessScore;
  doc["status"] = status;

  String body;

  serializeJson(doc, body);

  Serial.println("\nSending JSON:");
  Serial.println(body);

  int code = http.POST(body);

  Serial.print("HTTP Response: ");
  Serial.println(code);

  if (code > 0)
  {
    Serial.println(http.getString());
  }

  http.end();
}

/************************************************/
/* SETUP */
/************************************************/
void setup()
{
  Serial.begin(115200);

  /* UART TO ESP32-CAM */
  Serial2.begin(
    115200,
    SERIAL_8N1,
    16,
    17
  );

  pinMode(IR_DOOR_PIN, INPUT);

  pinMode(LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  digitalWrite(LED_PIN, LOW);
  digitalWrite(BUZZER_PIN, LOW);

  dht.begin();

  connectWiFi();

  Serial.println(
    "Smart Food Management System Ready"
  );
}

/************************************************/
/* LOOP */
/************************************************/
void loop()
{
  float temperature =
    dht.readTemperature();

  float humidity =
    dht.readHumidity();

  int gasValue =
    analogRead(GAS_PIN);

  bool doorOpen =
    (
      digitalRead(IR_DOOR_PIN)
      == HIGH
    );

  /******** DHT VALIDATION ********/

  if (
    isnan(temperature) ||
    isnan(humidity)
  )
  {
    Serial.println(
      "DHT Read Failed"
    );

    delay(2000);
    return;
  }

  /******** FRESHNESS SCORE ********/

  int freshnessScore = 100;

  if (temperature > TEMP_WARNING)
  {
    freshnessScore -= 20;
  }

  if (humidity > HUMIDITY_WARNING)
  {
    freshnessScore -= 15;
  }

  if (gasValue > GAS_WARNING)
  {
    freshnessScore -= 20;
  }

  if (gasValue > GAS_SPOILAGE)
  {
    freshnessScore -= 25;
  }

  if (freshnessScore < 0)
  {
    freshnessScore = 0;
  }

  String status;

  if (freshnessScore >= 80)
  {
    status = "FRESH";
  }
  else if (freshnessScore >= 50)
  {
    status = "USE_SOON";
  }
  else
  {
    status = "NEAR_EXPIRY";
  }

  bool spoilage = false;

  if (
    gasValue > GAS_SPOILAGE ||
    freshnessScore < 50
  )
  {
    spoilage = true;
  }

  /******** ALERTS ********/

  // Turn on LED and Buzzer if food status is not FRESH
  if (status != "FRESH")
  {
    digitalWrite(
      LED_PIN,
      HIGH
    );

    digitalWrite(
      BUZZER_PIN,
      HIGH
    );
    
    Serial.println("⚠️  ALERT: Food status is NOT FRESH!");
  }
  else
  {
    digitalWrite(
      LED_PIN,
      LOW
    );

    digitalWrite(
      BUZZER_PIN,
      LOW
    );
    
    Serial.println("✓ Status: FRESH - No alerts");
  }

  /******** DOOR CLOSED -> CAMERA ********/

  if (
      !doorOpen &&
      previousDoorState
  )
  {
    Serial.println(
      "Door Closed"
    );

    Serial2.println(
      "CAPTURE"
    );

    Serial.println(
      "Camera Triggered"
    );
  }

  previousDoorState =
    doorOpen;

  /******** SEND TO BACKEND ********/

  sendData(
    temperature,
    humidity,
    gasValue,
    doorOpen,
    spoilage,
    freshnessScore,
    status
  );

  /******** SERIAL MONITOR ********/

  Serial.println(
    "\n========== STATUS =========="
  );

  Serial.print(
    "Temperature : "
  );
  Serial.println(
    temperature
  );

  Serial.print(
    "Humidity    : "
  );
  Serial.println(
    humidity
  );

  Serial.print(
    "Gas Value   : "
  );
  Serial.println(
    gasValue
  );

  Serial.print(
    "Gas Warning Threshold : "
  );
  Serial.println(
    GAS_WARNING
  );

  Serial.print(
    "Gas Spoilage Threshold: "
  );
  Serial.println(
    GAS_SPOILAGE
  );

  Serial.print(
    "Door        : "
  );
  Serial.println(
    doorOpen
    ?
    "OPEN"
    :
    "CLOSED"
  );

  Serial.print(
    "Freshness   : "
  );
  Serial.println(
    freshnessScore
  );

  Serial.print(
    "Status      : "
  );
  Serial.println(
    status
  );

  Serial.print(
    "Spoilage    : "
  );
  Serial.println(
    spoilage
    ?
    "YES"
    :
    "NO"
  );

  Serial.println(
    "============================\n"
  );

  delay(3000);
}
