import 'dart:convert'; // Đã có, dùng cho jsonEncode
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';       // Gói quét v4
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart'; // Gói cầu nối v1.1.0
import 'package:ndef_record/ndef_record.dart';     // Gói chứa NdefRecord (MỚI)

// Enum để quản lý trạng thái giao diện
enum NfcStatus { ready, scanning, success, error }

class NfcWriterScreen extends StatefulWidget {
  const NfcWriterScreen({super.key});

  @override
  State<NfcWriterScreen> createState() => _NfcWriterScreenState();
}

class _NfcWriterScreenState extends State<NfcWriterScreen> {
  // ✅ THAY ĐỔI: Dùng 3 controllers cho 3 trường dữ liệu
  final _idCayController = TextEditingController();
  final _tuoiCayController = TextEditingController();
  final _maCayController = TextEditingController();

  NfcStatus _status = NfcStatus.ready;
  String _feedbackMessage = 'Nhập dữ liệu và nhấn "Bắt đầu ghi"';

  @override
  void dispose() {
    // ✅ THAY ĐỔI: Dispose cả 3 controllers
    _idCayController.dispose();
    _tuoiCayController.dispose();
    _maCayController.dispose();
    NfcManager.instance.stopSession();
    super.dispose();
  }

  /// Bắt đầu quá trình ghi dữ liệu lên thẻ NFC
  Future<void> _startNfcWriting() async {
    NfcAvailability availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      if (!mounted) return;
      setState(() {
        _status = NfcStatus.error;
        _feedbackMessage = 'NFC không được bật hoặc không được hỗ trợ.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _status = NfcStatus.scanning;
      _feedbackMessage = 'Đang chờ thẻ NFC...\nVui lòng đưa thẻ lại gần điện thoại.';
    });

    try {
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            var ndef = Ndef.from(tag); // Lấy từ nfc_manager_ndef
            if (ndef == null) {
              _updateStatus(NfcStatus.error, 'Thẻ này không hỗ trợ NDEF.');
              return;
            }

            if (!ndef.isWritable) {
              _updateStatus(NfcStatus.error, 'Thẻ này không thể ghi.');
              return;
            }

            // ✅ THAY ĐỔI: Lấy dữ liệu từ 3 controllers
            final idCay = _idCayController.text;
            final tuoiCay = _tuoiCayController.text;
            final maCay = _maCayController.text;

            if (idCay.isEmpty || tuoiCay.isEmpty || maCay.isEmpty) {
              _updateStatus(NfcStatus.error, 'Dữ liệu không được để trống.');
              return;
            }

            // 1. ✅ TẠO MAP (ĐỐI TƯỢNG) TỪ DỮ LIỆU
            final dataMap = {
              'idCay': idCay,
              'tuoiCay': int.tryParse(tuoiCay) ?? 0, // Chuyển tuổi sang số
              'maCay': maCay,
            };

            // 2. ✅ CHUYỂN ĐỔI MAP THÀNH CHUỖI JSON
            final dataToWrite = jsonEncode(dataMap);

            // 3. TẠO RECORD TỪ CHUỖI JSON (dùng hàm helper cũ)
            final record = _createNdefTextRecord(dataToWrite, languageCode: 'vi');
            final message = NdefMessage(records: [record]);

            await ndef.write(message: message);

            _updateStatus(NfcStatus.success, 'Đã ghi thành công dữ liệu:\n$dataToWrite');

          } catch (e) {
            _updateStatus(NfcStatus.error, 'Ghi thẻ thất bại. Vui lòng thử lại: $e');
          }
        },
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
      );
    } catch (e) {
      _updateStatus(NfcStatus.error, 'Lỗi khi bắt đầu phiên NFC: $e');
    }
  }

  // Hàm helper để cập nhật trạng thái và dừng phiên NFC
  void _updateStatus(NfcStatus status, String message) {
    NfcManager.instance.stopSession().catchError((_) {});
    if (mounted) {
      setState(() {
        _status = status;
        _feedbackMessage = message;
      });
    }
  }

  //
  // ✅ HÀM HELPER NÀY GIỮ NGUYÊN (Nó chỉ cần 1 chuỗi, JSON là 1 chuỗi)
  //
  NdefRecord _createNdefTextRecord(String text, {String languageCode = 'en'}) {
    final langBytes = utf8.encode(languageCode);
    final textBytes = utf8.encode(text);
    final status = langBytes.length;
    final payload = Uint8List.fromList([status, ...langBytes, ...textBytes]);
    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x54]), // Type = 'T' (Text)
      identifier: Uint8List(0),
      payload: payload,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi thẻ NFC (JSON)'), // ✅ Đổi tiêu đề
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusIndicator(),
            const SizedBox(height: 32),

            // ✅ THAY ĐỔI: 3 TextFields cho 3 dữ liệu
            TextField(
              controller: _idCayController,
              decoration: InputDecoration(
                labelText: 'ID Cây',
                hintText: 'VD: 12345',
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tuoiCayController,
              keyboardType: TextInputType.number, // Bàn phím số
              decoration: InputDecoration(
                labelText: 'Tuổi Cây (năm)',
                hintText: 'VD: 2',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _maCayController,
              decoration: InputDecoration(
                labelText: 'Mã Cây (Lô/Vườn)',
                hintText: 'VD: L001_A1',
                prefixIcon: const Icon(Icons.article_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _status == NfcStatus.scanning ? null : _startNfcWriting,
              icon: _status == NfcStatus.scanning
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.nfc),
              label: Text(_status == NfcStatus.scanning ? 'Đang quét...' : 'Bắt đầu ghi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget hiển thị trạng thái (icon và text)
  Widget _buildStatusIndicator() {
    IconData icon;
    Color color;
    switch (_status) {
      case NfcStatus.scanning:
        icon = Icons.sensors;
        color = Colors.blue;
        break;
      case NfcStatus.success:
        icon = Icons.check_circle_outline_rounded;
        color = Colors.green;
        break;
      case NfcStatus.error:
        icon = Icons.error_outline_rounded;
        color = Colors.red;
        break;
      default:
        icon = Icons.nfc_rounded;
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Column(
        children: [
          Icon(icon, size: 64, color: color),
          const SizedBox(height: 16),
          Text(
            _feedbackMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}