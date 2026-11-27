import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'theme.dart';

/// Reusable Glassmorphism Container with customizable blur, opacity, border, and gradient
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.borderRadius = 18.0,
    this.padding,
    this.margin,
    this.color,
    this.border,
    this.boxShadow,
    this.gradient,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? const Color(0xFF161B26).withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.78);
    final defaultBorder = Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.90),
      width: 1,
    );

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? (gradient == null ? defaultBg : null),
              gradient: gradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ?? defaultBorder,
              boxShadow: boxShadow ?? [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Explicit tag [E] matching Apple Music / Spotify explicit badge
class ExplicitBadge extends StatelessWidget {
  final double size;
  const ExplicitBadge({super.key, this.size = 14});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(3.5),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.22) : Colors.black.withValues(alpha: 0.12),
          width: 0.6,
        ),
      ),
      child: Text(
        'E',
        style: TextStyle(
          color: isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF1C1C1E),
          fontSize: size * 0.72,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Lossless / Hi-Res Lossless audio quality pill badge with sound wave icon
class LosslessBadge extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool? isDark;
  final Color? color;

  const LosslessBadge({
    super.key,
    this.label = 'Hi-Res Lossless',
    this.onTap,
    this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final bg = dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06);
    final border = dark ? Colors.white.withValues(alpha: 0.20) : Colors.black.withValues(alpha: 0.12);
    final fg = color ?? (dark ? Colors.white.withValues(alpha: 0.92) : const Color(0xFF1C1C1E));

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: border,
                width: 0.8,
              ),
              boxShadow: !dark
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.waveform,
                  size: 11,
                  color: fg,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted circular button with subtle glass highlight
class FrostedCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final Color? backgroundColor;

  const FrostedCircleButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 40,
    this.iconSize = 20,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.72);
    final defaultIconColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final defaultBorder = isDark ? Colors.white.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.90);

    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: backgroundColor ?? defaultBg,
                border: Border.all(
                  color: defaultBorder,
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: iconSize,
                  color: iconColor ?? defaultIconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted pill button for controls (Shuffle, Repeat, Autoplay)
class FrostedPillButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isActive;
  final Color? activeColor;
  final double width;
  final double height;

  const FrostedPillButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isActive = false,
    this.activeColor,
    this.width = 64,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveActiveColor = activeColor ?? AppTheme.accentColor1;
    final inactiveBg = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.65);
    final inactiveBorder = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.85);
    final inactiveIcon = isDark ? Colors.white : const Color(0xFF1C1C1E);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isActive
                    ? effectiveActiveColor.withValues(alpha: 0.22)
                    : inactiveBg,
                border: Border.all(
                  color: isActive
                      ? effectiveActiveColor.withValues(alpha: 0.55)
                      : inactiveBorder,
                  width: 0.8,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: effectiveActiveColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 18,
                  color: isActive ? effectiveActiveColor : inactiveIcon,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated 3-bar playing audio wave indicator
class AnimatedEqualizer extends StatelessWidget {
  final Animation<double> animation;
  final Color? color;
  final double maxHeight;

  const AnimatedEqualizer({
    super.key,
    required this.animation,
    this.color,
    this.maxHeight = 16,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? AppTheme.accentColor1;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final val = animation.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBar(6 + (maxHeight - 6) * val, barColor),
            const SizedBox(width: 2.5),
            _buildBar(maxHeight - (maxHeight - 6) * val, barColor),
            const SizedBox(width: 2.5),
            _buildBar(8 + (maxHeight - 8) * (1.0 - val), barColor),
          ],
        );
      },
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 3,
      height: height.clamp(4.0, maxHeight),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Apple Music style wave symbol icon (3 curved parallel lines)
class RadioWaveIcon extends StatelessWidget {
  final double size;
  final Color color;

  const RadioWaveIcon({
    super.key,
    this.size = 28,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.7),
      painter: _RadioWavePainter(color: color),
    );
  }
}

class _RadioWavePainter extends CustomPainter {
  final Color color;
  _RadioWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.height * 0.14;

    final w = size.width;
    final h = size.height;

    final path1 = Path();
    path1.moveTo(w * 0.1, h * 0.25);
    path1.quadraticBezierTo(w * 0.5, h * 0.0, w * 0.9, h * 0.25);
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(w * 0.2, h * 0.58);
    path2.quadraticBezierTo(w * 0.5, h * 0.38, w * 0.8, h * 0.58);
    canvas.drawPath(path2, paint);

    final path3 = Path();
    path3.moveTo(w * 0.3, h * 0.92);
    path3.quadraticBezierTo(w * 0.5, h * 0.76, w * 0.7, h * 0.92);
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
