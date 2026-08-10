import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;

  List<_OnboardingSlide> _pages(BuildContext context) {
    final palette = context.appPalette;
    return [
    _OnboardingSlide(
      icon: Icons.shield_rounded,
      iconBg: palette.primarySoft,
      iconColor: palette.primary,
      title: context.l10n.onboardingTitle1,
      subtitle: context.l10n.onboardingSubtitle1,
    ),
    _OnboardingSlide(
      icon: Icons.description_rounded,
      iconBg: const Color(0xFFE6F8F1),
      iconColor: const Color(0xFF059669),
      title: context.l10n.onboardingTitle2,
      subtitle: context.l10n.onboardingSubtitle2,
    ),
    _OnboardingSlide(
      icon: Icons.collections_bookmark_rounded,
      iconBg: const Color(0xFFE8EEFF),
      iconColor: const Color(0xFF1152D4),
      title: context.l10n.onboardingTitle3,
      subtitle: context.l10n.onboardingSubtitle3,
    ),
    _OnboardingSlide(
      icon: Icons.backup_rounded,
      iconBg: const Color(0xFFFFF3E0),
      iconColor: const Color(0xFFD97706),
      title: context.l10n.onboardingTitle4,
      subtitle: context.l10n.onboardingSubtitle4,
    ),
  ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final pages = _pages(context);
    final isLast = _currentPage == pages.length - 1;

    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: Text(
                    context.l10n.onboardingSkip,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _buildSlide(pages[i]),
              ),
            ),
            // Dots
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? palette.primary
                          : palette.stroke,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: isLast
                      ? widget.onComplete
                      : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: Text(isLast ? context.l10n.onboardingGetStarted : context.l10n.onboardingNext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_OnboardingSlide slide) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: slide.iconBg,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(slide.icon, size: 46, color: slide.iconColor),
          ),
          const SizedBox(height: 36),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
}
