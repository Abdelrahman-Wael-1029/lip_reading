import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  // Singleton Pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityResult> _connectivityStreamController =
      StreamController<ConnectivityResult>.broadcast();

  /// Starts listening to connectivity changes
  void initialize() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _connectivityStreamController.add(result);
    });
  }

  /// Get current connectivity status (wifi, mobile, none)
  Future<ConnectivityResult> checkConnectivity() async {
    return await _connectivity.checkConnectivity();
  }

  /// Check if there is any network (WiFi or Mobile)
  Future<bool> isConnected() async {
    ConnectivityResult result = await checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Stream of connectivity changes
  Stream<ConnectivityResult> get onConnectivityChanged =>
      _connectivityStreamController.stream;

  /// Dispose the stream controller
  void dispose() {
    _connectivityStreamController.close();
  }
}
