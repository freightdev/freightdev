import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/system.dart';
import '../models/agent.dart';
import '../models/command_result.dart';

class ApiService {
  // Backend URLs - configure these for your setup
  static const String baseUrl = 'http://localhost:8080';  // Rust/Go backend
  static const String wsUrl = 'ws://localhost:8080/ws';    // WebSocket
  
  final http.Client _client;
  
  ApiService() : _client = http.Client();

  // Get all systems
  Future<List<SystemModel>> getSystems() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/systems'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SystemModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load systems: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching systems: $e');
      return _getMockSystems(); // Fallback to mock data
    }
  }

  // Execute command on system
  Future<CommandResult> executeCommand(
    String systemName,
    String command,
    List<String> args,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/execute'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'system_name': systemName,
          'command': command,
          'args': args,
        }),
      );

      if (response.statusCode == 200) {
        return CommandResult.fromJson(json.decode(response.body));
      } else {
        throw Exception('Command failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error executing command: $e');
      return CommandResult(
        stdout: '',
        stderr: e.toString(),
        exitCode: 1,
      );
    }
  }

  // Launch agent
  Future<bool> launchAgent(
    String systemName,
    String agentType,
    String configPath,
    String scriptPath,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/agents/launch'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'system_name': systemName,
          'agent_type': agentType,
          'config_path': configPath,
          'script_path': scriptPath,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error launching agent: $e');
      return false;
    }
  }

  // Kill agent
  Future<bool> killAgent(String systemName, String agentName, int? pid) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/agents/kill'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'system_name': systemName,
          'agent_name': agentName,
          'pid': pid,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error killing agent: $e');
      return false;
    }
  }

  // Get logs
  Future<List<LogEntry>> getLogs(
    String systemName,
    String agentName,
    int lineCount,
  ) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/logs?system=$systemName&agent=$agentName&lines=$lineCount'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => LogEntry.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load logs');
      }
    } catch (e) {
      print('Error fetching logs: $e');
      return [];
    }
  }

  // Mock data for development
  List<SystemModel> _getMockSystems() {
    return [
      SystemModel(
        name: 'workbox',
        hostname: 'localhost',
        status: SystemStatus.online,
        cpuUsage: 23.5,
        memoryUsage: 45.2,
        memoryTotal: '16GB',
        agentCount: 2,
        agents: [
          AgentModel(
            name: 'HWY',
            systemName: 'workbox',
            status: AgentStatus.running,
            type: AgentType.hwy,
            cpuUsage: 12.3,
            memoryUsage: '256MB',
            uptimeSeconds: 9240,
            pid: 1234,
          ),
          AgentModel(
            name: 'FED',
            systemName: 'workbox',
            status: AgentStatus.running,
            type: AgentType.fed,
            cpuUsage: 8.1,
            memoryUsage: '512MB',
            uptimeSeconds: 9240,
            pid: 1235,
          ),
        ],
        uptimeSeconds: 86400,
      ),
      SystemModel(
        name: 'helpbox',
        hostname: 'helpbox',
        status: SystemStatus.online,
        cpuUsage: 15.2,
        memoryUsage: 32.1,
        memoryTotal: '8GB',
        agentCount: 1,
        agents: [
          AgentModel(
            name: 'ELDA',
            systemName: 'helpbox',
            status: AgentStatus.running,
            type: AgentType.elda,
            cpuUsage: 5.3,
            memoryUsage: '384MB',
            uptimeSeconds: 7200,
            pid: 2234,
          ),
        ],
        uptimeSeconds: 72000,
      ),
      SystemModel(
        name: 'hostbox',
        hostname: 'hostbox',
        status: SystemStatus.online,
        cpuUsage: 8.7,
        memoryUsage: 28.5,
        memoryTotal: '8GB',
        agentCount: 1,
        agents: [
          AgentModel(
            name: 'ECO',
            systemName: 'hostbox',
            status: AgentStatus.running,
            type: AgentType.eco,
            cpuUsage: 3.2,
            memoryUsage: '128MB',
            uptimeSeconds: 3600,
            pid: 3234,
          ),
        ],
        uptimeSeconds: 54000,
      ),
      SystemModel(
        name: 'callbox',
        hostname: 'callbox',
        status: SystemStatus.online,
        cpuUsage: 12.4,
        memoryUsage: 35.8,
        memoryTotal: '8GB',
        agentCount: 0,
        agents: [],
        uptimeSeconds: 43200,
      ),
      SystemModel(
        name: 'safebox',
        hostname: 'safebox',
        status: SystemStatus.offline,
        cpuUsage: 0,
        memoryUsage: 0,
        memoryTotal: '4GB',
        agentCount: 0,
        agents: [],
        uptimeSeconds: 0,
      ),
    ];
  }

  void dispose() {
    _client.close();
  }
}
