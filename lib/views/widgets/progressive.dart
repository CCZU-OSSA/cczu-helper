import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:flutter/material.dart';

class ProgressiveView extends StatefulWidget {
  final List<Widget> children;
  final Function() onSubmit;
  final PreferredSizeWidget? appBar;
  const ProgressiveView({
    super.key,
    required this.onSubmit,
    required this.children,
    this.appBar,
  });

  @override
  State<StatefulWidget> createState() => ProgressiveViewState();
}

class ProgressiveViewState extends State<ProgressiveView> {
  late PageController pageController;
  late bool _canSubmit;
  @override
  void initState() {
    super.initState();

    _canSubmit = widget.children.length == 1;
    pageController = PageController();
  }

  void animateToPage(int page) {
    pageController.animateToPage(page,
        duration: Durations.medium4, curve: Curves.fastEaseInToSlowEaseOut);
  }

  @override
  void dispose() {
    pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var nav = Navigator.of(context);
    return Scaffold(
      appBar: widget.appBar ??
          AppBar(
            leading: BackButton(
              onPressed: () {
                if (ArcheBus.bus
                    .of<ApplicationConfigs>()
                    .skipServiceExitConfirm
                    .getOr(false)) {
                  Navigator.of(context).pop();
                  return;
                }

                ComplexDialog.instance
                    .confirm(
                        context: context,
                        title: const Text("返回?"),
                        content: const Text("未保存的内容将会丢失"))
                    .then((value) {
                  if (value) {
                    nav.pop();
                  }
                });
              },
            ),
          ),
      floatingActionButton: AnimatedSwitcher(
        duration: Durations.medium4,
        child: _canSubmit
            ? FloatingActionButton(
                key: ValueKey(_canSubmit),
                onPressed: widget.onSubmit,
                child: const Icon(Icons.check),
              )
            : FloatingActionButton(
                key: ValueKey(_canSubmit),
                onPressed: () {
                  pageController.nextPage(
                      duration: Durations.medium4,
                      curve: Curves.fastEaseInToSlowEaseOut);
                },
                child: const Icon(Icons.arrow_forward),
              ),
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: (value) {
          if (value == widget.children.length - 1) {
            setState(() {
              _canSubmit = true;
            });
          } else {
            setState(() {
              _canSubmit = false;
            });
          }
        },
        children: widget.children,
      ),
    );
  }
}
