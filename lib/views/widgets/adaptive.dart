import 'package:arche/extensions/iter.dart';
import 'package:cczu_helper/controllers/navigator.dart';
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
    this.cardMargin = const EdgeInsets.only(bottom: 48),
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

class AdaptiveListItem {
  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;

  final Widget? page;
  const AdaptiveListItem({
    this.title,
    this.subtitle,
    this.leading,
    this.page,
  });
}

class AdaptiveListView extends StatefulWidget {
  final List<AdaptiveListItem> items;
  const AdaptiveListView({
    super.key,
    required this.items,
  });

  @override
  State<StatefulWidget> createState() => AdaptiveListViewState();
}

class AdaptiveListViewState extends State<AdaptiveListView> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    if (isWideScreen(context)) {
      return Row(
        children: [
          Flexible(
            flex: 1,
            child: ListView(
              children: widget.items
                  .enumerate(
                    (index, e) => AnimatedSwitcher(
                      duration: Durations.medium4,
                      child: ListTile(
                        key: ValueKey(index),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        tileColor: this.index == index
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        title: e.title,
                        leading: e.leading,
                        subtitle: e.subtitle,
                        onTap: () => setState(() {
                          this.index = index;
                        }),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Flexible(
            flex: 3,
            child: AnimatedSwitcher(
              duration: Durations.medium4,
              child: Container(
                key: ValueKey(index),
                child: widget.items[index].page,
              ),
            ),
          )
        ],
      );
    }

    return ListView(
      children: widget.items
          .map((e) => ListTile(
                title: e.title,
                leading: e.leading,
                subtitle: e.subtitle,
                onTap: e.page == null
                    ? null
                    : () => pushMaterialRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(),
                            body: e.page,
                          ),
                        ),
              ))
          .toList(),
    );
  }
}
