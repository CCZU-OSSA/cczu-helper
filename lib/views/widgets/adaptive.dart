import 'package:cczu_helper/controllers/platform.dart';
import 'package:flutter/material.dart';

class AdaptiveView extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AdaptiveView({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    Widget content = SizedBox.expand(
        child: SingleChildScrollView(
      child: Padding(
        padding: padding,
        child: child,
      ),
    ));
    if (isWideScreen(context)) {
      content = Row(
        children: [
          const Flexible(
            flex: 3,
            child: SizedBox.expand(),
          ),
          Flexible(
            flex: 4,
            child: Card(
              child: content,
            ),
          ),
          const Flexible(
            flex: 3,
            child: SizedBox.expand(),
          ),
        ],
      );
    }

    return AnimatedSwitcher(
      duration: Durations.medium4,
      child: content,
    );
  }
}
