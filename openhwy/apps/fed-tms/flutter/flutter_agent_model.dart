enum AgentStatus {
  running,
  stopped,
  error,
  starting,
}

enum AgentType {
  hwy,      // Security & Connections
  fed,      // Fleet Director
  elda,     // Creator & Architect
  eco,      // Matching Engine
  traka,    // Tool Manager
  wheeler,  // Driver tools
}

class AgentModel {
  final String name;
  final String systemName;
  final AgentStatus status;
  final AgentType type;
  final double cpuUsage;
  final String memoryUsage;
  final int uptimeSeconds;
  final int? pid;
  final String? configPath;

  AgentModel({
    required this.name,
    required this.systemName,
    required this.status,
    required this.type,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.uptimeSeconds,
    this.pid,
    this.configPath,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      name: json['name'] as String,
      systemName: json['system_name'] as String,
      status: _statusFromString(json['status'] as String),
      type: _typeFromString(json['type'] as String),
      cpuUsage: (json['cpu_usage'] as num).toDouble(),
      memoryUsage: json['memory_usage'] as String,
      uptimeSeconds: json['uptime_seconds'] as int,
      pid: json['pid'] as int?,
      configPath: json['config_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'system_name': systemName,
      'status': _statusToString(status),
      'type': _typeToString(type),
      'cpu_usage': cpuUsage,
      'memory_usage': memoryUsage,
      'uptime_seconds': uptimeSeconds,
      'pid': pid,
      'config_path': configPath,
    };
  }

  String get uptimeFormatted {
    final hours = uptimeSeconds ~/ 3600;
    final minutes = (uptimeSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get typeDescription {
    switch (type) {
      case AgentType.hwy:
        return 'Security & Connections';
      case AgentType.fed:
        return 'Fleet Director';
      case AgentType.elda:
        return 'Creator & Architect';
      case AgentType.eco:
        return 'Matching Engine';
      case AgentType.traka:
        return 'Tool Manager';
      case AgentType.wheeler:
        return 'Driver Tools';
    }
  }

  static AgentStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'running':
        return AgentStatus.running;
      case 'stopped':
        return AgentStatus.stopped;
      case 'error':
        return AgentStatus.error;
      case 'starting':
        return AgentStatus.starting;
      default:
        return AgentStatus.stopped;
    }
  }

  static String _statusToString(AgentStatus status) {
    return status.toString().split('.').last;
  }

  static AgentType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'hwy':
        return AgentType.hwy;
      case 'fed':
        return AgentType.fed;
      case 'elda':
        return AgentType.elda;
      case 'eco':
        return AgentType.eco;
      case 'traka':
        return AgentType.traka;
      case 'wheeler':
        return AgentType.wheeler;
      default:
        return AgentType.wheeler;
    }
  }

  static String _typeToString(AgentType type) {
    return type.toString().split('.').last;
  }
}
