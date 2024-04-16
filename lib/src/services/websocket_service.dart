import 'dart:async';
import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart';

class WebsocketService {
  Socket? socket;
  // String socketUrl = "https://10.0.2.2:3000";
  String socketUrl = "https://192.168.5.119:3000";
  String myUserId = "";

  WebsocketService._();
  static final instance = WebsocketService._();

  final Completer<void> _socketConnCompleter = Completer<void>();

  Future<void> connect() async {
    socket = io(socketUrl, <String, dynamic>{
      "transports": ["websocket"],
    });

    socket!.onConnect((_) async {
      log("<<< Connected >>>");
      myUserId = socket!.id!;
      log("User ID >>> $myUserId");

      _socketConnCompleter.complete();
    });

    socket!.onConnectError((e) {
      log("Connection Error >>> $e");
      _socketConnCompleter.completeError(e);
    });

    socket!.onDisconnect((_) => log("<<< Socket Disconnected >>>"));

    socket!.onError((e) => log("Error >>> $e"));
  }

  Future<void> waitUntilSocketConnected() {
    return _socketConnCompleter.future;
  }
}
