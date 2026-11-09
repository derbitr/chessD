import 'package:flutter_test/flutter_test.dart';
import 'package:chess_d/services/app_update_service.dart';

void main() {
  group('Serviço de Notificação & Verificação de Atualizações (AppUpdateService)', () {
    test('isVersionNewer detecta versões mais novas corretamente', () {
      expect(AppUpdateService.isVersionNewer('v1.0.2', 'v1.0.3'), isTrue);
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
  });
}
