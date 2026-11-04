import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Persistent storage for JSON snapshots that have already synced successfully.
///
/// This service does not perform synchronization or cache live network responses.
class OfflineCacheService {
  OfflineCacheService._();

  static const String _boxName = 'samal_nav_synced_records_v1';
  static Box<String>? _box;

  static Future<void> initialize() async {
    if (_box?.isOpen == true) return;

    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Saves a JSON-compatible snapshot and the time it was synchronized.
  static Future<void> saveSnapshot(
    String key,
    Map<String, dynamic> data, {
    DateTime? syncedAt,
  }) async {
    final box = _requireBox();
    await box.put(
      key,
      jsonEncode({
        'syncedAt': (syncedAt ?? DateTime.now()).toUtc().toIso8601String(),
        'data': data,
      }),
    );
  }

  /// Returns the last synced snapshot, or null when no snapshot is stored.
  static Map<String, dynamic>? readSnapshot(String key) {
    final raw = _requireBox().get(key);
    if (raw == null) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> || decoded['data'] is! Map) {
      return null;
    }
    return {
      'syncedAt': decoded['syncedAt'],
      'data': Map<String, dynamic>.from(decoded['data'] as Map),
    };
  }

  static Future<void> removeSnapshot(String key) async {
    await _requireBox().delete(key);
  }

  static Box<String> _requireBox() {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('OfflineCacheService.initialize() must be called first.');
    }
    return box;
  }
}
