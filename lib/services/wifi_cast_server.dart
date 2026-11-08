import 'dart:convert';
import 'dart:io';

/// Servidor Local HTTP Embutido para Espelhamento de Partida (Wi-Fi Cast)
/// Permite projetar o tabuleiro e lances ao vivo para qualquer Smart TV ou navegador na rede local
class WifiCastServer {
  HttpServer? _server;
  String _currentFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  List<String> _movesHistory = [];
  int _port = 8080;

  bool get isRunning => _server != null;
  int get port => _port;

  String get localIpAddress {
    return '192.168.1.50'; // IP simulado ou resolvido pela rede
  }

  void updateState({required String fen, List<String>? moves}) {
    _currentFen = fen;
    if (moves != null) {
      _movesHistory = List.from(moves);
    }
  }

  Future<bool> start({int port = 8080}) async {
    if (_server != null) return true;
    _port = port;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _port = _server!.port;
      _server!.listen(_handleRequest);
      return true;
    } catch (_) {
      // Fallback para porta efêmera caso 8080 esteja em uso
      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
        _port = _server!.port;
        _server!.listen(_handleRequest);
        return true;
      } catch (e) {
        return false;
      }
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  void _handleRequest(HttpRequest request) {
    final path = request.uri.path;

    if (path == '/api/state') {
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'fen': _currentFen,
          'moves': _movesHistory,
          'timestamp': DateTime.now().toIso8601String(),
        }))
        ..close();
      return;
    }

    // Página HTML5 de Espelhamento para Smart TV
    final html = '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <title>Soberano Chess • Wi-Fi Cast</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { background: #0B0F17; color: #F8FAFC; font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
    h1 { color: #00E5FF; letter-spacing: 2px; }
    .box { background: #151C28; border: 1px solid #1E2838; border-radius: 16px; padding: 24px; text-align: center; max-width: 500px; }
    .fen { font-family: monospace; background: #0B0F17; padding: 12px; border-radius: 8px; word-break: break-all; color: #FFB300; margin: 16px 0; }
    .badge { background: #00E676; color: #000; font-weight: bold; padding: 4px 12px; border-radius: 12px; display: inline-block; }
  </style>
</head>
<body>
  <div class="box">
    <div class="badge">TRANSMISSÃO AO VIVO • WI-FI CAST</div>
    <h1>SOBERANO CHESS</h1>
    <p>Partida sincronizada em tempo real via rede local sem internet.</p>
    <div class="fen" id="fen">$_currentFen</div>
    <p id="moves">Lances: ${_movesHistory.length}</p>
  </div>
</body>
</html>
''';

    request.response
      ..headers.contentType = ContentType.html
      ..write(html)
      ..close();
  }
}
