import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Represents a single offline operation that needs to be synced
class OfflineOperation {
  final String id;
  final String operationType; // 'order', 'subscription', 'profile', etc.
  final Map<String, dynamic> data;
  final DateTime timestamp;
  bool synced;
  String? error;

  OfflineOperation({
    required this.id,
    required this.operationType,
    required this.data,
    DateTime? timestamp,
    this.synced = false,
    this.error,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Converts operation to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operationType': operationType,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'synced': synced,
      'error': error,
    };
  }

  /// Creates operation from JSON
  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      id: json['id'] ?? '',
      operationType: json['operationType'] ?? '',
      data: json['data'] ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      synced: json['synced'] ?? false,
      error: json['error'],
    );
  }
}

/// Service for managing offline operations and data persistence
///
/// Ensures no data is lost during network interruptions by:
/// - Queuing operations when offline
/// - Persisting to local storage
/// - Syncing when connection is restored
/// - Tracking operation status
class OfflineOperationService extends ChangeNotifier {
  static const String _storageKey = 'offline_operations';
  late SharedPreferences _prefs;
  final List<OfflineOperation> _operationQueue = [];
  bool _isInitialized = false;

  /// Initializes the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadOperations();
    _isInitialized = true;
  }

  /// Gets all pending operations
  List<OfflineOperation> get pendingOperations =>
      _operationQueue.where((op) => !op.synced).toList();

  /// Gets all synced operations (for history)
  List<OfflineOperation> get syncedOperations =>
      _operationQueue.where((op) => op.synced).toList();

  /// Gets all operations
  List<OfflineOperation> get allOperations => List.from(_operationQueue);

  /// Gets operations by type
  List<OfflineOperation> getOperationsByType(String operationType) =>
      _operationQueue.where((op) => op.operationType == operationType).toList();

  /// Gets pending operations by type
  List<OfflineOperation> getPendingByType(String operationType) =>
      _operationQueue
          .where((op) => op.operationType == operationType && !op.synced)
          .toList();

  /// Adds an operation to the queue (persists automatically)
  Future<void> queueOperation({
    required String operationType,
    required Map<String, dynamic> data,
    String? operationId,
  }) async {
    await initialize();

    final id = operationId ??
        '${operationType}_${DateTime.now().millisecondsSinceEpoch}';
    final operation = OfflineOperation(
      id: id,
      operationType: operationType,
      data: data,
    );

    _operationQueue.add(operation);
    await _saveOperations();
    notifyListeners();

    debugPrint('[Offline] Operation queued: $operationType - $id');
  }

  /// Marks an operation as synced
  Future<void> markAsSynced(String operationId) async {
    final operation = _operationQueue.firstWhere(
      (op) => op.id == operationId,
      orElse: () => OfflineOperation(
        id: '',
        operationType: '',
        data: {},
      ),
    );

    if (operation.id.isNotEmpty) {
      operation.synced = true;
      operation.error = null;
      await _saveOperations();
      notifyListeners();
      debugPrint('[Offline] Operation synced: $operationId');
    }
  }

  /// Marks an operation as failed with error message
  Future<void> markAsFailed(String operationId, String error) async {
    final operation = _operationQueue.firstWhere(
      (op) => op.id == operationId,
      orElse: () => OfflineOperation(
        id: '',
        operationType: '',
        data: {},
      ),
    );

    if (operation.id.isNotEmpty) {
      operation.error = error;
      await _saveOperations();
      notifyListeners();
      debugPrint('[Offline] Operation failed: $operationId - $error');
    }
  }

  /// Removes an operation from queue
  Future<void> removeOperation(String operationId) async {
    _operationQueue.removeWhere((op) => op.id == operationId);
    await _saveOperations();
    notifyListeners();
    debugPrint('[Offline] Operation removed: $operationId');
  }

  /// Clears all synced operations (keeps pending for retry)
  Future<void> clearSyncedOperations() async {
    _operationQueue.removeWhere((op) => op.synced);
    await _saveOperations();
    notifyListeners();
  }

  /// Clears all operations
  Future<void> clearAllOperations() async {
    _operationQueue.clear();
    await _saveOperations();
    notifyListeners();
  }

  /// Gets the count of pending operations
  int get pendingCount => pendingOperations.length;

  /// Checks if there are any pending operations
  bool get hasPendingOperations => pendingOperations.isNotEmpty;

  /// Gets retry information for an operation
  Map<String, dynamic> getRetryInfo(String operationId) {
    final operation = _operationQueue.firstWhere(
      (op) => op.id == operationId,
      orElse: () => OfflineOperation(
        id: '',
        operationType: '',
        data: {},
      ),
    );

    return {
      'id': operation.id,
      'timestamp': operation.timestamp,
      'attemptedAt': operation.timestamp,
      'type': operation.operationType,
      'error': operation.error,
    };
  }

  // ==================== Private Methods ====================

  /// Loads operations from persistent storage
  Future<void> _loadOperations() async {
    try {
      final json = _prefs.getString(_storageKey);
      if (json == null) return;

      final List<dynamic> decoded = jsonDecode(json);
      _operationQueue.clear();
      for (final item in decoded) {
        _operationQueue.add(OfflineOperation.fromJson(item));
      }

      debugPrint('[Offline] Loaded ${_operationQueue.length} operations');
    } catch (e) {
      debugPrint('[Offline] Error loading operations: $e');
    }
  }

  /// Saves operations to persistent storage
  Future<void> _saveOperations() async {
    try {
      final json =
          jsonEncode(_operationQueue.map((op) => op.toJson()).toList());
      await _prefs.setString(_storageKey, json);
    } catch (e) {
      debugPrint('[Offline] Error saving operations: $e');
    }
  }
}
