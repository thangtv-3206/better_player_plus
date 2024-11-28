import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

const _valueChangedThreshold = 3.0;
const _orientationChangedThreshold = 8.5;
const _samplingPeriod = Duration(milliseconds: Platform.isAndroid ? 200 : 50);

AccelerometerEvent _lastEvent = AccelerometerEvent(0, 0, 0, DateTime(0));
DeviceOrientation _lastKnownOrientation = DeviceOrientation.portraitUp;

Stream<DeviceOrientation> deviceOrientationStream =
//ignore:avoid_redundant_argument_values
    accelerometerEventStream(samplingPeriod: _samplingPeriod).map((event) {
  if (event.timestamp.difference(_lastEvent.timestamp) >= _samplingPeriod) {
    final x = event.x;
    final y = event.y;
    final z = event.z;

    final xAbs = x.abs();
    final yAbs = y.abs();
    final zAbs = z.abs();

    final xDiff = (x - _lastEvent.x).abs();
    final yDiff = (y - _lastEvent.y).abs();
    final zDiff = (z - _lastEvent.z).abs();

    _lastEvent = event;
    if (xDiff < _valueChangedThreshold &&
        yDiff < _valueChangedThreshold &&
        zDiff < _valueChangedThreshold) {
      if (xAbs > yAbs && xAbs > zAbs && zAbs < 6) {
        if (x > _orientationChangedThreshold) {
          _lastKnownOrientation = Platform.isIOS
              ? DeviceOrientation.landscapeRight
              : DeviceOrientation.landscapeLeft;
        } else if (x < -_orientationChangedThreshold) {
          _lastKnownOrientation = Platform.isIOS
              ? DeviceOrientation.landscapeLeft
              : DeviceOrientation.landscapeRight;
        }
      } else if (yAbs > xAbs && yAbs > zAbs && zAbs < 6) {
        if (y > _orientationChangedThreshold) {
          _lastKnownOrientation = DeviceOrientation.portraitUp;
        } else if (y < -_orientationChangedThreshold) {
          _lastKnownOrientation = DeviceOrientation.portraitDown;
        }
      }
    }
  }

  return _lastKnownOrientation;
}).distinct();
