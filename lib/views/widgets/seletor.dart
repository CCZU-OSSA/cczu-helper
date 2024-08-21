import 'package:arche/arche.dart';
import 'package:flutter/material.dart';

class Seletor<T> extends StatefulWidget {
  final Iterable<T> Function(BuildContext context) itemBuilder;
  final Widget Function(BuildContext context, T value)? labelBuilder;
  final Widget Function(BuildContext context, T value)? tileBuilder;

  final StringTranslator<T>? translator;
  final T value;
  final Function(T value)? onSelected;
  const Seletor({
    super.key,
    required this.itemBuilder,
    required this.value,
    required this.onSelected,
    this.translator,
    this.labelBuilder,
    this.tileBuilder,
  });

  @override
  State<StatefulWidget> createState() => EnumSeletorState<T>();
}

class EnumSeletorState<T> extends State<Seletor<T>> {
  late T value;

  @override
  void initState() {
    super.initState();

    this.value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    var translator = widget.translator;
    var labelBuilder = widget.labelBuilder;
    var tileBuilder = widget.tileBuilder;
    GlobalKey<PopupMenuButtonState> key = GlobalKey();
    return PopupMenuButton<T>(
      key: key,
      initialValue: value,
      position: PopupMenuPosition.under,
      onSelected: (value) {
        setState(() {
          this.value = value;
        });
        var callback = widget.onSelected;

        if (callback != null) {
          callback(value);
        }
      },
      itemBuilder: (context) => widget
          .itemBuilder(context)
          .map(
            (item) => PopupMenuItem(
              value: item,
              child: tileBuilder != null
                  ? tileBuilder(context, item)
                  : Text(translator != null
                      ? translator.translation(item)!
                      : item.toString()),
            ),
          )
          .toList(),
      child: ActionChip(
        onPressed: () {
          key.currentState?.showButtonMenu();
        },
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            labelBuilder != null
                ? labelBuilder(context, value)
                : Text(translator != null
                    ? translator.translation(value)!
                    : value.toString()),
            const Icon(Icons.arrow_drop_down_rounded)
          ],
        ),
      ),
    );
  }
}
