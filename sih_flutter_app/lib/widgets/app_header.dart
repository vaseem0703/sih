import 'package:flutter/material.dart';
import '../app/theme.dart';

class AppHeader extends StatelessWidget {
  final VoidCallback? onOfflineTap;

  const AppHeader({super.key, this.onOfflineTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Brand Logo & Title
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryButtonGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'S',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'SIH',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Mother-Tongue Classroom Assistant',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Offline Ready Pill
          GestureDetector(
            onTap:
                onOfflineTap ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Offline Ready • Translation, lessons and audio available',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6F3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD7E9DD)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7DD28F),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Offline Ready',
                    style: TextStyle(
                      color: Color(0xFF39764E),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
