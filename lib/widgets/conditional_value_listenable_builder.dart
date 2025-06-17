import 'package:flutter/material.dart';

class ConditionalValueListenableBuilder<T> extends ValueListenableBuilder<T> {
  final bool Function(T value) shouldRebuild;
  
  const ConditionalValueListenableBuilder({
    super.key,
    required super.valueListenable,
    required this.shouldRebuild,
    required super.builder,
    super.child,
  });

  @override
  State<ConditionalValueListenableBuilder<T>> createState() =>
      _ConditionalValueListenableBuilderState<T>();
}

class _ConditionalValueListenableBuilderState<T>
    extends State<ConditionalValueListenableBuilder<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.valueListenable.value;
    widget.valueListenable.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(ConditionalValueListenableBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueListenable != widget.valueListenable) {
      oldWidget.valueListenable.removeListener(_valueChanged);
      _value = widget.valueListenable.value;
      widget.valueListenable.addListener(_valueChanged);
    }
  }

  @override
  void dispose() {
    widget.valueListenable.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() {
    final newValue = widget.valueListenable.value;
    if (widget.shouldRebuild(newValue)) {
      setState(() {
        _value = newValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _value, widget.child);
  }
}