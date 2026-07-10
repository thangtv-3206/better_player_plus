import 'package:better_player_plus/better_player_plus.dart';
import 'package:better_player_plus/src/configuration/better_player_controller_event.dart';
import 'package:better_player_plus/src/core/better_player_base.dart';
import 'package:better_player_plus/src/core/better_player_with_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// iOS-specific implementation of BetterPlayer widget.
/// Handles rotation based on MediaQuery screen orientation.
class BetterPlayerIOS extends BetterPlayerBase {
  const BetterPlayerIOS({Key? key, required super.controller}) : super(key: key);

  @override
  State<BetterPlayerIOS> createState() => _BetterPlayerIOSState();
}

class _BetterPlayerIOSState extends BetterPlayerBaseState<BetterPlayerIOS> {
  Orientation? _lastOrientation;

  @override
  void initializeRotationListener() {
    deviceOrientationSubscription =
        deviceOrientationStream.skip(1).listen((deviceOrientation) {
      final controller = widget.controller;
      if (!controller.isPlayerVisible || controller.isPipMode() == true) {
        SystemChrome.setPreferredOrientations(
            betterPlayerConfiguration.deviceOrientationsAfterFullScreen);
      } else {
        if ([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight].contains(deviceOrientation)) {
          SystemChrome.setPreferredOrientations([]);
        }
      }
    });
  }

  @override
  void onControllerEvent(BetterPlayerControllerEvent event) {
    switch (event) {
      case BetterPlayerControllerEvent.openFullscreen:
        onFullScreenChanged();
        break;
      case BetterPlayerControllerEvent.hideFullscreen:
        // iOS-specific: Reset orientation before hiding fullscreen
        SystemChrome.setPreferredOrientations(
            betterPlayerConfiguration.deviceOrientationsAfterFullScreen);
        onFullScreenChanged();
        break;
      default:
        setState(() {});
        break;
    }
  }

  @override
  Widget buildPlayer(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    if (orientation != _lastOrientation) {
      _lastOrientation = orientation;
      final controller = widget.controller;

      if (betterPlayerConfiguration.enterFullScreenWhenRotate == true &&
          controller.isPlayerVisible &&
          controller.isPipMode() == false) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!isFullScreenByRotate &&
              controller.controlsEnabled &&
              !controller.isFullScreen &&
              orientation == Orientation.landscape) {
            isFullScreenByRotate = true;
            controller.enterFullScreen();
          } else if (isFullScreenByRotate &&
              controller.isFullScreen &&
              orientation == Orientation.portrait) {
            controller.exitFullScreen();
          }
        });
      }
    }


    return VisibilityDetector(
      key: Key("${widget.controller.hashCode}_key"),
      onVisibilityChanged: (VisibilityInfo info) =>
          widget.controller.onPlayerVisibilityChanged(info.visibleFraction),
      child: BetterPlayerWithControls(
        controller: widget.controller,
      ),
    );
  }
}
