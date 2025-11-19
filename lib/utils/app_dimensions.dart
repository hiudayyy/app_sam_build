// lib/utils/app_dimensions.dart (Đã sửa lỗi getter/const)

import 'package:flutter/material.dart';
import 'dart:math' as math;

class AppDimensions {
  static const double _designWidth = 375.0;
  static const double _designHeight = 812.0;
  static const double _minScaleLimit = 1.0;

  // Tỷ lệ co giãn theo CHIỀU RỘNG (dùng cho Font Size)
  static double scaleFactorWidth(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scaleWidth = screenWidth / _designWidth;
    return math.max(scaleWidth, _minScaleLimit);
  }

  // Co giãn cho kích thước ngang
  static double responsiveWidth(BuildContext context, double size) {
    return size * scaleFactorWidth(context);
  }

  // Co giãn cho kích thước dọc (ví dụ dùng cho SizedBox height)
  static double responsiveHeight(BuildContext context, double size) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double scaleHeight = screenHeight / _designHeight;
    return size * math.max(scaleHeight, _minScaleLimit);
  }

  // GIÁ TRỊ THÔ CONST (KHÔNG PHẢI GETTER)
  static const double sp2 = 2.0;
  static const double sp6 = 6.0;
  static const double fontSizeExtraSmall = 10.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 18.0; // Đã sửa lỗi: Giờ là const, không phải getter
  static const double fontSizeExtraLarge = 24.0;
  static const double fontSizeOverSized = 36.0;

  static const double spacingMedium = 16.0;
// ... (các const spacing khác)
}