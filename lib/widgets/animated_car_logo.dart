import 'package:flutter/material.dart';

class AnimatedCarLogo extends StatefulWidget {
  final double size;
  final Color? carColor;
  final bool isAnimated;

  const AnimatedCarLogo({
    super.key,
    this.size = 60.0,
    this.carColor,
    this.isAnimated = true,
  });

  @override
  State<AnimatedCarLogo> createState() => _AnimatedCarLogoState();
}

class _AnimatedCarLogoState extends State<AnimatedCarLogo>
    with TickerProviderStateMixin {
  late AnimationController _carController;
  late AnimationController _roadController;
  late Animation<double> _carAnimation;
  late Animation<double> _roadAnimation;

  @override
  void initState() {
    super.initState();
    
    _carController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _roadController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _carAnimation = Tween<double>(
      begin: -0.3,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _carController,
      curve: Curves.easeInOut,
    ));

    _roadAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _roadController,
      curve: Curves.easeInOut,
    ));

    if (widget.isAnimated) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _roadController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _carController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _carController.dispose();
    _roadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carColor = widget.carColor ?? Colors.blue.shade600;
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Road background
          AnimatedBuilder(
            animation: _roadAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: RoadPainter(
                  progress: _roadAnimation.value,
                  roadColor: Colors.grey.shade400,
                ),
              );
            },
          ),
          // Animated car
          AnimatedBuilder(
            animation: _carAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _carAnimation.value * widget.size * 0.3,
                  0,
                ),
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: CarPainter(
                    carColor: carColor,
                    size: widget.size * 0.6,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class RoadPainter extends CustomPainter {
  final double progress;
  final Color roadColor;

  RoadPainter({
    required this.progress,
    required this.roadColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = roadColor
      ..style = PaintingStyle.fill;

    final roadWidth = size.width * 0.6;
    final roadHeight = size.height * 0.15;
    final roadY = size.height * 0.6;

    // Main road
    final roadRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, roadY),
        width: roadWidth * progress,
        height: roadHeight,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(roadRect, paint);

    // Road lines
    if (progress > 0.3) {
      final linePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final lineY = roadY;
      final lineSpacing = roadWidth * 0.2;
      
      for (int i = 0; i < 3; i++) {
        final x = (size.width - roadWidth) / 2 + (i + 1) * lineSpacing;
        if (x < (size.width - roadWidth) / 2 + roadWidth * progress) {
          canvas.drawLine(
            Offset(x, lineY - roadHeight / 4),
            Offset(x, lineY + roadHeight / 4),
            linePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CarPainter extends CustomPainter {
  final Color carColor;
  final double size;

  CarPainter({
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

    final strokePaint = Paint()
      ..color = carColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Car body
    final carRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: size * 0.8,
        height: size * 0.4,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(carRect, paint);

    // Car roof
    final roofRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY - size * 0.1),
        width: size * 0.5,
        height: size * 0.3,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(roofRect, paint);

    // Wheels
    final wheelPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final wheelRadius = size * 0.08;
    
    // Front wheel
    canvas.drawCircle(
      Offset(centerX + size * 0.25, centerY + size * 0.15),
      wheelRadius,
      wheelPaint,
    );
    
    // Back wheel
    canvas.drawCircle(
      Offset(centerX - size * 0.25, centerY + size * 0.15),
      wheelRadius,
      wheelPaint,
    );

    // Headlights
    final headlightPaint = Paint()
      ..color = Colors.yellow.shade300
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX + size * 0.35, centerY - size * 0.05),
      size * 0.04,
      headlightPaint,
    );

    // Windshield
    final windshieldPaint = Paint()
      ..color = Colors.blue.shade100
      ..style = PaintingStyle.fill;

    final windshieldRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY - size * 0.1),
        width: size * 0.3,
        height: size * 0.2,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(windshieldRect, windshieldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
