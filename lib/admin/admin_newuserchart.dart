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
    List<UserGrowthData> fullYearData = [];

    // If data is not empty, fill in a full year of data
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate bar width based on available space
        // Reserve 50px for left/right padding and divide the rest among 12 months
        final double availableWidth = constraints.maxWidth - 50.0;
        final double barWidth =
            (availableWidth / 12) * 0.7; // Use 70% of available space for bars
        final double barSpacing =
            (availableWidth / 12) * 0.3; // Use 30% for spacing

        return Column(
          children: [
            // Chart container
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 40.0, // Space for y-axis labels
                  right: 10.0,
                  bottom: 5.0,
                  top: 20.0, // Space for bar value labels
                ),
                child: CustomPaint(
                  size: Size(
                    constraints.maxWidth - 50.0,
                    constraints.maxHeight * 0.85,
                  ),
                  painter: BarChartPainter(
                    data: fullYearData,
                    maxValue: maxValue,
                    barWidth: barWidth,
                    barSpacing: barSpacing,
                  ),
                ),
              ),
            ),

            // Month labels container - no scrolling needed
            SizedBox(
              height: 22,
              child: Padding(
                padding: const EdgeInsets.only(left: 40.0, right: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(fullYearData.length, (index) {
                    return SizedBox(
                      width: barWidth + barSpacing,
                      child: Center(
                        child: Text(
                          DateFormat('MMM').format(fullYearData[index].month),
                          style: const TextStyle(
                            fontSize: 10, // Slightly smaller to fit
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
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
              height: 20,
              child: Padding(
                padding: const EdgeInsets.only(left: 40.0, right: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (fullYearData.isNotEmpty)
                      Text(
                        fullYearData.first.month.year.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
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
}

/// Custom painter for drawing the bar chart
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
    final Paint gridPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.2)
          ..strokeWidth = 1;

    for (int i = 0; i <= gridLines; i++) {
      final double y = height - (height / gridLines * i);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);

      // Drawing the values as simple text outside the chart area
      final String valueText = ((maxValue / gridLines) * i).toInt().toString();

      // Simple approach - draw a small rectangle with the value next to it
      final Paint textBgPaint =
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill;

      // Draw a small background for the text to make it more readable
      canvas.drawRect(Rect.fromLTWH(-35, y - 7, 30, 14), textBgPaint);

      // Use drawParagraph instead of TextPainter
      final ui.ParagraphBuilder paragraphBuilder =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                textAlign: TextAlign.right,
                fontSize: 10,
                maxLines: 1,
              ),
            )
            ..pushStyle(ui.TextStyle(color: Colors.grey))
            ..addText(valueText);

      final ui.Paragraph paragraph =
          paragraphBuilder.build()
            ..layout(const ui.ParagraphConstraints(width: 30));

      canvas.drawParagraph(paragraph, Offset(-35, y - 7));
    }

    // Draw bars with fixed width and spacing
    final Paint barPaint =
        Paint()
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
        final ui.ParagraphBuilder valueParagraphBuilder =
            ui.ParagraphBuilder(
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

        final ui.Paragraph valueParagraph =
            valueParagraphBuilder.build()
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
