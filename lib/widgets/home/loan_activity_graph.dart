import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class LoanActivityGraph extends StatelessWidget {
  const LoanActivityGraph({super.key});

  @override
  Widget build(BuildContext context) {
    // mock data for the line graph (deposits from 0 to 10000, 8 weeks = 2 months)
    final List<double> values = [1200, 3500, 2800, 5000, 4200, 8000, 6500, 9500];
    final List<String> labels = ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7', 'W8'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Activity Overview',
                style: TextStyle(
                  fontFamily: 'Arial',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Past 2 Months',
                style: TextStyle(
                  fontFamily: 'Arial',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                // Y-axis Labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildYLabel('10k'),
                    _buildYLabel('7.5k'),
                    _buildYLabel('5k'),
                    _buildYLabel('2.5k'),
                    _buildYLabel('0'),
                    const SizedBox(height: 12), // Align with x-axis labels
                  ],
                ),
                const SizedBox(width: 16),
                // The Graph
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomPaint(
                          size: const Size(double.infinity, double.infinity),
                          painter: LineChartPainter(
                            values: values,
                            maxValue: 10000,
                            lineColor: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // X-axis Labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: labels.map((label) => _buildXLabel(label)).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Arial',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildXLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Arial',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final Color lineColor;

  LineChartPainter({
    required this.values,
    required this.maxValue,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintFill = Paint()..style = PaintingStyle.fill;
      
    final path = Path();
    final fillPath = Path();

    final double stepX = size.width / (values.length - 1);

    // Grid lines (horizontal)
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 4; i++) {
      final double y = size.height - (size.height * (i / 4));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Calculate path
    for (int i = 0; i < values.length; i++) {
      final double x = i * stepX;
      final double normalizedY = 1 - (values[i] / maxValue).clamp(0.0, 1.0);
      final double y = size.height * normalizedY;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final double prevX = (i - 1) * stepX;
        final double prevNormalizedY = 1 - (values[i - 1] / maxValue).clamp(0.0, 1.0);
        final double prevY = size.height * prevNormalizedY;

        // Smooth curve
        final double controlPointX = prevX + (x - prevX) / 2;
        path.cubicTo(controlPointX, prevY, controlPointX, y, x, y);
        fillPath.cubicTo(controlPointX, prevY, controlPointX, y, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Gradient fill
    paintFill.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        lineColor.withOpacity(0.25),
        lineColor.withOpacity(0.0),
      ],
    ).createShader(Offset.zero & size);

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    // Draw dots on top
    for (int i = 0; i < values.length; i++) {
      final double x = i * stepX;
      final double normalizedY = 1 - (values[i] / maxValue).clamp(0.0, 1.0);
      final double y = size.height * normalizedY;
      
      final isLast = i == values.length - 1;
      
      final dotFillPaint = Paint()..color = isLast ? lineColor : Colors.white;
      final dotBorderPaint = Paint()
        ..color = lineColor
        ..strokeWidth = isLast ? 0 : 2
        ..style = PaintingStyle.stroke;
        
      canvas.drawCircle(Offset(x, y), isLast ? 5 : 4, dotFillPaint);
      if (!isLast) {
        canvas.drawCircle(Offset(x, y), 4, dotBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.maxValue != maxValue;
  }
}

