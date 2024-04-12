import 'package:flutter/material.dart';

class ProgressiveView extends StatefulWidget {
  final List<Widget> children;
  final Function() onSubmit;
  const ProgressiveView(
      {super.key, required this.onSubmit, required this.children});

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
    pageController.addListener(() {
      if (pageController.page?.toInt() == widget.children.length - 1) {
        setState(() {
          _canSubmit = true;
        });
      } else {
        setState(() {
          _canSubmit = false;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
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
        children: widget.children,
      ),
    );
  }
}


