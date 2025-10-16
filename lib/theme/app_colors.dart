import 'package:flutter/material.dart';

class AppColors {
  // Primary Color - Confident Digital Blue
  static const Color primary = Color(0xFF2D5BFF);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFF60A5FA);
  
  // Success/Action Color - Fresh Energetic Teal-Green
  static const Color success = Color(0xFF00C48C);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);
  
  // Warning/Alert Color - Soft Clear Red
  static const Color warning = Color(0xFFFF6B6B);
  static const Color warningLight = Color(0xFFFCA5A5);
  static const Color warningDark = Color(0xFFDC2626);
  
  // Background Color - Very Light Gray
  static const Color background = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFFE5E7EB);
  
  // Text Color - Dark Navy Gray
  static const Color text = Color(0xFF2E3A59);
  static const Color textLight = Color(0xFF6B7280);
  static const Color textWhite = Color(0xFFFFFFFF);
  
  // Additional Colors
  static const Color disabled = Color(0xFFD1D5DB);
  static const Color border = Color(0xFFE5E7EB);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF111827);
  
  // Status Colors
  static const Color available = success;
  static const Color booked = warning;
  static const Color expired = Color(0xFF9CA3AF);
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2D5BFF), Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00C48C), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
