import 'package:flutter/material.dart';

import '../tokens.dart';

/// A paper slip torn from a pad: perforated top edge. Used for confirmations ("यह लिखूँ?").
class Parchi extends StatelessWidget {
  const Parchi({super.key, required this.child, this.color = SutraColors.card, this.padding = const EdgeInsets.fromLTRB(18, 22, 18, 18)});

  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return PhysicalShape(
      clipper: const _PerforatedClipper(),
      color: color,
      elevation: 3,
      shadowColor: const Color(0x337A4B2A),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _PerforatedClipper extends CustomClipper<Path> {
  const _PerforatedClipper();

  static const _hole = 4.0;
  static const _gap = 14.0;

  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, _hole);
    var x = 0.0;
    while (x + _gap <= size.width) {
      path
        ..lineTo(x + (_gap - _hole * 2) / 2, _hole)
        ..arcToPoint(Offset(x + (_gap + _hole * 2) / 2, _hole), radius: const Radius.circular(_hole), clockwise: false);
      x += _gap;
    }
    path
      ..lineTo(size.width, _hole)
      ..lineTo(size.width, size.height - 10)
      ..quadraticBezierTo(size.width, size.height, size.width - 10, size.height)
      ..lineTo(10, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - 10)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
