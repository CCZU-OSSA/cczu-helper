import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

Widget rainbow(Widget child, [Duration? duration]) {
  return child
      .animate(
        onPlay: (controller) => controller.repeat(reverse: true),
      )
      .shimmer(
          duration: duration ?? 1200.ms,
          colors: [
            Colors.blue.shade300,
            Colors.yellow,
            Colors.pink.shade200,
            Colors.red,
          ],
          curve: Curves.linear);
}

extension RainBow on Widget {
  Widget rainbow([Duration? duration]) {
    return animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).shimmer(
        duration: duration ?? 1200.ms,
        colors: [
          Colors.blue.shade300,
          Colors.yellow,
          Colors.pink.shade200,
          Colors.red,
        ],
        curve: Curves.linear);
  }

  Widget rainbowWhen(bool condition, [Duration? duration]) {
    if (!condition) {
      return this;
    }
    return animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).shimmer(
        duration: duration ?? 1200.ms,
        colors: [
          Colors.blue.shade300,
          Colors.yellow,
          Colors.pink.shade200,
          Colors.red,
        ],
        curve: Curves.linear);
  }
}
