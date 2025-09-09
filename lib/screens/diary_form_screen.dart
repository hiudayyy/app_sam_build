import 'package:flutter/material.dart';

class DiaryFormScreen extends StatefulWidget {
  final List<String> plantIds;
  final Function(Map<String, dynamic>) onSubmit;
  final VoidCallback onCancel;

  const DiaryFormScreen({
    Key? key,
    required this.plantIds,
    required this.onSubmit,
    required this.onCancel,
  }) : super(key: key);

  @override
  _DiaryFormScreenState createState() => _DiaryFormScreenState();
}

class _DiaryFormScreenState extends State<DiaryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  String _selectedAction = 'watering';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cập nhật nhật ký'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
        actions: [
          TextButton(
            onPressed: _handleSubmit,
            child: Text('Lưu'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cập nhật cho ${widget.plantIds.length} cây',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),

              SizedBox(height: 24),

              Text('Hoạt động'),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedAction,
                onChanged: (value) {
                  setState(() {
                    _selectedAction = value!;
                  });
                },
                items: [
                  DropdownMenuItem(value: 'watering', child: Text('Tưới nước')),
                  DropdownMenuItem(value: 'fertilizing', child: Text('Bón phân')),
                  DropdownMenuItem(value: 'pruning', child: Text('Tỉa cành')),
                  DropdownMenuItem(value: 'pest_control', child: Text('Xử lý sâu bệnh')),
                ],
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 16),

              Text('Ghi chú'),
              SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Nhập ghi chú...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập ghi chú';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit({
        'plantIds': widget.plantIds,
        'action': _selectedAction,
        'note': _noteController.text,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}