import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
class Responsive {
  final BuildContext context;

  Responsive(this.context);

  // Screen size getters
  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;

  // Device type checks
  bool get isSmallPhone => width < 360;
  bool get isMobile => width < 600;
  bool get isTablet => width >= 600 && width < 900;
  bool get isDesktop => width >= 900;
  bool get isLargeDesktop => width >= 1200;

  // Responsive value getter
  double value({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  // Responsive spacing
  double spacing({
    required double mobile,
    double? tablet,
    double? desktop,
  }) =>
      value(mobile: mobile, tablet: tablet, desktop: desktop);

  // Responsive font size
  double fontSize({
    required double mobile,
    double? tablet,
    double? desktop,
  }) =>
      value(mobile: mobile, tablet: tablet, desktop: desktop);

  // Responsive padding
  EdgeInsets padding({
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  // Responsive icon size
  double iconSize({
    required double mobile,
    double? tablet,
    double? desktop,
  }) =>
      value(mobile: mobile, tablet: tablet, desktop: desktop);

  // Quick access for common values
  double get smallSpacing => spacing(mobile: 8, tablet: 12, desktop: 16);
  double get mediumSpacing => spacing(mobile: 16, tablet: 20, desktop: 24);
  double get largeSpacing => spacing(mobile: 24, tablet: 32, desktop: 40);
  double get xlargeSpacing => spacing(mobile: 32, tablet: 40, desktop: 48);

  double get smallFontSize => fontSize(mobile: 12, tablet: 13, desktop: 14);
  double get bodyFontSize => fontSize(mobile: 14, tablet: 15, desktop: 16);
  double get titleFontSize => fontSize(mobile: 16, tablet: 17, desktop: 18);
  double get headingFontSize => fontSize(mobile: 20, tablet: 22, desktop: 24);
  double get largeFontSize => fontSize(mobile: 28, tablet: 32, desktop: 38);

  double get smallIconSize => iconSize(mobile: 20, tablet: 22, desktop: 24);
  double get mediumIconSize => iconSize(mobile: 24, tablet: 26, desktop: 28);
  double get largeIconSize => iconSize(mobile: 28, tablet: 32, desktop: 36);

  // Button heights
  double get buttonHeight => value(mobile: 56, tablet: 60, desktop: 64);
  double get smallButtonHeight => value(mobile: 44, tablet: 48, desktop: 52);

  // Container constraints
  double get maxContentWidth => value(mobile: 420, tablet: 500, desktop: 550);

  // Horizontal padding for pages
  double get pagePadding =>
      value(mobile: isSmallPhone ? 16 : 24, tablet: 32, desktop: 40);
}

/// Extension on BuildContext for easy access
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}

/// Responsive builder widget for conditional rendering
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    if (responsive.isDesktop && desktop != null) {
      return desktop!;
    }
    if (responsive.isTablet && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

/// Responsive SizedBox for spacing
class ResponsiveSpacing extends StatelessWidget {
  final double mobile;
  final double? tablet;
  final double? desktop;
  final bool isHorizontal;

  const ResponsiveSpacing({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.isHorizontal = false,
  });

  const ResponsiveSpacing.horizontal({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : isHorizontal = true;

  @override
  Widget build(BuildContext context) {
    final size = context.responsive.value(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );

    return SizedBox(
      width: isHorizontal ? size : null,
      height: !isHorizontal ? size : null,
    );
  }
}

/// Responsive Text widget
class ResponsiveText extends StatelessWidget {
  final String text;
  final double mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
      this.text, {
        super.key,
        required this.mobileFontSize,
        this.tabletFontSize,
        this.desktopFontSize,
        this.fontWeight,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow,
      });

  @override
  Widget build(BuildContext context) {
    final fontSize = context.responsive.fontSize(
      mobile: mobileFontSize,
      tablet: tabletFontSize,
      desktop: desktopFontSize,
    );

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}