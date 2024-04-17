import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:test_webrtc_mobile/src/pages/call_page.dart';
import 'package:test_webrtc_mobile/src/pages/chat_page.dart';
import 'package:test_webrtc_mobile/src/services/websocket_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late WebsocketService websocketService;
  dynamic incomingSdpOffer;

  String myUserId = '';
  bool isConnect = true;

  final callerController = TextEditingController();

  @override
  void initState() {
    _connect();
    WebsocketService.instance.socket!.on('offer', (data) {
      if (mounted) {
        setState(() {
          incomingSdpOffer = data;
        });
        debugPrint('<<< Incoming offer >>>');
      }
    });
    super.initState();
  }

  _connect() {
    websocketService = WebsocketService.instance;
    websocketService.connect();
    websocketService.waitUntilSocketConnected().then((_) {
      setState(() {
        myUserId = websocketService.myUserId;
      });
    }).catchError((error) {
      setState(() {
        isConnect = false;
      });
    });
  }

  _joinCall({
    required String userId,
    required String remoteId,
    dynamic offer,
  }) {
    Navigator.push(
      context,
      // MaterialPageRoute(
      //   builder: (BuildContext context) => CallPage(
      //     myUserId: userId,
      //     remoteId: remoteId,
      //     offer: offer,
      //   ),
      // ),
      MaterialPageRoute(
        builder: (BuildContext context) => ChatPage(
          myUserId: userId,
          remoteId: remoteId,
          offer: offer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 100,
        title: const Text(
          'NKRI WebRTC Simulator',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xffBF3131),
          ),
        ),
      ),
      body: isConnect
          ? SafeArea(
              child: incomingSdpOffer == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: Column(
                              children: [
                                TextField(
                                  controller: TextEditingController(
                                    text: myUserId,
                                  ),
                                  textAlign: TextAlign.center,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'ID Anda',
                                    contentPadding: const EdgeInsets.all(15.0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: callerController,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: 'Masukkan Remote ID',
                                    alignLabelWithHint: true,
                                    contentPadding: const EdgeInsets.all(15.0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                  onPressed: () {
                                    _joinCall(
                                      userId: myUserId,
                                      remoteId: callerController.text,
                                    );
                                  },
                                  child: const Text(
                                    'Undang',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.08,
                        width: MediaQuery.of(context).size.width,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.75),
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Panggilan Masuk dari ${incomingSdpOffer['from']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.call_end),
                                color: Colors.redAccent,
                                onPressed: () {
                                  setState(() {
                                    incomingSdpOffer = null;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.call),
                                color: Colors.greenAccent,
                                onPressed: () {
                                  _joinCall(
                                      userId: myUserId,
                                      remoteId: incomingSdpOffer['from'],
                                      offer: incomingSdpOffer['offer']);
                                  setState(() {
                                    incomingSdpOffer = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            )
          : const Center(
              child: Text('Gagal Mendapatkan ID-mu :('),
            ),
    );
  }
}
