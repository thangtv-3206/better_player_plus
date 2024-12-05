import 'dart:io';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_in_app_pip/picture_in_picture.dart';
import 'package:flutter_in_app_pip/pip_params.dart';

const _pipWidth = 192.0;
const videoAspectRatio = 16 / 9;

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
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final maxPipWidth = MediaQuery.sizeOf(context).width - 30;
      PictureInPicture.updatePiPParams(
        pipParams: PiPParams(
          pipWindowHeight: _pipWidth / videoAspectRatio,
          pipWindowWidth: _pipWidth,
          bottomSpace: 64,
          resizable: true,
          minSize: const Size(_pipWidth, _pipWidth / videoAspectRatio),
          maxSize: Size(maxPipWidth, maxPipWidth / videoAspectRatio),
        ),
      );
    });
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      widget.betterPlayerController.resetToOriginPipContentSource();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: Colors.black,
              child: VideoPlayer(widget.betterPlayerController.videoPlayerController),
            ),
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
