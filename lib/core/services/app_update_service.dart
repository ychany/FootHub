import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateService {
  // 앱스토어 앱 ID (iTunes Connect에서 확인 가능)
  static const String _appStoreId = '6757123385';

  /// 앱스토어에서 최신 버전 정보 가져오기
  static Future<String?> getAppStoreVersion() async {
    try {
      final response = await http.get(
        Uri.parse('https://itunes.apple.com/lookup?id=$_appStoreId&country=kr'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final results = json['results'] as List;
        if (results.isNotEmpty) {
          return results.first['version'] as String?;
        }
      }
    } catch (e) {
      // 네트워크 오류 등은 무시
    }
    return null;
  }

  /// 현재 앱 버전 가져오기
  static Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// 업데이트 필요 여부 확인
  static Future<bool> isUpdateAvailable() async {
    try {
      final currentVersion = await getCurrentVersion();
      final storeVersion = await getAppStoreVersion();

      if (storeVersion == null) return false;

      return _compareVersions(storeVersion, currentVersion) > 0;
    } catch (e) {
      return false;
    }
  }

  /// 버전 비교 (storeVersion > currentVersion이면 양수 반환)
  static int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2Parts = version2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // 길이 맞추기
    while (v1Parts.length < 3) {
      v1Parts.add(0);
    }
    while (v2Parts.length < 3) {
      v2Parts.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (v1Parts[i] > v2Parts[i]) return 1;
      if (v1Parts[i] < v2Parts[i]) return -1;
    }
    return 0;
  }

  /// 앱스토어 URL
  static String get appStoreUrl =>
      'https://apps.apple.com/app/id$_appStoreId';
}
