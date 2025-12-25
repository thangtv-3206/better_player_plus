import 'package:better_player_plus/better_player_plus.dart';
import 'package:better_player_plus/src/core/better_player_base.dart';
import 'package:better_player_plus/src/core/better_player_with_controls.dart';
import 'package:better_player_plus/src/video_player/video_player_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Android-specific implementation of BetterPlayer widget.
/// Handles rotation with auto-rotate system setting check.
class BetterPlayerAndroid extends BetterPlayerBase {
  const BetterPlayerAndroid({Key? key, required super.controller}) : super(key: key);

  @override
  State<BetterPlayerAndroid> createState() => _BetterPlayerAndroidState();
}

class _BetterPlayerAndroidState extends BetterPlayerBaseState<BetterPlayerAndroid> {
  @override
  void initializeRotationListener() {
    if (betterPlayerConfiguration.enterFullScreenWhenRotate == true) {
      deviceOrientationSubscription = deviceOrientationStream.skip(1).listen((deviceOrientation) async {
        final controller = widget.controller;
        if (!controller.isPlayerVisible || controller.isPipMode() == true) {
          return;
        }
        final isDeviceEnableRotate = (await VideoPlayerPlatform.instance.isAutoRotateEnabled() ?? false);
        final isLandscape = [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight].contains(deviceOrientation);

        if (!isFullScreenByRotate &&
            controller.controlsEnabled &&
            !controller.isFullScreen &&
            isLandscape &&
            isDeviceEnableRotate) {
          isFullScreenByRotate = true;
          controller.enterFullScreen();
        } else if (isFullScreenByRotate &&
            controller.isFullScreen &&
            deviceOrientation == DeviceOrientation.portraitUp) {
          lastLandscapeOrientation = null;
          SystemChrome.setPreferredOrientations(betterPlayerConfiguration.deviceOrientationsAfterFullScreen);
          controller.exitFullScreen();
        } else if (isDeviceEnableRotate && isLandscape && controller.isFullScreen && isFullScreenByRotate && controller.controlsEnabled) {
          // Handle the case where the device is rotated 360 degrees without triggering the 'Enter Fullscreen' toggle
          SystemChrome.setPreferredOrientations([deviceOrientation]);
        }
      });
    }
  }

  @override
  Widget buildPlayer(BuildContext context) {
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
