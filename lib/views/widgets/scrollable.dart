import 'package:flutter/material.dart';

class PaddingScrollView extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget? child;
  const PaddingScrollView({
    super.key,
    this.padding = const EdgeInsets.all(8),
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: SingleChildScrollView(
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
