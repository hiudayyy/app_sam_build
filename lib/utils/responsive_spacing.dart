// lib/utils/responsive_spacing.dart

import 'package:flutter/material.dart';
import 'app_dimensions.dart'; // Import AppDimensions

// 1. Widget SizedBox co giãn theo chiều cao
class VSpace extends StatelessWidget {
  final double rawSize; // Kích thước thô từ AppDimensions.spacingMedium
  const VSpace(this.rawSize, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Co giãn theo chiều cao màn hình
      height: AppDimensions.responsiveHeight(context, rawSize),
    );
  }
}

// 2. Widget SizedBox co giãn theo chiều rộng
class HSpace extends StatelessWidget {
  final double rawSize; // Kích thước thô từ AppDimensions.spacingMedium
  const HSpace(this.rawSize, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Co giãn theo chiều rộng màn hình
      width: AppDimensions.responsiveWidth(context, rawSize),
    );
  }
}

// 3. Hàm tiện ích cho EdgeInsets
class RSpace { // RSpace = Responsive Space
  // Padding/Margin đều co giãn theo cả 2 chiều
  static EdgeInsets all(BuildContext context, double rawSize) {
    final double horz = AppDimensions.responsiveWidth(context, rawSize);
    final double vert = AppDimensions.responsiveHeight(context, rawSize);
    return EdgeInsets.symmetric(horizontal: horz, vertical: vert);
  }

  // Padding/Margin chỉ co giãn theo chiều ngang
  static EdgeInsets horizontal(BuildContext context, double rawSize) {
    final double horz = AppDimensions.responsiveWidth(context, rawSize);
    return EdgeInsets.symmetric(horizontal: horz);
  }

  // Padding/Margin chỉ co giãn theo chiều dọc
  static EdgeInsets vertical(BuildContext context, double rawSize) {
    final double vert = AppDimensions.responsiveHeight(context, rawSize);
    return EdgeInsets.symmetric(vertical: vert);
  }

// Thêm các hàm khác như top, left, right, bottom nếu cần
}