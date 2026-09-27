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
        key: const ValueKey('shili-coach-card-v14'),
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * 0.22),
          border: Border.all(
            color: const Color(0xFFD8B34D),
            width: 1.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44B98B2E),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/shili_coach_card_v14.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              alignment: Alignment.center,
              color: const Color(0xFFF6EAC3),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: width * 0.55,
                color: const Color(0xFF7B521B),
              ),
            );
          },
        ),
      ),
    );
  }
}
