import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';
import 'api_client.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _storage = LocalStorageService();
  final _api = ApiClient();
  

  StreamSubscription? _connectivitySubscription;

  void init() {
    // Listen to network changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
       // connectivity_plus returns a list now in newer versions
       if (results.any((r) => r != ConnectivityResult.none)) {
         if (kDebugMode) print('📶 Network Connected. Triggering Sync...');
         triggerSync();
       }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<List<Map<String, dynamic>>>? _syncFuture;

  Future<List<Map<String, dynamic>>> triggerSync() async {
    if (_syncFuture != null) return _syncFuture!;

    _syncFuture = _processQueue();
    // We await it here so that triggerSync itself waits, 
    // but the future is also stored in _syncFuture for other callers.
    try {
      return await _syncFuture!;
    } finally {
      // Ensure we clear the future even if error, so next call can try again
      _syncFuture = null;
    }
  }

  Future<List<Map<String, dynamic>>> _processQueue() async {
    final List<Map<String, dynamic>> results = [];
    
    // Double check real internet
    bool hasInternet = await InternetConnectionChecker.instance.hasConnection;
    if (!hasInternet) {
      if (kDebugMode) print('⚠️ Network connected but no Internet access.');
      return results;
    }

    try {
      final queue = _storage.getQueue();
      if (queue.isEmpty) {
        if (kDebugMode) print('✅ Sync Queue is empty.');
        return results;
      }

      if (kDebugMode) print('🔄 Processing Sync Queue (${queue.length} items)...');

      // Process items one by one (FIFO)
      // Note: We read the *current* queue status. If new items are added while syncing, they are appended.
      // We will loop until queue is empty or error occurs.
      
      int processedCount = 0;
      
      // Reload queue to be sure
      var currentQueue = _storage.getQueue();
      
      while (currentQueue.isNotEmpty) {
        final item = currentQueue.first; // Peek first
        final method = item['method'] as String;
        final endpoint = item['endpoint'] as String;
        final body = item['body'];

        bool success = false;
        dynamic response;

        try {
          if (kDebugMode) print('📤 Sending: $method $endpoint');
          
          switch (method.toUpperCase()) {
            case 'POST':
              response = await _api.post(endpoint, body);
              break;
            case 'PUT':
              response = await _api.put(endpoint, body);
              break;
            case 'PATCH':
              response = await _api.patch(endpoint, body);
              break;
            case 'DELETE':
              response = await _api.delete(endpoint);
              break;
            default:
              if (kDebugMode) print('❌ Unknown method $method. Discarding.');
              success = true; // Auto-discard bad items
              break;
          }
          success = true;
          
          if (response != null) {
              results.add({
                  'method': method,
                  'endpoint': endpoint,
                  'response': response
              });
          }
          
        } catch (e) {
          if (kDebugMode) print('❌ Sync Error for $endpoint: $e');
          // If 5xx or Network -> Stop sync, keep item.
          // If 4xx -> Discard item?
          // For now, simpler: Stop sync on any error to prevent data loss or disorder.
          // Exception: 400/403 might block queue forever if not handled.
          // Ideally check statusCode if possible. ApiClient throws ApiException(msg, code).
          
          if (e.toString().contains('400') || e.toString().contains('403') || e.toString().contains('404')) {
             if (kDebugMode) print('⚠️ Client Error ($e). Discarding item to unblock queue.');
             success = true; // Treated as "handled" (discarded)
          } else {
             // Server/Network error -> Retry later
             success = false;
          }
        }

        if (success) {
          await _storage.removeFromQueue(0); // Remove the first item
          processedCount++;
          // Reload queue for next iteration (in case logic changed or list shifted)
          currentQueue = _storage.getQueue();
        } else {
          // Stop processing if we failed (preserve order)
          break;
        }
      }
      
      if (kDebugMode) print('✅ Sync Finished. Processed $processedCount items.');

    } catch (e) {
       if (kDebugMode) print('❌ Critical Sync Error: $e');
    }
    
    return results;
  }
}
