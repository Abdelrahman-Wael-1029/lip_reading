import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  // Singleton Pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<List<ConnectivityResult>>
      _connectivityStreamController =
      StreamController<List<ConnectivityResult>>.broadcast();

  /// Starts listening to connectivity changes
  void initialize() {
    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _connectivityStreamController.add(results);
    });
  }

  /// Get current connectivity status (wifi, mobile, none)
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return await _connectivity.checkConnectivity();
  }

  /// Check if there is any network (WiFi or Mobile)
  Future<bool> isConnected() async {
    List<ConnectivityResult> results = await checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  /// Stream of connectivity changes
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivityStreamController.stream;

  /// Dispose the stream controller
  void dispose() {
    _connectivityStreamController.close();
  }
}
