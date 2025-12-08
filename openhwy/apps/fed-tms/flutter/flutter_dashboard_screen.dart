import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../models/system.dart';
import '../models/agent.dart';
import '../theme/app_theme.dart';
import '../widgets/system_card.dart';
import '../widgets/agent_card.dart';
import '../widgets/tool_button.dart';
import '../widgets/log_view.dart';

class DashboardScreen extends StatefulWidget {
  final ApiService apiService;
  final WebSocketService wsService;

  const DashboardScreen({
    Key? key,
    required this.apiService,
    required this.wsService,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  List<SystemModel> _systems = [];
  bool _loading = true;
  Timer? _refreshTimer;
  
  // Panel state
  bool _panelOpen = false;
  String _activeTab = 'systems';
  late AnimationController _animationController;
  late Animation<double> _panelAnimation;

  // Tools list
  final List<String> _tools = [
    'Packet Pilot',
    'Whisper Witness',
    'Big Bear',
    'Cargo Connect',
    'Fuel Factor',
    'Iron Insight',
    'Night Nexus',
    'Zone Zipper',
    'Legal Logger',
    'Memory MARK',
    'Ghost Guard',
    'Jackknife Jailer',
  ];

  @override
  void initState() {
    super.initState();
    
    // Animation controller for panel
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    
    _panelAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _loadSystems();
    _startAutoRefresh();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSystems() async {
    setState(() => _loading = true);
    try {
      final systems = await widget.apiService.getSystems();
      setState(() {
        _systems = systems;
        _loading = false;
      });
    } catch (e) {
      print('Error loading systems: $e');
      setState(() => _loading = false);
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _loadSystems();
    });
  }

  void _connectWebSocket() {
    widget.wsService.connect();
    
    // Listen to system updates
    widget.wsService.systemUpdates.listen((system) {
      setState(() {
        final index = _systems.indexWhere((s) => s.name == system.name);
        if (index != -1) {
          _systems[index] = system;
        }
      });
    });

    // Listen to agent updates
    widget.wsService.agentUpdates.listen((agent) {
      setState(() {
        final systemIndex =
            _systems.indexWhere((s) => s.name == agent.systemName);
        if (systemIndex != -1) {
          final system = _systems[systemIndex];
          final agentIndex =
              system.agents.indexWhere((a) => a.name == agent.name);
          if (agentIndex != -1) {
            system.agents[agentIndex] = agent;
          }
        }
      });
    });
  }

  void _togglePanel() {
    setState(() {
      _panelOpen = !_panelOpen;
      if (_panelOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _launchAgent(String systemName, AgentType type) async {
    final success = await widget.apiService.launchAgent(
      systemName,
      type.toString().split('.').last,
      '/home/admin/agents/${type.toString().split('.').last}.toml',
      '/home/admin/agents/${type.toString().split('.').last}.lua',
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agent launched successfully')),
      );
      await _loadSystems();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to launch agent'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _killAgent(AgentModel agent) async {
    final success = await widget.apiService.killAgent(
      agent.systemName,
      agent.name,
      agent.pid,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agent stopped successfully')),
      );
      await _loadSystems();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stop agent'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E3A8A),
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),
          
          // Main content
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator())
                    : _buildMainContent(),
              ),
            ],
          ),

          // Sliding bottom panel
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Text(
              '🚛 OpenHWY',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.accentCyan],
                  ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
              ),
            ),
            SizedBox(width: 24),
            _buildDomainButton('open-hwy.com'),
            SizedBox(width: 12),
            _buildDomainButton('fedispatching.com'),
            SizedBox(width: 12),
            _buildDomainButton('8teenwheelers.com'),
            Spacer(),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadSystems,
              color: Colors.white,
            ),
            IconButton(
              icon: Icon(Icons.terminal),
              onPressed: () {},
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainButton(String domain) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.5),
        ),
      ),
      child: Text(
        domain,
        style: TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          // Left panel - Community
          _build3DPanel(
            title: 'Community',
            color: AppTheme.primaryBlue.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPanelItem(Icons.cloud, 'HWY LogBook'),
                SizedBox(height: 8),
                _buildPanelItem(Icons.dataset, 'Community Datasets'),
              ],
            ),
          ),
          
          SizedBox(width: 32),
          
          // Center panel - Freight Services
          Expanded(
            child: _build3DPanel(
              title: 'Freight Services',
              color: AppTheme.cardBg.withOpacity(0.6),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _buildServiceButton('AI/ML Management'),
                  _buildServiceButton('Transportation Systems'),
                  _buildServiceButton('DevOps Engineering'),
                  _buildServiceButton('Performance Tuning'),
                  _buildServiceButton('Freight Training'),
                  _buildServiceButton('Infrastructure'),
                  _buildServiceButton('Full Stack Dev'),
                  _buildServiceButton('Full Stack Debug'),
                  _buildServiceButton('Agent Development'),
                  _buildServiceButton('Service Development'),
                ],
              ),
            ),
          ),
          
          SizedBox(width: 32),
          
          // Right panel - Agents & Tools
          _build3DPanel(
            title: 'Agent Services',
            color: Colors.purple.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPanelItem(Icons.precision_manufacturing, 'EcoX'),
                SizedBox(height: 8),
                _buildPanelItem(Icons.route, 'Marketeer'),
                SizedBox(height: 8),
                _buildPanelItem(Icons.view_in_ar, 'ZBoxxy'),
                SizedBox(height: 16),
                Text(
                  'Tools',
                  style: TextStyle(
                    color: Colors.purple.shade300,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                ..._tools.take(4).map((tool) => Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        tool,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DPanel({
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(-0.1),
      alignment: Alignment.center,
      child: Container(
        width: 280,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: Offset(10, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentCyan,
              ),
            ),
            SizedBox(height: 16),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  // Continued in next file...
