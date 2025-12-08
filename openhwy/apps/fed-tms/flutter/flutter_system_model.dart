import 'agent.dart';

enum SystemStatus {
  online,
  offline,
  degraded,
}

class SystemModel {
  final String name;
  final String hostname;
  final SystemStatus status;
  final double cpuUsage;
  final double memoryUsage;
  final String memoryTotal;
  final int agentCount;
  final List<AgentModel> agents;
  final int uptimeSeconds;

  SystemModel({
    required this.name,
    required this.hostname,
    required this.status,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.memoryTotal,
    required this.agentCount,
    required this.agents,
    required this.uptimeSeconds,
  });

  factory SystemModel.fromJson(Map<String, dynamic> json) {
    return SystemModel(
      name: json['name'] as String,
      hostname: json['hostname'] as String,
      status: _statusFromString(json['status'] as String),
      cpuUsage: (json['cpu_usage'] as num).toDouble(),
      memoryUsage: (json['memory_usage'] as num).toDouble(),
      memoryTotal: json['memory_total'] as String,
      agentCount: json['agent_count'] as int,
      agents: (json['agents'] as List<dynamic>?)
              ?.map((a) => AgentModel.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      uptimeSeconds: json['uptime_seconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'hostname': hostname,
      'status': _statusToString(status),
      'cpu_usage': cpuUsage,
      'memory_usage': memoryUsage,
      'memory_total': memoryTotal,
      'agent_count': agentCount,
      'agents': agents.map((a) => a.toJson()).toList(),
      'uptime_seconds': uptimeSeconds,
    };
  }

  String get uptimeFormatted {
    final hours = uptimeSeconds ~/ 3600;
    final minutes = (uptimeSeconds % 3600) ~/ 60;
    if (hours > 24) {
      final days = hours ~/ 24;
      return '${days}d ${hours % 24}h';
    }
    return '${hours}h ${minutes}m';
  }

  static SystemStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return SystemStatus.online;
      case 'offline':
        return SystemStatus.offline;
      case 'degraded':
        return SystemStatus.degraded;
      default:
        return SystemStatus.offline;
    }
  }

  static String _statusToString(SystemStatus status) {
    return status.toString().split('.').last;
  }
}

class CommandResult {
  final String stdout;
  final String stderr;
  final int exitCode;

  CommandResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
  });

  factory CommandResult.fromJson(Map<String, dynamic> json) {
    return CommandResult(
      stdout: json['stdout'] as String? ?? '',
      stderr: json['stderr'] as String? ?? '',
      exitCode: json['exit_code'] as int? ?? 1,
    );
  }

  bool get isSuccess => exitCode == 0;
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String source;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    required this.source,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] as int) * 1000,
      ),
      level: _levelFromString(json['level'] as String),
      message: json['message'] as String,
      source: json['source'] as String? ?? '',
    );
  }

  static LogLevel _levelFromString(String level) {
    switch (level.toLowerCase()) {
      case 'debug':
        return LogLevel.debug;
      case 'info':
        return LogLevel.info;
      case 'warn':
      case 'warning':
        return LogLevel.warn;
      case 'error':
        return LogLevel.error;
      default:
        return LogLevel.info;
    }
  }
}

enum LogLevel {
  debug,
  info,
  warn,
  error,
}
