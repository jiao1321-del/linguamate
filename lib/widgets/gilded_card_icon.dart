import 'package:flutter/material.dart';

class GildedCardIcon extends StatelessWidget {
  final double width;
  final double height;

  const GildedCardIcon({
    super.key,
    this.width = 28,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'AI 學習卡',
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * 0.22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2A1B0B),
              Color(0xFF7B521B),
              Color(0xFFD8B34D),
              Color(0xFF5C3B12),
            ],
            stops: [0.0, 0.34, 0.68, 1.0],
          ),
          border: Border.all(
            color: const Color(0xFFFFE59A),
            width: 1.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55B98B2E),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: height * 0.12,
              left: width * 0.16,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: width * 0.28,
                color: const Color(0xFFFFF1B8),
              ),
            ),
            Icon(
              Icons.style_rounded,
              size: width * 0.58,
              color: const Color(0xFFFFF6D6),
            ),
            Positioned(
              right: width * 0.12,
              bottom: height * 0.10,
              child: Icon(
                Icons.star_rounded,
                size: width * 0.23,
                color: const Color(0xFFFFD666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
