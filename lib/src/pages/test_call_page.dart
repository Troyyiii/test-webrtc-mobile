import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:test_webrtc_mobile/src/common/call_status.dart';
import 'package:test_webrtc_mobile/src/services/websocket_service.dart';

class TestCallPage extends StatefulWidget {
  final String userId;
  final String? remoteId;

  const TestCallPage({
    super.key,
    required this.userId,
    this.remoteId,
  });

  @override
  State<TestCallPage> createState() => _TestCallPageState();
}

class _TestCallPageState extends State<TestCallPage> {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  List<MediaDeviceInfo>? devices;

  final socket = WebsocketService().socket;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  CallStatus status = CallStatus.start;
  bool isAudioOn = true, isSpeaker = false;

  @override
  void initState() {
    super.initState();
    _initRenderer();
    _createPeerConnection();
  }

  @override
  void dispose() {
    super.dispose();
    _peerConnection?.close();
    _disposeRenderers();
    _disposeSocket();
  }

  Future<String> _getDeviceId(String deviceType) async {
    devices = await navigator.mediaDevices.enumerateDevices();

    MediaDeviceInfo device =
        devices!.firstWhere((element) => element.deviceId == deviceType);

    return device.deviceId;
  }

  _initRenderer() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();
  }

  void _disposeRenderers() {
    _localRenderer.dispose();
    _localRenderer.srcObject?.getTracks().forEach((track) => track.stop());
    _localRenderer.srcObject = null;
    _remoteRenderer.dispose();
    _remoteRenderer.srcObject = null;
  }

  void _disposeSocket() {
    socket?.off('offer');
    socket?.off('answer');
    socket?.off('iceCandidate');
  }

  Future<void> _createPeerConnection() async {
    String? incomeId;

    final Map<String, dynamic> configuration = {
      "iceServers": [
        {
          "urls": [
            "stun:stun1.l.google.com:19302",
            "stun:stun2.l.google.com:19302",
          ]
        },
      ]
    };

    final Map<String, dynamic> config = {
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    final Map<String, dynamic> dcConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': false,
      },
      'optional': [],
    };

    _peerConnection = await createPeerConnection(configuration, config);

    // Set local stream settings
    _localStream = await _getUserMedia();
    final String audioDevice = await _getDeviceId('earpiece');
    setState(() {
      _localRenderer.srcObject = _localStream;
      _localRenderer.audioOutput(audioDevice);
    });

    // Send local stream
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    if (widget.remoteId != null) {
      RTCSessionDescription offer =
          await _peerConnection!.createOffer(dcConstraints);

      _peerConnection?.setLocalDescription(offer);

      socket!.emit("offer", {
        "offer": offer.toMap(),
        "to": widget.remoteId,
        "from": widget.userId,
      });

      socket!.on("answer", (data) async {
        try {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(
              data["answer"]["sdp"],
              data["answer"]["type"],
            ),
          );
        } catch (e) {
          log("Gagal on answer: $e");
        }
      });
    } else {
      socket!.on('offer', (data) async {
        try {
          incomeId = data['from'];

          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(
              data['offer']["sdp"],
              data['offer']["type"],
            ),
          );

          RTCSessionDescription answer =
              await _peerConnection!.createAnswer(dcConstraints);

          _peerConnection?.setLocalDescription(answer);

          socket!.emit("answer", {
            "answer": answer.toMap(),
            "to": incomeId,
            "from": widget.userId,
          });
        } catch (e) {
          log("Gagal on set remote description: $e");
        }
      });
    }

    socket!.on("iceCandidate", (data) async {
      try {
        RTCIceCandidate iceCandidates = RTCIceCandidate(
          data['iceCandidate']["candidate"],
          data['iceCandidate']["sdpMid"],
          data['iceCandidate']["sdpMLineIndex"],
        );
        await _peerConnection!.addCandidate(iceCandidates);
      } catch (e) {
        log("Gagal on ice candidate: $e");
      }
    });

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        socket!.emit(
          "iceCandidate",
          {
            "iceCandidate": {
              "candidate": candidate.candidate,
              "sdpMid": candidate.sdpMid,
              "sdpMLineIndex": candidate.sdpMLineIndex
            },
            "to": widget.remoteId ?? incomeId,
          },
        );
      }
    };

    // Add remote renderer
    _peerConnection?.onTrack = (event) {
      _remoteRenderer.srcObject = event.streams[0];
    };

    _peerConnection?.onConnectionState = (state) {
      log('Connection state: $state');
      if (mounted) {
        setState(() {
          switch (state) {
            case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
              status = CallStatus.connecting;
              _initRenderer();
              break;
            case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
              status = CallStatus.connected;
              break;
            case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
                  RTCPeerConnectionState.RTCPeerConnectionStateFailed:
              status = CallStatus.close;
              break;
            default:
              status = CallStatus.start;
          }
        });
      }
    };
  }

  Future<MediaStream> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': isAudioOn,
      'video': false
      // ? {
      //     'mandatory': {
      //       'minWidth': '640',
      //       'minHeight': '480',
      //       'minFrameRate': '30',
      //     },
      //     'facingMode': 'user',
      //     'optional': [],
      //   }
      // : false,
    };

    MediaStream stream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);

    return stream;
  }

  void _muteMic() async {
    setState(() {
      isAudioOn = !isAudioOn;
      _localStream
          ?.getAudioTracks()
          .forEach((track) => track.enabled = isAudioOn);
    });
  }

  void _switchAudio() async {
    String? device;
    isSpeaker = !isSpeaker;
    isSpeaker ? device = 'speaker' : device = 'earpiece';
    final String audioDevice = await _getDeviceId(device);
    setState(() {
      _localRenderer.audioOutput(audioDevice);
    });
  }

  void _leaveCall() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: status == CallStatus.connected
          ? SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 0,
                    height: 0,
                    child: RTCVideoView(_remoteRenderer),
                  ),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text("User"),
                        CircleAvatar(
                          radius: 75,
                          child: Icon(
                            Icons.person,
                            size: 50,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    color: Colors.blueAccent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: Icon(
                            isAudioOn ? Icons.mic : Icons.mic_off,
                            color: isAudioOn ? Colors.white : Colors.redAccent,
                          ),
                          onPressed: () {
                            _muteMic();
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.volume_up,
                            color: isSpeaker ? Colors.white : Colors.grey,
                          ),
                          onPressed: () {
                            _switchAudio();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.call_end),
                          color: Colors.redAccent,
                          onPressed: () {
                            _leaveCall();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : const Center(
              child: Text('Ringing . . .'),
            ),
    );
  }
}
