import 'package:flutter/foundation.dart';
import '../providers/network_provider.dart';
import '../services/offline_operation_service.dart';

/// Network operation interceptor that prevents operations from running
/// without a valid internet connection and provides offline support.
///
/// This class acts as middleware for all network-dependent operations,
/// ensuring that:
/// - Operations don't run without connection
/// - Operations are queued offline
/// - Operations are retried when connection restored
/// - User is informed of network issues
class NetworkOperationInterceptor {
  static const Duration _defaultTimeout = Duration(seconds: 30);

  /// Attempts to execute an async operation with network validation
  ///
  /// Parameters:
  /// - operation: The async function to execute
  /// - operationName: Name of the operation (for logging)
  /// - onNetworkError: Callback when network is poor/unavailable
  /// - timeout: Max time to wait for operation
  ///
  /// Returns:
  /// - Operation result if successful
  /// - Throws exception if network unavailable or operation fails
  static Future<T> executeWithNetworkCheck<T>({
    required Future<T> Function() operation,
    required String operationName,
    required NetworkProvider networkProvider,
    VoidCallback? onNetworkError,
    Duration timeout = _defaultTimeout,
  }) async {
    // Check current network status
    if (!networkProvider.isGood) {
      debugPrint(
          '[Network] Operation blocked: $operationName - Poor connection');
      onNetworkError?.call();
      throw NetworkException(
        'Network unavailable',
        operationName,
      );
    }

    try {
      // Execute operation with timeout
      final result = await operation().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('Operation timeout: $operationName');
        },
      );

      debugPrint('[Network] Operation successful: $operationName');
      return result;
    } on TimeoutException catch (e) {
      debugPrint('[Network] Operation timeout: $operationName');
      throw NetworkException(
        'Operation timeout',
        operationName,
        originalError: e,
      );
    } catch (e) {
      debugPrint('[Network] Operation failed: $operationName - $e');
      rethrow;
    }
  }

  /// Executes operation with offline support
  ///
  /// If network is unavailable, operation is queued for later sync
  static Future<T?> executeWithOfflineSupport<T>({
    required Future<T> Function() operation,
    required String operationName,
    required String operationType,
    required Map<String, dynamic> operationData,
    required NetworkProvider networkProvider,
    required OfflineOperationService offlineService,
    VoidCallback? onNetworkError,
    Duration timeout = _defaultTimeout,
  }) async {
    // If connection is good, execute immediately
    if (networkProvider.isGood) {
      try {
        final result = await operation().timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException('Operation timeout: $operationName');
          },
        );
        debugPrint(
            '[Network] Operation successful with offline support: $operationName');
        return result;
      } catch (e) {
        debugPrint(
            '[Network] Operation failed: $operationName - $e, queuing for offline');
        // Queue for offline retry on failure
        await offlineService.queueOperation(
          operationType: operationType,
          data: operationData,
        );
        rethrow;
      }
    } else {
      // Connection unavailable - queue operation
      debugPrint(
          '[Network] No connection, queuing operation for offline sync: $operationName');
      await offlineService.queueOperation(
        operationType: operationType,
        data: operationData,
      );
      onNetworkError?.call();
      return null;
    }
  }

  /// Waits for connection and then executes operation
  static Future<T> executeWhenConnected<T>({
    required Future<T> Function() operation,
    required String operationName,
    required NetworkProvider networkProvider,
    Duration timeout = _defaultTimeout,
    Duration maxWaitTime = const Duration(minutes: 5),
  }) async {
    // Wait for good connection
    final isConnected = await networkProvider.waitForGoodConnection(
      timeout: maxWaitTime,
    );

    if (!isConnected) {
      throw NetworkException(
        'Could not establish connection within timeout',
        operationName,
      );
    }

    // Execute after connection established
    try {
      return await operation().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('Operation timeout: $operationName');
        },
      );
    } catch (e) {
      debugPrint('[Network] Operation failed after connection: $operationName');
      rethrow;
    }
  }

  /// Validates if an operation can proceed without network
  static bool canOperateOffline(String operationType) {
    const offlineCapableOperations = [
      'local_cache_update',
      'local_data_save',
      'ui_interaction',
    ];
    return offlineCapableOperations.contains(operationType);
  }

  /// Gets retry information for failed operation
  static Map<String, dynamic> getOperationRetryInfo(
    String operationId,
    OfflineOperationService offlineService,
  ) {
    return offlineService.getRetryInfo(operationId);
  }
}

/// Custom exception for network-related errors
class NetworkException implements Exception {
  final String message;
  final String operationName;
  final dynamic originalError;

  NetworkException(
    this.message,
    this.operationName, {
    this.originalError,
  });

  @override
  String toString() => 'NetworkException: $message (Operation: $operationName)';
}

/// Exception for timeout errors
class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

/// Helper extension for easier usage
extension NetworkOperationExt on NetworkProvider {
  /// Checks if operation can proceed
  bool shouldProceedWithOperation(String operationType) {
    if (isGood) return true;
    if (NetworkOperationInterceptor.canOperateOffline(operationType)) {
      return true;
    }
    return false;
  }

  /// Gets user-friendly error message
  String getErrorMessage() {
    if (!hasConnection) {
      return 'No internet connection. Please check your network.';
    }
    if (isPoor) {
      return 'Weak connection. The app may work slowly.';
    }
    if (isCritical) {
      return 'Critical connection issue. Please check your network.';
    }
    return 'Network error occurred.';
  }
}
