import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/telemetry_data.dart';

enum ConnectionStateEnum {
  disconnected,
  connecting,
  connected,
  error,
}

class BluetoothService {
  // Nome do dispositivo ESP32 alvo
  static const String targetDeviceName = "Telemetria_Completa_Corsa";
  
  // String exata de alerta crítico da ECU
  static const String criticalAlertTrigger = "[ALERTA] Comunicação com a ECU interrompida!";

  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;

  // Streams reativos para UI
  final _connectionStateController = StreamController<ConnectionStateEnum>.broadcast();
  final _telemetryController = StreamController<TelemetryData>.broadcast();
  final _criticalAlertController = StreamController<String>.broadcast();
  final _rawLogsController = StreamController<String>.broadcast();

  Stream<ConnectionStateEnum> get connectionStateStream => _connectionStateController.stream;
  Stream<TelemetryData> get telemetryStream => _telemetryController.stream;
  Stream<String> get criticalAlertStream => _criticalAlertController.stream;
  Stream<String> get rawLogsStream => _rawLogsController.stream;

  ConnectionStateEnum _currentState = ConnectionStateEnum.disconnected;
  ConnectionStateEnum get currentState => _currentState;

  // Buffer para juntar fragmentos de pacotes seriais (até quebrar por \n)
  String _serialBuffer = "";

  BluetoothService() {
    _connectionStateController.add(ConnectionStateEnum.disconnected);
  }

  /// Solicita permissões necessárias do Android (incluindo Android 12+)
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool allGranted = true;
    statuses.forEach((perm, status) {
      if (status.isDenied || status.isPermanentlyDenied) {
        allGranted = false;
      }
    });
    return allGranted;
  }

  /// Busca o dispositivo "Telemetria_Completa_Corsa" entre os pareados ou faz discovery
  Future<BluetoothDevice?> findTargetDevice() async {
    try {
      // 1. Busca primeiro nos dispositivos já pareados no Android
      List<BluetoothDevice> bondedDevices = await _bluetooth.getBondedDevices();
      for (BluetoothDevice device in bondedDevices) {
        if (device.name == targetDeviceName) {
          return device;
        }
      }
      return null;
    } catch (e) {
      _rawLogsController.add("[ERRO] Falha ao listar pareados: $e");
      return null;
    }
  }

  /// Conecta ao ESP32 via Bluetooth Clássico RFCOMM
  Future<bool> connectToTargetDevice() async {
    if (_currentState == ConnectionStateEnum.connecting) return false;

    _updateState(ConnectionStateEnum.connecting);
    _rawLogsController.add("[STATUS] Solicitando permissões e iniciando conexão...");

    bool hasPerms = await requestPermissions();
    if (!hasPerms) {
      _rawLogsController.add("[AVISO] Permissões de Bluetooth/Localização negadas pelo usuário.");
    }

    // Verifica se o Bluetooth do aparelho está ligado
    bool? isEnabled = await _bluetooth.isEnabled;
    if (isEnabled != true) {
      _rawLogsController.add("[STATUS] Ativando Bluetooth...");
      await _bluetooth.requestEnable();
    }

    // Busca o dispositivo alvo
    BluetoothDevice? target = await findTargetDevice();

    if (target == null) {
      _rawLogsController.add("[ERRO] Dispositivo '$targetDeviceName' não encontrado nos pareados! Pareie nas configurações do Android.");
      _updateState(ConnectionStateEnum.error);
      return false;
    }

    try {
      _rawLogsController.add("[STATUS] Conectando a ${target.name} (${target.address})...");
      
      // Estabelece o canal de comunicação Serial Port Profile (SPP)
      _connection = await BluetoothConnection.toAddress(target.address);
      _updateState(ConnectionStateEnum.connected);
      _rawLogsController.add("[STATUS] Conexão Bluetooth estabelecida com sucesso!");

      // Inicia a escuta contínua do fluxo serial vindo do ESP32
      _connection!.input?.listen(
        _onDataReceived,
        onDone: () {
          _rawLogsController.add("[STATUS] Conexão Bluetooth encerrada pelo dispositivo.");
          _updateState(ConnectionStateEnum.disconnected);
        },
        onError: (error) {
          _rawLogsController.add("[ERRO] Erro no stream Bluetooth: $error");
          _updateState(ConnectionStateEnum.error);
        },
      );

      return true;
    } catch (e) {
      _rawLogsController.add("[ERRO] Falha ao conectar: $e");
      _updateState(ConnectionStateEnum.error);
      return false;
    }
  }

  /// Processa os bytes recebidos da Serial, bufferiza por linha (\n) e faz o parse
  void _onDataReceived(Uint8List data) {
    try {
      String chunk = utf8.decode(data, allowMalformed: true);
      _serialBuffer += chunk;

      // Processa linhas completas que terminem com \n
      while (_serialBuffer.contains('\n')) {
        int index = _serialBuffer.indexOf('\n');
        String line = _serialBuffer.substring(0, index).trim();
        _serialBuffer = _serialBuffer.substring(index + 1);

        if (line.isNotEmpty) {
          _processSerialLine(line);
        }
      }
    } catch (e) {
      _rawLogsController.add("[ERRO BUFFER]: $e");
    }
  }

  /// Analisa cada linha serial para verificar alertas críticos ou atualizar dados
  void _processSerialLine(String line) {
    _rawLogsController.add("RX: $line");

    // REQUISITO 4: Detecta a string de Alerta Crítico
    if (line.contains(criticalAlertTrigger)) {
      _criticalAlertController.add("Corte de Alimentação na Central!");
      return;
    }

    // Parse da telemetria normal
    final telemetry = TelemetryData.parse(line);
    if (telemetry != null) {
      _telemetryController.add(telemetry);
    }
  }

  /// Envia comando serial para o ESP32 (ex: reset, calibração)
  Future<void> sendCommand(String cmd) async {
    if (_connection != null && _connection!.isConnected) {
      _connection!.output.add(Uint8List.fromList(utf8.encode("$cmd\n")));
      await _connection!.output.allSent;
      _rawLogsController.add("TX: $cmd");
    }
  }

  /// Desconecta a comunicação
  Future<void> disconnect() async {
    if (_connection != null) {
      _rawLogsController.add("[STATUS] Desconectando Bluetooth...");
      await _connection?.close();
      _connection = null;
    }
    _updateState(ConnectionStateEnum.disconnected);
  }

  void _updateState(ConnectionStateEnum state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  void dispose() {
    _connection?.close();
    _connectionStateController.close();
    _telemetryController.close();
    _criticalAlertController.close();
    _rawLogsController.close();
  }
}
