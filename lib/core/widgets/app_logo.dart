import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

// Brand mark in a white circle; the dark strokes need a light backdrop.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 44});

  static const String asset = 'assets/branding/logo_mark.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    // Decode at display size to keep memory low on 2GB devices.
    final int cacheSize = (size * MediaQuery.devicePixelRatioOf(context))
        .round();
    return Semantics(
      label: 'Logo Family Finance',
      image: true,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.12),
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Image.asset(
          asset,
          cacheWidth: cacheSize,
          cacheHeight: cacheSize,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
