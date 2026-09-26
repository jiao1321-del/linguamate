import 'package:flutter/material.dart';

class ShiliCoachAvatar extends StatelessWidget {
  final double size;

  const ShiliCoachAvatar({
    super.key,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF5FA),
            Color(0xFFEDE5FF),
            Color(0xFFDCCEFF),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFE8D5FF),
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'web/icons/Shili-192-v052.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              alignment: Alignment.center,
              color: const Color(0xFFF3ECFF),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: size * 0.48,
                color: const Color(0xFF7B61A8),
              ),
            );
          },
        ),
      ),
    );
  }
}
