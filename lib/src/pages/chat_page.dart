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

  RTCPeerConnection? _peerConnection;

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
    _initWebrtc();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _initWebrtc() async {
    _peerConnection = await createPeerConnection(_configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        log('Peer on ice candidate');
        socket!.emit(
          'ice candidate',
          {
            'iceCandidate': {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex
            },
            'to': widget.remoteId,
          },
        );
      }
    };

    socket!.on('ice candidate', (data) async {
      log('Socket on ice candidate');

      RTCIceCandidate iceCandidates = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(iceCandidates);
      socket!.emit('ice added');
    });

    if (widget.offer != null) {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(
          widget.offer['sdp'],
          widget.offer['type'],
        ),
      );

      RTCSessionDescription answer = await _peerConnection!.createAnswer();

      await _peerConnection!.setLocalDescription(answer);

      socket!.emit('answer', {
        'answer': answer.toMap(),
        'to': widget.remoteId,
        'from': widget.myUserId,
      });
    } else {
      RTCSessionDescription offer = await _peerConnection!.createOffer();

      await _peerConnection!.setLocalDescription(offer);

      socket!.emit('offer', {
        'offer': offer.toMap(),
        'to': widget.remoteId,
        'from': widget.myUserId,
      });

      socket!.on('answer', (data) async {
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
