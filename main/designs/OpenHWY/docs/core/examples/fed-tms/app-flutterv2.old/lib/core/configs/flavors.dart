enum FlavorType {
  dev,
  staging,
  prod,
}

class FlavorConfig {
  static FlavorType? _currentFlavor;

  static FlavorType get currentFlavor {
    if (_currentFlavor == null) {
      throw Exception('Flavor not initialized. Call setFlavor() first.');
    }
    return _currentFlavor!;
  }

  static void setFlavor(FlavorType flavor) {
    _currentFlavor = flavor;
  }

  static bool get isDev => currentFlavor == FlavorType.dev;
  static bool get isStaging => currentFlavor == FlavorType.staging;
  static bool get isProd => currentFlavor == FlavorType.prod;

  static String get apiBaseUrl {
    switch (currentFlavor) {
      case FlavorType.dev:
        return 'http://localhost:3000/api';
      case FlavorType.staging:
        return 'https://staging-api.open-hwy.com/api/v1';
      case FlavorType.prod:
        return 'https://api.open-hwy.com/api/v1';
    }
  }

  static String get wsBaseUrl {
    switch (currentFlavor) {
      case FlavorType.dev:
        return 'ws://localhost:3000';
      case FlavorType.staging:
        return 'wss://staging-api.open-hwy.com';
      case FlavorType.prod:
        return 'wss://api.open-hwy.com';
    }
  }
}
