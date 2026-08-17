import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';

/// Событие от backend (через WebSocket hub).
/// Типы: appointment.create, appointment.update, appointment.delete.
class WsEvent {
  final String type;
  final Map<String, dynamic> data;
  final String shopId;

  WsEvent({required this.type, required this.data, required this.shopId});

  factory WsEvent.fromJson(Map<String, dynamic> j) => WsEvent(
        type: j['type'] as String? ?? '',
        data: (j['data'] as Map?)?.cast<String, dynamic>() ?? {},
        shopId: j['shop_id'] as String? ?? '',
      );
}

/// WebSocket-клиент с авто-переподключением.
/// Подключается к /api/ws?token=<access> — на web Authorization header
/// недоступен, поэтому token передаётся в query param.
/// Backend поддерживает оба способа.
class WsClient {
  final String _wsUrl;
  final SecureStorage _storage;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  final _events = StreamController<WsEvent>.broadcast();
  bool _disposed = false;
  int _reconnectDelay = 1;

  WsClient(this._wsUrl, this._storage);

  Stream<WsEvent> get events => _events.stream;

  Future<void> connect() async {
    if (_disposed) return;
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) return;
    final uri = Uri.parse('$_wsUrl/api/ws?token=$token');
    try {
      _channel = WebSocketChannel.connect(uri);
      _sub = _channel!.stream.listen(
        (msg) {
          try {
            final json = jsonDecode(msg as String) as Map<String, dynamic>;
            _events.add(WsEvent.fromJson(json));
          } catch (_) {
            // ignore parse errors
          }
        },
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: true,
      );
      _reconnectDelay = 1;
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    final delay = _reconnectDelay;
    _reconnectDelay = (_reconnectDelay * 2).clamp(1, 30);
    Future.delayed(Duration(seconds: delay), () {
      if (!_disposed) connect();
    });
  }

  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _channel?.sink.close();
    _events.close();
  }
}

/// Provider для WsClient (singleton).
final wsClientProvider = Provider<WsClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final client = WsClient(AppConfig.wsBaseUrl, storage);
  ref.onDispose(client.dispose);
  return client;
});

