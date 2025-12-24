import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> bootstrap(FlavorType flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await StorageService.init();
  LoggerService.init(flavor);

  // Set flavor
  FlavorConfig.setFlavor(flavor);

  LoggerService.info('App bootstrapped with flavor: ${flavor.name}');
}
