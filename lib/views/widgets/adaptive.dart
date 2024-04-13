import 'package:cczu_helper/controllers/platform.dart';
import 'package:flutter/material.dart';

class AdaptiveView extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry cardMargin;
  final bool shrinkWrap;
  const AdaptiveView({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(8),
    this.cardMargin = const EdgeInsets.only(top: 48, bottom: 48),
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (!shrinkWrap) {
      content = SizedBox.expand(
          child: SingleChildScrollView(
        child: Padding(
          padding: padding,
          child: child,
        ),
      ));
    } else {
      content = SizedBox.expand(child: child);
    }

    if (isWideScreen(context)) {
      content = Row(
        children: [
          const Flexible(
            flex: 2,
            child: SizedBox.expand(),
          ),
          Flexible(
            flex: 5,
            child: Padding(
              padding: cardMargin,
              child: Card(
                child: content,
              ),
            ),
          ),
          const Flexible(
            flex: 2,
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
