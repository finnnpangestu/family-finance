import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../theme/app_spacing.dart';
import 'page_header.dart';

// Shared shell for simple single-column pages (settings sub-pages):
// mobile uses the full width, tablet centers a readable column.
class SubpageScaffold extends StatelessWidget {
  const SubpageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool tablet =
                constraints.maxWidth >= AppSpacing.tabletBreakpoint;
            final double gutter = tablet ? AppSpacing.xxl : AppSpacing.lg;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                  children: [
                    PageHeader(
                      title: title,
                      subtitle: subtitle,
                      action: action,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: gutter),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
