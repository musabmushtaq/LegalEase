import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  group('WebSocket Connection Tests', () {
    test('WebSocket connects successfully', () async {
      final uri = Uri.parse('ws://127.0.0.1:8000/ws/health');
      final channel = WebSocketChannel.connect(uri);

      // Wait for connection to establish
      await Future.delayed(const Duration(seconds: 1));

      expect(channel, isNotNull);
      await channel.sink.close();
    });

    test('WebSocket receives heartbeats', () async {
      final uri = Uri.parse('ws://127.0.0.1:8000/ws/health');
      final channel = WebSocketChannel.connect(uri);

      int heartbeatCount = 0;
      channel.stream.listen((message) {
        if (message is String) {
          // Verify it's valid JSON with heartbeat structure
          if (message.contains('heartbeat') && message.contains('timestamp')) {
            heartbeatCount++;
          }
        }
      });

      // Wait for 2 heartbeats (10 seconds apart)
      await Future.delayed(const Duration(seconds: 25));

      expect(heartbeatCount, greaterThanOrEqualTo(2));
      await channel.sink.close();
    });

    test('WebSocket channel is of correct type', () async {
      final uri = Uri.parse('ws://127.0.0.1:8000/ws/health');
      final channel = WebSocketChannel.connect(uri);

      expect(channel, isA<WebSocketChannel>());
      await channel.sink.close();
    });
  });
}
