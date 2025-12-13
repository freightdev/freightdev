import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/bootstraps/bootstrap.dart';
import 'core/configs/flavors.dart';
import 'app.dart';

void main() async {
  await bootstrap(FlavorType.dev);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUIOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
