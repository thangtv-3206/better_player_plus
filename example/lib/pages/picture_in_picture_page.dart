import 'dart:io';

import 'package:better_player_example/constants.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PictureInPicturePage extends StatefulWidget {
  @override
  _PictureInPicturePageState createState() => _PictureInPicturePageState();
}

class _PictureInPicturePageState extends State<PictureInPicturePage> with WidgetsBindingObserver {
  late BetterPlayerController _betterPlayerController;
  GlobalKey _betterPlayerKey = GlobalKey();
  late bool _shouldStartPIP = false;
  late bool _isPiPMode = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      autoPlay: true,
      autoDispose: false,
      allowedScreenSleep: false,
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitDown,
        DeviceOrientation.portraitUp
      ],
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration,
        betterPlayerDataSource: BetterPlayerDataSource.network(
          Constants.elephantDreamVideoUrl,
          liveStream: true,
        ));
    _betterPlayerController.setBetterPlayerGlobalKey(_betterPlayerKey);
    _betterPlayerController.setVolume(0);
    _betterPlayerController.addEventsListener(eventListener);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _betterPlayerController.removeEventsListener(eventListener);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Platform.isIOS) {
      if (_betterPlayerController.isPipMode() ?? false) {
        _betterPlayerController.disablePictureInPicture();
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  void eventListener(BetterPlayerEvent event) {
    debugPrint("FlutterDebug: ${event.betterPlayerEventType}");
    if (event.betterPlayerEventType == BetterPlayerEventType.play) {
      if (Platform.isAndroid || !_isPiPMode) {
        _betterPlayerController.setAutomaticPipMode(autoPip: true);
        setState(() {
          _shouldStartPIP = true;
        });
      }
    } else if (event.betterPlayerEventType == BetterPlayerEventType.pause) {
      if (Platform.isAndroid || !_isPiPMode) {
        _betterPlayerController.setAutomaticPipMode(autoPip: false);
        setState(() {
          _shouldStartPIP = false;
        });
      }
    } else if (event.betterPlayerEventType == BetterPlayerEventType.enteringPip) {
      if (!_betterPlayerController.isFullScreen) {
        _betterPlayerController.enterFullScreen();
      }
      _betterPlayerController.setControlsEnabled(false);
      setState(() {
        _isPiPMode = true;
      });
    } else if (event.betterPlayerEventType == BetterPlayerEventType.restorePip) {
      _betterPlayerController.exitFullScreen();
      _betterPlayerController.setControlsEnabled(true);
      setState(() {
        _isPiPMode = false;
      });
    } else if (event.betterPlayerEventType == BetterPlayerEventType.closePip) {
      _betterPlayerController.exitFullScreen();
      _betterPlayerController.setControlsEnabled(true);
      _betterPlayerController.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          title: Text("Picture in Picture player"),
        ),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(
              controller: _betterPlayerController,
              key: _betterPlayerKey,
            ),
          ),
          ElevatedButton(
            child: Text("Show PiP"),
            onPressed: () async {
              final hasPipPermission = Platform.isIOS ||
                  (Platform.isAndroid &&
                      await _betterPlayerController.hasPipPermission());
              if (hasPipPermission) {
                _betterPlayerController
                    .enablePictureInPicture(_betterPlayerKey);
              } else {
                if (Platform.isAndroid) {
                  _betterPlayerController.openPipPermissionSettings();
                }
              }
            },
          ),
          ElevatedButton(
            child: Text("Disable PiP"),
            onPressed: () async {
              _betterPlayerController.disablePictureInPicture();
            },
          ),
          ElevatedButton(
            child: Text('Auto PIP: ' + (_shouldStartPIP ? 'ON' : 'OFF')),
            onPressed: () async {
              setState(() {
                if (Platform.isAndroid) {
                  _shouldStartPIP = !_shouldStartPIP;
                }
                _betterPlayerController.setAutomaticPipMode(autoPip: _shouldStartPIP);
              });
            },
          ),
        ],
      ),
    );
  }
}
