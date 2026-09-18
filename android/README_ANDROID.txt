ANDROID SETUP
=============

1. First create the normal project:
   flutter create syswatch_mobile

2. Copy this package's pubspec.yaml, lib folder, and AndroidManifest.xml into that project.

3. The included AndroidManifest.xml intentionally enables:
   - INTERNET access
   - Android browser discovery for Microsoft login
   - clear-text HTTP for the intranet XAMPP server
   - AppAuth redirect: com.nuclark.syswatch.mobile://oauthredirect

4. Keep android:taskAffinity="" OUT of MainActivity and RedirectUriReceiverActivity.
   flutter_appauth documents that an empty taskAffinity can stop the browser redirect
   from returning to the Flutter app.

5. Run:
   flutter clean
   flutter pub get
   flutter run
