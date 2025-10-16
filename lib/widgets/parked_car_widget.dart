import 'package:flutter/material.dart';

class ParkedCarWidget extends StatefulWidget {
  final double size;
  final Color? carColor;
  final bool isAnimated;

  const ParkedCarWidget({
    super.key,
    this.size = 40.0,
    this.carColor,
    this.isAnimated = true,
  });

  @override
  State<ParkedCarWidget> createState() => _ParkedCarWidgetState();
}

class _ParkedCarWidgetState extends State<ParkedCarWidget>
    with TickerProviderStateMixin {
  late AnimationController _parkingController;
  late AnimationController _pulseController;
  late Animation<double> _parkingAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _parkingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _parkingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _parkingController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isAnimated) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _parkingController.forward();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _parkingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carColor = widget.carColor ?? Colors.blue.shade600;
    
    return AnimatedBuilder(
      animation: _parkingAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _parkingAnimation.value,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: ParkedCarPainter(
                    carColor: carColor,
                    size: widget.size,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ParkedCarPainter extends CustomPainter {
  final Color carColor;
  final double size;

  ParkedCarPainter({
    required this.carColor,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final centerX = canvasSize.width / 2;
    final centerY = canvasSize.height / 2;

    final paint = Paint()
      ..color = carColor
      ..style = PaintingStyle.fill;

    // Car body
    final carRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: size * 0.7,
        height: size * 0.35,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(carRect, paint);

    // Car roof
    final roofRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY - size * 0.08),
        width: size * 0.45,
        height: size * 0.25,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(roofRect, paint);

    // Wheels
    final wheelPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final wheelRadius = size * 0.06;
    
    // Front wheel
    canvas.drawCircle(
      Offset(centerX + size * 0.2, centerY + size * 0.12),
      wheelRadius,
      wheelPaint,
    );
    
    // Back wheel
    canvas.drawCircle(
      Offset(centerX - size * 0.2, centerY + size * 0.12),
      wheelRadius,
      wheelPaint,
    );

    // Headlights (dimmed for parked state)
    final headlightPaint = Paint()
      ..color = Colors.orange.shade300
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX + size * 0.28, centerY - size * 0.03),
      size * 0.03,
      headlightPaint,
    );

    // Windshield
    final windshieldPaint = Paint()
      ..color = Colors.blue.shade100
      ..style = PaintingStyle.fill;

    final windshieldRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY - size * 0.08),
        width: size * 0.25,
        height: size * 0.15,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(windshieldRect, windshieldPaint);

    // Parking indicator (small dot)
    final indicatorPaint = Paint()
      ..color = Colors.green.shade600
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY + size * 0.2),
      size * 0.02,
      indicatorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
