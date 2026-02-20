import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/network_service.dart';

/// Callback function signature for network status changes
typedef NetworkStatusCallback = void Function(bool isConnected, bool isPoor);

/// Comprehensive network monitoring provider that tracks connection status,
/// speed, and provides callbacks for app-wide network state changes.
///
/// Features:
/// - Real-time connection monitoring across the entire app
/// - Periodic speed checks with configurable thresholds
/// - Callbacks for connection status changes
/// - Prevents operations without valid connection
/// - Safe retry logic with exponential backoff
class NetworkProvider with ChangeNotifier {
  double? _speedMbps;
  bool _hasConnection = true;
  bool _isMonitoring = false;
  Timer? _monitoringTimer;
  Timer? _retryTimer;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connSub;

  // Callbacks for network status changes
  final List<NetworkStatusCallback> _statusCallbacks = [];

  // Thresholds for network quality assessment
  static const double _poorThresholdMbps = 0.1; // 100 kbps
  static const double _criticalThresholdMbps = 0.05; // 50 kbps

  // Monitoring intervals
  static const Duration _monitoringInterval = Duration(seconds: 10);
  static const Duration _retryInterval = Duration(seconds: 15);

  // Retry logic
  int _failureCount = 0;
  static const int _maxFailures = 3;

  NetworkProvider() {
    _initializeMonitoring();
  }

  /// Initializes network monitoring
  Future<void> _initializeMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // Perform initial check
    await _checkSpeed();

    // Listen for connectivity changes
    _connSub = _connectivity.onConnectivityChanged.listen((result) {
      _handleConnectivityChange(result);
    });

    // Start periodic monitoring
    _startPeriodicMonitoring();
  }

  /// Handles connectivity changes from the system
  void _handleConnectivityChange(ConnectivityResult result) {
    final connected = result != ConnectivityResult.none;

    if (_hasConnection != connected) {
      _hasConnection = connected;
      _speedMbps = connected ? _speedMbps : 0.0;

      if (!connected) {
        _failureCount = 0;
        _notifyStatusCallbacks();
      } else {
        // Connection restored - perform immediate check
        _checkSpeed();
      }
    }
  }

  /// Starts periodic monitoring of network speed and quality
  void _startPeriodicMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      _checkSpeed();
    });
  }

  // ==================== Public Getters ====================

  double? get speedMbps => _speedMbps;
  bool get hasConnection => _hasConnection;
  bool get isMonitoring => _isMonitoring;

  /// Returns true if connection is poor (slow or no connection)
  bool get isPoor =>
      !_hasConnection ||
      (_speedMbps != null && _speedMbps! < _poorThresholdMbps);

  /// Returns true if connection is critically bad
  bool get isCritical =>
      !_hasConnection ||
      (_speedMbps != null && _speedMbps! < _criticalThresholdMbps);

  /// Returns true for good connection
  bool get isGood =>
      _hasConnection &&
      (_speedMbps == null || _speedMbps! >= _poorThresholdMbps);

  /// Returns connection status message
  String get statusMessage {
    if (!_hasConnection) return 'No Connection';
    if (isCritical) return 'Critical Connection';
    if (isPoor) return 'Poor Connection';
    return 'Good Connection';
  }

  // ==================== Public Methods ====================

  /// Registers a callback for network status changes
  void addStatusCallback(NetworkStatusCallback callback) {
    if (!_statusCallbacks.contains(callback)) {
      _statusCallbacks.add(callback);
    }
  }

  /// Removes a status callback
  void removeStatusCallback(NetworkStatusCallback callback) {
    _statusCallbacks.remove(callback);
  }

  /// Performs an immediate speed check and updates listeners
  Future<void> performCheck() async {
    await _checkSpeed();
  }

  /// Checks if an operation can proceed safely
  /// Returns true only if connection is good
  bool canProceed() {
    return isGood;
  }

  /// Waits for a good connection before proceeding
  /// Returns true if connection becomes good, false if timeout
  Future<bool> waitForGoodConnection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (isGood) return true;

    final completer = Completer<bool>();
    late final StreamSubscription subscription;

    subscription = _connectivity.onConnectivityChanged.listen((result) {
      if (isGood) {
        completer.complete(true);
        subscription.cancel();
      }
    });

    Future.delayed(timeout).then((_) {
      if (!completer.isCompleted) {
        completer.complete(false);
        subscription.cancel();
      }
    });

    return completer.future;
  }

  // ==================== Private Methods ====================

  /// Performs speed check with retry logic
  Future<void> _checkSpeed() async {
    try {
      final connResult = await _connectivity.checkConnectivity();

      if (connResult == ConnectivityResult.none) {
        _updateConnectionStatus(false, 0.0);
        _failureCount++;
      } else {
        _hasConnection = true;
        try {
          final speed = await NetworkService.checkNetworkSpeed()
              .timeout(const Duration(seconds: 10));
          _speedMbps = speed;
          _failureCount = 0; // Reset on success
        } catch (e) {
          // Speed check failed, but we have connectivity
          debugPrint('Speed check failed: $e');
          _speedMbps = 0.0;
          _failureCount++;
        }
      }
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
      _updateConnectionStatus(false, 0.0);
      _failureCount++;
    }

    // Implement exponential backoff on repeated failures
    if (_failureCount >= _maxFailures) {
      _scheduleRetry();
    }

    _notifyStatusCallbacks();
  }

  /// Updates connection status
  void _updateConnectionStatus(bool connected, double speed) {
    _hasConnection = connected;
    _speedMbps = speed;
  }

  /// Schedules a retry with exponential backoff
  void _scheduleRetry() {
    _retryTimer?.cancel();
    final delaySeconds = (_failureCount - _maxFailures) * 5; // 5s, 10s, 15s...
    _retryTimer = Timer(
      Duration(seconds: delaySeconds.clamp(1, 60)),
      _checkSpeed,
    );
  }

  /// Notifies all registered callbacks of status changes
  void _notifyStatusCallbacks() {
    for (final callback in _statusCallbacks) {
      callback(_hasConnection, isPoor);
    }
    notifyListeners();
  }

  // ==================== Lifecycle ====================

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    _retryTimer?.cancel();
    _connSub?.cancel();
    _statusCallbacks.clear();
    super.dispose();
  }
}
