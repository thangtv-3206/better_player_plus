import 'dart:async';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:better_player_plus/src/configuration/better_player_controller_event.dart';
import 'package:better_player_plus/src/core/better_player_utils.dart';
import 'package:better_player_plus/src/core/better_player_with_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

///Widget which uses provided controller to render video player.
class BetterPlayer extends StatefulWidget {
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
  _BetterPlayerState createState() {
    return _BetterPlayerState();
  }
}

class _BetterPlayerState extends State<BetterPlayer> {
  BetterPlayerConfiguration get _betterPlayerConfiguration =>
      widget.controller.betterPlayerConfiguration;

  bool _isFullScreen = false;

  ///State of navigator on widget created
  late NavigatorState? _navigatorState;

  StreamSubscription<DeviceOrientation>? _deviceOrientationSubscription;

  bool _isFullScreenByRotate = false;

  ///Flag which determines if widget has initialized
  bool _initialized = false;

  ///Subscription for controller events
  StreamSubscription? _controllerEventSubscription;

  @override
  void initState() {
    super.initState();
    if (_betterPlayerConfiguration.enterFullScreenWhenRotate == true) {
      _deviceOrientationSubscription = deviceOrientationStream.skip(1).listen((deviceOrientation) {
        var controller = widget.controller;
        if (!controller.isPlayerVisible) return;
        if (!_isFullScreenByRotate &&
            controller.controlsEnabled &&
            !controller.isFullScreen &&
            [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight].contains(deviceOrientation)) {
          _isFullScreenByRotate = true;
          controller.enterFullScreen();
        } else if (_isFullScreenByRotate &&
            controller.isFullScreen &&
            deviceOrientation == DeviceOrientation.portraitUp) {
          SystemChrome.setPreferredOrientations(_betterPlayerConfiguration.deviceOrientationsAfterFullScreen);
          controller.exitFullScreen();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    if (!_initialized) {
      final navigator = Navigator.maybeOf(context);
      setState(() {
        _navigatorState = navigator;
      });
      _setup();
      _initialized = true;
    }
    super.didChangeDependencies();
  }

  Future<void> _setup() async {
    _controllerEventSubscription =
        widget.controller.controllerEventStream.listen(onControllerEvent);

    //Default locale
    var locale = const Locale("en", "US");
    try {
      if (mounted) {
        final contextLocale = Localizations.localeOf(context);
        locale = contextLocale;
      }
    } on Exception catch (exception) {
      BetterPlayerUtils.log(exception.toString());
    }
    widget.controller.setupTranslations(locale);
  }

  @override
  void dispose() {
    ///If somehow BetterPlayer widget has been disposed from widget tree and
    ///full screen is on, then full screen route must be pop and return to normal
    ///state.
    if (_isFullScreen) {
      WakelockPlus.disable();
      _navigatorState?.maybePop();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: _betterPlayerConfiguration.systemOverlaysAfterFullScreen);
      SystemChrome.setPreferredOrientations(
          _betterPlayerConfiguration.deviceOrientationsAfterFullScreen);
    }

    _controllerEventSubscription?.cancel();
    widget.controller.dispose();
    VisibilityDetectorController.instance
        .forget(Key("${widget.controller.hashCode}_key"));
    _deviceOrientationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(BetterPlayer oldWidget) {
    if (oldWidget.controller != widget.controller) {
      _controllerEventSubscription?.cancel();
      _controllerEventSubscription =
          widget.controller.controllerEventStream.listen(onControllerEvent);
    }
    super.didUpdateWidget(oldWidget);
  }

  void onControllerEvent(BetterPlayerControllerEvent event) {
    switch (event) {
      case BetterPlayerControllerEvent.openFullscreen:
        onFullScreenChanged();
        break;
      case BetterPlayerControllerEvent.hideFullscreen:
        onFullScreenChanged();
        break;
      default:
        setState(() {});
        break;
    }
  }

  // ignore: avoid_void_async
  Future<void> onFullScreenChanged() async {
    final controller = widget.controller;
    if (controller.isFullScreen && !_isFullScreen) {
      _isFullScreen = true;
      controller
          .postEvent(BetterPlayerEvent(BetterPlayerEventType.openFullscreen));
      await _pushFullScreenWidget(context);
    } else if (_isFullScreen) {
      Navigator.maybeOf(context, rootNavigator: true)?.pop();
      _isFullScreen = false;
      _isFullScreenByRotate = false;
      controller
          .postEvent(BetterPlayerEvent(BetterPlayerEventType.hideFullscreen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BetterPlayerControllerProvider(
      controller: widget.controller,
      child: _buildPlayer(),
    );
  }

  Widget _buildFullScreenVideo(
      BuildContext context, BetterPlayerControllerProvider controllerProvider) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Center(
        child: controllerProvider,
      ),
    );
  }

  Widget _fullScreenRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final controllerProvider = BetterPlayerControllerProvider(
        controller: widget.controller, child: _buildPlayer());

    final routePageBuilder = _betterPlayerConfiguration.routePageBuilder;
    if (routePageBuilder == null) {
      return _buildFullScreenVideo(context, controllerProvider);
    }

    return routePageBuilder(
        context, animation, secondaryAnimation, controllerProvider);
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final TransitionRoute<void> route = PageRouteBuilder<void>(
      settings: const RouteSettings(),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([]);
    if (!_betterPlayerConfiguration.allowedScreenSleep) {
      WakelockPlus.enable();
    }

    await Navigator.of(context, rootNavigator: true).push(route);
    _isFullScreen = false;
    widget.controller.exitFullScreen();

    // The wakelock plugins checks whether it needs to perform an action internally,
    // so we do not need to check Wakelock.isEnabled.
    WakelockPlus.disable();

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: _betterPlayerConfiguration.systemOverlaysAfterFullScreen);
    await SystemChrome.setPreferredOrientations(
        _betterPlayerConfiguration.deviceOrientationsAfterFullScreen);
  }

  Widget _buildPlayer() {
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

///Page route builder used in fullscreen mode.
typedef BetterPlayerRoutePageBuilder = Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    BetterPlayerControllerProvider controllerProvider);
