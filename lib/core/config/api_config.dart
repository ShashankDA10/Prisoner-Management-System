/// Central API configuration.
///
/// MIGRATION: Change baseUrl here to point at your production server.
/// Nothing else in the app needs to change.
class ApiConfig {
  ApiConfig._();

  /// ── Change this to your server's IP when running on a real device. ──────
  /// Desktop/emulator:   http://10.0.2.2:3000   (Android emulator → host)
  /// Real phone (LAN):   http://192.168.x.x:3000 (your PC's local IP)
  /// Deployed server:    https://api.yourdomain.com
  static const String baseUrl = 'https://prisoner-management-system-production.up.railway.app';

  static const String login     = '/api/auth/login';
  static const String logout    = '/api/auth/logout';
  static const String me        = '/api/auth/me';

  static const String prisoners       = '/api/prisoners';
  static const String prisonerStats   = '/api/prisoners/stats';
  static const String prisonerByDate  = '/api/prisoners/by-date';
  static const String prisonerImport  = '/api/prisoners/import';

  static String prisonerById(String id) => '/api/prisoners/$id';

  static const String users = '/api/users';
  static String userById(String id) => '/api/users/$id';

  /// Cross-station read-only search (returns prisoners from stations other
  /// than the requester's own station; excludeStation param is optional).
  static const String prisonersCrossStation = '/api/prisoners/cross-station';

  /// Request timeout
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
