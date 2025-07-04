import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:developer' as developer;

class NetworkHandler {
  final String apiGwUrl =
      "wss://m67w5e0n7f.execute-api.us-east-1.amazonaws.com/production"; // Use wss://

  WebSocketChannel? _channel;
  Map<String, Function(Map<String, dynamic>)> _actionHandlers = {};

  bool get registeredHandlers => _actionHandlers.isEmpty;

  void connect(
      {required String idToken,
      Function()? onConnected,
      Function()? onConnectionError,
      Function()? onClosed}) {
    final uri = Uri.parse('$apiGwUrl?Authorization=$idToken');

    _channel = WebSocketChannel.connect(uri);
    onConnected?.call();

    _channel!.stream.listen(
      (message) {
        developer.log(message);
        final decoded = jsonDecode(message);
        final action = decoded['action'];

        if (_actionHandlers.containsKey(action)) {
          _actionHandlers[action]!(decoded);
        } else {
          developer.log(message);
          developer.log("Unhandled action: $action");
        }
      },
      onDone: () {
        developer.log("WebSocket Closed");
        _channel = null;
        onClosed?.call();
      },
      onError: (error) {
        developer.log("WebSocket error: $error");
        onConnectionError?.call();
      },
    );
  }

  void sendMessage(String action, Map<String, dynamic> payload) {
    final message = {
      'action': action,
      ...payload,
    };
    _channel?.sink.add(jsonEncode(message));
  }

  void registerHandler(String action, Function(Map<String, dynamic>) handler) {
    _actionHandlers[action] = handler;
  }

  void disconnect() {
    _channel?.sink.close(status.goingAway);
    _channel = null;
  }
}
