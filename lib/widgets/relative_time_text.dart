import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/time_format.dart';

/// Texto de tiempo relativo que se refresca solo ("hace 2 min").
class RelativeTimeText extends StatefulWidget {
  const RelativeTimeText({
    super.key,
    required this.time,
    this.style,
    this.prefix = '',
  });

  final DateTime time;
  final TextStyle? style;
  final String prefix;

  @override
  State<RelativeTimeText> createState() => _RelativeTimeTextState();
}

class _RelativeTimeTextState extends State<RelativeTimeText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.prefix}${formatRelativeTime(widget.time)}',
      style: widget.style,
    );
  }
}
