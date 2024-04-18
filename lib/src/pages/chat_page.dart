import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:test_webrtc_mobile/src/services/websocket_service.dart';

class ChatPage extends StatefulWidget {
  final String myUserId, remoteId;
  final dynamic offer;

  const ChatPage(
      {super.key, required this.myUserId, required this.remoteId, this.offer});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final socket = WebsocketService.instance.socket;

  // RTCPeerConnection? _peerConnection;

  RTCPeerConnection? alice;
  RTCPeerConnection? bob;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ]
      },
    ]
  };

  @override
  void initState() {
    // _initWebrtc();
    _dummyWebrtc();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // _initWebrtc() async {
  //   _peerConnection = await createPeerConnection(_configuration);

  //   _peerConnection!.onIceCandidate = (candidate) {
  //     if (candidate.candidate != null) {
  //       log('Peer on ice candidate');
  //       socket!.emit(
  //         'ice candidate',
  //         {
  //           'iceCandidate': {
  //             'candidate': candidate.candidate,
  //             'sdpMid': candidate.sdpMid,
  //             'sdpMLineIndex': candidate.sdpMLineIndex
  //           },
  //           'to': widget.remoteId,
  //         },
  //       );
  //     }
  //   };

  //   socket!.on('ice candidate', (data) async {
  //     log('Socket on ice candidate');

  //     RTCIceCandidate iceCandidates = RTCIceCandidate(
  //       data['candidate'],
  //       data['sdpMid'],
  //       data['sdpMLineIndex'],
  //     );
  //     await _peerConnection!.addCandidate(iceCandidates);
  //     socket!.emit('ice added');
  //   });

  //   if (widget.offer == null) {
  //     RTCSessionDescription offer = await _peerConnection!.createOffer();

  //     await _peerConnection!.setLocalDescription(offer);

  //     socket!.emit('offer', {
  //       'offer': offer.toMap(),
  //       'to': widget.remoteId,
  //       'from': widget.myUserId,
  //     });

  //     socket!.on('answer', (data) async {
  //       await _peerConnection!.setRemoteDescription(
  //         RTCSessionDescription(
  //           data['answer']['sdp'],
  //           data['answer']['type'],
  //         ),
  //       );
  //     });
  //   } else {
  //     await _peerConnection!.setRemoteDescription(
  //       RTCSessionDescription(
  //         widget.offer['sdp'],
  //         widget.offer['type'],
  //       ),
  //     );

  //     RTCSessionDescription answer = await _peerConnection!.createAnswer();

  //     await _peerConnection!.setLocalDescription(answer);

  //     socket!.emit('answer', {
  //       'answer': answer.toMap(),
  //       'to': widget.remoteId,
  //       'from': widget.myUserId,
  //     });
  //   }
  // }

  _dummyWebrtc() async {
    alice = await createPeerConnection(_configuration);
    bob = await createPeerConnection(_configuration);

    RTCSessionDescription offer = await alice!.createOffer();
    await alice!.setLocalDescription(offer);
    socket!.emit('offer', {
      'offer': offer.toMap(),
      'to': socket!.id,
      'from': socket!.id,
    });

    socket!.on('offer', (data) async {
      await bob!.setRemoteDescription(
        RTCSessionDescription(
          data['offer']['sdp'],
          data['offer']['type'],
        ),
      );
      RTCSessionDescription answer = await bob!.createAnswer();
      await bob!.setLocalDescription(answer);
      socket!.emit('answer', {
        'answer': answer.toMap(),
        'to': socket!.id,
        'from': socket!.id,
      });
    });

    socket!.on('answer', (data) async {
      await alice!.setRemoteDescription(
        RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        ),
      );
    });

    alice!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        log('Peer alice on ice candidate');
        socket!.emit(
          'ice candidate',
          {
            'iceCandidate': {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
            'to': socket!.id,
          },
        );
      }
    };

    socket!.on('ice candidate', (data) async {
      log('Socket bob on ice candidate');
      RTCIceCandidate iceCandidates = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );
      await bob!.addCandidate(iceCandidates);
    });

    bob!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        log('Peer bob on ice candidate');
        socket!.emit(
          'ice candidate',
          {
            'iceCandidate': {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
            'to': socket!.id,
          },
        );
      }
    };

    socket!.on('ice candidate', (data) async {
      log('Socket alice on ice candidate');
      RTCIceCandidate iceCandidates = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );
      await alice!.addCandidate(iceCandidates);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
