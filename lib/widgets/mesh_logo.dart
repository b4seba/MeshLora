import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MeshLogo extends StatelessWidget {
  final double size;
  final double? width;
  final double? height;
  final Color? nodeColor;
  final Color? accentColor;
  final double borderRadius;
  final bool showBorder;
  final bool showShadow;
  final bool showContainer;
  final bool isCircle;
  final EdgeInsetsGeometry? padding;
  final BoxFit fit;

  const MeshLogo({
    super.key,
    this.size = 40,
    this.width,
    this.height,
    this.nodeColor,
    this.accentColor,
    this.borderRadius = 8,
    this.showBorder = false,
    this.showShadow = false,
    this.showContainer = false,
    this.isCircle = false,
    this.padding = EdgeInsets.zero,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveHeight = height ?? size;
    final effectiveWidth = width ?? (effectiveHeight * (744.0 / 494.0));
    final effectiveRadius = isCircle
        ? BorderRadius.circular(effectiveHeight / 2)
        : (borderRadius > 0 ? BorderRadius.circular(borderRadius) : BorderRadius.zero);

    Widget imageWidget = Image.asset(
      'assets/images/LOGO.jpeg',
      width: effectiveWidth,
      height: effectiveHeight,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            Icons.radar_rounded,
            size: effectiveHeight * 0.7,
            color: AppTheme.electricBlue,
          ),
        );
      },
    );

    if (borderRadius > 0 || isCircle) {
      imageWidget = ClipRRect(
        borderRadius: effectiveRadius,
        child: imageWidget,
      );
    }

    if (!showContainer && !showBorder && !showShadow && (padding == null || padding == EdgeInsets.zero)) {
      return SizedBox(
        width: effectiveWidth,
        height: effectiveHeight,
        child: imageWidget,
      );
    }

    return Container(
      width: effectiveWidth,
      height: effectiveHeight,
      padding: padding,
      decoration: BoxDecoration(
        color: showContainer ? Colors.white : Colors.transparent,
        borderRadius: effectiveRadius,
        border: showBorder
            ? Border.all(
                color: isDark ? AppTheme.borderDark : const Color(0xFFE2E8F0),
                width: 1.2,
              )
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: imageWidget,
    );
  }
}
