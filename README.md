# Telemetria Automotiva Chevrolet Corsa - Flutter + ESP32

Aplicativo Android (APK) para telemetria em tempo real da injeção eletrônica do Corsa via Bluetooth Clássico (SPP) com ESP32.

---

## 📱 Como Gerar o APK (.apk)

### Opção 1: Gerar Automaticamente na Nuvem (Sem Instalar Nada)
1. Crie um repositório no seu GitHub (gratuito) e envie os arquivos deste projeto.
2. Acesse a aba **Actions** no seu repositório.
3. O workflow `Compilar APK Flutter Corsa Telemetria` será executado automaticamente.
4. Ao finalizar (aprox. 2 minutos), baixe o arquivo **app-release.apk** diretamente nos *Artifacts*.

---

### Opção 2: Compilar no seu Computador (Flutter SDK)
1. Certifique-se de ter o Flutter instalado (`flutter doctor`).
2. Abra o terminal na pasta do projeto:
   ```bash
   cd corsa_telemetria
   flutter pub get
   flutter build apk --release
   ```
3. O arquivo APK pronto para instalação no celular estará em:
   `build/app/outputs/flutter-apk/app-release.apk`

---

## ⚡ Como Gravar o ESP32
1. Abra o arquivo `esp32_firmware/Telemetria_Completa_Corsa.ino` na **Arduino IDE**.
2. Instale o pacote de placas ESP32 na Arduino IDE (*Tools > Board > Boards Manager*).
3. Selecione a placa **"ESP32 Dev Module"**.
4. Conecte o ESP32 via cabo USB e clique em **Upload**.
5. O Bluetooth do ESP32 será iniciado como **"Telemetria_Completa_Corsa"**.

---

## 📲 Como Instalar o APK no Smartphone Android
1. Transfira o arquivo `app-release.apk` para o celular (via WhatsApp, Google Drive, cabo USB ou Telegram).
2. Toque no arquivo e permita a instalação de fontes desconhecidas se solicitado pelo Android.
3. Pareie o celular com o dispositivo Bluetooth **"Telemetria_Completa_Corsa"** nas configurações do Android.
4. Abra o aplicativo e toque em **"Conectar Bluetooth"**.
