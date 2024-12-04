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
  final key = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.betterPlayerController.setBetterPlayerGlobalKey(key);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // delay a bit to make sure pip is rendered
      Future.delayed(const Duration(milliseconds: 250), () {
        widget.betterPlayerController.setBeforePipSourceRectHint(key);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: VideoPlayer(key: key, widget.betterPlayerController.videoPlayerController),
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
