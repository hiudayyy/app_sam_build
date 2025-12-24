import 'package:flutter/material.dart';

class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final AlignmentGeometry alignment;
  final TextDirection? textDirection;
  final StackFit sizing;

  const LazyIndexedStack({
    Key? key,
    required this.index,
    required this.children,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.sizing = StackFit.loose,
  }) : super(key: key);

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late List<bool> _activatedList;

  @override
  void initState() {
    super.initState();
    // Tạo danh sách đánh dấu xem tab nào đã từng được mở
    _activatedList = List<bool>.filled(widget.children.length, false);
    // Tab đầu tiên (thường là index 0) luôn được active ngay lập tức
    _activatedList[widget.index] = true;
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Khi index thay đổi (người dùng chuyển tab), đánh dấu tab đó là đã active
    if (widget.index != oldWidget.index) {
      _activatedList[widget.index] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      alignment: widget.alignment,
      textDirection: widget.textDirection,
      sizing: widget.sizing,
      children: List.generate(widget.children.length, (i) {
        // Nếu tab đã được active (đã từng bấm vào) -> Hiển thị Widget thật
        if (_activatedList[i]) {
          return widget.children[i];
        }
        // Nếu chưa từng bấm vào -> Hiển thị hộp rỗng (không tốn tài nguyên)
        return const SizedBox.shrink();
      }),
    );
  }
}