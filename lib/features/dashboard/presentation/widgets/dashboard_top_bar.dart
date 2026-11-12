import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../settings/presentation/page/settings_page.dart';

// Inline header (no AppBar): greeting, title, today's date and the logo.
class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({super.key, this.logoSize = 48});

  final double logoSize;

  static String greeting(DateTime now) => switch (now.hour) {
    < 11 => 'Selamat pagi',
    < 15 => 'Selamat siang',
    < 18 => 'Selamat sore',
    _ => 'Selamat malam',
  };

  // "Selamat pagi, Muhammad", or just the greeting without an account name.
  static String personalGreeting(DateTime now, String? firstName) =>
      firstName == null ? greeting(now) : '${greeting(now)}, $firstName';

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Greeting(now: now),
              Text(
                DateFormatter.long(now),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const _SettingsButton(),
        const SizedBox(width: AppSpacing.sm),
        AppLogo(size: logoSize),
      ],
    );
  }
}

// Only this line rebuilds when the signed-in account changes.
class _Greeting extends ConsumerWidget {
  const _Greeting({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? firstName = ref.watch(
      activeAccountProvider.select((a) => a?.firstName),
    );
    return Text(
      DashboardTopBar.personalGreeting(now, firstName),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.headingMedium,
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Pengaturan',
      excludeSemantics: true,
      child: Material(
        color: AppColors.card,
        shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage())),
          child: const SizedBox.square(
            dimension: AppSpacing.minTouchTarget,
            child: Icon(
              FluentIcons.settings_24_regular,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
