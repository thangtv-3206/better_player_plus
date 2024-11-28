import 'dart:io';

import 'package:better_player_example/constants.dart';
import 'package:better_player_example/pages/pip/live_video_controls.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PictureInPicturePage extends StatefulWidget {
  @override
  _PictureInPicturePageState createState() => _PictureInPicturePageState();
}

class _PictureInPicturePageState extends State<PictureInPicturePage>
    with WidgetsBindingObserver {
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
      controlsConfiguration: BetterPlayerControlsConfiguration(
        showControlsOnInitialize: false,
        controlBarHeight: 24,
        controlBarColor: Colors.black54,
        playerTheme: BetterPlayerTheme.custom,
        qualitiesIcon: Icons.settings,
        enableSubtitles: false,
        customControlsBuilder: (controller, onPlayerVisibilityChanged) {
          return LiveVideoControls(
            onClickOpenJyo: () {},
            onClickOpenChangeQuality: () {},
            onClickOpenChat: () {},
          );
        },
      ),
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration,
        betterPlayerDataSource: BetterPlayerDataSource.network(
          Constants.elephantDreamVideoUrl,
          liveStream: true,
        ));
    _betterPlayerController.setBetterPlayerGlobalKey(_betterPlayerKey);
    _betterPlayerController.addEventsListener(eventListener);
    super.initState();
  }

  Future<void> handlePipStatusEvent(BetterPlayerEventType eventType) async {
    switch (eventType) {
      case BetterPlayerEventType.enteringPip:
        if (Platform.isIOS) {
          _betterPlayerController.setControlsEnabled(false);
        }
      case BetterPlayerEventType.restorePip:
        if (Platform.isIOS) {
          _betterPlayerController.setControlsEnabled(true);
        }
      case BetterPlayerEventType.closePip:
        if (Platform.isIOS) {
          _betterPlayerController.pause();
          _betterPlayerController.setControlsEnabled(true);
        }
      // ignore: no_default_cases
      default:
    }
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
    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.play:
        if (Platform.isIOS && !_isPiPMode) {
          _betterPlayerController.setAutomaticPipMode(autoPip: true);
          setState(() {
            _shouldStartPIP = true;
          });
        }
        break;
      case BetterPlayerEventType.pause:
        if (Platform.isIOS && !_isPiPMode) {
          _betterPlayerController.setAutomaticPipMode(autoPip: false);
          setState(() {
            _shouldStartPIP = false;
          });
        }
      case BetterPlayerEventType.enteringPip:
      case BetterPlayerEventType.restorePip:
      case BetterPlayerEventType.closePip:
        handlePipStatusEvent(event.betterPlayerEventType);
      default:
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
          if (Platform.isIOS)
            ElevatedButton(
              child: Text('Auto PIP: ' + (_shouldStartPIP ? 'ON' : 'OFF')),
              onPressed: () async {
                setState(() {
                  _betterPlayerController.setAutomaticPipMode(
                      autoPip: _shouldStartPIP);
                });
              },
            ),
        ],
      ),
    );
  }
}
