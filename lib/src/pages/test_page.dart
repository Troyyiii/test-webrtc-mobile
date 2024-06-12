import 'package:flutter/material.dart';
import 'package:test_webrtc_mobile/src/pages/test_call_page.dart';
import 'package:test_webrtc_mobile/src/services/websocket_service.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final websocketService = WebsocketService();
  String? incomingNotif;

  @override
  void initState() {
    super.initState();
    _connect();
    _listenEvents();
  }

  _connect() {
    websocketService.init();
  }

  _listenEvents() {
    websocketService.socket?.on('notif', (data) {
      if (mounted) {
        setState(() {
          incomingNotif = data['id'];
        });
      }
    });
  }

  _toCall(String? remoteId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => TestCallPage(
          userId: websocketService.socket!.id!,
          remoteId: remoteId,
        ),
      ),
    );
  }

  _sendNotif() {
    String socketId = websocketService.socket!.id!;
    websocketService.socket?.emit('notif', {'id': socketId});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: incomingNotif == null
          ? Center(
              child: IconButton(
                onPressed: () {
                  _sendNotif();
                  _toCall(null);
                },
                icon: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.call),
                ),
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(incomingNotif ?? 'Error'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            incomingNotif = null;
                          });
                        },
                        icon: const CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(Icons.call_end),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _toCall(incomingNotif);
                          setState(() {
                            incomingNotif = null;
                          });
                        },
                        icon: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.call),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
