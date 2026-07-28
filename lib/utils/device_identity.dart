import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
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
  /// "already logged in" message, e.g. "Samsung Galaxy S21" / "iPhone 14 Pro".
  static Future<String> getDeviceName() async {
    if (_cachedName != null) return _cachedName!;

    final prefs = await SharedPreferences.getInstance();
    var name = prefs.getString(_nameKey);

    // Older builds stored a generic placeholder ("Android Device"). Recompute
    // when that is what we find, so existing installs upgrade to the real model
    // name instead of being stuck with the placeholder forever.
    if (name == null || name.isEmpty || _genericNames.contains(name)) {
      name = await _describeDevice();
      await prefs.setString(_nameKey, name);
    }

    _cachedName = name;
    return name;
  }

  /// Placeholders written by earlier versions of this class.
  static const _genericNames = {
    'Android Device',
    'iPhone / iPad',
    'Unknown Device',
  };

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

  /// Resolves the real device model, e.g. "Samsung SM-G991B" or
  /// "iPhone 14 Pro". Falls back to a generic label if the platform lookup
  /// fails, so a device name can never block login.
  static Future<String> _describeDevice() async {
    final plugin = DeviceInfoPlugin();

    try {
      if (kIsWeb) {
        final info = await plugin.webBrowserInfo;
        final browser = info.browserName.name;
        return browser.isEmpty ? 'Web Browser' : '$browser Browser';
      }

      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        // `model` is often already prefixed with the brand on some OEMs;
        // avoid "Samsung Samsung SM-G991B".
        final brand = _capitalize(info.brand.trim());
        final model = info.model.trim();
        if (model.isEmpty) return brand.isEmpty ? 'Android Device' : brand;
        if (brand.isEmpty || model.toLowerCase().startsWith(brand.toLowerCase())) {
          return model;
        }
        return '$brand $model';
      }

      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        // utsname.machine is the hardware id ("iPhone15,2"); map it to the
        // marketing name people recognise, falling back to `.name` (the
        // user-set device name) and then the raw id.
        final machine = info.utsname.machine;
        final mapped = _iosModelNames[machine];
        if (mapped != null) return mapped;
        if (info.name.trim().isNotEmpty) return info.name.trim();
        return machine.isNotEmpty ? machine : 'iPhone / iPad';
      }

      if (Platform.isMacOS) {
        final info = await plugin.macOsInfo;
        return info.model.trim().isNotEmpty ? info.model.trim() : 'Mac';
      }

      if (Platform.isWindows) {
        final info = await plugin.windowsInfo;
        return info.computerName.trim().isNotEmpty
            ? '${info.computerName.trim()} (Windows)'
            : 'Windows PC';
      }

      if (Platform.isLinux) {
        final info = await plugin.linuxInfo;
        return info.prettyName.trim().isNotEmpty ? info.prettyName.trim() : 'Linux PC';
      }
    } catch (e) {
      debugPrint('DeviceIdentity: could not read device info: $e');
    }

    return 'Unknown Device';
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  /// Marketing names for the iPhone/iPad hardware identifiers currently in
  /// circulation. Unlisted models fall back to the device's own name.
  static const Map<String, String> _iosModelNames = {
    // iPhone SE / 8 era
    'iPhone8,4': 'iPhone SE (1st gen)',
    'iPhone10,1': 'iPhone 8',
    'iPhone10,4': 'iPhone 8',
    'iPhone10,2': 'iPhone 8 Plus',
    'iPhone10,5': 'iPhone 8 Plus',
    'iPhone10,3': 'iPhone X',
    'iPhone10,6': 'iPhone X',
    'iPhone11,8': 'iPhone XR',
    'iPhone11,2': 'iPhone XS',
    'iPhone11,4': 'iPhone XS Max',
    'iPhone11,6': 'iPhone XS Max',
    // iPhone 11 / 12
    'iPhone12,1': 'iPhone 11',
    'iPhone12,3': 'iPhone 11 Pro',
    'iPhone12,5': 'iPhone 11 Pro Max',
    'iPhone12,8': 'iPhone SE (2nd gen)',
    'iPhone13,1': 'iPhone 12 mini',
    'iPhone13,2': 'iPhone 12',
    'iPhone13,3': 'iPhone 12 Pro',
    'iPhone13,4': 'iPhone 12 Pro Max',
    // iPhone 13 / 14
    'iPhone14,4': 'iPhone 13 mini',
    'iPhone14,5': 'iPhone 13',
    'iPhone14,2': 'iPhone 13 Pro',
    'iPhone14,3': 'iPhone 13 Pro Max',
    'iPhone14,6': 'iPhone SE (3rd gen)',
    'iPhone14,7': 'iPhone 14',
    'iPhone14,8': 'iPhone 14 Plus',
    'iPhone15,2': 'iPhone 14 Pro',
    'iPhone15,3': 'iPhone 14 Pro Max',
    // iPhone 15 / 16
    'iPhone15,4': 'iPhone 15',
    'iPhone15,5': 'iPhone 15 Plus',
    'iPhone16,1': 'iPhone 15 Pro',
    'iPhone16,2': 'iPhone 15 Pro Max',
    'iPhone17,3': 'iPhone 16',
    'iPhone17,4': 'iPhone 16 Plus',
    'iPhone17,1': 'iPhone 16 Pro',
    'iPhone17,2': 'iPhone 16 Pro Max',
    'iPhone17,5': 'iPhone 16e',
    // iPad
    'iPad11,6': 'iPad (8th gen)',
    'iPad12,1': 'iPad (9th gen)',
    'iPad13,18': 'iPad (10th gen)',
    'iPad13,1': 'iPad Air (4th gen)',
    'iPad13,16': 'iPad Air (5th gen)',
    'iPad14,1': 'iPad mini (6th gen)',
    'iPad13,4': 'iPad Pro 11-inch',
    'iPad13,8': 'iPad Pro 12.9-inch',
  };

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
