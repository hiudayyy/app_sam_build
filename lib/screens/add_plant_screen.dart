import 'dart:convert';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:nftsam/api/api_option.dart';
import 'package:nftsam/models/vuontrong/caysam_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../api/api.dart';
import '../models/option_model.dart';

class AddPlantScreen extends StatefulWidget {
  final Function(Map<String, dynamic>, List<File?>,String? caysamid) onSubmit;
  final VoidCallback onCancel;
  final String? gridPosition;
  final int? losamId;
  final String? areaId;
  final CaySamModel? caysam;
  final String? EditNhatKy;

  const AddPlantScreen({
    Key? key,
    required this.onSubmit,
    required this.onCancel,
    this.gridPosition,
    this.losamId,
    this.areaId,
    this.caysam,
    this.EditNhatKy,
  }) : super(key: key);

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _maCayController = TextEditingController();
  final _tenCayController = TextEditingController();
  final _loaiCayController = TextEditingController();
  final _viTriController = TextEditingController();
  final _gridPositionController = TextEditingController();
  final _soLaController = TextEditingController();
  final _TrongluongController = TextEditingController();
  String? _tuoicay;
  String? _diemSucKhoe;
  String? _tinhTrang;
  int? _sola;
  File? _selectedImageTQ;
  File? _selectedImageCT;
  String? _selectedImageTQUrl;
  String? _selectedImageCTUrl;
  final ImagePicker _picker = ImagePicker();
  List<OptionModel> OptionLoSamLoaiTuoi = [];
  List<OptionModel> OptionLoSamTinhTrang = [];
  List<OptionModel> OptionLoSamDiemSucKhoe = [];

  // BIẾN MỚI
  bool _sendNotification = true;
  final _ghiChuController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _initializeFields();
    _initializeData();
  }

  void _removeImageTQ() {
    setState(() {
      _selectedImageTQ = null;
      _selectedImageTQUrl = null;
    });
  }

  void _removeImageCT() {
    setState(() {
      _selectedImageCT = null;
      _selectedImageCTUrl = null;
    });
  }

  Future<void> _showImagePickerDialogTQ() async {
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
                  _takePhotoTQ();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageTQ();
                },
              ),
              if (_selectedImageTQ != null || _selectedImageTQUrl != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Xóa ảnh', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImageTQ();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showImagePickerDialogCT() async {
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
                  _takePhotoCT();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageCT();
                },
              ),
              if (_selectedImageCT != null || _selectedImageCTUrl != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Xóa ảnh', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImageCT();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<File> testCompressAndGetFile(File file, String targetPath) async {
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,      // Chất lượng 80%
      minWidth: 1024,   // Ép chiều rộng về 1024
      minHeight: 1024,  // Ép chiều cao về 1024
      rotate: 0,        // Giữ nguyên góc xoay
    );

    // Nếu nén lỗi thì trả về file gốc, còn ngon thì trả về file đã nén
    return result != null ? File(result.path) : file;
  }
  Future<void> _pickImageTQ() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        File originalFile = File(image.path);
        final Directory tempDir = await getTemporaryDirectory();
        final String targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        File compressedFile = await testCompressAndGetFile(originalFile, targetPath);
        setState(() {
          _selectedImageTQ = compressedFile;
          _selectedImageTQUrl = null;
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

  Future<File> base64ToFile(String base64Str, String filename) async {
    final bytes = base64Decode(base64Str);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _takePhotoTQ() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        File originalFile = File(image.path);
        final Directory tempDir = await getTemporaryDirectory();
        final String targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        File compressedFile = await testCompressAndGetFile(originalFile, targetPath);
        setState(() {
          _selectedImageTQ = compressedFile;
          _selectedImageTQUrl = null;
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

  Future<void> _pickImageCT() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        File originalFile = File(image.path);
        final Directory tempDir = await getTemporaryDirectory();
        final String targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        File compressedFile = await testCompressAndGetFile(originalFile, targetPath);
        setState(() {
          _selectedImageCT = compressedFile;
          _selectedImageCTUrl = null;
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

  Future<void> _takePhotoCT() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        File originalFile = File(image.path);
        final Directory tempDir = await getTemporaryDirectory();
        final String targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        File compressedFile = await testCompressAndGetFile(originalFile, targetPath);
        setState(() {
          _selectedImageCT = compressedFile;
          _selectedImageCTUrl = null;
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

  void _initializeFields() {
    if (widget.gridPosition != null) {
      _gridPositionController.text = widget.gridPosition!;
    }
    if((widget.areaId ?? "").isNotEmpty && (widget.gridPosition ?? "").isNotEmpty) {
      _maCayController.text = '${widget.areaId}_${widget.gridPosition}';
    }else{
      _maCayController.text = widget.caysam?.maCaySam ?? "";
    }
    if (widget.gridPosition != null) {
      _viTriController.text = '${widget.gridPosition}';
    }
    _loaiCayController.text = 'Panax vietnamensis';
    _tenCayController.text = 'Sâm Ngọc Linh';
  }

  Future<void> _initializeData() async {
    final api = API();
    final apiOptinlt = await api.OptionLoSamLoaiTuoi();
    if (apiOptinlt != null) {
      setState(() {
        OptionLoSamLoaiTuoi = apiOptinlt;
      });
    }
    final apiOptintt = await api.OptionLoSamTinhTrang();
    if (apiOptintt != null) {
      setState(() {
        OptionLoSamTinhTrang = apiOptintt;
      });
    }
    final apiOptindsk = await api.OptionLoSamDiemSucKhoe();
    if (apiOptindsk != null) {
      setState(() {
        OptionLoSamDiemSucKhoe = apiOptindsk;
      });
    }
    _tuoicay = widget.caysam?.tuoiCayId.toString() ?? "";
    _tinhTrang = widget.caysam?.caySamNhatKys.first?.tinhTrang.toString() ?? "";

    if (widget.caysam != null && widget.EditNhatKy == null) {
      _viTriController.text = widget.caysam?.viTriTrongLo ?? "";

      _soLaController.text =
          widget.caysam?.caySamNhatKys.first?.soLa.toString() ?? "";
      _TrongluongController.text = widget.caysam?.caySamNhatKys.firstOrNull?.trongLuong?.toString() ?? "";
      _diemSucKhoe =
          widget.caysam?.caySamNhatKys.first?.diemSucKhoe.toString() ?? "";
      final hinhTQ = widget.caysam?.caySamNhatKys.first?.hinhAnhTongQuan;
      final hinhCT = widget.caysam?.caySamNhatKys.first?.hinhAnhChiTiet;
      if (hinhTQ != null) {
        if (hinhTQ.startsWith('http')) {
          _selectedImageTQUrl = hinhTQ;
          _selectedImageTQ = null;
        } else {
          _selectedImageTQ = await base64ToFile(hinhTQ, "anh_tq.jpg");
          _selectedImageTQUrl = null;
        }
      }
      if (hinhCT != null) {
        if (hinhCT.startsWith('http')) {
          _selectedImageCTUrl = hinhCT;
          _selectedImageCT = null;
        } else {
          _selectedImageCT = await base64ToFile(hinhCT, "anh_ct.jpg");
          _selectedImageCTUrl = null;
        }
      }
    }
  }

  @override
  void dispose() {
    _maCayController.dispose();
    _tenCayController.dispose();
    _loaiCayController.dispose();
    _viTriController.dispose();
    _gridPositionController.dispose();
    _soLaController.dispose();
    _ghiChuController.dispose(); // Dọn dẹp controller mới
    super.dispose();
  }

  void _handleSubmit() {
    double trongLuong = double.tryParse(_TrongluongController.text.replaceAll(',', '.')) ?? 0.0;
    if (_formKey.currentState!.validate()) {
      final plantData = {
        "CaySam": {
          "LoSam_ID": widget.losamId,
          "ViTriTrongLo": _viTriController.text,
          "MaCaySam": _maCayController.text,
          "TuoiCay_ID": int.parse(_tuoicay ?? "")
        },
        "CaySamNhatKy": {
          "NgayGhi": DateTime.now().toIso8601String(),
          "SoLa": int.parse(_soLaController.text ?? ""),
          "DiemSucKhoe": int.parse(_diemSucKhoe ?? ""),
          "TinhTrang": int.parse(_tinhTrang ?? ""),
          "TrongLuong" : trongLuong,
        },
      };
      widget.onSubmit(
        plantData,
        [_selectedImageTQ, _selectedImageCT],
          null,
      );
    }
  }

  void _handleSubmitnk() {
    double trongLuong = double.tryParse(_TrongluongController.text.replaceAll(',', '.')) ?? 0.0;
    if (_formKey.currentState!.validate()) {
      bool isAnhTongQuan = _selectedImageTQ != null;
      final plantData = {
        "TuoiId": int.parse(_tuoicay ?? ""),
        "HinhAnh": isAnhTongQuan,
        "CaySamNhatKy": {
          "NgayGhi": DateTime.now().toIso8601String(),
          "SoLa": int.parse(_soLaController.text ?? ""),
          "DiemSucKhoe": int.parse(_diemSucKhoe ?? ""),
          "TinhTrang": int.parse(_tinhTrang ?? ""),
          "GhiChu": _ghiChuController.text,
          "IsThongBao": _sendNotification,
          "TrongLuong" : trongLuong,
        },
      };
      widget.onSubmit(
        plantData,
        [_selectedImageTQ, _selectedImageCT],
          widget.caysam?.caySamId.toString()
      );
    }
  }

  void _handleSubmitnktm() {
    double trongLuong = double.tryParse(_TrongluongController.text.replaceAll(',', '.')) ?? 0.0;
    if (_formKey.currentState!.validate()) {
      final plantData = {
        "CaySamId": widget.caysam?.caySamId,
        "NgayGhi": DateTime.now().toIso8601String(),
        "SoLa": int.parse(_soLaController.text ?? ""),
        "DiemSucKhoe": int.parse(_diemSucKhoe ?? ""),
        "TinhTrang": int.parse(_tinhTrang ?? ""),
        "GhiChu": _ghiChuController.text,
        "IsThongBao": _sendNotification,
        "TrongLuong" : trongLuong,
      };
      widget.onSubmit(
        plantData,
        [_selectedImageTQ, _selectedImageCT],
          widget.caysam?.caySamId.toString()
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
              () {
            if (widget.caysam == null) {
              return 'Thêm cây mới${widget.gridPosition != null ? ' - Ô ${widget.gridPosition}' : ''}';
            }
            if (widget.EditNhatKy == null) {
              return "Cập nhật nhật ký";
            }
            return 'Thêm mới nhật ký${widget.gridPosition != null ? ' - Ô ${widget.gridPosition}' : ''}';
          }(),
        ),
        backgroundColor: widget.caysam != null
            ? Colors.blue.shade600
            : Colors.green.shade600,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                TextFormField(
                  controller: _maCayController,
                  decoration: InputDecoration(
                    labelText: 'Mã cây sâm',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.lock, color: Colors.grey),
                    helperText: 'Mã tự động: {mã_lô}_{vị_trí_ô}',
                  ),
                  readOnly: true,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _gridPositionController,
                  decoration: InputDecoration(
                    labelText: 'Vị trí trong lô',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.grid_3x3, color: Colors.grey),
                  ),
                  readOnly: true,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _soLaController,
                  decoration: const InputDecoration(
                    labelText: 'Số lá',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.format_list_numbered),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    _sola = int.tryParse(value) ?? 0;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Vui lòng nhập số lá';
                    if (int.tryParse(value) == null) return 'Chỉ được nhập số';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: OptionLoSamLoaiTuoi.any((opt) => opt.value == _tuoicay)
                      ? _tuoicay
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Tuổi của cây trồng',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timeline),
                  ),
                  items: OptionLoSamLoaiTuoi.map((opt) {
                    dynamic icon;
                    switch (opt.value) {
                      case '1':
                        icon = FontAwesomeIcons.seedling;
                        break;
                      case '2':
                        icon = FontAwesomeIcons.leaf;
                        break;
                      case '3':
                        icon = Icons.park;
                        break;
                      case '4':
                        icon = Icons.forest;
                        break;
                      default:
                        icon = Icons.help_outline;
                    }

                    return DropdownMenuItem<String>(
                      value: opt.value,
                      child: Row(
                        children: [
                          FaIcon(icon, size: 18, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(opt.text),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _tuoicay = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: OptionLoSamDiemSucKhoe.any((opt) => opt.value == _diemSucKhoe)
                      ? _diemSucKhoe
                      : null, // Nếu giá trị là null, validator sẽ bắt được
                  decoration: const InputDecoration(
                    labelText: 'Sức khỏe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_heart),
                  ),
                  // --- THÊM PHẦN NÀY ---
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng chọn mức độ sức khỏe'; // Dòng chữ đỏ sẽ hiện ra
                    }
                    return null; // Hợp lệ
                  },
                  // ---------------------
                  items: OptionLoSamDiemSucKhoe.map((opt) {
                    Color color;
                    switch (opt.value) {
                      case '5':
                        color = Colors.green;
                        break;
                      case '4':
                        color = Colors.blue;
                        break;
                      case '3':
                        color = Colors.yellow;
                        break;
                      case '2':
                        color = Colors.orange;
                        break;
                      case '1':
                        color = Colors.red;
                        break;
                      default:
                        color = Colors.grey;
                    }

                    return DropdownMenuItem<String>(
                      value: opt.value,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration:
                            BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(opt.text),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _diemSucKhoe = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: OptionLoSamTinhTrang.any(
                          (opt) => opt.value == _tinhTrang)
                      ? _tinhTrang
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Tình Trạng',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.assignment),
                  ),
                  items: OptionLoSamTinhTrang.map((opt) {
                    Color color;
                    switch (opt.value) {
                      case '1':
                        color = Colors.green;
                        break;
                      case '2':
                        color = Colors.blue;
                        break;
                      case '3':
                        color = Colors.red;
                        break;
                      default:
                        color = Colors.grey;
                    }

                    return DropdownMenuItem<String>(
                      value: opt.value,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(opt.text),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _tinhTrang = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _TrongluongController,
                  decoration: const InputDecoration(
                    labelText: 'Trọng lượng',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_weight),
                    suffixText: '(gram)',
                    // Hoặc dùng suffixStyle nếu muốn chỉnh font chữ
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (value) {
                    // Xử lý giá trị khi nhập
                    if (value.isEmpty) {
                      // Xử lý khi xóa hết
                    } else {
                      double? weight = double.tryParse(value);
                    }
                  },
                ),
                if (widget.caysam != null)
                  CheckboxListTile(
                    title: const Text("Gửi thông báo"),
                    value: _sendNotification,
                    onChanged: (bool? value) {
                      setState(() {
                        _sendNotification = value ?? false;
                      });
                    },
                    secondary: const Icon(Icons.notifications_active_outlined),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: Theme.of(context).primaryColorDark,
                  ),
                if (widget.caysam != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    controller: _ghiChuController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note_alt_outlined),
                      hintText: 'VD: Cây bị sâu bệnh, úng nước...',
                    ),
                    validator: (value) {
                      if (_sendNotification) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập ghi chú khi gửi thông báo.';
                        }
                      }
                      return null;
                    },
                  ),
                ),

                // ===== KẾT THÚC WIDGET MỚI =====
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Icon mới
                            Icon(
                              Icons.image_outlined,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 12),
                            // Text của bạn
                            const Text(
                              'Hình ảnh',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        // Sử dụng Row để đặt 2 uploader cạnh nhau
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Uploader cho Ảnh tổng quan
                            Expanded(
                              child: _buildImageUploader(
                                title: 'Ảnh tổng quan',
                                selectedImageFile: _selectedImageTQ,
                                selectedImageUrl: _selectedImageTQUrl,
                                onPick: _showImagePickerDialogTQ,
                                onRemove: _removeImageTQ,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Uploader cho Ảnh chi tiết
                            Expanded(
                              child: _buildImageUploader(
                                title: 'Ảnh chi tiết',
                                selectedImageFile: _selectedImageCT,
                                selectedImageUrl: _selectedImageCTUrl,
                                onPick: _showImagePickerDialogCT,
                                onRemove: _removeImageCT,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Hỗ trợ: JPG, PNG (tối đa 5MB)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onCancel,
                        icon: Icon(Icons.close),
                        label: Text('Hủy'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey),
                          foregroundColor: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (widget.caysam == null) {
                            _handleSubmit();
                          } else {
                            if (widget.EditNhatKy == null) {
                              _handleSubmitnk();
                            } else {
                              _handleSubmitnktm();
                            }
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: Text(() {
                          if (widget.caysam == null) {
                            return 'Lưu';
                          }
                          if (widget.EditNhatKy == null) {
                            return 'Lưu';
                          }
                          return 'Lưu';
                        }()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: () {
                            if (widget.caysam == null)
                              return Colors.green.shade600;
                            if (widget.EditNhatKy == null) {
                              return Colors.blue.shade600;
                            }
                            return Colors.green.shade600;
                          }(),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Text(
        'Ảnh lỗi',
        style: TextStyle(
          color: Colors.red.shade400,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  // ✅ WIDGET HỖ TRỢ ĐÃ ĐƯỢC CẬP NHẬT HOÀN TOÀN VỚI TỶ LỆ 16:9
  Widget _buildImageUploader({
    required String title,
    required File? selectedImageFile,
    required String? selectedImageUrl,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    bool hasImage = selectedImageFile != null || selectedImageUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // Image Preview / Selector Area
        AspectRatio(
          // ✅ THAY ĐỔI TỶ LỆ Ở ĐÂY (TỪ 1 SANG 16/9)
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: selectedImageUrl != null
                          ? Image.network(
                        selectedImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                      )
                          : Image.file(
                        selectedImageFile!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                      ),
                    ),
                  if (!hasImage)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Chọn ảnh',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  if (hasImage)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}