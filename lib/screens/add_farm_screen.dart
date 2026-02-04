import 'dart:convert';
import 'dart:io';
import 'package:nftsam/models/option_model.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../api/api.dart';
import '../models/vuontrong/losam_model.dart';
import '../models/vuontrong/vuontrong_model.dart';


class AddFarmScreen extends StatefulWidget {
  final VuonTrongModel?  farmId;
  final Function(VuonTrongModel model) onSubmit;

  const AddFarmScreen({
    Key? key,
    this.farmId,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _AddFarmScreenState createState() => _AddFarmScreenState();
}

class _AddFarmScreenState extends State<AddFarmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  TextEditingController? maLoController;
  TextEditingController? tenLoController;
  TextEditingController? loaiLoController;
  TextEditingController? ghichuLoController;
  // Form data
  late VuonTrongModel vuontrongData;
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
    vuontrongData = VuonTrongModel(
        vuonTrongId: 0,
        tenVuon: '',
        diaChi: '',
        viTri: '',
        ghiChu: '',
        trangThai: 1

    );
    if(widget.farmId != null){
      setState(() {
        vuontrongData = widget.farmId!;
        maLoController = TextEditingController(text: vuontrongData.tenVuon);
        tenLoController= TextEditingController(text: vuontrongData.viTri);
        loaiLoController = TextEditingController(text: vuontrongData.diaChi);
        ghichuLoController = TextEditingController(text: vuontrongData.ghiChu);

      });
    }
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
    super.dispose();
  }

  Future<void> _initializeData() async {
    final api = API();


  }

  Future<File> base64ToFile(String base64String, String fileName) async {
    final bytes = base64Decode(base64String);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  void _updateLoSamData(String field, dynamic value) {
    setState(() {
      switch (field) {
        case 'tenvuon':
          vuontrongData.tenVuon = value.toString();
          break;
        case 'vitri':
          vuontrongData.viTri = value.toString();
          break;
        case 'diachi':
          vuontrongData.diaChi = value.toString();
          break;
        case 'ghiChu':
          vuontrongData.ghiChu = value.toString();
          break;
      }

      // Clear error
      if (errors.containsKey(field)) {
        errors.remove(field);
      }
    });
  }

  bool _validateForm() {
    errors.clear();
    setState(() {
      if (vuontrongData.tenVuon.trim().isEmpty) {
        errors['tenvuon'] = 'Tên vườn là bắt buộc';
      }
      if (vuontrongData.viTri.trim().isEmpty) {
        errors['vitri'] = 'Nhập thông tin vị trí';
      }
    });
    return errors.isEmpty;
  }

  void _handleSubmit() {
    if (!_validateForm()) {
      return;
    }


    widget.onSubmit(vuontrongData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.farmId == null
          ? AppBar(
        title: const Text('Thêm vườn'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      )
          : AppBar(
        title: const Text('Chỉnh sửa vườn'),
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
                    label: 'Tên vườn *',
                    controller: maLoController,
                    onChanged: (value) => _updateLoSamData('tenvuon', value),
                    errorKey: 'tenvuon',
                    hintText: 'VD: Vườn sâm',
                  ),
                  _buildTextField(
                    label: 'Vị trí *',
                    controller: tenLoController,
                    onChanged: (value) =>
                        _updateLoSamData('vitri', value),
                    errorKey: 'vitri',
                    hintText: '',
                  ),
                  _buildTextField(
                    label: 'Địa chỉ',
                    controller: loaiLoController,
                    onChanged: (value) => _updateLoSamData('diachi', value),
                    errorKey: 'diachi',
                    hintText: '',
                  ),
                  _buildTextField(
                    label: 'Ghi chú',
                    controller: ghichuLoController,
                    onChanged: (value) =>
                        _updateLoSamData('ghiChu', value),
                    errorKey: 'ghiChu',
                    maxLines: 3,
                    hintText: 'Ghi chú về vườn...',
                  ),
                ],
              ),

              const SizedBox(height: 16),

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
                  widget.farmId == null ?
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
                          Text('Tạo vườn'),
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
                          Text('Lưu'),
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

}
