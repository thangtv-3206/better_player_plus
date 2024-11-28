import 'dart:io';

import 'package:better_player_example/constants.dart';
import 'package:better_player_example/pages/pip/inapp_pip.dart';
import 'package:better_player_example/pages/pip/live_video_controls.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_in_app_pip/flutter_in_app_pip.dart';
import 'package:visibility_detector/visibility_detector.dart';

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
  late ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);
    PictureInPicture.updatePiPParams(
      pipParams: const PiPParams(
        pipWindowHeight: 108,
        pipWindowWidth: 192,
        bottomSpace: 64,
      ),
    );
    BetterPlayerConfiguration betterPlayerConfiguration = BetterPlayerConfiguration(
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
      playerVisibilityChangedBehavior: (controller, visibilityFraction) {
        final isShowing = visibilityFraction > 0;
        final isPlaying = controller.isPlaying() ?? false;
        final isPipMode = controller.isPipMode() ?? false;
        final isFullScreen = controller.isFullScreen;

        if (isPlaying && !isShowing && !PictureInPicture.isActive && !isPipMode && !isFullScreen) {
          PictureInPicture.startPiP(
            pipWidget: Builder(builder: (context) {
              return InAppPip(
                betterPlayerController: _betterPlayerController,
                onTap: () => _scrollController.jumpTo(0),
              );
            }),
          );
        }
      },
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _betterPlayerController.removeEventsListener(eventListener);
    _scrollController.dispose();
    if (PictureInPicture.isActive) {
      PictureInPicture.stopPiP();
    }
    _betterPlayerController.dispose(forceDispose: true);
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
        setState(() {
          _isPiPMode = true;
        });
      case BetterPlayerEventType.restorePip:
        setState(() {
          _isPiPMode = false;
        });
      case BetterPlayerEventType.closePip:
        if (Platform.isIOS) {
          _betterPlayerController.pause();
        }
        setState(() {
          _isPiPMode = false;
        });
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
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            VisibilityDetector(
              key: UniqueKey(),
              onVisibilityChanged: (info) {
                final isShowing = info.visibleFraction > 0;
                if (isShowing && PictureInPicture.isActive) {
                  PictureInPicture.stopPiP();
                  _betterPlayerController.setAutomaticPipMode(
                      autoPip: _betterPlayerController.isPlaying() ?? false);
                }
              },
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(
                  controller: _betterPlayerController,
                  key: _betterPlayerKey,
                ),
              ),
            ),
            ElevatedButton(
              child: Text("Show PiP"),
              onPressed: () async {
                final hasPipPermission = Platform.isIOS ||
                    (Platform.isAndroid && await _betterPlayerController.hasPipPermission());
                if (hasPipPermission) {
                  _betterPlayerController.enablePictureInPicture(_betterPlayerKey);
                } else {
                  if (Platform.isAndroid) {
                    _betterPlayerController.openPipPermissionSettings();
                  }
                }
              },
            ),
            ElevatedButton(
              child: Text("Disable PiP"),
              onPressed: () {
                _betterPlayerController.disablePictureInPicture();
              },
            ),
            ElevatedButton(
              child: Text('Auto PIP: ' + (_shouldStartPIP ? 'ON' : 'OFF')),
              onPressed: () {
                setState(() {
                  _betterPlayerController.setAutomaticPipMode(autoPip: _shouldStartPIP);
                });
              },
            ),
            Container(height: 500, color: Colors.amber),
            Container(height: 500, color: Colors.red),
          ],
        ),
      ),
    );
  }
}
