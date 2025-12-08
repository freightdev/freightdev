import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/system.dart';
import '../models/agent.dart';

class WebSocketService {
  static const String wsUrl = 'ws://localhost:8080/ws';
  
  WebSocketChannel? _channel;
  StreamController<SystemModel>? _systemController;
  StreamController<AgentModel>? _agentController;
  StreamController<LogEntry>? _logController;
  
  bool _isConnected = false;
  Timer? _reconnectTimer;

  Stream<SystemModel> get systemUpdates =>
      _systemController?.stream ?? Stream.empty();
  
  Stream<AgentModel> get agentUpdates =>
      _agentController?.stream ?? Stream.empty();
  
  Stream<LogEntry> get logUpdates =>
      _logController?.stream ?? Stream.empty();

  bool get isConnected => _isConnected;

  void connect() {
    if (_isConnected) return;

    try {
      _systemController = StreamController<SystemModel>.broadcast();
      _agentController = StreamController<AgentModel>.broadcast();
      _logController = StreamController<LogEntry>.broadcast();

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );

      print('WebSocket connected to $wsUrl');
    } catch (e) {
      print('WebSocket connection error: $e');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message as String);
      final type = data['type'] as String?;

      switch (type) {
        case 'system_update':
          final system = SystemModel.fromJson(data['data']);
          _systemController?.add(system);
          break;
        
        case 'agent_update':
          final agent = AgentModel.fromJson(data['data']);
          _agentController?.add(agent);
          break;
        
        case 'log':
          final log = LogEntry.fromJson(data['data']);
          _logController?.add(log);
          break;
        
        default:
          print('Unknown WebSocket message type: $type');
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  void _handleError(error) {
    print('WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _handleDone() {
    print('WebSocket connection closed');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: 5), () {
      print('Attempting to reconnect...');
      connect();
    });
  }

  void send(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(json.encode(message));
    } else {
      print('Cannot send message: WebSocket not connected');
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _systemController?.close();
    _agentController?.close();
    _logController?.close();
    _isConnected = false;
  }
}
