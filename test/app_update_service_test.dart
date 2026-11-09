import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_d/main.dart';
import 'package:chess_d/services/app_update_service.dart';

void main() {
  tearDown(() {
    AppUpdateService.testCheckOverride = null;
  });

  group('Serviço de Notificação & Verificação de Atualizações (AppUpdateService)', () {
    test('isVersionNewer detecta versões mais novas corretamente', () {
      expect(AppUpdateService.isVersionNewer('v1.0.2', 'v1.0.3'), isTrue);
      expect(AppUpdateService.isVersionNewer('v1.0.4', 'v1.0.5'), isTrue);
      expect(AppUpdateService.isVersionNewer('v1.0.2', 'v1.1.0'), isTrue);
      expect(AppUpdateService.isVersionNewer('v1.0.2', 'v2.0.0'), isTrue);
      expect(AppUpdateService.isVersionNewer('1.0.2', '1.0.3'), isTrue);
      expect(AppUpdateService.isVersionNewer('v1.0.2', 'v1.0.2.1'), isTrue);
    });

    test('isVersionNewer rejeita versões iguais ou mais antigas', () {
      expect(AppUpdateService.isVersionNewer('v1.0.2', 'v1.0.2'), isFalse);
      expect(AppUpdateService.isVersionNewer('v1.0.2', 'v1.0.1'), isFalse);
      expect(AppUpdateService.isVersionNewer('v1.0.2', 'v0.9.9'), isFalse);
      expect(AppUpdateService.isVersionNewer('v1.0.2', ''), isFalse);
    });

    test('extractTagFromRedirectUrl e buildExpectedDownloadUrl funcionam por plataforma', () {
      expect(
        AppUpdateService.extractTagFromRedirectUrl(
          'https://github.com/derbitr/chessD/releases/tag/v1.0.5',
        ),
        equals('v1.0.5'),
      );
      expect(
        AppUpdateService.buildExpectedDownloadUrl('v1.0.5', isAndroid: true, isWindows: false),
        equals('https://github.com/derbitr/chessD/releases/download/v1.0.5/chessD-v1.0.5-android.apk'),
      );
      expect(
        AppUpdateService.buildExpectedDownloadUrl('v1.0.5', isAndroid: false, isWindows: true),
        equals('https://github.com/derbitr/chessD/releases/download/v1.0.5/chessD-v1.0.5-windows-x64.zip'),
      );
    });

    test('parseReleaseJson seleciona APK no Android e ZIP no Windows', () {
      final json = <String, dynamic>{
        'tag_name': 'v1.0.5',
        'body': 'Notas da release',
        'html_url': 'https://github.com/derbitr/chessD/releases/tag/v1.0.5',
        'assets': [
          {
            'name': 'chessD-v1.0.5-android.apk',
            'browser_download_url': 'https://example.com/chessD-v1.0.5-android.apk',
          },
          {
            'name': 'chessD-v1.0.5-windows-x64.zip',
            'browser_download_url': 'https://example.com/chessD-v1.0.5-windows-x64.zip',
          },
        ],
      };

      final androidInfo = AppUpdateService.parseReleaseJson(
        json,
        currentVersionOverride: 'v1.0.4',
        isAndroid: true,
        isWindows: false,
      );
      expect(androidInfo, isNotNull);
      expect(androidInfo!.hasUpdate, isTrue);
      expect(androidInfo.downloadUrl, equals('https://example.com/chessD-v1.0.5-android.apk'));

      final windowsInfo = AppUpdateService.parseReleaseJson(
        json,
        currentVersionOverride: 'v1.0.4',
        isAndroid: false,
        isWindows: true,
      );
      expect(windowsInfo, isNotNull);
      expect(windowsInfo!.hasUpdate, isTrue);
      expect(windowsInfo.downloadUrl, equals('https://example.com/chessD-v1.0.5-windows-x64.zip'));
    });

    test('checkForUpdateDetailed usa API HTTP real e faz fallback via 302 redirect quando API sofre rate-limit', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      bool forceApi403 = false;
      server.listen((HttpRequest req) async {
        if (req.uri.path == '/api/latest') {
          if (forceApi403) {
            req.response.statusCode = 403;
            req.response.write('API rate limit exceeded');
          } else {
            req.response.statusCode = 200;
            req.response.headers.contentType = ContentType.json;
            req.response.write(jsonEncode({
              'tag_name': 'v9.9.9',
              'body': 'Correcao de notificacoes',
              'html_url': 'https://github.com/derbitr/chessD/releases/tag/v9.9.9',
              'assets': [
                {
                  'name': 'chessD-v9.9.9-android.apk',
                  'browser_download_url': 'https://github.com/derbitr/chessD/releases/download/v9.9.9/chessD-v9.9.9-android.apk',
                },
              ],
            }));
          }
          await req.response.close();
        } else if (req.uri.path == '/releases/latest') {
          req.response.statusCode = HttpStatus.found;
          req.response.headers.set(
            HttpHeaders.locationHeader,
            'https://github.com/derbitr/chessD/releases/tag/v9.9.9',
          );
          await req.response.close();
        } else {
          req.response.statusCode = 404;
          await req.response.close();
        }
      });

      final apiUri = Uri.parse('http://127.0.0.1:${server.port}/api/latest');
      final redirectUri = Uri.parse('http://127.0.0.1:${server.port}/releases/latest');

      // 1. Caminho feliz via API JSON (bypassa HttpOverrides de TestWidgetsFlutterBinding via runZoned com IO real ou factory nula? HttpOverrides.runZoned com createHttpClient: (_) => HttpClient() usa TestWidgets binding? Não! SecurityContext/HttpOverrides.runZoned((() => ...), createHttpClient: null) não reseta? Vamos usar factory nativa!)
      // Na verdade HttpClient(context: ...) em dart:io também passa por HttpOverrides se houver; usando HttpOverrides.global = null dentro do teste funciona 100%!
      final prevOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = prevOverrides);

      final okOutcome = await AppUpdateService.checkForUpdateDetailed(
        apiUri: apiUri,
        redirectUri: redirectUri,
        currentVersionOverride: 'v1.0.4',
        isAndroidOverride: true,
        isWindowsOverride: false,
      );
      expect(okOutcome.hasError, isFalse);
      expect(okOutcome.info?.hasUpdate, isTrue);
      expect(okOutcome.info?.latestVersion, equals('v9.9.9'));
      expect(okOutcome.info?.downloadUrl, endsWith('chessD-v9.9.9-android.apk'));

      // 2. Fallback quando API retorna 403 rate limit
      forceApi403 = true;
      final fallbackOutcome = await AppUpdateService.checkForUpdateDetailed(
        apiUri: apiUri,
        redirectUri: redirectUri,
        currentVersionOverride: 'v1.0.4',
        isAndroidOverride: true,
        isWindowsOverride: false,
      );
      expect(fallbackOutcome.hasError, isFalse);
      expect(fallbackOutcome.info?.hasUpdate, isTrue);
      expect(fallbackOutcome.info?.latestVersion, equals('v9.9.9'));
      expect(fallbackOutcome.info?.downloadUrl, endsWith('chessD-v9.9.9-android.apk'));

      // 3. Erro claro quando ambos endpoints falham
      await server.close(force: true);
      final errOutcome = await AppUpdateService.checkForUpdateDetailed(
        apiUri: apiUri,
        redirectUri: redirectUri,
        currentVersionOverride: 'v1.0.4',
      );
      expect(errOutcome.hasError, isTrue);
      expect(errOutcome.errorMessage, isNotEmpty);
    });
  });

  group('UI de Notificação de Atualização no Hub Principal', () {
    testWidgets('Exibe balão, sino na AppBar e badge na aba Mais quando há nova versão', (tester) async {
      AppUpdateService.testCheckOverride = () async => const AppUpdateCheckOutcome(
            info: AppUpdateInfo(
              latestVersion: 'v9.9.9',
              currentVersion: 'v1.0.4',
              hasUpdate: true,
              releaseNotes: 'Correcao completa de notificacoes OTA.',
              downloadUrl: 'https://github.com/derbitr/chessD/releases/download/v9.9.9/chessD-v9.9.9-android.apk',
              releaseUrl: 'https://github.com/derbitr/chessD/releases/tag/v9.9.9',
            ),
          );

      tester.view.physicalSize = const Size(1080, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const ChessDApp());
      await tester.pumpAndSettle();

      // Balão no topo da aba Início + Sino na AppBar
      expect(find.text('Nova Versão Disponível (v9.9.9)'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);

      // Tocar no sino da AppBar abre o diálogo de atualização com notas
      await tester.tap(find.byIcon(Icons.notifications_active_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Nova Atualização!'), findsOneWidget);
      expect(find.text('Versão v9.9.9 disponível para download.'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.text('Baixar Agora')),
        findsOneWidget,
      );

      await tester.tap(find.text('Depois').last);
      await tester.pumpAndSettle();

      // Na aba Mais, o item Verificar Atualizações mostra badge da nova versão
      await tester.tap(find.text('Mais'));
      await tester.pumpAndSettle();
      expect(find.text('Nova versão v9.9.9 disponível!'), findsOneWidget);
      expect(find.text('v9.9.9'), findsOneWidget);
    });

    testWidgets('Verificação manual exibe erro honesto quando sem rede ao invés de dizer que está atualizado', (tester) async {
      AppUpdateService.testCheckOverride = () async => const AppUpdateCheckOutcome(
            errorMessage: 'Sem conexão com a internet ou bloqueio de rede no dispositivo.',
          );

      tester.view.physicalSize = const Size(1080, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const ChessDApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mais'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Verificar Atualizações'));
      await tester.pumpAndSettle();

      expect(find.text('Falha ao Verificar'), findsOneWidget);
      expect(find.text('Versão Mais Recente'), findsNothing);
    });
  });
}
