import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/dashboard_screen.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock to landscape on desktop/tablet, allow both on mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize services
  final apiService = ApiService();
  final wsService = WebSocketService();

  runApp(OpenHWYApp(
    apiService: apiService,
    wsService: wsService,
  ));
}

class OpenHWYApp extends StatelessWidget {
  final ApiService apiService;
  final WebSocketService wsService;

  const OpenHWYApp({
    Key? key,
    required this.apiService,
    required this.wsService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenHWY Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: DashboardScreen(
        apiService: apiService,
        wsService: wsService,
      ),
    );
  }
}
