#include "esp_camera.h"
#include <WiFi.h>
#include <HTTPClient.h>

// ===========================
// Enter your WiFi credentials
// ===========================
const char* ssid = "Harshu";
const char* password = "harshu26";

// ===========================
// UPDATE THIS IP ADDRESS!
// Ensure this matches your PC's current IP
// ===========================
String serverName = "http://10.168.12.204:8000/upload-image"; 

// AI Thinker Camera Pins
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

// --- NEW: Flash LED Pin ---
#define FLASH_LED_PIN      4

void setup() {
  // Start Serial to communicate with the main ESP32
  Serial.begin(115200);

  Serial.println("ESP32-CAM Starting up...");

  // Initialize the Flash LED pin and ensure it is off
  pinMode(FLASH_LED_PIN, OUTPUT);
  digitalWrite(FLASH_LED_PIN, LOW);

  // Connect to WiFi
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println();
  Serial.print("WiFi Connected! Camera IP: ");
  Serial.println(WiFi.localIP());

  // Configure Camera
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;

  // Frame parameters - optimized for multiple captures
  if (psramFound()) {
    Serial.println("PSRAM found - using high quality settings");
    config.frame_size = FRAMESIZE_UXGA; // High resolution
    config.jpeg_quality = 10;
    config.fb_count = 1;  // Use only 1 buffer to save memory
  } else {
    Serial.println("PSRAM NOT found - using lower quality settings");
    config.frame_size = FRAMESIZE_SVGA; // Lower resolution if no PSRAM
    config.jpeg_quality = 12;
    config.fb_count = 1;
  }

  // Initialize Camera
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x", err);
    return;
  }
  
  Serial.println("Camera Ready! Waiting for CAPTURE command...");
}

void loop() {
  // Check if a command is received from the main ESP32 over UART
  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    command.trim(); // Remove whitespace/newlines

    if (command == "CAPTURE") {
      Serial.println("\n>>> Capture command received!");
      takePhotoAndSend();
      Serial.println(">>> Capture cycle complete.\n");
    }
  }
  
  // Small delay to prevent overwhelming the system
  delay(100);
}

void takePhotoAndSend() {
  // Print memory info before capture
  Serial.print("Free Heap before capture: ");
  Serial.print(ESP.getFreeHeap());
  Serial.println(" bytes");

  camera_fb_t * fb = NULL;

  Serial.println("Turning Flash ON...");
  digitalWrite(FLASH_LED_PIN, HIGH);
  
  // Give the camera 1 full second to adjust auto-exposure and white balance
  // Without this, the photo will be totally washed out or totally dark.
  delay(1000); 
  
  // Take Picture with Camera
  fb = esp_camera_fb_get();  

  // Turn Flash OFF immediately after taking the picture
  digitalWrite(FLASH_LED_PIN, LOW);
  Serial.println("Flash OFF.");

  if (!fb) {
    Serial.println("Failed to capture image!");
    Serial.print("Free Heap after failed capture: ");
    Serial.print(ESP.getFreeHeap());
    Serial.println(" bytes");
    return;
  }
  
  Serial.print("Image captured! Size: ");
  Serial.print(fb->len);
  Serial.println(" bytes");

  // Send over HTTP if WiFi is connected
  if (WiFi.status() == WL_CONNECTED) {
    
    WiFiClient client;
    HTTPClient http;
    http.setConnectTimeout(5000);  // 5 second timeout
    http.setTimeout(10000);        // 10 second response timeout
    
    if (!http.begin(client, serverName)) {
      Serial.println("Failed to begin HTTP connection!");
      esp_camera_fb_return(fb);
      client.stop();
      return;
    }
    
    // Specify content type as jpeg
    http.addHeader("Content-Type", "image/jpeg");
    http.addHeader("Content-Length", String(fb->len));

    Serial.println("Sending image to PC...");
    
    // Send the raw frame buffer bytes
    int httpResponseCode = http.POST(fb->buf, fb->len);
    
    Serial.print("HTTP Response Code: ");
    Serial.println(httpResponseCode);
    
    if (httpResponseCode == 200) {
      String response = http.getString();
      Serial.println("✓ Upload Success!");
      Serial.println(response);
    } else if (httpResponseCode > 0) {
      Serial.print("✗ Upload Failed! Response: ");
      Serial.println(http.getString());
    } else {
      Serial.print("✗ HTTP Error: ");
      Serial.println(http.errorToString(httpResponseCode));
    }

    // Properly close HTTP connection
    http.end();
    delay(100);  // Give connection time to close
    
    // Explicitly stop WiFi client
    if (client.connected()) {
      client.stop();
    }
    
  } else {
    Serial.println("✗ WiFi Disconnected. Cannot send image.");
  }
  
  // Release frame buffer LAST - after all network operations complete
  esp_camera_fb_return(fb);
  
  // Print memory info after completion
  Serial.print("Free Heap after completion: ");
  Serial.print(ESP.getFreeHeap());
  Serial.println(" bytes");
  
  // Small delay to allow system to clean up
  delay(500);
}
