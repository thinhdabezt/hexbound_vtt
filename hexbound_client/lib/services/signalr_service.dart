import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  late HubConnection _hubConnection;
  final String _serverUrl = "http://localhost:5169/gameHub"; // Adjust if testing on Android/iOS

  Future<void> connect() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(_serverUrl)
        .build();

    _hubConnection.onclose(({error}) {
      debugPrint("SignalR Connection Closed: $error");
    });

    try {
      await _hubConnection.start();
      debugPrint("✅ SignalR Connected to $_serverUrl");
      
      // Listen for messages (matches GameHub.cs: SendMessage)
      _hubConnection.on("ReceiveMessage", _handleReceiveMessage);
      
    } catch (e) {
      debugPrint("❌ SignalR Connection Error: $e");
    }
  }

  void _handleReceiveMessage(List<Object?>? args) {
    if (args != null && args.length >= 2) {
      final user = args[0] as String;
      final message = args[1] as String;
      debugPrint("📩 Message from $user: $message");
    }
  }

  Future<void> sendMessage(String user, String message) async {
    if (_hubConnection.state == HubConnectionState.Connected) {
      await _hubConnection.invoke("SendMessage", args: [user, message]);
    } else {
      debugPrint("Cannot send message: Disconnected");
    }
  }
}
