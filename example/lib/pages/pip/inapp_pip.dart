import 'dart:io';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_in_app_pip/picture_in_picture.dart';

class InAppPip extends StatefulWidget {
  const InAppPip({
    super.key,
    required this.betterPlayerController,
    required this.onTap,
  });

  final BetterPlayerController betterPlayerController;
  final void Function() onTap;

  @override
  State<InAppPip> createState() => _InAppPipState();
}

class _InAppPipState extends State<InAppPip> {
  @override
  void initState() {
    if (Platform.isIOS) {
      widget.betterPlayerController.setAutomaticPipMode(autoPip: true);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          SizedBox(
            width: 192,
            height: 108,
            child: VideoPlayer(widget.betterPlayerController.videoPlayerController),
          ),
          ColoredBox(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () {
                if (PictureInPicture.isActive) {
                  PictureInPicture.stopPiP();
                }
              },
              iconSize: 20,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
