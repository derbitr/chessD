import 'dart:convert';
import 'dart:io';

class AppUpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final bool hasUpdate;
  final String releaseNotes;
  final String downloadUrl;
  final String releaseUrl;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.hasUpdate,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.releaseUrl,
  });
}

class AppUpdateService {
  static const String currentVersion = 'v1.0.4';
  static const String repoApiUrl = 'https://api.github.com/repos/derbitr/chessD/releases/latest';
  static const String repoReleasesPage = 'https://github.com/derbitr/chessD/releases';

  /// Consulta a API do GitHub Releases de forma silenciosa e não bloqueante
  static Future<AppUpdateInfo?> checkForUpdate() async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      final request = await client.getUrl(Uri.parse(repoApiUrl));
      request.headers.set('User-Agent', 'chessD-App');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close().timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;

        final tagName = (json['tag_name'] as String? ?? '').trim();
        final bodyText = (json['body'] as String? ?? '').trim();
        final htmlUrl = (json['html_url'] as String? ?? repoReleasesPage).trim();

        // Procura por assets adequados à plataforma (.apk para Android, .zip para Windows)
        String downloadUrl = htmlUrl;
        final assets = json['assets'] as List<dynamic>? ?? [];

        for (final item in assets) {
          final asset = item as Map<String, dynamic>;
          final name = (asset['name'] as String? ?? '').toLowerCase();
          final browserUrl = asset['browser_download_url'] as String? ?? '';

          if (Platform.isAndroid && name.endsWith('.apk')) {
            downloadUrl = browserUrl;
            break;
          } else if (Platform.isWindows && name.endsWith('.zip')) {
            downloadUrl = browserUrl;
            break;
          }
        }

        final isNewer = isVersionNewer(currentVersion, tagName);

        return AppUpdateInfo(
          latestVersion: tagName,
          currentVersion: currentVersion,
          hasUpdate: isNewer,
          releaseNotes: bodyText,
          downloadUrl: downloadUrl,
          releaseUrl: htmlUrl,
        );
      }
    } catch (_) {
      // Falha silenciosa em caso de ausência de rede (100% offline-first)
    } finally {
      client?.close(force: true);
    }
    return null;
  }

  /// Compara versões semânticas (ex: v1.0.2 vs v1.0.3)
  static bool isVersionNewer(String current, String latest) {
    if (latest.isEmpty) return false;

    final currParts = current.replaceAll(RegExp(r'[^0-9.]'), '').split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final latestParts = latest.replaceAll(RegExp(r'[^0-9.]'), '').split('.').map((p) => int.tryParse(p) ?? 0).toList();

    final maxLen = currParts.length > latestParts.length ? currParts.length : latestParts.length;

    for (int i = 0; i < maxLen; i++) {
      final c = i < currParts.length ? currParts[i] : 0;
      final l = i < latestParts.length ? latestParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}
