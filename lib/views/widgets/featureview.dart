import 'package:cczu_helper/controllers/platform.dart';
import 'package:flutter/material.dart';

class FeatureView extends StatelessWidget {
  final Widget primary;
  final Widget secondary;
  final bool reverse;
  final EdgeInsetsGeometry padding;
  const FeatureView({
    super.key,
    this.primary = const SizedBox.shrink(),
    this.secondary = const SizedBox.shrink(),
    this.reverse = false,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    var isWide = isWideScreen(context);
    var pageItems = [
      Expanded(
        flex: 3,
        child: primary,
      ),
      Expanded(
        flex: 2,
        child: secondary,
      )
    ];

    if (reverse) {
      pageItems = pageItems.reversed.toList();
    }
    return Padding(
      padding: padding,
      child: AnimatedSwitcher(
        duration: Durations.medium4,
        child: isWide
            ? Row(
                children: pageItems,
              )
            : Column(
                children: pageItems,
              ),
      ),
    );
  }
}
