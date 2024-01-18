import 'package:flutter/material.dart';

class Pixel extends StatelessWidget {
  final Color? color;
  final size = 16.0;

  const Pixel({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      margin: const EdgeInsets.all(1),
    );
  }
}
