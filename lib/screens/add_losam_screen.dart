import 'dart:io';

import 'package:csam_mobile/api/api_option.dart';
import 'package:csam_mobile/models/option_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api.dart';

class LoSamChiTiet {
  int loSamLoaiTuoiId;
  int soLuong;
  int trangThai;

  LoSamChiTiet({
    required this.loSamLoaiTuoiId,
    required this.soLuong,
    required this.trangThai,
  });
}

class LoSamCamera {
  int loSamLoaiCameraId;
  String rtsp;
  String url;
  int trangThai;

  LoSamCamera({
    required this.loSamLoaiCameraId,
    required this.rtsp,
    required this.url,
    required this.trangThai,
  });
}

class LoSamFormData {
  String maLo;
  String tenLo;
  int soHang;
  int soCot;
  double dienTich;
  String ghiChu;
  String loai;
  int trangThai;
  int vuonTrongId;

  LoSamFormData({
    required this.maLo,
    required this.tenLo,
    required this.soHang,
    required this.soCot,
    required this.dienTich,
    required this.ghiChu,
    required this.loai,
    required this.trangThai,
    required this.vuonTrongId,
  });
}

class AddLoSamScreen extends StatefulWidget {
  final int zoneId;
  final String zoneName;
  final Function(Map<String, dynamic> data, {File? image}) onSubmit;

  const AddLoSamScreen({
    Key? key,
    required this.zoneId,
    required this.zoneName,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _AddLoSamScreenState createState() => _AddLoSamScreenState();
}

class _AddLoSamScreenState extends State<AddLoSamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Mock data for dropdowns
  static const List<Map<String, dynamic>> loaiTuoiOptions = [
    {'id': 1, 'name': 'Sâm 1 năm tuổi'},
    {'id': 2, 'name': 'Sâm 2 năm tuổi'},
    {'id': 3, 'name': 'Sâm 3 năm tuổi'},
    {'id': 4, 'name': 'Sâm 4 năm tuổi'},
    {'id': 5, 'name': 'Sâm 5 năm tuổi'},
  ];

  static const List<Map<String, dynamic>> loaiCameraOptions = [
    {'id': 1, 'name': 'Camera giám sát chính'},
    {'id': 2, 'name': 'Camera nhiệt độ'},
    {'id': 3, 'name': 'Camera độ ẩm'},
    {'id': 4, 'name': 'Camera thời tiết'},
  ];

  static const List<String> loaiSamOptions = [
    'Loại A - Chất lượng cao',
    'Loại B - Chất lượng trung bình',
    'Loại C - Chất lượng thấp',
    'Sâm giống',
    'Sâm thương phẩm'
  ];

  // Form data
  late LoSamFormData loSamData;
  List<LoSamChiTiet> chiTiets = [];
  List<LoSamCamera> cameras = [];
  List<OptionModel> OptionLoSamLoaiTuoi = [];
  List<OptionModel> OptionLoaiCamera = [];
  Map<String, String> errors = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Initialize form data
    loSamData = LoSamFormData(
      maLo: '',
      tenLo: '',
      soHang: 1,
      soCot: 1,
      dienTich: 0,
      ghiChu: '',
      loai: '',
      trangThai: 1,
      vuonTrongId: widget.zoneId ?? 1,
    );
    // Initialize with one item each
    // chiTiets.add(LoSamChiTiet(loSamLoaiTuoiId: 1, soLuong: 0, trangThai: 1));
    // cameras.add(LoSamCamera(loSamLoaiCameraId: 1, rtsp: '', url: '', trangThai: 1));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _initializeData() async {
    // Calculate plant statistics

    final api = API();
    // Calculate farms with plants data
    // farmsWithPlantsData = MockData.mockFarms
    //     .map((farm) => farm.copyWith(
    //   investorPlantCount: widget.plants
    //       .where((plant) => farm.zones.any((zone) =>
    //       zone.areas.any((area) => area.id == plant.areaId)))
    //       .length,
    // ))
    //     .where((farm) => farm.investorPlantCount! > 0)
    //     .toList();
    final apiOptinlt = await api.OptionLoSamLoaiTuoi();
    final apiOptincmr = await api.OptionLoSamLoaiCamera();
    if (apiOptinlt != null) {
      setState(() {
        OptionLoSamLoaiTuoi = apiOptinlt;
      });
    }
    if (apiOptincmr != null) {
      setState(() {
        OptionLoaiCamera = apiOptincmr;
      });
    }
  }

  void _updateLoSamData(String field, dynamic value) {
    setState(() {
      switch (field) {
        case 'maLo':
          loSamData.maLo = value.toString();
          break;
        case 'tenLo':
          loSamData.tenLo = value.toString();
          break;
        case 'soHang':
          loSamData.soHang =
              value is int ? value : int.tryParse(value.toString()) ?? 1;
          _updateDienTich();
          break;
        case 'soCot':
          loSamData.soCot =
              value is int ? value : int.tryParse(value.toString()) ?? 1;
          _updateDienTich();
          break;
        case 'dienTich':
          loSamData.dienTich =
              value is double ? value : double.tryParse(value.toString()) ?? 0;
          break;
        case 'ghiChu':
          loSamData.ghiChu = value.toString();
          break;
        case 'loai':
          loSamData.loai = value.toString();
          break;
      }

      // Clear error
      if (errors.containsKey(field)) {
        errors.remove(field);
      }
    });
  }

  void _updateDienTich() {
    loSamData.dienTich = (loSamData.soHang * loSamData.soCot).toDouble();
  }

  void _addChiTiet() {
    setState(() {
      chiTiets.add(LoSamChiTiet(loSamLoaiTuoiId: 1, soLuong: 0, trangThai: 1));
    });
  }

  void _removeChiTiet(int index) {
    if (chiTiets.length > 1) {
      setState(() {
        chiTiets.removeAt(index);
      });
    }
  }

  void _updateChiTiet(int index, String field, dynamic value) {
    setState(() {
      switch (field) {
        case 'loSamLoaiTuoiId':
          chiTiets[index].loSamLoaiTuoiId =
              value is int ? value : int.tryParse(value.toString()) ?? 1;
          break;
        case 'soLuong':
          chiTiets[index].soLuong =
              value is int ? value : int.tryParse(value.toString()) ?? 0;
          break;
      }
    });
  }

  void _addCamera() {
    setState(() {
      cameras.add(
          LoSamCamera(loSamLoaiCameraId: 1, rtsp: '', url: '', trangThai: 1));
    });
  }

  void _removeCamera(int index) {
    if (cameras.length > 1) {
      setState(() {
        cameras.removeAt(index);
      });
    }
  }

  void _updateCamera(int index, String field, String value) {
    setState(() {
      switch (field) {
        case 'loSamLoaiCameraId':
          cameras[index].loSamLoaiCameraId = int.tryParse(value) ?? 1;
          break;
        case 'rtsp':
          cameras[index].rtsp = value;
          break;
        case 'url':
          cameras[index].url = value;
          break;
      }
    });
  }

  bool _validateForm() {
    errors.clear();

    if (loSamData.maLo.trim().isEmpty) {
      errors['maLo'] = 'Mã lô là bắt buộc';
    } else if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(loSamData.maLo)) {
      errors['maLo'] = 'Mã lô chỉ được chứa chữ cái không dấu và số, không ký tự đặc biệt';
    }

    if (loSamData.tenLo.trim().isEmpty) {
      errors['tenLo'] = 'Tên lô là bắt buộc';
    }

    if (loSamData.loai.isEmpty) {
      errors['loai'] = 'Loại sâm là bắt buộc';
    }

    if (loSamData.soHang < 1) {
      errors['soHang'] = 'Số hàng phải lớn hơn 0';
    }

    if (loSamData.soCot < 1) {
      errors['soCot'] = 'Số cột phải lớn hơn 0';
    }
    if(_selectedImage == null){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng tải hình ảnh của lô sâm'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Validate chi tiets
    for (int i = 0; i < chiTiets.length; i++) {
      if (chiTiets[i].soLuong < 0) {
        errors['chiTiet_${i}_soLuong'] = 'Số lượng không được âm';
      }
    }

    // Validate cameras
    for (int i = 0; i < cameras.length; i++) {
      if (cameras[i].rtsp.isNotEmpty &&
          !cameras[i].rtsp.startsWith('rtsp://')) {
        errors['camera_${i}_rtsp'] = 'RTSP phải bắt đầu với rtsp://';
      }
      if (cameras[i].url.isNotEmpty && !cameras[i].url.startsWith('http')) {
        errors['camera_${i}_url'] =
            'URL phải bắt đầu với http:// hoặc https://';
      }
    }

    setState(() {});
    return errors.isEmpty;
  }

  void _handleSubmit() {
    if (!_validateForm()) {
      return;
    }

    final submitData = {
      'LoSam': {
        'MaLo': loSamData.maLo,
        'TenLo': loSamData.tenLo,
        'SoHang': loSamData.soHang,
        'SoCot': loSamData.soCot,
        'DienTich': loSamData.dienTich,
        'GhiChu': loSamData.ghiChu,
        'Loai': loSamData.loai,
        'TrangThai': loSamData.trangThai,
        'VuonTrong_ID': loSamData.vuonTrongId,
        'Ngay': DateTime.now().toIso8601String(),
      },
      'LoSamChiTiets': chiTiets
          .map((ct) => {
                'LoSamLoaiTuoiId': ct.loSamLoaiTuoiId,
                'SoLuong': ct.soLuong,
                'TrangThai': ct.trangThai,
              })
          .toList(),
      'LoSamCameras': cameras
          .map((cam) => {
                'LoSamLoaiCameraId': cam.loSamLoaiCameraId,
                'RTSP': cam.rtsp,
                'Url': cam.url,
                'TrangThai': cam.trangThai,
              })
          .toList(),
    };

    widget.onSubmit(submitData,image: _selectedImage);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm lô sâm mới'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSectionCard(
                title: 'Thông tin cơ bản',
                icon: Icons.info_outline,
                children: [
                  _buildTextField(
                    label: 'Mã lô *',
                    value: loSamData.maLo,
                    onChanged: (value) => _updateLoSamData('maLo', value),
                    errorKey: 'maLo',
                    hintText: 'VD: T001',
                  ),
                  _buildTextField(
                    label: 'Tên lô *',
                    value: loSamData.tenLo,
                    onChanged: (value) => _updateLoSamData('tenLo', value),
                    errorKey: 'tenLo',
                    hintText: 'VD: Lô Sâm A',
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'Số hàng *',
                          value: loSamData.soHang,
                          onChanged: (value) =>
                              _updateLoSamData('soHang', value),
                          errorKey: 'soHang',
                          min: 1,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildNumberField(
                          label: 'Số cột *',
                          value: loSamData.soCot,
                          onChanged: (value) =>
                              _updateLoSamData('soCot', value),
                          errorKey: 'soCot',
                          min: 1,
                        ),
                      ),
                    ],
                  ),
/*                  _buildNumberField(
                    label: 'Diện tích (m²)',
                    value: loSamData.dienTich,
                    onChanged: (value) => _updateLoSamData('dienTich', value),
                    isDouble: true,
                    readOnly: true,
                    helperText:
                        'Tự động tính: ${loSamData.soHang} × ${loSamData.soCot} = ${loSamData.soHang * loSamData.soCot}',
                  ),*/
                  _buildTextField(
                    label: 'Loại sâm *',
                    value: loSamData.loai,
                    onChanged: (value) => _updateLoSamData('loai', value),
                    errorKey: 'loai',
                    hintText: 'VD: Loại A',
                  ),
                  _buildTextField(
                    label: 'Ghi chú',
                    value: loSamData.ghiChu,
                    onChanged: (value) => _updateLoSamData('ghiChu', value),
                    maxLines: 3,
                    hintText: 'Ghi chú về lô sâm...',
                  ),
                ],
              ),

              const SizedBox(height: 16),

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
                          label: Text(_selectedImage != null
                              ? 'Thay đổi ảnh'
                              : 'Chọn ảnh'),
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
              const SizedBox(height: 16),
              _buildDynamicSection(
                title: 'Chi tiết lô sâm',
                icon: Icons.grass,
                items: chiTiets,
                onAdd: _addChiTiet,
                onRemove: _removeChiTiet,
                itemBuilder: (index) => _buildChiTietItem(index),
              ),

              const SizedBox(height: 16),

              // Camera Section
              _buildDynamicSection(
                title: 'Camera giám sát',
                icon: Icons.camera_alt,
                items: cameras,
                onAdd: _addCamera,
                onRemove: _removeCamera,
                itemBuilder: (index) => _buildCameraItem(index),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 16),
                          SizedBox(width: 8),
                          Text('Tạo lô sâm'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicSection<T>({
    required String title,
    required IconData icon,
    required List<T> items,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    required Widget Function(int) itemBuilder,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(items.length, itemBuilder),
          ],
        ),
      ),
    );
  }

  Widget _buildChiTietItem(int index) {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (chiTiets.length > 1)
                  IconButton(
                    onPressed: () => _removeChiTiet(index),
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    label: 'Loại tuổi sâm',
                    value: chiTiets[index].loSamLoaiTuoiId,
                    items: OptionLoSamLoaiTuoi,
                    onChanged: (value) =>
                        _updateChiTiet(index, 'loSamLoaiTuoiId', value),
                    isMap: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumberField(
                    label: 'Số lượng',
                    value: chiTiets[index].soLuong,
                    onChanged: (value) =>
                        _updateChiTiet(index, 'soLuong', value),
                    errorKey: 'chiTiet_${index}_soLuong',
                    min: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraItem(int index) {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (cameras.length > 1)
                  IconButton(
                    onPressed: () => _removeCamera(index),
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Loại camera',
              value: cameras[index].loSamLoaiCameraId,
              items: OptionLoaiCamera,
              onChanged: (value) =>
                  _updateCamera(index, 'loSamLoaiCameraId', value.toString()),
              isMap: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'RTSP Stream',
                    value: cameras[index].rtsp,
                    onChanged: (value) => _updateCamera(index, 'rtsp', value),
                    errorKey: 'camera_${index}_rtsp',
                    hintText: 'rtsp://camera-ip:port/stream',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Web URL',
                    value: cameras[index].url,
                    onChanged: (value) => _updateCamera(index, 'url', value),
                    errorKey: 'camera_${index}_url',
                    hintText: 'http://camera-web-interface',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required Function(String) onChanged,
    String? errorKey,
    String? hintText,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            onChanged: onChanged,
            maxLines: maxLines,
            readOnly: readOnly,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
              errorText: errorKey != null ? errors[errorKey] : null,
              filled: readOnly,
              fillColor: readOnly ? Colors.grey.shade100 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required num value,
    required Function(num) onChanged,
    String? errorKey,
    num? min,
    bool isDouble = false,
    bool readOnly = false,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value.toString(),
            onChanged: (val) {
              if (isDouble) {
                onChanged(double.tryParse(val) ?? 0);
              } else {
                onChanged(int.tryParse(val) ?? 0);
              }
            },
            keyboardType: TextInputType.number,
            readOnly: readOnly,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              errorText: errorKey != null ? errors[errorKey] : null,
              helperText: helperText,
              filled: readOnly,
              fillColor: readOnly ? Colors.grey.shade100 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required dynamic value,
    required List<OptionModel> items,
    required Function(dynamic) onChanged,
    String? errorKey,
    bool isMap = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: (items.isNotEmpty) ? value?.toString() : null,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              errorText: errorKey != null ? errors[errorKey] : null,
            ),
            items: items.map<DropdownMenuItem<String>>((item) {
              return DropdownMenuItem<String>(
                value: item.value.toString(), // ép int -> String
                child: Text(item.text),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          )
        ],
      ),
    );
  }
}
