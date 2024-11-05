
import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:wakelock/wakelock.dart';
import 'package:http/http.dart' as http;

const appId = "fc22b1634fcf4b5eacef4b96cc41cc17";

class AudioCall extends StatefulWidget {
  final String token;
  final String channelName;
  final int timer;
  final String user;

  const AudioCall({
    required this.token,
    required this.channelName,
    required this.timer,
    required this.user,
    Key? key,
  }) : super(key: key);

  @override
  State<AudioCall> createState() => _AudioCallState();
}

class _AudioCallState extends State<AudioCall> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _isMicEnabled = false;
  int _callDuration = 0;
  late Timer _callTimer;
  bool _disconnectCalled = false; // Flag to track if disconnect has been called
  bool _timerStarted = false; // Flag to track whether the timer has started

  @override
  void initState() {
    //Wakelock.enable();
    super.initState();
    initAgora();
    startCallTimer();
  }

  void disconnectBothUsers() {
    // Disconnect the call for both users
    disconnect();
    _remoteUid = null;

    // Stop the timer
    _timerStarted = false;
    _callTimer.cancel();
    _disconnectCalled = true;
    Navigator.of(context).pop();
  }

  void startCallTimer() {
    const duration = Duration(seconds: 1);
    _callTimer = Timer.periodic(duration, (Timer timer) {
      setState(() {
        _callDuration++;
      });

      // Check if the call duration exceeds a certain limit (in seconds)
      // Check if the remote user hasn't joined within 20 seconds
      if (_localUserJoined &&
          _remoteUid == null &&
          _callDuration >= 20 &&
          !_disconnectCalled) {
        disconnect();
        timer.cancel();
        _disconnectCalled = true;
      }
      if (_localUserJoined && _remoteUid != null && !_timerStarted) {
        // Both local and remote users have joined within 20 seconds
        _timerStarted = true;
        _callDuration = 0; // Reset call duration to 0 when both users have joined
      }

      // Check if the call duration has exceeded the specified limit
      if (_callDuration >= widget.timer * 60 && _remoteUid == 0) {
        // Automatically disconnect the call after 3 minutes (adjust as needed)
        disconnect();
        timer.cancel();
      }
    });
  }

  Future<void> initAgora() async {
    // retrieve permissions
    await [Permission.microphone].request();

    // create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          if (!_localUserJoined) {
            // Local user hasn't joined yet, deny access to remote users
            _engine.leaveChannel();
            Navigator.of(context).pop();
          } else {
            debugPrint("remote user $remoteUid joined");
            setState(() {
              _remoteUid = remoteUid;
            });
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          if (remoteUid == 0) {
            // Local user has disconnected
            disconnect();
          } else if (remoteUid == _remoteUid) {
            // Remote user has disconnected
            disconnect();
          }
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint(
              '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableAudio(); // Enable audio only
    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    //Wakelock.disable();
    _callTimer.cancel();
    super.dispose();

    _dispose();
    sendPostData();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  void disconnect() {
    _engine.leaveChannel();
    // Navigate back to the previous screen or perform other actions
    Navigator.of(context).pop();
  }

  void toggleMute() {
    _engine.muteLocalAudioStream(!_isMicEnabled);
  }

  void sendPostData() async {
    try {
      // Check if the user is the local user (user ID 0)
      if (_remoteUid != null && _remoteUid != 0) {
        final response = await http.post(
          Uri.parse('https://instamatchonline.com/useraudiocallstatus'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'user': widget.user, // Include local user information
            'duration': _callDuration,
            // Add other necessary data
          }),
        );

        if (response.statusCode == 200) {
          if (kDebugMode) {
            print('Post request successful callduration: $_callDuration');
          }
        } else {
          if (kDebugMode) {
            print(
              'Failed to send post request. Status code: ${response.statusCode}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending post request: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Color.fromRGBO(33, 37, 41, 1.0) // Set your desired color here
    ));
    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          Center(
            child: _remoteUserIcon(),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 150,
              child: Center(
                child: _localUserJoined
                    ? const Icon(
                  Icons.account_circle,
                  size: 100,
                  color: Colors.white,
                )
                    : const CircularProgressIndicator(),
              ),


            ),
          ),
          _toolbar(), // Add the toolbar widget
        ],
      ),
    );
  }

  Widget _remoteUserIcon() {
    if (_remoteUid != null) {
      return const Icon(
        Icons.account_circle,
        size: 200,
        color: Colors.white,
      );
    } else {
      return const Text(
        'Please wait for the Umeed member to join',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 16.0,
        ),
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              RawMaterialButton(
                onPressed: () {
                  setState(() {
                    _isMicEnabled = !_isMicEnabled; // Toggle the microphone state
                  });
                  toggleMute(); // Call your mute toggle function here if needed
                },
                shape: CircleBorder(),
                elevation: 2.0,
                fillColor: _isMicEnabled ? Colors.white : Colors.blueAccent,
                padding: const EdgeInsets.all(15.0),
                child: Icon(
                  _isMicEnabled ? Icons.mic : Icons.mic_off,
                  color: _isMicEnabled ? Colors.blueAccent : Colors.white,
                  size: 30.0,
                ),
              ),
              RawMaterialButton(
                onPressed: () {
                  disconnect(); // Call your disconnect function here if needed
                  //Navigator.pop(context); // Navigate back to the previous screen
                },
                shape: CircleBorder(),
                elevation: 2.0,
                fillColor: Colors.redAccent,
                padding: const EdgeInsets.all(15.0),
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 35.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Call Duration: $_callDuration seconds',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }
}
