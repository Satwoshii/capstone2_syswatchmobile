class AppConfig {
  AppConfig._();

  // Android Emulator -> XAMPP on the same Windows PC.
  // For a real phone, replace 10.0.2.2 with the LAN IPv4 address of the
  // computer running XAMPP, for example 192.168.100.219.
  static const String apiBaseUrl =
      'http://192.168.100.219/syswatch_api/mobile_app/';

  static const Duration healthTimeout = Duration(seconds: 8);
  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration uploadTimeout = Duration(seconds: 35);
}
