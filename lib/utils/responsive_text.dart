// lib/utils/responsive_text.dart (Đã sửa lỗi logic và tham số)

import 'package:flutter/material.dart';
import 'app_dimensions.dart';

class ResponsiveText extends StatelessWidget {
  final String text;
  final double rawFontSize; // Kích thước font thô (sẽ nhận AppDimensions.fontSizeLarge)
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;

  const ResponsiveText(
      this.text, {
        super.key,
        required this.rawFontSize, // rawFontSize nhận giá trị const
        this.fontWeight,
        this.color,
        this.textAlign,
      });

  @override
  Widget build(BuildContext context) {
    // Lấy tỷ lệ co giãn theo chiều rộng
    final double scale = AppDimensions.scaleFactorWidth(context);

    // Tính toán Font Size cuối cùng
    final double finalFontSize = rawFontSize * scale;

    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: finalFontSize, // Áp dụng kích thước đã co giãn
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}