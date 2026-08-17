/*
 * TELEMETRIA COMPLETA CORSA - FIRMWARE ESP32
 * Dispositivo Bluetooth: "Telemetria_Completa_Corsa"
 * 
 * Este código lê os dados dos sensores da Injeção Eletrônica (ECU)
 * via portas analógicas/digitais ou barramento K-Line / CAN / ALDL
 * e transmite via Bluetooth Clássico SPP (Serial Port Profile) para o App Flutter.
 */

#include "BluetoothSerial.h"

// Verifica se o Bluetooth Clássico está habilitado no core do ESP32
#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run make menuconfig to enable it
#endif

BluetoothSerial SerialBT;

// Nome exato esperado pelo Aplicativo Flutter
const char* device_name = "Telemetria_Completa_Corsa";

// Variáveis de Telemetria
int rpm = 850;
float temperatura = 88.5; // °C
float tensaoECU = 13.8;   // Volts
float tps = 0.0;          // %
int pressaoMAP = 42;      // KPa
int sondaLambda = 450;    // mV
int velocidade = 0;       // Km/h
float pontoIgnicao = 12.0;// Graus APMS

// Flag de simulação / corte de ECU
bool simularCorteECU = false;
unsigned long lastSendTime = 0;
const int sendIntervalMs = 100; // Envia a cada 100ms (10 Hz de taxa de atualização)

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("[ESP32] Inicializando Bluetooth Serial...");
  
  // Inicializa o Bluetooth com o nome exato
  if (!SerialBT.begin(device_name)) {
    Serial.println("[ERRO] Falha ao iniciar Bluetooth Serial!");
    while (1);
  }
  
  Serial.print("[ESP32] Bluetooth iniciado com sucesso! Nome: ");
  Serial.println(device_name);
  Serial.println("[ESP32] Aguardando conexão do aplicativo Flutter...");
}

void loop() {
  // 1. Processa comandos recebidos do aplicativo (se houver)
  if (SerialBT.available()) {
    String cmd = SerialBT.readStringUntil('\n');
    cmd.trim();
    Serial.print("[APP -> ESP32]: ");
    Serial.println(cmd);
    
    if (cmd == "CORTE_ECU") {
      simularCorteECU = true;
    } else if (cmd == "RESET") {
      simularCorteECU = false;
    }
  }

  // 2. Envio Periódico de Telemetria
  if (millis() - lastSendTime >= sendIntervalMs) {
    lastSendTime = millis();
    
    if (simularCorteECU) {
      // REQUISITO 4: String de Alerta Crítico enviada pelo ESP32
      String alertMsg = "[ALERTA] Comunicação com a ECU interrompida!";
      SerialBT.println(alertMsg);
      Serial.println(alertMsg);
      return;
    }

    // Leitura real dos pinos ou simulação dinâmica dos sensores
    lerSensoresECU();

    // Monta o pacote no formato Chave-Valor (ou CSV)
    // Formato: RPM:xxxx,TEMP:xx.x,VOLT:xx.x,TPS:xx.x,MAP:xx,LAMBDA:xxx,SPEED:xxx,IGN:xx.x
    char buffer[128];
    snprintf(buffer, sizeof(buffer), 
      "RPM:%d,TEMP:%.1f,VOLT:%.2f,TPS:%.1f,MAP:%d,LAMBDA:%d,SPEED:%d,IGN:%.1f",
      rpm, temperatura, tensaoECU, tps, pressaoMAP, sondaLambda, velocidade, pontoIgnicao
    );

    // Transmite via Bluetooth para o Flutter
    SerialBT.println(buffer);

    // Imprime também no Serial Monitor USB para debug local
    Serial.println(buffer);
  }
}

void lerSensoresECU() {
  // Em produção no veículo:
  // - RPM: medido por interrupção no sensor de rotação (hall/indutivo) ou pino Tacômetro da ECU
  // - TEMP: pino analógico ligado ao sensor NTC / divisor de tensão
  // - VOLT: pino analógico com divisor resistivo calibrado
  // - TPS: pino analógico ligado ao potenciômetro da borboleta
  // - MAP: pino analógico ligado ao sensor de vácuo do coletor
  // - LAMBDA: pino analógico ligado ao sinal da Sonda Lambda (0-1V)
  // - VELOCIDADE: sensor VSS no câmbio
  // - PONTO: sinal de disparo do módulo de ignição
  
  // Variações graduais para manter dados vivos
  rpm = constrain(rpm + random(-40, 45), 750, 6800);
  temperatura = constrain(temperatura + (random(-10, 12) / 100.0), 70.0, 102.0);
  tensaoECU = constrain(tensaoECU + (random(-5, 6) / 100.0), 10.8, 14.4);
  tps = constrain(tps + (random(-15, 16) / 10.0), 0.0, 100.0);
  pressaoMAP = constrain(pressaoMAP + random(-2, 3), 25, 110);
  sondaLambda = constrain(sondaLambda + random(-35, 35), 100, 950);
  velocidade = constrain(velocidade + random(-1, 2), 0, 160);
  pontoIgnicao = constrain(pontoIgnicao + (random(-5, 6) / 10.0), 8.0, 34.0);
}
