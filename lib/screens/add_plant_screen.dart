import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddPlantScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final VoidCallback onCancel;

  const AddPlantScreen({
    Key? key,
    required this.onSubmit,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenCayController = TextEditingController();
  final _viTriController = TextEditingController();
  final _ghiChuController = TextEditingController();
  final _tuoiCayController = TextEditingController();
  final _chieuCaoController = TextEditingController();
  final _duongKinhGocController = TextEditingController();

  DateTime _ngayTrong = DateTime.now();
  String _giongCay = '';
  String _trangThai = 'khoe_manh';
  String _khuVuc = '';
  bool _isSubmitting = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _tenCayController.dispose();
    _viTriController.dispose();
    _ghiChuController.dispose();
    _tuoiCayController.dispose();
    _chieuCaoController.dispose();
    _duongKinhGocController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _ngayTrong,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      // Remove locale parameter to avoid initialization issues
    );
    if (picked != null && picked != _ngayTrong) {
      setState(() {
        _ngayTrong = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    // Use simple date formatting without locale dependency
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chụp ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _showImagePickerDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Xóa ảnh', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Generate new plant ID
      final newPlantId = 'SAM${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final plantData = {
        'ID': newPlantId,
        'tenCay': _tenCayController.text.trim(),
        'giongCay': _giongCay,
        'ngayTrong': _ngayTrong.toIso8601String(),
        'viTri': _viTriController.text.trim(),
        'trangThai': _trangThai,
        'ghiChu': _ghiChuController.text.trim(),
        'khuVuc': _khuVuc,
        'tuoiCay': _tuoiCayController.text.isNotEmpty ? int.tryParse(_tuoiCayController.text) : null,
        'chieuCao': _chieuCaoController.text.isNotEmpty ? double.tryParse(_chieuCaoController.text) : null,
        'duongKinhGoc': _duongKinhGocController.text.isNotEmpty ? double.tryParse(_duongKinhGocController.text) : null,
        'hinhAnh': _selectedImage?.path ?? '',
        'ngayTao': DateTime.now().toIso8601String(),
        'ngayCapNhat': DateTime.now().toIso8601String(),
        'NhatKy_ID': null,
        'MoiTruong_ID': null,
        'XacThuc_ID': null,
      };

      await widget.onSubmit(plantData);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thêm cây: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'khoe_manh':
        return const Text('🟢', style: TextStyle(fontSize: 16));
      case 'yeu':
        return const Text('🟡', style: TextStyle(fontSize: 16));
      case 'benh':
        return const Text('🟠', style: TextStyle(fontSize: 16));
      case 'chet':
        return const Text('🔴', style: TextStyle(fontSize: 16));
      default:
        return const Text('🟢', style: TextStyle(fontSize: 16));
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'khoe_manh':
        return 'Khỏe mạnh';
      case 'yeu':
        return 'Yếu';
      case 'benh':
        return 'Bệnh';
      case 'chet':
        return 'Chết';
      default:
        return 'Khỏe mạnh';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: widget.onCancel,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thêm cây mới',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'Nhập thông tin cây sâm mới',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _isSubmitting || _tenCayController.text.isEmpty ? null : _handleSubmit,
              icon: Icon(Icons.save, size: 16),
              label: Text(
                _isSubmitting ? 'Đang lưu...' : 'Lưu',
                style: TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size(0, 32),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Basic Information
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin cơ bản',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Tên cây
                    TextFormField(
                      controller: _tenCayController,
                      decoration: InputDecoration(
                        labelText: 'Tên cây *',
                        hintText: 'VD: Sâm Ngọc Linh 001',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên cây';
                        }
                        return null;
                      },
                      onChanged: (value) => setState(() {}),
                    ),
                    SizedBox(height: 16),

                    // Giống cây
                    DropdownButtonFormField<String>(
                      value: _giongCay.isEmpty ? null : _giongCay,
                      decoration: InputDecoration(
                        labelText: 'Giống cây',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'ngoc_linh', child: Text('Sâm Ngọc Linh')),
                        DropdownMenuItem(value: 'han_quoc', child: Text('Sâm Hàn Quốc')),
                        DropdownMenuItem(value: 'my', child: Text('Sâm Mỹ')),
                        DropdownMenuItem(value: 'trung_quoc', child: Text('Sâm Trung Quốc')),
                      ],
                      onChanged: (value) => setState(() => _giongCay = value ?? ''),
                    ),
                    SizedBox(height: 16),

                    // Ngày trồng
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Ngày trồng *',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _formatDate(_ngayTrong),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Trạng thái
                    DropdownButtonFormField<String>(
                      value: _trangThai,
                      decoration: InputDecoration(
                        labelText: 'Trạng thái',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'khoe_manh',
                          child: Row(
                            children: [
                              _buildStatusIcon('khoe_manh'),
                              SizedBox(width: 8),
                              Text(_getStatusText('khoe_manh')),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'yeu',
                          child: Row(
                            children: [
                              _buildStatusIcon('yeu'),
                              SizedBox(width: 8),
                              Text(_getStatusText('yeu')),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'benh',
                          child: Row(
                            children: [
                              _buildStatusIcon('benh'),
                              SizedBox(width: 8),
                              Text(_getStatusText('benh')),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'chet',
                          child: Row(
                            children: [
                              _buildStatusIcon('chet'),
                              SizedBox(width: 8),
                              Text(_getStatusText('chet')),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => _trangThai = value!),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Plant Image
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hình ảnh cây',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Image Preview
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.all(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Chưa có hình ảnh',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Upload Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showImagePickerDialog,
                        icon: Icon(Icons.camera_alt),
                        label: Text(_selectedImage != null ? 'Thay đổi ảnh' : 'Chọn ảnh'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    SizedBox(height: 8),
                    Text(
                      'Hỗ trợ định dạng: JPG, PNG, GIF (tối đa 5MB)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Location Information
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin vị trí',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Khu vực
                    DropdownButtonFormField<String>(
                      value: _khuVuc.isEmpty ? null : _khuVuc,
                      decoration: InputDecoration(
                        labelText: 'Khu vực',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'A', child: Text('Khu vực A')),
                        DropdownMenuItem(value: 'B', child: Text('Khu vực B')),
                        DropdownMenuItem(value: 'C', child: Text('Khu vực C')),
                        DropdownMenuItem(value: 'D', child: Text('Khu vực D')),
                      ],
                      onChanged: (value) => setState(() => _khuVuc = value ?? ''),
                    ),
                    SizedBox(height: 16),

                    // Vị trí cụ thể
                    TextFormField(
                      controller: _viTriController,
                      decoration: InputDecoration(
                        labelText: 'Vị trí cụ thể',
                        hintText: 'VD: Hàng 5, Cột 12',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Physical Information
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông số vật lý',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tuoiCayController,
                            decoration: InputDecoration(
                              labelText: 'Tuổi cây (năm)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _chieuCaoController,
                            decoration: InputDecoration(
                              labelText: 'Chiều cao (cm)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    TextFormField(
                      controller: _duongKinhGocController,
                      decoration: InputDecoration(
                        labelText: 'Đường kính gốc (mm)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Notes
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ghi chú',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    TextFormField(
                      controller: _ghiChuController,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú thêm',
                        hintText: 'Nhập ghi chú về cây sâm...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: Text('Hủy'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting || _tenCayController.text.isEmpty ? null : _handleSubmit,
                    child: Text(_isSubmitting ? 'Đang lưu...' : 'Thêm cây'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}