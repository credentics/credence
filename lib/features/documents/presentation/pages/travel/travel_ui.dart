import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

const Color travelBackgroundColor = Color(0xFFF6F7FB);
const Color travelCardBorderColor = Color(0xFFE1E7F2);
const Color travelCardShadowColor = Color(0x10214268);

TextStyle travelInputTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: context.appPalette.textPrimary,
  );
}

InputDecoration travelInputDecoration(
  BuildContext context, {
  required String hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: context.appPalette.textMuted,
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: context.appPalette.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: context.appPalette.stroke),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: context.appPalette.stroke),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: context.appPalette.primary, width: 1.1),
    ),
  );
}

class TravelSectionLabel extends StatelessWidget {
  const TravelSectionLabel({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF7F90AA),
      ),
    );
  }
}

class TravelSurfaceCard extends StatelessWidget {
  const TravelSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: palette.stroke),
        boxShadow: const [
          BoxShadow(
            color: travelCardShadowColor,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class TravelStatusPill extends StatelessWidget {
  const TravelStatusPill({
    super.key,
    required this.label,
    this.backgroundColor = const Color(0xFFF1F5FD),
    this.foregroundColor = const Color(0xFF4D617F),
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.8,
          fontWeight: FontWeight.w800,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class TravelCategoryChip extends StatelessWidget {
  const TravelCategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? context.appPalette.primary : context.appPalette.surfaceSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? context.appPalette.primary : context.appPalette.stroke,
          ),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x302A1464),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? Colors.white : context.appPalette.textSecondary,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : context.appPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TravelUploadActionButton extends StatelessWidget {
  const TravelUploadActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: CustomPaint(
        painter: const _DashedRoundedBorderPainter(
          color: Color(0xFFC8D6F3),
          strokeWidth: 1.3,
          radius: 18,
          dashLength: 8,
          gapLength: 5,
        ),
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: context.appPalette.primary),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4E607C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TravelBottomNavStrip extends StatelessWidget {
  const TravelBottomNavStrip({
    super.key,
    required this.items,
    required this.activeKey,
    this.centerAction,
  });

  final List<TravelBottomNavItem> items;
  final String activeKey;
  final Widget? centerAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.stroke)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final item in items) ...[
              Expanded(
                child: _BottomNavCell(
                  icon: item.icon,
                  label: item.label,
                  active: item.key == activeKey,
                ),
              ),
              if (centerAction != null &&
                  item == items[(items.length ~/ 2) - 1])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: centerAction!,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottomNavCell extends StatelessWidget {
  const _BottomNavCell({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? context.appPalette.primary : const Color(0xFFA4B0C4);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.8,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}

class TravelBottomNavItem {
  const TravelBottomNavItem({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

List<TravelBottomNavItem> travelBottomItemsTrips(BuildContext context) {
  return const [
    TravelBottomNavItem(
      key: 'trips',
      label: 'TRIPS',
      icon: Icons.luggage_outlined,
    ),
    TravelBottomNavItem(key: 'explore', label: 'EXPLORE', icon: Icons.explore),
    TravelBottomNavItem(
      key: 'wallet',
      label: 'WALLET',
      icon: Icons.account_balance_wallet_outlined,
    ),
    TravelBottomNavItem(key: 'profile', label: 'PROFILE', icon: Icons.person),
  ];
}

List<TravelBottomNavItem> travelBottomItemsDashboard() {
  return const [
    TravelBottomNavItem(
      key: 'dashboard',
      label: 'DASHBOARD',
      icon: Icons.grid_view_rounded,
    ),
    TravelBottomNavItem(key: 'explore', label: 'EXPLORE', icon: Icons.explore),
    TravelBottomNavItem(key: 'saved', label: 'SAVED', icon: Icons.favorite),
    TravelBottomNavItem(key: 'profile', label: 'PROFILE', icon: Icons.person),
  ];
}

List<TravelBottomNavItem> travelBottomItemsTimeline() {
  return const [
    TravelBottomNavItem(key: 'explore', label: 'EXPLORE', icon: Icons.explore),
    TravelBottomNavItem(
      key: 'timeline',
      label: 'TIMELINE',
      icon: Icons.watch_later_rounded,
    ),
    TravelBottomNavItem(
      key: 'docs',
      label: 'DOCS',
      icon: Icons.description_outlined,
    ),
    TravelBottomNavItem(key: 'profile', label: 'PROFILE', icon: Icons.person),
  ];
}

List<TravelBottomNavItem> travelBottomItemsExpenses() {
  return const [
    TravelBottomNavItem(key: 'home', label: 'Home', icon: Icons.home),
    TravelBottomNavItem(
      key: 'itinerary',
      label: 'Itinerary',
      icon: Icons.calendar_today,
    ),
    TravelBottomNavItem(
      key: 'expenses',
      label: 'Expenses',
      icon: Icons.account_balance_wallet,
    ),
    TravelBottomNavItem(key: 'profile', label: 'Profile', icon: Icons.person),
  ];
}
