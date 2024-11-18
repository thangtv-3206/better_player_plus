import 'dart:io';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:better_player_example/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PictureInPicturePage extends StatefulWidget {
  @override
  _PictureInPicturePageState createState() => _PictureInPicturePageState();
}

class _PictureInPicturePageState extends State<PictureInPicturePage> {
  late BetterPlayerController _betterPlayerController;
  GlobalKey _betterPlayerKey = GlobalKey();
  late bool _shouldStartPIP = false;
  late bool _isPiPMode = false;

  @override
  void initState() {
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      deviceOrientationsOnFullScreen: DeviceOrientation.values,
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitDown,
        DeviceOrientation.portraitUp
      ],
    );
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      Constants.elephantDreamVideoUrl,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    _betterPlayerController.setBetterPlayerGlobalKey(_betterPlayerKey);
    _betterPlayerController.addEventsListener(eventListener);
    super.initState();
  }

  @override
  void dispose() {
    _betterPlayerController.removeEventsListener(eventListener);
    super.dispose();
  }

  void eventListener(BetterPlayerEvent event) {
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
      _betterPlayerController.setControlsEnabled(false);
      setState(() {
        _isPiPMode = true;
      });
    } else if (event.betterPlayerEventType == BetterPlayerEventType.exitingPip) {
      _betterPlayerController.setControlsEnabled(true);
      setState(() {
        _isPiPMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid && _isPiPMode) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: BetterPlayer(
          controller: _betterPlayerController,
          key: _betterPlayerKey,
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Picture in Picture player"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Example which shows how to use PiP.",
              style: TextStyle(fontSize: 16),
            ),
          ),
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
