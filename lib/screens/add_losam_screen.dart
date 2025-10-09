import 'dart:convert';
import 'dart:io';

import 'package:csam_mobile/api/api_caytrong.dart';
import 'package:csam_mobile/api/api_option.dart';
import 'package:csam_mobile/models/option_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../api/api.dart';
import '../models/vuontrong/losam_model.dart';
import '../models/vuontrong/losamcamera_model.dart';
import '../models/vuontrong/losamchitiet_model.dart';

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
  final int farmId;
  final int? zoneid;
  final Function(Map<String, dynamic> data, int id, {File? image}) onSubmit;

  const AddLoSamScreen({
    Key? key,
    required this.farmId,
    this.zoneid,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _AddLoSamScreenState createState() => _AddLoSamScreenState();
}

class _AddLoSamScreenState extends State<AddLoSamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  File? _selectedImage;
  String? _selectedImageUrl;
  final ImagePicker _picker = ImagePicker();
  TextEditingController? maLoController;
  TextEditingController? tenLoController;
  TextEditingController? loaiLoController;
  TextEditingController? ghichuLoController;
  List<TextEditingController?> rtspControllers = [];
  // Form data
  late LoSamFormData loSamData;
  List<LoSamChiTietModel> chiTiets = [];
  List<LoSamCameraModel> cameras = [];
  List<OptionModel> OptionLoSamLoaiTuoi = [];
  List<OptionModel> OptionLoaiCamera = [];
  LoSamModel? losam;
  Map<String, String> errors = {};
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadData(); // Gọi hàm async để chờ xong việc khởi tạo
  }

  Future<void> _loadData() async {
    loSamData = LoSamFormData(
      maLo: '',
      tenLo: '',
      soHang: 1,
      soCot: 1,
      dienTich: 0,
      ghiChu: '',
      loai: '',
      trangThai: 1,
      vuonTrongId: widget.farmId ?? 1,
    );
    await _initializeData();
    if (mounted) {
      setState(() {
        _isLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    maLoController?.dispose();
    tenLoController?.dispose();
    ghichuLoController?.dispose();
    loaiLoController?.dispose();
    for (var c in rtspControllers) {
      c?.dispose();
    }
    super.dispose();
  }

  // void _removeImage() {
  //   setState(() {
  //     _selectedImage = null;
  //   });
  // }

  Future<void> _initializeData() async {
    final api = API();

    final apiOptinlt = await api.OptionLoSamLoaiTuoi();
    if (!mounted) return;
    if (apiOptinlt != null) {
      setState(() {
        OptionLoSamLoaiTuoi = apiOptinlt;
      });
    }

    final apiOptincmr = await api.OptionLoSamLoaiCamera();
    if (!mounted) return;
    if (apiOptincmr != null) {
      setState(() {
        OptionLoaiCamera = apiOptincmr;
      });
    }

    if (widget.zoneid != null) {
      losam = await api.getLoSamById(widget.zoneid ?? 0);
      if (!mounted) return;

      setState(() {
        loSamData.maLo = losam?.maLo ?? "";
        loSamData.tenLo = losam?.tenLo ?? "";
        loSamData.soHang = losam?.soHang ?? 0;
        loSamData.soCot = losam?.soCot ?? 0;
        loSamData.ghiChu = losam?.ghiChu ?? "";
        loSamData.loai = losam?.loai ?? "";
        chiTiets = losam?.loSamChiTiets ?? [];
        cameras = losam?.loSamCameras ?? [];
        maLoController = TextEditingController(text: loSamData.maLo);
        tenLoController = TextEditingController(text: loSamData.tenLo);
        loaiLoController = TextEditingController(text: loSamData.loai);
        ghichuLoController = TextEditingController(text: losam?.ghiChu);
        rtspControllers =
            cameras.map((c) => TextEditingController(text: c.rtsp)).toList();
      });

      final hinhLo = losam?.hinhAnh;

      if (hinhLo?.isNotEmpty ?? false) {
        if (hinhLo!.startsWith('http')) {
          if (!mounted) return;
          setState(() {
            _selectedImageUrl = hinhLo;
            _selectedImage = null;
          });
        } else {
          final file = await base64ToFile(hinhLo, "anh_lo.jpg");
          if (!mounted) return;
          setState(() {
            _selectedImage = file;
            _selectedImageUrl = null;
          });
        }
      }
    }
  }

  Future<File> base64ToFile(String base64String, String fileName) async {
    final bytes = base64Decode(base64String);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageUrl = null;
    });
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
      chiTiets.add(LoSamChiTietModel(
        id: 0,
        loSamId: widget.zoneid ?? 0,
        loSamLoaiTuoiId: 1,
        soLuong: 0,
        trangThai: 1,
      ));
    });
  }

  void _removeChiTiet(int index) {
    setState(() {
      chiTiets.removeAt(index);
    });
  }

  void _updateChiTiet(int index, String field, dynamic value) {
    final oldItem = chiTiets[index];

    final updatedItem = LoSamChiTietModel(
      id: oldItem.id,
      loSamId: oldItem.loSamId,
      loSamLoaiTuoiId: field == 'loSamLoaiTuoiId'
          ? (value is int ? value : int.tryParse(value.toString()) ?? 1)
          : oldItem.loSamLoaiTuoiId,
      soLuong: field == 'soLuong'
          ? (value is int ? value : int.tryParse(value.toString()) ?? 0)
          : oldItem.soLuong,
      trangThai: 1,
    );

    setState(() {
      chiTiets[index] = updatedItem;
    });
  }

  void _addCamera() {
    setState(() {
      // Thêm camera mới
      cameras.add(LoSamCameraModel(
        id: 0,
        loSamId: widget.zoneid ?? 0,
        loSamLoaiCameraId: 1,
        trangThai: 1,
        rtsp: '',
        userName: '',
        password: '',
        url: '',
      ));

      // Thêm controller tương ứng
      rtspControllers.add(TextEditingController());
    });
  }

  void _removeCamera(int index) {
    setState(() {
      cameras.removeAt(index);
      rtspControllers.removeAt(index);
    });
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
      ),
    );
  }

  void _updateCamera(int index, String field, dynamic value) {
    final oldItem = cameras[index];

    final updatedItem = LoSamCameraModel(
      id: oldItem.id,
      loSamId: oldItem.loSamId,
      loSamLoaiCameraId: field == 'loSamLoaiCameraId'
          ? (value is int ? value : int.tryParse(value.toString()) ?? 1)
          : oldItem.loSamLoaiCameraId,
      rtsp: field == 'rtsp' ? value?.toString() ?? '' : oldItem.rtsp,
      url: field == 'url' ? value?.toString() ?? '' : oldItem.url,
      trangThai: oldItem.trangThai,
      userName: oldItem.userName,
      password: oldItem.password,
    );

    // 🟡 Không gọi setState nếu chỉ thay đổi RTSP hoặc URL (text)
    if (field == 'loSamLoaiCameraId') {
      setState(() {
        cameras[index] = updatedItem;
      });
    } else {
      cameras[index] = updatedItem; // cập nhật dữ liệu nhưng không rebuild
    }
  }



  bool _validateForm() {
    errors.clear();

    if (loSamData.maLo.trim().isEmpty) {
      errors['maLo'] = 'Mã lô là bắt buộc';
    } else if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(loSamData.maLo)) {
      errors['maLo'] =
          'Mã lô chỉ được chứa chữ cái không dấu và số, không ký tự đặc biệt';
    }

    if (loSamData.tenLo.trim().isEmpty) {
      errors['tenLo'] = 'Tên lô là bắt buộc';
    }

    if (loSamData.loai.isEmpty) {
      errors['loai'] = 'Loại lô là bắt buộc';
    }

    if (loSamData.soHang < 1) {
      errors['soHang'] = 'Số hàng phải lớn hơn 0';
    }

    if (loSamData.soCot < 1) {
      errors['soCot'] = 'Số cột phải lớn hơn 0';
    }
    // if(_selectedImage == null){
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Vui lòng tải hình ảnh của lô sâm'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    // }

    // Validate chi tiets
    for (int i = 0; i < chiTiets.length; i++) {
      if (chiTiets[i].soLuong < 0) {
        errors['chiTiet_${i}_soLuong'] = 'Số lượng không được âm';
      }
    }

    // Validate cameras
    // for (int i = 0; i < cameras.length; i++) {
    //   if (cameras[i].rtsp.isNotEmpty &&
    //       !cameras[i].rtsp.startsWith('rtsp://')) {
    //     errors['camera_${i}_rtsp'] = 'RTSP phải bắt đầu với rtsp://';
    //   }
    //   if (cameras[i].url.isNotEmpty && !cameras[i].url.startsWith('http')) {
    //     errors['camera_${i}_url'] =
    //         'URL phải bắt đầu với http:// hoặc https://';
    //   }
    // }

    setState(() {});
    return errors.isEmpty;
  }

  void _handleSubmit() {
    if (!_validateForm()) {
      return;
    }

    final submitData = {
      'LoSam': {
        'MaLo': maLoController?.text,
        'TenLo': tenLoController?.text,
        'SoHang': loSamData.soHang,
        'SoCot': loSamData.soCot,
        'DienTich': loSamData.dienTich,
        'GhiChu': ghichuLoController?.text,
        'Loai': loaiLoController?.text,
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
      'LoSamCameras': List.generate(
          cameras.length,
          (index) => {
                'LoSamLoaiCameraId': cameras[index].loSamLoaiCameraId,
                'RTSP': rtspControllers[index]?.text, // 🔹 lấy từ controller
                'Url': cameras[index].url,
                'TrangThai': cameras[index].trangThai,
              }),
    };

    widget.onSubmit(submitData, losam?.loSamId ?? 0, image: _selectedImage);
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
          _selectedImageUrl = null;
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
          _selectedImageUrl = null;
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
      appBar: widget.zoneid == null
          ? AppBar(
              title: const Text('Thêm lô'),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : AppBar(
              title: const Text('Chỉnh sửa lô'),
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
      body: _isLoaded
          ? Form(
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
                          controller: maLoController,
                          onChanged: (value) => _updateLoSamData('maLo', value),
                          errorKey: 'maLo',
                          hintText: 'VD: T001',
                        ),
                        _buildTextField(
                          label: 'Tên lô *',
                          controller: tenLoController,
                          onChanged: (value) =>
                              _updateLoSamData('tenLo', value),
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
                          label: 'Loại lô *',
                          controller: loaiLoController,
                          onChanged: (value) => _updateLoSamData('loai', value),
                          errorKey: 'loai',
                          hintText: 'VD: Mái vòm,..',
                        ),
                        _buildTextField(
                          label: 'Ghi chú',
                          controller: ghichuLoController,
                          onChanged: (value) =>
                              _updateLoSamData('ghiChu', value),
                          maxLines: 3,
                          hintText: 'Ghi chú về lô sâm...',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hình ảnh lô',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Image Preview
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade50,
                              ),
                              child: (_selectedImage != null ||
                                      _selectedImageUrl != null)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        children: [
                                          // Nếu có URL thì hiển thị từ server
                                          if (_selectedImageUrl != null)
                                            Image.network(
                                              _selectedImageUrl!,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                              loadingBuilder:
                                                  (context, child, progress) {
                                                if (progress == null)
                                                  return child;
                                                return const Center(
                                                    child:
                                                        CircularProgressIndicator());
                                              },
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  _buildErrorImage(),
                                            )
                                          // Nếu có file local thì hiển thị File
                                          else if (_selectedImage != null)
                                            Image.file(
                                              _selectedImage!,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  _buildErrorImage(),
                                            ),

                                          // Nút xóa ảnh
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: _removeImage,
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding:
                                                    const EdgeInsets.all(4),
                                                child: const Icon(Icons.close,
                                                    color: Colors.white,
                                                    size: 20),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image,
                                            size: 48,
                                            color: Colors.grey.shade400),
                                        const SizedBox(height: 8),
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

                            const SizedBox(height: 16),

                            // Upload Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _showImagePickerDialog,
                                icon: const Icon(Icons.camera_alt),
                                label: Text(
                                  (_selectedImage != null ||
                                          _selectedImageUrl != null)
                                      ? 'Thay đổi ảnh'
                                      : 'Chọn ảnh',
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            Text(
                              'Hỗ trợ định dạng: JPG, PNG, GIF (tối đa 5MB)',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDynamicSection(
                      title: 'Chi tiết lô',
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
                        widget.zoneid == null ?
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
                        ):
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Chỉnh sửa'),
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
            ) :const Center(child: CircularProgressIndicator()),
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
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Header
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

            // 🔹 Danh sách chi tiết
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Chưa có dữ liệu',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Column(
                children: List.generate(items.length, (index) {
                  return Container(
                    key: ValueKey(
                        items[index]), // 🔸 giúp Flutter rebuild đúng item
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Header mỗi chi tiết
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Chi tiết #${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => onRemove(index),
                              tooltip: 'Xóa chi tiết',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 🔹 Nội dung item
                        itemBuilder(index),
                      ],
                    ),
                  );
                }),
              ),
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
                    controller: rtspControllers[index],
                    onChanged: (value) => _updateCamera(index, 'rtsp', value),
                    errorKey: 'camera_${index}_rtsp',
                    hintText: 'rtsp://camera-ip:port/stream',
                  ),
                ),
                // const SizedBox(width: 16),
                // Expanded(
                //   child: _buildTextField(
                //     label: 'Web URL',
                //     controller: urlControllers[index],
                //     onChanged: (value) => _updateCamera(index, 'url', value),
                //     errorKey: 'camera_${index}_url',
                //     hintText: 'http://camera-web-interface',
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController? controller,
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
            controller: controller,
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
            key: ValueKey(value), // 🔹 Buộc rebuild khi value thay đổi
            initialValue: value.toString(),
            onChanged: (val) {
              num parsedValue;

              if (isDouble) {
                parsedValue = double.tryParse(val) ?? 0;
              } else {
                parsedValue = int.tryParse(val) ?? 0;
              }

              // Nếu có min thì đảm bảo giá trị không nhỏ hơn min
              if (min != null && parsedValue < min) {
                parsedValue = min;
              }

              onChanged(parsedValue);
            },
            keyboardType: TextInputType.numberWithOptions(
              decimal: isDouble,
              signed: false,
            ),
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
          DropdownButtonFormField<int>(
            // 🔹 Giữ giá trị là int thay vì String
            value: value is int ? value : int.tryParse(value?.toString() ?? ''),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              errorText: errorKey != null ? errors[errorKey] : null,
            ),
            items: items.map<DropdownMenuItem<int>>((item) {
              final intVal = int.tryParse(item.value.toString()) ?? 0;
              return DropdownMenuItem<int>(
                value: intVal,
                child: Text(item.text),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                onChanged(newValue); // 🔹 Trả lại int thật sự
              }
            },
          ),
        ],
      ),
    );
  }
}
