import 'dart:async';
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

class AppUpdateCheckOutcome {
  final AppUpdateInfo? info;
  final String? errorMessage;

  const AppUpdateCheckOutcome({
    this.info,
    this.errorMessage,
  });

  bool get hasError => info == null && errorMessage != null;
}

class AppUpdateService {
  static const String currentVersion = 'v1.0.5';
  static const String repoApiUrl = 'https://api.github.com/repos/derbitr/chessD/releases/latest';
  static const String repoLatestWebUrl = 'https://github.com/derbitr/chessD/releases/latest';
  static const String repoReleasesPage = 'https://github.com/derbitr/chessD/releases';

  /// Hook opcional para testes de widget isolarem consultas reais de rede.
  static Future<AppUpdateCheckOutcome> Function()? testCheckOverride;

  /// Consulta simples mantendo compatibilidade com chamadas existentes.
  static Future<AppUpdateInfo?> checkForUpdate() async {
    final outcome = await checkForUpdateDetailed();
    return outcome.info;
  }

  /// Consulta detalhada com fallback via redirecionamento HTTP caso a API do GitHub sofra rate-limit.
  static Future<AppUpdateCheckOutcome> checkForUpdateDetailed({
    Uri? apiUri,
    Uri? redirectUri,
    String? currentVersionOverride,
    bool? isAndroidOverride,
    bool? isWindowsOverride,
    HttpClient Function()? httpClientFactory,
  }) async {
    if (testCheckOverride != null && apiUri == null && redirectUri == null) {
      return testCheckOverride!();
    }

    final String activeCurrentVersion = currentVersionOverride ?? currentVersion;
    final bool android = isAndroidOverride ?? Platform.isAndroid;
    final bool windows = isWindowsOverride ?? Platform.isWindows;
    final HttpClient Function() createClient = httpClientFactory ?? HttpClient.new;
    late String apiError;

    // 1. Tenta a API oficial de Releases do GitHub
    HttpClient? client;
    try {
      client = createClient();
      client.connectionTimeout = const Duration(seconds: 6);

      final request = await client.getUrl(apiUri ?? Uri.parse(repoApiUrl));
      request.headers.set('User-Agent', 'chessD-App/$activeCurrentVersion');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        final parsed = parseReleaseJson(
          json,
          currentVersionOverride: activeCurrentVersion,
          isAndroid: android,
          isWindows: windows,
        );
        if (parsed != null) {
          return AppUpdateCheckOutcome(info: parsed);
        }
        apiError = 'Resposta do GitHub sem tag de versão válida.';
      } else {
        apiError = 'GitHub API retornou HTTP ${response.statusCode}';
      }
    } on SocketException {
      apiError = 'Sem conexão com a internet ou bloqueio de rede no dispositivo.';
    } on TimeoutException {
      apiError = 'Tempo limite esgotado ao consultar o GitHub.';
    } catch (e) {
      apiError = 'Falha ao consultar atualizações ($e).';
    } finally {
      client?.close(force: true);
    }

    // 2. Fallback sem limite de taxa (rate-limit free) seguindo cabeçalho Location do /releases/latest
    HttpClient? webClient;
    try {
      webClient = createClient();
      webClient.connectionTimeout = const Duration(seconds: 6);

      final req = await webClient.getUrl(redirectUri ?? Uri.parse(repoLatestWebUrl));
      req.followRedirects = false;
      req.headers.set('User-Agent', 'chessD-App/$activeCurrentVersion');

      final res = await req.close().timeout(const Duration(seconds: 8));
      await res.drain<void>();

      final location = res.headers.value(HttpHeaders.locationHeader);
      final tagName = extractTagFromRedirectUrl(location);
      if (tagName != null && tagName.isNotEmpty) {
        final releaseUrl = '$repoReleasesPage/tag/$tagName';
        final downloadUrl = buildExpectedDownloadUrl(
          tagName,
          isAndroid: android,
          isWindows: windows,
        );
        return AppUpdateCheckOutcome(
          info: AppUpdateInfo(
            latestVersion: tagName,
            currentVersion: activeCurrentVersion,
            hasUpdate: isVersionNewer(activeCurrentVersion, tagName),
            releaseNotes: 'Nova versão $tagName disponível no GitHub Releases.',
            downloadUrl: downloadUrl,
            releaseUrl: releaseUrl,
          ),
        );
      }
    } catch (_) {
      // Mantém erro informativo obtido na etapa primária
    } finally {
      webClient?.close(force: true);
    }

    return AppUpdateCheckOutcome(
      errorMessage: apiError,
    );
  }

  /// Faz o parsing do JSON retornado por GitHub Releases.
  static AppUpdateInfo? parseReleaseJson(
    Map<String, dynamic> json, {
    String? currentVersionOverride,
    bool? isAndroid,
    bool? isWindows,
  }) {
    final tagName = (json['tag_name'] as String? ?? '').trim();
    if (tagName.isEmpty) return null;

    final activeCurrentVersion = currentVersionOverride ?? currentVersion;
    final bodyText = (json['body'] as String? ?? '').trim();
    final htmlUrl = (json['html_url'] as String? ?? repoReleasesPage).trim();
    final android = isAndroid ?? Platform.isAndroid;
    final windows = isWindows ?? Platform.isWindows;

    String downloadUrl = htmlUrl;
    final assets = json['assets'] as List<dynamic>? ?? [];

    for (final item in assets) {
      final asset = item as Map<String, dynamic>;
      final name = (asset['name'] as String? ?? '').toLowerCase();
      final browserUrl = (asset['browser_download_url'] as String? ?? '').trim();
      if (browserUrl.isEmpty) continue;

      if (android && name.endsWith('.apk')) {
        downloadUrl = browserUrl;
        break;
      } else if (windows && name.endsWith('.zip')) {
        downloadUrl = browserUrl;
        break;
      }
    }

    return AppUpdateInfo(
      latestVersion: tagName,
      currentVersion: activeCurrentVersion,
      hasUpdate: isVersionNewer(activeCurrentVersion, tagName),
      releaseNotes: bodyText,
      downloadUrl: downloadUrl,
      releaseUrl: htmlUrl,
    );
  }

  /// Extrai a tag da URL de redirecionamento do GitHub (`/releases/tag/v1.0.5`).
  static String? extractTagFromRedirectUrl(String? location) {
    if (location == null || location.trim().isEmpty) return null;
    final uri = Uri.tryParse(location.trim());
    if (uri == null) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final tagIndex = segments.indexOf('tag');
    if (tagIndex != -1 && tagIndex + 1 < segments.length) {
      return segments[tagIndex + 1].trim();
    }
    return null;
  }

  /// Monta o link direto esperado para o binário da release quando obtido via fallback.
  static String buildExpectedDownloadUrl(
    String tagName, {
    bool? isAndroid,
    bool? isWindows,
  }) {
    final android = isAndroid ?? Platform.isAndroid;
    final windows = isWindows ?? Platform.isWindows;
    if (android) {
      return '$repoReleasesPage/download/$tagName/chessD-$tagName-android.apk';
    }
    if (windows) {
      return '$repoReleasesPage/download/$tagName/chessD-$tagName-windows-x64.zip';
    }
    return '$repoReleasesPage/tag/$tagName';
  }

  /// Compara versões semânticas (ex: v1.0.2 vs v1.0.3).
  static bool isVersionNewer(String current, String latest) {
    if (latest.isEmpty) return false;

    final currParts = current
        .replaceAll(RegExp(r'[^0-9.]'), '')
        .split('.')
        .where((p) => p.isNotEmpty)
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
    final latestParts = latest
        .replaceAll(RegExp(r'[^0-9.]'), '')
        .split('.')
        .where((p) => p.isNotEmpty)
        .map((p) => int.tryParse(p) ?? 0)
        .toList();

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
