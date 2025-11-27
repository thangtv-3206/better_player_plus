import 'dart:io';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:better_player_plus/src/core/better_player_android.dart';
import 'package:better_player_plus/src/core/better_player_ios.dart';
import 'package:flutter/material.dart';

/// Widget which uses provided controller to render video player.
class BetterPlayer extends StatelessWidget {
  const BetterPlayer({Key? key, required this.controller}) : super(key: key);

  factory BetterPlayer.network(
    String url, {
    BetterPlayerConfiguration? betterPlayerConfiguration,
  }) =>
      BetterPlayer(
        controller: BetterPlayerController(
          betterPlayerConfiguration ?? const BetterPlayerConfiguration(),
          betterPlayerDataSource:
              BetterPlayerDataSource(BetterPlayerDataSourceType.network, url),
        ),
      );

  factory BetterPlayer.file(
    String url, {
    BetterPlayerConfiguration? betterPlayerConfiguration,
  }) =>
      BetterPlayer(
        controller: BetterPlayerController(
          betterPlayerConfiguration ?? const BetterPlayerConfiguration(),
          betterPlayerDataSource:
              BetterPlayerDataSource(BetterPlayerDataSourceType.file, url),
        ),
      );

  final BetterPlayerController controller;

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return BetterPlayerAndroid(controller: controller);
    } else {
      return BetterPlayerIOS(controller: controller);
    }
  }
}

///Page route builder used in fullscreen mode.
typedef BetterPlayerRoutePageBuilder = Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    BetterPlayerControllerProvider controllerProvider);
