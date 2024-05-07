import 'package:flutter/material.dart';
import 'package:test_webrtc_mobile/src/pages/main_page.dart';
import 'package:test_webrtc_mobile/src/services/websocket_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late WebsocketService websocketService;

  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _connect() {
    websocketService = WebsocketService.instance;
    websocketService.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: textController,
            ),
            ElevatedButton(
              onPressed: () {
                if (WebsocketService.instance.socket!.connected &&
                    textController.text.isNotEmpty) {
                  WebsocketService.instance.socket!
                      .emit('add_user', {textController.text});
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainPage(),
                    ),
                  );
                }
              },
              child: const Text('test'),
            ),
          ],
        ),
      ),
    );
  }
}
