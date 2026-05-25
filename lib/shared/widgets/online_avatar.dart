import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class OnlineAvatar extends StatelessWidget {
  final String name;
  final bool isOnline;
  final int index;
  final double size;
  final VoidCallback? onTap;

  const OnlineAvatar({
    super.key,
    required this.name,
    this.isOnline = false,
    required this.index,
    this.size = 65,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradients = [
      AppColors.primaryGradient,
      AppColors.pinkGradient,
      [AppColors.diamondBlue, AppColors.primaryPurple],
      [AppColors.successGreen, AppColors.diamondBlue],
      AppColors.premiumGradient,
      [AppColors.neonPink, AppColors.primaryPurple],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: gradients[index % gradients.length],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradients[index % gradients.length][0].withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: gradients[index % gradients.length],
                        ).createShader(Rect.fromLTWH(0, 0, size, size)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}
