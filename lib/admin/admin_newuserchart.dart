import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

/// Data class for user growth information
class UserGrowthData {
  final DateTime month;
  final int newUsers;

  UserGrowthData({required this.month, required this.newUsers});
}

/// A widget that displays monthly user growth data as a bar chart
class UserGrowthChart extends StatelessWidget {
  final List<UserGrowthData> data;

  const UserGrowthChart({Key? key, required this.data}) : super(key: key);

  // Design System Constants (enhanced for consistency)
  static const Color _primaryColor = Color(0xFF3B6EA5);
  static const Color _primaryLightColor = Color(0xFF5A8BC4);
  static const Color _primaryDarkColor =
      Color(0xFF2A5A87); // Added for consistency
  static const Color _backgroundColor = Color(0xFFF7F9FB);
  static const Color _surfaceColor = Colors.white;
  static const Color _errorColor = Color(0xFFE53E3E);
  static const Color _successColor = Color(0xFF38A169);
  static const Color _warningColor = Color(0xFFD69E2E);
  static const Color _dividerColor = Color(0xFFE2E8F0);
  static const Color _selectedBackgroundColor = Color(0xFFEDF2F7);
  static const Color _textPrimaryColor = Color(0xFF2D3748);
  static const Color _textSecondaryColor = Color(0xFF718096);
  static const Color _textTertiaryColor = Color(0xFFA0AEC0);

  // Spacing Constants
  static const double _spacingXs = 4.0;
  static const double _spacingS = 8.0;
  static const double _spacingM = 12.0;
  static const double _spacingL = 16.0;
  static const double _spacingXl = 20.0;
  static const double _spacingXxl = 24.0;
  static const double _spacingXxxl = 32.0;

  // Size Constants
  static const double _borderRadius = 12.0;
  static const double _borderRadiusS = 8.0;
  static const double _borderRadiusL = 16.0;

  // Typography Constants
  static const double _fontSizeXs = 11;
  static const double _fontSizeS = 12;
  static const double _fontSizeM = 13;
  static const double _fontSizeL = 15;

  static const FontWeight _fontWeightRegular = FontWeight.w400;
  static const FontWeight _fontWeightMedium = FontWeight.w500;
  static const FontWeight _fontWeightSemiBold = FontWeight.w600;
  static const FontWeight _fontWeightBold = FontWeight.w700;

  // Chart specific constants
  static const double _chartPaddingLeft = 40.0;
  static const double _chartPaddingRight = 10.0;
  static const double _chartPaddingTop = 20.0;
  static const double _chartPaddingBottom = 5.0;
  static const double _monthLabelHeight = 22.0;
  static const double _yearLabelHeight = 20.0;
  static const double _barWidthRatio = 0.7;
  static const double _barSpacingRatio = 0.3;
  static const int _gridLines = 5;
  static const double _minBarHeightForLabel = 25.0;

  @override
  Widget build(BuildContext context) {
    // Find max value for scaling, with a minimum default of 10
    double maxValue = 10.0;
    if (data.isNotEmpty) {
      final max = data
          .map((e) => e.newUsers.toDouble())
          .reduce((a, b) => a > b ? a : b);
      // Add 20% padding to the max value and round to next multiple of 5
      maxValue = (max * 1.2);
      maxValue = (maxValue / 5).ceil() * 5.0;
    }

    // Create a list with all 12 months for the year
    List<UserGrowthData> fullYearData = _prepareFullYearData();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate bar dimensions based on available space
        final double availableWidth =
            constraints.maxWidth - (_chartPaddingLeft + _chartPaddingRight);
        final double barWidth = (availableWidth / 12) * _barWidthRatio;
        final double barSpacing = (availableWidth / 12) * _barSpacingRatio;

        return Column(
          children: [
            // Chart container
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: _chartPaddingLeft,
                  right: _chartPaddingRight,
                  bottom: _chartPaddingBottom,
                  top: _chartPaddingTop,
                ),
                child: CustomPaint(
                  size: Size(
                    availableWidth,
                    constraints.maxHeight * 0.85,
                  ),
                  painter: EnhancedBarChartPainter(
                    data: fullYearData,
                    maxValue: maxValue,
                    barWidth: barWidth,
                    barSpacing: barSpacing,
                  ),
                ),
              ),
            ),

            // Month labels container
            SizedBox(
              height: _monthLabelHeight,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: _chartPaddingLeft,
                  right: _chartPaddingRight,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(fullYearData.length, (index) {
                    return SizedBox(
                      width: barWidth + barSpacing,
                      child: Center(
                        child: Text(
                          DateFormat('MMM').format(fullYearData[index].month),
                          style: TextStyle(
                            fontSize: _fontSizeXs,
                            fontWeight: _fontWeightBold,
                            color: _textSecondaryColor,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Year label at the bottom
            SizedBox(
              height: _yearLabelHeight,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: _chartPaddingLeft,
                  right: _chartPaddingRight,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (fullYearData.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _spacingM,
                          vertical: _spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedBackgroundColor,
                          borderRadius: BorderRadius.circular(_borderRadiusS),
                        ),
                        child: Text(
                          fullYearData.first.month.year.toString(),
                          style: TextStyle(
                            fontSize: _fontSizeS,
                            fontWeight: _fontWeightMedium,
                            color: _textPrimaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Prepares a full year of data with all 12 months
  List<UserGrowthData> _prepareFullYearData() {
    List<UserGrowthData> fullYearData = [];

    if (data.isNotEmpty) {
      // Determine the year to use (from the first data point)
      final int year = data.first.month.year;

      // Create map of existing data for quick lookup
      Map<int, int> monthDataMap = {};
      for (var item in data) {
        monthDataMap[item.month.month] = item.newUsers;
      }

      // Create a full year of data (January to December)
      for (int month = 1; month <= 12; month++) {
        fullYearData.add(
          UserGrowthData(
            month: DateTime(year, month, 1),
            newUsers: monthDataMap[month] ?? 0, // Use 0 if no data for month
          ),
        );
      }
    } else {
      // If no data, just use current year with zeros
      final int currentYear = DateTime.now().year;
      for (int month = 1; month <= 12; month++) {
        fullYearData.add(
          UserGrowthData(month: DateTime(currentYear, month, 1), newUsers: 0),
        );
      }
    }

    return fullYearData;
  }
}

/// Enhanced custom painter for drawing the bar chart with improved styling
class EnhancedBarChartPainter extends CustomPainter {
  final List<UserGrowthData> data;
  final double maxValue;
  final double barWidth;
  final double barSpacing;

  EnhancedBarChartPainter({
    required this.data,
    required this.maxValue,
    required this.barWidth,
    required this.barSpacing,
  });

  // Design System Constants
  static const Color _primaryColor = Color(0xFF3B6EA5);
  static const Color _primaryLightColor = Color(0xFF5A8BC4);
  static const Color _primaryDarkColor = Color(0xFF2A5A87);
  static const Color _surfaceColor = Colors.white;
  static const Color _textSecondaryColor = Color(0xFF718096);
  static const Color _textTertiaryColor = Color(0xFFA0AEC0);
  static const Color _dividerColor = Color(0xFFE2E8F0);

  static const int _gridLines = 5;
  static const double _gridLineWidth = 1.0;
  static const double _gridLineOpacity = 0.3;
  static const double _barCornerRadius = 6.0;
  static const double _shadowBlurRadius = 4.0;
  static const double _shadowOpacity = 0.15;
  static const double _fontSizeGrid = 10.0;
  static const double _fontSizeValue = 10.0;
  static const double _minBarHeightForLabel = 25.0;
  static const double _labelPaddingFromBar = 16.0;
  static const double _gridLabelWidth = 35.0;
  static const double _gridLabelHeight = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    _drawGridLines(canvas, width, height);
    _drawBars(canvas, width, height);
  }

  /// Draws horizontal grid lines and y-axis labels
  void _drawGridLines(Canvas canvas, double width, double height) {
    // Enhanced grid line paint
    final Paint gridPaint = Paint()
      ..color = _dividerColor.withOpacity(_gridLineOpacity)
      ..strokeWidth = _gridLineWidth
      ..style = PaintingStyle.stroke;

    // Grid label background paint
    final Paint labelBgPaint = Paint()
      ..color = _surfaceColor
      ..style = PaintingStyle.fill;

    // Grid label border paint
    final Paint labelBorderPaint = Paint()
      ..color = _dividerColor.withOpacity(0.5)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= _gridLines; i++) {
      final double y = height - (height / _gridLines * i);

      // Draw grid line
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);

      // Calculate and format the value
      final String valueText = ((maxValue / _gridLines) * i).toInt().toString();

      // Draw enhanced background for the label
      final Rect labelRect = Rect.fromLTWH(
        -_gridLabelWidth - 5,
        y - _gridLabelHeight / 2,
        _gridLabelWidth,
        _gridLabelHeight,
      );

      // Draw label background with rounded corners
      final RRect labelRRect = RRect.fromRectAndRadius(
        labelRect,
        const Radius.circular(4),
      );

      canvas.drawRRect(labelRRect, labelBgPaint);
      canvas.drawRRect(labelRRect, labelBorderPaint);

      // Draw the label text
      final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: _fontSizeGrid,
          maxLines: 1,
        ),
      )
        ..pushStyle(ui.TextStyle(
          color: _textSecondaryColor,
          fontWeight: ui.FontWeight.w500,
        ))
        ..addText(valueText);

      final ui.Paragraph paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: _gridLabelWidth));

      canvas.drawParagraph(
        paragraph,
        Offset(-_gridLabelWidth - 5, y - _gridLabelHeight / 2 + 2),
      );
    }
  }

  /// Draws the bars with enhanced styling
  void _drawBars(Canvas canvas, double width, double height) {
    for (int i = 0; i < data.length; i++) {
      final double barHeight = (data[i].newUsers / maxValue) * height;
      final double x = i * (barWidth + barSpacing);

      if (data[i].newUsers > 0) {
        _drawSingleBar(canvas, x, height - barHeight, barWidth, barHeight,
            data[i].newUsers);
      } else {
        _drawEmptyBar(canvas, x, height, barWidth);
      }
    }
  }

  /// Draws a single bar with gradient and shadow
  void _drawSingleBar(Canvas canvas, double x, double y, double width,
      double height, int value) {
    final Rect barRect = Rect.fromLTWH(x, y, width, height);

    // Create shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(_shadowOpacity)
      ..maskFilter =
          const ui.MaskFilter.blur(ui.BlurStyle.normal, _shadowBlurRadius);

    final RRect shadowRRect = RRect.fromRectAndRadius(
      barRect.translate(2, 2),
      const Radius.circular(_barCornerRadius),
    );

    canvas.drawRRect(shadowRRect, shadowPaint);

    // Create gradient paint for the bar
    final Paint barPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(x, y),
        Offset(x, y + height),
        [
          _primaryLightColor,
          _primaryColor,
          _primaryDarkColor,
        ],
        [0.0, 0.7, 1.0],
      )
      ..style = PaintingStyle.fill;

    // Draw the main bar
    final RRect barRRect = RRect.fromRectAndRadius(
      barRect,
      const Radius.circular(_barCornerRadius),
    );

    canvas.drawRRect(barRRect, barPaint);

    // Add a subtle highlight on top
    final Paint highlightPaint = Paint()
      ..color = _surfaceColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final RRect highlightRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, math.min(height * 0.3, 8)),
      const Radius.circular(_barCornerRadius),
    );

    canvas.drawRRect(highlightRRect, highlightPaint);

    // Draw value label on top of the bar if it's tall enough
    if (height > _minBarHeightForLabel) {
      _drawValueLabel(canvas, x, y, width, value);
    }
  }

  /// Draws an empty bar placeholder
  void _drawEmptyBar(Canvas canvas, double x, double y, double width) {
    final Paint emptyBarPaint = Paint()
      ..color = _textTertiaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final RRect emptyBarRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y - 3, width, 3),
      const Radius.circular(1.5),
    );

    canvas.drawRRect(emptyBarRRect, emptyBarPaint);
  }

  /// Draws the value label above a bar
  void _drawValueLabel(
      Canvas canvas, double x, double y, double width, int value) {
    // Create background for the label
    final Paint labelBgPaint = Paint()
      ..color = _primaryColor
      ..style = PaintingStyle.fill;

    // Calculate label dimensions
    final String valueText = value.toString();
    const double labelPadding = 6.0;
    const double labelHeight = 20.0;
    final double labelWidth =
        math.max(valueText.length * 7.0 + labelPadding * 2, 24.0);

    // Draw label background
    final RRect labelBgRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        x + (width - labelWidth) / 2,
        y - _labelPaddingFromBar - labelHeight,
        labelWidth,
        labelHeight,
      ),
      const Radius.circular(labelHeight / 2),
    );

    canvas.drawRRect(labelBgRRect, labelBgPaint);

    // Draw the value text
    final ui.ParagraphBuilder valueParagraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: _fontSizeValue,
        maxLines: 1,
      ),
    )
      ..pushStyle(
        ui.TextStyle(
          color: _surfaceColor,
          fontWeight: ui.FontWeight.w600,
        ),
      )
      ..addText(valueText);

    final ui.Paragraph valueParagraph = valueParagraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: labelWidth));

    canvas.drawParagraph(
      valueParagraph,
      Offset(
        x + (width - labelWidth) / 2,
        y - _labelPaddingFromBar - labelHeight + 5,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Original bar chart painter for backward compatibility
class BarChartPainter extends CustomPainter {
  final List<UserGrowthData> data;
  final double maxValue;
  final double barWidth;
  final double barSpacing;

  BarChartPainter({
    required this.data,
    required this.maxValue,
    required this.barWidth,
    required this.barSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Draw horizontal grid lines
    final int gridLines = 5;
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= gridLines; i++) {
      final double y = height - (height / gridLines * i);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);

      // Drawing the values as simple text outside the chart area
      final String valueText = ((maxValue / gridLines) * i).toInt().toString();

      // Simple approach - draw a small rectangle with the value next to it
      final Paint textBgPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      // Draw a small background for the text to make it more readable
      canvas.drawRect(Rect.fromLTWH(-35, y - 7, 30, 14), textBgPaint);

      // Use drawParagraph instead of TextPainter
      final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.right,
          fontSize: 10,
          maxLines: 1,
        ),
      )
        ..pushStyle(ui.TextStyle(color: Colors.grey))
        ..addText(valueText);

      final ui.Paragraph paragraph = paragraphBuilder.build()
        ..layout(const ui.ParagraphConstraints(width: 30));

      canvas.drawParagraph(paragraph, Offset(-35, y - 7));
    }

    // Draw bars with fixed width and spacing
    final Paint barPaint = Paint()
      ..color = const Color(0xFF3B6EA5)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final double barHeight = (data[i].newUsers / maxValue) * height;
      // Position bars with consistent spacing
      final double x = i * (barWidth + barSpacing);

      final Rect barRect = Rect.fromLTWH(
        x,
        height - barHeight,
        barWidth,
        barHeight,
      );
      final RRect roundedRect = RRect.fromRectAndCorners(
        barRect,
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(roundedRect, barPaint);

      // Draw value on top of the bar if it's non-zero (optional)
      if (data[i].newUsers > 0) {
        final ui.ParagraphBuilder valueParagraphBuilder = ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: TextAlign.center,
            fontSize: 10,
            maxLines: 1,
          ),
        )
          ..pushStyle(
            ui.TextStyle(
              color: const Color(0xFF3B6EA5),
              fontWeight: ui.FontWeight.bold,
            ),
          )
          ..addText(data[i].newUsers.toString());

        final ui.Paragraph valueParagraph = valueParagraphBuilder.build()
          ..layout(ui.ParagraphConstraints(width: barWidth));

        // Only show the value if the bar is tall enough
        if (barHeight > 25) {
          canvas.drawParagraph(
            valueParagraph,
            Offset(x, height - barHeight - 16),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
