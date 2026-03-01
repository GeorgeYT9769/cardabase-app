import 'package:flutter/widgets.dart';

class MultiListenableBuilder extends StatefulWidget {
  const MultiListenableBuilder({
    super.key,
    required this.listenables,
    required this.builder,
  });

  final List<Listenable> listenables;
  final WidgetBuilder builder;

  @override
  State<MultiListenableBuilder> createState() => _MultiListenableBuilderState();
}

class _MultiListenableBuilderState extends State<MultiListenableBuilder> {
  @override
  void initState() {
    super.initState();
    for (final listenable in widget.listenables) {
      listenable.addListener(_onChange);
    }
  }

  @override
  void didUpdateWidget(covariant MultiListenableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // remove all listeners for listenables which don't exist anymore
    for (final listenable in oldWidget.listenables) {
      if (!widget.listenables.contains(listenable)) {
        listenable.removeListener(_onChange);
      }
    }
    // add all listeners for listenables which don't exist yet
    for (final listenable in widget.listenables) {
      if (!oldWidget.listenables.contains(listenable)) {
        listenable.addListener(_onChange);
      }
    }
  }

  @override
  void dispose() {
    for (final listenable in widget.listenables) {
      listenable.removeListener(_onChange);
    }
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
