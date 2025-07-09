import 'dart:async';
import 'dart:io';

import 'package:better_player_example/pages/pip/animated_play_pause.dart';
import 'package:better_player_example/size_config.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:better_player_plus/src/video_player/video_player.dart';
import 'package:flutter/material.dart';

class LiveVideoControls extends StatefulWidget {
  const LiveVideoControls({
    super.key,
    required this.onClickOpenJyo,
    required this.onClickOpenChangeQuality,
    required this.onClickOpenChat,
    this.onControlsVisibilityChanged,
  });

  final VoidCallback onClickOpenJyo;
  final VoidCallback onClickOpenChangeQuality;
  final VoidCallback onClickOpenChat;
  final void Function(bool visible)? onControlsVisibilityChanged;

  @override
  State<StatefulWidget> createState() {
    return _LiveVideoControlsState();
  }
}

class _LiveVideoControlsState
    extends BetterPlayerControlsState<LiveVideoControls> {
  late final bool isFullScreen;
  VideoPlayerValue? _latestValue;
  double? _latestVolume;
  Timer? _hideTimer;
  Timer? _initTimer;
  Timer? _showAfterExpandCollapseTimer;
  bool _wasLoading = false;
  VideoPlayerController? _controller;
  BetterPlayerController? _betterPlayerController;
  Future<bool>? isPictureInPictureSupportedFuture;
  StreamSubscription<bool>? _controlsVisibilityStreamSubscription;

  BetterPlayerControlsConfiguration get _controlsConfiguration =>
      _betterPlayerController!.betterPlayerControlsConfiguration;

  @override
  VideoPlayerValue? get latestValue => _latestValue;

  @override
  BetterPlayerController? get betterPlayerController => _betterPlayerController;

  @override
  BetterPlayerControlsConfiguration get betterPlayerControlsConfiguration =>
      _controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    return buildLTRDirectionality(_buildMainWidget());
  }

  Widget _buildMainWidget() {
    _wasLoading = _controller?.isLoading() ?? false;

    return GestureDetector(
      onTap: () {
        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onTap?.call();
        }
        controlsNotVisible
            ? cancelAndRestartTimer()
            : changePlayerControlsNotVisible(true);
      },
      onDoubleTap: () {
        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onDoubleTap?.call();
        }
        cancelAndRestartTimer();
      },
      onLongPress: () {
        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onLongPress?.call();
        }
      },
      child: AbsorbPointer(
        absorbing: controlsNotVisible,
        child: !_betterPlayerController!.controlsEnabled
            ? const SizedBox()
            : Stack(
                fit: StackFit.expand,
                children: [
                  if (_controller?.value.hasError ?? false)
                    _buildErrorWidget()
                  else if (_wasLoading)
                    ColoredBox(
                        color: _controlsConfiguration.controlBarColor,
                        child: Center(child: _buildLoadingWidget()))
                  else
                    _buildHitArea(),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildTopBar(),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomBar(),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    isFullScreen = Navigator.maybeOf(context) ==
        Navigator.maybeOf(context, rootNavigator: true);
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    _controller?.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
    _controlsVisibilityStreamSubscription?.cancel();
  }

  @override
  void didChangeDependencies() {
    final oldController = _betterPlayerController;
    _betterPlayerController = BetterPlayerController.of(context);
    _controller = _betterPlayerController!.videoPlayerController;
    _latestValue = _controller!.value;

    if (oldController != _betterPlayerController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Widget _buildErrorWidget() {
    final errorBuilder =
        _betterPlayerController!.betterPlayerConfiguration.errorBuilder;
    if (errorBuilder != null) {
      return errorBuilder(
          context,
          _betterPlayerController!
              .videoPlayerController!.value.errorDescription);
    } else {
      final textStyle = TextStyle(color: _controlsConfiguration.textColor);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              color: _controlsConfiguration.iconsColor,
              size: 42,
            ),
            Text(
              _betterPlayerController!.translations.generalDefaultError,
              style: textStyle,
            ),
            if (_controlsConfiguration.enableRetry)
              TextButton(
                onPressed: () {
                  _betterPlayerController!.retryDataSource();
                },
                child: Text(
                  _betterPlayerController!.translations.generalRetry,
                  style: textStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              )
          ],
        ),
      );
    }
  }

  Widget _buildTopBar() {
    return AnimatedOpacity(
      opacity: controlsNotVisible ? 0.0 : 1.0,
      duration: _controlsConfiguration.controlsHideTime,
      onEnd: _onPlayerHide,
      child: isFullScreen
          ? Row(
              children: [
                _buildMaterialClickableWidget(
                  onTap: _betterPlayerController!.toggleFullScreen,
                  child: Container(
                    margin: MediaQuery.orientationOf(context) ==
                            Orientation.portrait
                        ? EdgeInsets.only(
                            top: Scaffold.maybeOf(context)?.appBarMaxHeight ??
                                kToolbarHeight)
                        : null,
                    padding: const EdgeInsets.all(16.0),
                    child: Icon(
                      Icons.close,
                      color: _controlsConfiguration.iconsColor,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_controlsConfiguration.enablePip)
                  _buildPipButtonWrapperWidget(
                      controlsNotVisible, _onPlayerHide)
                else
                  const SizedBox(),
              ],
            ),
    );
  }

  Widget _buildPipButton() {
    return Visibility(
      visible: !(_controller?.value.hasError ?? false),
      child: _buildMaterialClickableWidget(
        onTap: () async {
          final hasPipPermission = Platform.isIOS ||
              (Platform.isAndroid &&
                  await betterPlayerController!.hasPipPermission());
          if (hasPipPermission) {
            changePlayerControlsNotVisible(true);
            if (!_controller!.value.isPlaying) {
              _betterPlayerController!.play();
            }
            betterPlayerController!.enablePictureInPicture(
                betterPlayerController!.betterPlayerGlobalKey!);
          } else {
            if (Platform.isAndroid) {
              await betterPlayerController!.openPipPermissionSettings();
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Icon(
            betterPlayerControlsConfiguration.pipMenuIcon,
            color: betterPlayerControlsConfiguration.iconsColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPipButtonWrapperWidget(
      bool hideStuff, void Function() onPlayerHide) {
    return FutureBuilder<bool>(
      future: isPictureInPictureSupportedFuture,
      builder: (context, snapshot) {
        final bool isPipSupported = snapshot.data ?? false;
        if (isPipSupported &&
            _betterPlayerController!.betterPlayerGlobalKey != null) {
          return AnimatedOpacity(
            opacity: hideStuff ? 0.0 : 1.0,
            duration: betterPlayerControlsConfiguration.controlsHideTime,
            onEnd: onPlayerHide,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildPipButton(),
              ],
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _buildBottomBar() {
    return AnimatedOpacity(
      opacity: controlsNotVisible ? 0.0 : 1.0,
      duration: _controlsConfiguration.controlsHideTime,
      onEnd: _onPlayerHide,
      child: Container(
        height: _controlsConfiguration.controlBarHeight + 20.0,
        margin: isFullScreen ? const EdgeInsets.only(bottom: 10.0) : null,
        child: isFullScreen
            ? Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildMuteButton(_controller),
                    _buildExpandButton(),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    flex: 75,
                    child: Row(
                      children: [
                        _buildMaterialClickableWidget(
                          onTap: () {
                            cancelAndRestartTimer();
                            widget.onClickOpenJyo.call();
                          },
                          child: Row(
                            children: [
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 4),
                                  margin: const EdgeInsets.only(right: 5),
                                  decoration: BoxDecoration(
                                      color: Color(0xFFE03D3D),
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    'LIVE',
                                    style: TextStyle(
                                        color: _controlsConfiguration.textColor,
                                        fontSize: FontSize.size_14,
                                        fontWeight: FontConfig.fontWeightBold),
                                  )),
                              Container(
                                constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.sizeOf(context).width - 260),
                                child: Text(
                                  'jyo',
                                  maxLines: 1,
                                  style: TextStyle(
                                      color: _controlsConfiguration.textColor,
                                      fontSize: FontSize.size_14,
                                      fontWeight: FontConfig.fontWeightBold),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 25,
                                color: _controlsConfiguration.iconsColor,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (_controlsConfiguration.enableMute)
                          _buildMuteButton(_controller)
                        else
                          const SizedBox(),
                        _buildMaterialClickableWidget(
                          onTap: () {
                            cancelAndRestartTimer();
                            widget.onClickOpenChangeQuality.call();
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Icon(
                              _controlsConfiguration.qualitiesIcon,
                              color: _controlsConfiguration.iconsColor,
                            ),
                          ),
                        ),
                        _buildMaterialClickableWidget(
                          onTap: () {
                            cancelAndRestartTimer();
                            widget.onClickOpenChat.call();
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Icon(
                              Icons.message,
                              color: _controlsConfiguration.iconsColor,
                            ),
                          ),
                        ),
                        if (_controlsConfiguration.enableFullscreen)
                          _buildExpandButton()
                        else
                          const SizedBox(),
                      ],
                    ),
                  ),
                  const SizedBox()
                ],
              ),
      ),
    );
  }

  Widget _buildExpandButton() {
    return _buildMaterialClickableWidget(
      onTap: betterPlayerController!.toggleFullScreen,
      child: AnimatedOpacity(
        opacity: controlsNotVisible ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        child: Container(
          height: _controlsConfiguration.controlBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Center(
            child: Icon(
              isFullScreen
                  ? _controlsConfiguration.fullscreenDisableIcon
                  : _controlsConfiguration.fullscreenEnableIcon,
              color: _controlsConfiguration.iconsColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHitArea() {
    return AnimatedOpacity(
      opacity: controlsNotVisible ? 0.0 : 1.0,
      duration: _controlsConfiguration.controlsHideTime,
      child: Container(
        alignment: Alignment.center,
        color: _controlsConfiguration.controlBarColor,
        child: Material(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(60),
          ),
          clipBehavior: Clip.hardEdge,
          color: Colors.transparent,
          child: IconButton(
            iconSize: 40,
            padding: const EdgeInsets.all(12.0),
            icon: AnimatedPlayPause(
              color: _controlsConfiguration.iconsColor,
              playing: _controller!.value.isPlaying,
            ),
            onPressed: _onPlayPause,
          ),
        ),
      ),
    );
  }

  Widget _buildMuteButton(
    VideoPlayerController? controller,
  ) {
    return _buildMaterialClickableWidget(
      onTap: () {
        cancelAndRestartTimer();
        if (controller.value.volume == 0) {
          _betterPlayerController!.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          _betterPlayerController!.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: controlsNotVisible ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        child: ClipRect(
          child: Container(
            height: _controlsConfiguration.controlBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              (controller!.value.volume > 0)
                  ? _controlsConfiguration.muteIcon
                  : _controlsConfiguration.unMuteIcon,
              color: _controlsConfiguration.iconsColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialClickableWidget({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return InkWell(
      onTap: onTap,
      child: child,
    );
  }

  @override
  void cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    changePlayerControlsNotVisible(false);
  }

  Future<void> _initialize() async {
    isPictureInPictureSupportedFuture =
        betterPlayerController!.isPictureInPictureSupported();
    _controller!.addListener(_updateState);

    _updateState();

    if ((_controller!.value.isPlaying) ||
        _betterPlayerController!.betterPlayerConfiguration.autoPlay) {
      _startHideTimer();
    }

    if (_controlsConfiguration.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        changePlayerControlsNotVisible(false);
      });
    }

    _controlsVisibilityStreamSubscription =
        _betterPlayerController!.controlsVisibilityStream.listen((state) {
      changePlayerControlsNotVisible(!state);
      if (!controlsNotVisible) {
        cancelAndRestartTimer();
      }
    });
  }

  void _onPlayPause() {
    if (_controller!.value.isPlaying) {
      changePlayerControlsNotVisible(false);
      _hideTimer?.cancel();
      _betterPlayerController!.pause();
    } else if (_controller!.value.initialized) {
      _betterPlayerController!.play();
      cancelAndRestartTimer();
    }
  }

  void _startHideTimer() {
    if (_betterPlayerController!.controlsAlwaysVisible) {
      return;
    }
    _hideTimer = Timer(const Duration(milliseconds: 3000), () {
      changePlayerControlsNotVisible(true);
    });
  }

  void _updateState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (!controlsNotVisible ||
            isVideoFinished(_controller!.value) ||
            _wasLoading ||
            _controller!.isLoading()) {
          setState(() {
            _latestValue = _controller!.value;
            if (isVideoFinished(_controller!.value) &&
                _betterPlayerController?.isLiveStream() == false) {
              changePlayerControlsNotVisible(false);
            }
          });
        }
      }
    });
  }

  void _onPlayerHide() {
    _betterPlayerController!.toggleControlsVisibility(!controlsNotVisible);
    widget.onControlsVisibilityChanged?.call(!controlsNotVisible);
  }

  Widget? _buildLoadingWidget() {
    if (_controlsConfiguration.loadingWidget != null) {
      return ColoredBox(
        color: _controlsConfiguration.controlBarColor,
        child: _controlsConfiguration.loadingWidget,
      );
    }

    return CircularProgressIndicator(
      valueColor:
          AlwaysStoppedAnimation<Color>(_controlsConfiguration.loadingColor),
    );
  }
}
