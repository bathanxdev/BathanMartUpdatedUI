import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  AppConstants._();

  static const String appName    = 'Bathan Mart';
  static const String appTagline = 'Local & Global Products. Delivered Fast.';
  static const String appVersion = '1.0.0';

  /// baseUrl automatically adjusts for each platform:
  ///   Web browser  → localhost:3000  (same machine)
  ///   Android emu  → 10.0.2.2:3000  (emulator special IP for host machine)
  ///   Physical phone → set YOUR_IP to your computer's local network IP
  ///
  /// ⚠️  For physical Android/iOS device, change YOUR_IP:
  ///     e.g. 'http://192.168.1.100:3000/api/v1'
  static String get baseUrl {
    if (kIsWeb) {
      // Running in Chrome / web browser
      return 'http://localhost:3000/api/v1';
    }
    // Android emulator uses 10.0.2.2 to reach host machine
    return 'http://10.0.2.2:3000/api/v1';
    // Physical device — uncomment and set your IP:
    // return 'http://192.168.1.100:3000/api/v1';
  }

  static const String tokenKey = 'bm_auth_token';
  static const String userKey  = 'bm_user_data';

  static const int defaultPageSize = 20;
  static const int cartBadgeMax    = 99;

  static const Map<String, String> tierLabels = {
    'MFDC': '⚡ Express (30 min – 2 hr)',
    'LWH':  '🚚 Same-Day / Next-Day',
    'MCW':  '📦 Standard (2–5 days)',
  };

  static const Map<String, String> orderStatusLabels = {
    'confirmed':        'Confirmed',
    'picking':          'Picking',
    'packed':           'Packed',
    'dispatched':       'Dispatched',
    'out_for_delivery': 'Out for Delivery',
    'delivered':        'Delivered',
    'cancelled':        'Cancelled',
    'returned':         'Returned',
  };
}
