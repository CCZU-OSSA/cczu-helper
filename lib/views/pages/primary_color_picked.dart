import 'package:cczu_helper/views/pages/services.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

class PrimaryColorPickedPage extends StatefulWidget {
  const PrimaryColorPickedPage({super.key});

  @override
  State<PrimaryColorPickedPage> createState() => _PrimaryColorPickedPageState();
}

class _PrimaryColorPickedPageState extends State<PrimaryColorPickedPage> {
  Color? pickedColor;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: pickedColor != null
            ? ColorScheme.fromSeed(
                seedColor: pickedColor!,
                brightness: Theme.of(context).brightness,
                dynamicSchemeVariant: DynamicSchemeVariant.content,
              )
            : null,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("主色调"),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pop(pickedColor);
          },
          child: Icon(Icons.check),
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          children: [
            ColorPicker(
              color: pickedColor ?? Theme.of(context).colorScheme.primary,
              showColorName: true,
              pickersEnabled: {
                ColorPickerType.both: false,
                ColorPickerType.primary: true,
                ColorPickerType.accent: false,
                ColorPickerType.bw: false,
                ColorPickerType.custom: false,
                ColorPickerType.customSecondary: false,
                ColorPickerType.wheel: false,
              },
              onColorChanged: (value) {
                setState(() {
                  pickedColor = value;
                });
              },
            ),
            _ColorDemo()
          ],
        ),
      ),
    );
  }
}

class _ColorDemo extends StatelessWidget {
  const _ColorDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 4,
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(
          onPressed: () {},
          child: const Text("Filled"),
        ),
        ElevatedButton(
          onPressed: () {},
          child: const Text("Elevated"),
        ),
        OutlinedButton(
          onPressed: () {},
          child: const Text("Outlined"),
        ),
        ServiceItem(
          text: "Service",
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Card.filled(
            child: ListTile(
              title: Text("Filled Card"),
              subtitle: Text("Subtitle"),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Card(
            child: ListTile(
              title: Text("Card"),
              subtitle: Text("Subtitle"),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Card.outlined(
            child: ListTile(
              title: Text("Outlined Card"),
              subtitle: Text("Subtitle"),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ),
      ],
    );
  }
}
