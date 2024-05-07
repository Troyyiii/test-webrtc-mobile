import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:test_webrtc_mobile/src/pages/call_page.dart';
import 'package:test_webrtc_mobile/src/services/websocket_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  dynamic incomingSdpOffer;

  final socket = WebsocketService.instance.socket;
  List<dynamic> listUser = [];

  @override
  void initState() {
    _listenEvents();
    super.initState();
  }

  _listenEvents() {
    socket!.on('get_user', (data) {
      setState(() {
        listUser = data;
      });
    });

    socket!.on('receive_offer', (data) {
      setState(() {
        incomingSdpOffer = data;
      });
    });
  }

  _toCall({
    required String userId,
    required String remoteId,
    dynamic offer,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => CallPage(
          myUserId: userId,
          remoteId: remoteId,
          offer: offer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return incomingSdpOffer != null
        ? Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(incomingSdpOffer['from']),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            incomingSdpOffer = null;
                          });
                        },
                        icon: const CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(Icons.call),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _toCall(
                            userId: socket!.id!,
                            remoteId: incomingSdpOffer['from'],
                            offer: incomingSdpOffer['offer'],
                          );
                          setState(() {
                            incomingSdpOffer = null;
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
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text("Contact"),
            ),
            body: ListView.builder(
              itemCount: listUser.length,
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () {
                    _toCall(
                      userId: socket!.id!,
                      remoteId: listUser[index]['socketId'],
                    );
                  },
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(listUser[index]['userId']),
                  subtitle: Text(listUser[index]['socketId']),
                );
              },
            ),
          );
  }
}
