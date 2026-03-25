import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_constants.dart';

enum ConnectionStatus { connected, disconnected, connecting }

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _dataController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;
  
  ConnectionStatus _currentStatus = ConnectionStatus.disconnected;
  Timer? _reconnectTimer;
  String? _currentBusId;
  int _retryCount = 0;

  void connect(String busId) {
    if (_currentBusId == busId && _currentStatus == ConnectionStatus.connected) return;
    
    _currentBusId = busId;
    _establishConnection();
  }

  void _establishConnection() {
    if (_currentBusId == null) return;
    
    _statusController.add(ConnectionStatus.connecting);
    _currentStatus = ConnectionStatus.connecting;

    try {
      final url = '${ApiConstants.wsBaseUrl}/ws/bus/bus_$_currentBusId';
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      _currentStatus = ConnectionStatus.connected;
      _statusController.add(ConnectionStatus.connected);
      _retryCount = 0;
      
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _dataController.add(data);
          } catch (e) {
            debugPrint("WS Decode Error: $e");
          }
        },
        onDone: () => _handleDisconnect(),
        onError: (e) => _handleDisconnect(),
      );
    } catch (e) {
      debugPrint("WS Connection Error: $e");
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _currentStatus = ConnectionStatus.disconnected;
    _statusController.add(ConnectionStatus.disconnected);
    _reconnectTimer?.cancel();
    _retryCount++;
    final backoffSeconds = (_retryCount * 2).clamp(2, 20);
    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      if (_currentStatus == ConnectionStatus.disconnected) {
        _establishConnection();
      }
    });
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel?.sink.add(jsonEncode(data));
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _currentStatus = ConnectionStatus.disconnected;
    _statusController.add(ConnectionStatus.disconnected);
    _currentBusId = null;
    _retryCount = 0;
  }
}
