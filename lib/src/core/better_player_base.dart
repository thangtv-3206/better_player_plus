import 'dart:async';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:better_player_plus/src/configuration/better_player_controller_event.dart';
import 'package:better_player_plus/src/core/better_player_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Base class for platform-specific BetterPlayer implementations.
/// Contains common functionality shared between Android and iOS.
abstract class BetterPlayerBase extends StatefulWidget {
  const BetterPlayerBase({Key? key, required this.controller}) : super(key: key);

  final BetterPlayerController controller;
}

abstract class BetterPlayerBaseState<T extends BetterPlayerBase> extends State<T> {
  BetterPlayerConfiguration get betterPlayerConfiguration =>
      widget.controller.betterPlayerConfiguration;

  bool isFullScreen = false;

  late NavigatorState? navigatorState;

  StreamSubscription<DeviceOrientation>? deviceOrientationSubscription;

  bool isFullScreenByRotate = false;

  bool initialized = false;

  StreamSubscription? controllerEventSubscription;

  @protected
  void initializeRotationListener();

  @override
  void initState() {
    super.initState();
    initializeRotationListener();
  }

  @override
  void didChangeDependencies() {
    if (!initialized) {
      final navigator = Navigator.maybeOf(context);
      setState(() {
        navigatorState = navigator;
      });
      setup();
      initialized = true;
    }
    super.didChangeDependencies();
  }

  @protected
  Future<void> setup() async {
    controllerEventSubscription =
        widget.controller.controllerEventStream.listen(onControllerEvent);

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
    /// If somehow BetterPlayer widget has been disposed from widget tree and
    /// full screen is on, then full screen route must be pop and return to normal state.
    if (isFullScreen) {
      navigatorState?.maybePop();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: betterPlayerConfiguration.systemOverlaysAfterFullScreen);
      SystemChrome.setPreferredOrientations(
          betterPlayerConfiguration.deviceOrientationsAfterFullScreen);
    }

    controllerEventSubscription?.cancel();
    widget.controller.dispose();
    VisibilityDetectorController.instance
        .forget(Key("${widget.controller.hashCode}_key"));
    deviceOrientationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    if (oldWidget.controller != widget.controller) {
      controllerEventSubscription?.cancel();
      controllerEventSubscription =
          widget.controller.controllerEventStream.listen(onControllerEvent);
    }
    super.didUpdateWidget(oldWidget);
  }

  @protected
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

  @protected
  Future<void> onFullScreenChanged() async {
    final controller = widget.controller;
    if (controller.isFullScreen && !isFullScreen) {
      isFullScreen = true;
      controller
          .postEvent(BetterPlayerEvent(BetterPlayerEventType.openFullscreen));
      await pushFullScreenWidget(context);
    } else if (isFullScreen) {
      Navigator.maybeOf(context, rootNavigator: true)?.pop();
      isFullScreen = false;
      isFullScreenByRotate = false;
      controller
          .postEvent(BetterPlayerEvent(BetterPlayerEventType.hideFullscreen));
    }
  }

  @protected
  Widget buildFullScreenVideo(
      BuildContext context, BetterPlayerControllerProvider controllerProvider) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Center(
        child: controllerProvider,
      ),
    );
  }

  @protected
  Widget fullScreenRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final controllerProvider = BetterPlayerControllerProvider(
        controller: widget.controller, child: buildPlayer(context));

    final routePageBuilder = betterPlayerConfiguration.routePageBuilder;
    if (routePageBuilder == null) {
      return buildFullScreenVideo(context, controllerProvider);
    }

    return routePageBuilder(
        context, animation, secondaryAnimation, controllerProvider);
  }

  @protected
  Future<dynamic> pushFullScreenWidget(BuildContext context) async {
    final TransitionRoute<void> route = PageRouteBuilder<void>(
      settings: const RouteSettings(),
      pageBuilder: fullScreenRoutePageBuilder,
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([]);

    await Navigator.of(context, rootNavigator: true).push(route);
    isFullScreen = false;
    widget.controller.exitFullScreen();

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: betterPlayerConfiguration.systemOverlaysAfterFullScreen);
    await SystemChrome.setPreferredOrientations(
        betterPlayerConfiguration.deviceOrientationsAfterFullScreen);
  }

  @protected
  Widget buildPlayer(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return BetterPlayerControllerProvider(
      controller: widget.controller,
      child: buildPlayer(context),
    );
  }
}
