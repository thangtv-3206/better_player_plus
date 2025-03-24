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

class _PictureInPicturePageState extends State<PictureInPicturePage> with WidgetsBindingObserver {
  late BetterPlayerController _betterPlayerController;
  GlobalKey _betterPlayerKey = GlobalKey();
  late ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);
    BetterPlayerConfiguration betterPlayerConfiguration = BetterPlayerConfiguration(
      enablePIP: true,
      enterFullScreenWhenRotate: true,
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      autoPlay: true,
      autoDispose: false,
      allowedScreenSleep: false,
      deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp],
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
        final isBuffering = controller.isBuffering() ?? false;
        final isVideoInitialized = controller.isVideoInitialized() ?? false;
        final isFullScreen = controller.isFullScreen;

        if ((isPlaying || (isBuffering && !isVideoInitialized)) &&
            !isShowing &&
            !PictureInPicture.isActive &&
            !isPipMode &&
            !isFullScreen) {
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
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setBetterPlayerGlobalKey(_betterPlayerKey);
    _betterPlayerController.addEventsListener(eventListener);
    _betterPlayerController.setupDataSource(
      BetterPlayerDataSource.network(
        Constants.hlsPlaylistUrl,
        liveStream: true,
        videoFormat: BetterPlayerVideoFormat.hls,
      ),
      // betterPlayerAsmsTrackFuture: Future.value(BetterPlayerAsmsTrack('', 422, 180, 258157, 0, '', '')),
    );
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
    super.didChangeAppLifecycleState(state);
  }

  void eventListener(BetterPlayerEvent event) {
    if (event.betterPlayerEventType != BetterPlayerEventType.progress &&
        event.betterPlayerEventType != BetterPlayerEventType.bufferingUpdate &&
        event.betterPlayerEventType != BetterPlayerEventType.controlsHiddenStart &&
        event.betterPlayerEventType != BetterPlayerEventType.controlsHiddenEnd &&
        event.betterPlayerEventType != BetterPlayerEventType.bufferingStart &&
        event.betterPlayerEventType != BetterPlayerEventType.bufferingEnd &&
        event.betterPlayerEventType != BetterPlayerEventType.controlsVisible) {
      debugPrint("FlutterDebug: ${event.betterPlayerEventType}");
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
                final hasPipPermission =
                    Platform.isIOS || (Platform.isAndroid && await _betterPlayerController.hasPipPermission());
                if (hasPipPermission) {
                  if (_betterPlayerController.isPlaying() == false) {
                    await _betterPlayerController.play();
                  }
                  _betterPlayerController.enablePictureInPicture(_betterPlayerController.betterPlayerGlobalKey!);
                } else {
                  if (Platform.isAndroid) {
                    _betterPlayerController.openPipPermissionSettings();
                  }
                }
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
