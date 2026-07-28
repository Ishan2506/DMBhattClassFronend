import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Identifies this installation to the backend so the server can enforce the
/// "max devices per student" limit.
///
/// The id is generated once and kept in SharedPreferences. It deliberately does
/// NOT use a hardware identifier (IMEI / Android ID / identifierForVendor):
/// those need extra permissions, are restricted on modern iOS/Android, and are
/// unavailable on web. The trade-off is that clearing app data or reinstalling
/// produces a new id — the old session then occupies a slot until it expires,
/// which the admin panel's "Logout All Devices" button exists to resolve.
class DeviceIdentity {
  static const _idKey = 'device_id';
  static const _nameKey = 'device_name';

  static String? _cachedId;
  static String? _cachedName;

  /// Stable per-install identifier. Safe to call repeatedly.
  static Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;

    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_idKey);

    if (id == null || id.isEmpty) {
      id = _generateId();
      await prefs.setString(_idKey, id);
    }

    _cachedId = id;
    return id;
  }

  /// Human-readable label shown in the admin panel and in the
  /// "already logged in" message, e.g. "Android Device" / "iPhone".
  static Future<String> getDeviceName() async {
    if (_cachedName != null) return _cachedName!;

    final prefs = await SharedPreferences.getInstance();
    var name = prefs.getString(_nameKey);

    if (name == null || name.isEmpty) {
      name = _describeDevice();
      await prefs.setString(_nameKey, name);
    }

    _cachedName = name;
    return name;
  }

  /// Platform label sent alongside the device name ("android", "ios", "web"…).
  static String getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  static String _describeDevice() {
    if (kIsWeb) return 'Web Browser';
    try {
      if (Platform.isAndroid) return 'Android Device';
      if (Platform.isIOS) return 'iPhone / iPad';
      if (Platform.isMacOS) return 'Mac';
      if (Platform.isWindows) return 'Windows PC';
      if (Platform.isLinux) return 'Linux PC';
    } catch (_) {
      // Platform is unavailable on some targets — fall through.
    }
    return 'Unknown Device';
  }

  /// RFC-4122-ish v4 identifier built from Random.secure(), so two installs
  /// never collide.
  static String _generateId() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));

    // Set version (4) and variant bits.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  /// Clears the cached values. The stored id itself is intentionally preserved
  /// across logout so the same physical device reclaims its own slot when the
  /// student signs back in.
  static void clearCache() {
    _cachedId = null;
    _cachedName = null;
  }
}
