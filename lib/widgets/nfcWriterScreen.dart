import 'dart:convert';
import 'dart:typed_data';
import 'package:csam_mobile/api/api.dart';
import 'package:csam_mobile/api/api_caysam.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:ndef_record/ndef_record.dart';
import '../models/vuontrong/caysam_model.dart';

enum NfcStatus { scanning, success, error }

class NfcWriterModal extends StatefulWidget {
  final CaySamModel plant;
  const NfcWriterModal({super.key, required this.plant});

  @override
  State<NfcWriterModal> createState() => _NfcWriterModalState();
}

class _NfcWriterModalState extends State<NfcWriterModal> {
  NfcStatus _status = NfcStatus.scanning; // Bắt đầu ở trạng thái quét
  String _feedbackMessage = 'Đang chờ thẻ NFC...\nVui lòng đưa thẻ lại gần điện thoại.';

  @override
  void initState() {
    super.initState();
    _startNfcWriting();
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<void> _startNfcWriting() async {
    NfcAvailability availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      _updateStatus(NfcStatus.error, 'NFC không được bật hoặc không được hỗ trợ.');
      return;
    }

    try {
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            var ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) {
              _updateStatus(NfcStatus.error, 'Thẻ này không thể ghi hoặc đã ghi.');
              return;
            }
            final String myLink = 'https://nft.samnghigia.com/caysam/${widget.plant.caySamId}';
            final String myAndroidPackageName = 'com.example.csam_mobile';
            final dataMap = {
              'caySamId':widget.plant.caySamId,
            };
            final dataToWrite = jsonEncode(dataMap);
            final record = _createNdefTextRecord(dataToWrite, languageCode: 'vi');
            final urirecord = _createNdefUriRecord(myLink);
            final aarRecord = _createNdefExternalRecord(
              'android.com', 'pkg', utf8.encode(myAndroidPackageName),
            );

            final message = NdefMessage(records: [urirecord]);
            await ndef.write(message: message);

            await ndef.writeLock();

            _updateStatus(NfcStatus.success, 'Đã ghi dữ liệu thành công!');
          } catch (e) {
            _updateStatus(NfcStatus.error, 'Ghi thẻ thất bại. Vui lòng thử lại');
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
  Future<void> _updateStatus(NfcStatus status, String message) async {
    NfcManager.instance.stopSession().catchError((_) {});
    if (mounted) {
      setState(() {
        _status = status;
        _feedbackMessage = message;
      });
      if(status == NfcStatus.success){
        await API().updateNFCCaySam( id: widget.plant.caySamId);
      }
      if (status == NfcStatus.success || status == NfcStatus.error) {
        Future.delayed(const Duration(seconds: 2, milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }

    }
  }


  // --- Các hàm tạo NDEF Record (giữ nguyên) ---
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
  NdefRecord _createNdefExternalRecord(String domain, String type, Uint8List payload) {
    final typeBytes = utf8.encode('$domain:$type');
    return NdefRecord(
      typeNameFormat: TypeNameFormat.external,
      type: Uint8List.fromList(typeBytes),
      identifier: Uint8List(0),
      payload: payload,
    );
  }
  NdefRecord _createNdefUriRecord(String uri) {
    Uri parsedUri = Uri.parse(uri);
    String scheme = parsedUri.scheme.toLowerCase();
    String host = parsedUri.host;
    String path = parsedUri.path;
    int prefixByte;
    String remainingPayload;
    if (scheme == 'https') {
      prefixByte = 0x04;
      remainingPayload = '$host$path';
    } else if (scheme == 'http') {
      prefixByte = 0x03;
      remainingPayload = '$host$path';
    } else {
      prefixByte = 0x00;
      remainingPayload = uri;
    }
    final uriBytes = utf8.encode(remainingPayload);
    final payloadBytes = Uint8List.fromList([prefixByte, ...uriBytes]);
    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList(utf8.encode('U')), // 'U'
      identifier: Uint8List(0),
      payload: payloadBytes,
    );
  }

  // --- Giao diện của Popup ---
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getTitle(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ),
          const SizedBox(height: 24),
          _buildStatusIndicator(),
          const SizedBox(height: 16),
          Text(
            _feedbackMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: _getColor()),
          ),
          const SizedBox(height: 24),

          // ✅ CHECKBOX ĐÃ ĐƯỢC XÓA BỎ

          const SizedBox(height: 16),

          if (_status == NfcStatus.scanning)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Hủy'),
              ),
            )
        ],
      ),
    );
  }

  // --- Các hàm build giao diện (giữ nguyên) ---
  String _getTitle() {
    switch (_status) {
      case NfcStatus.scanning: return 'Sẵn sàng quét';
      case NfcStatus.success: return 'Thành công!';
      case NfcStatus.error: return 'Ghi thẻ thất bại!';
    }
  }
  Color _getColor() {
    switch (_status) {
      case NfcStatus.scanning: return Colors.blue.shade700;
      case NfcStatus.success: return Colors.green.shade700;
      case NfcStatus.error: return Colors.red.shade700;
    }
  }
  Widget _buildStatusIndicator() {
    switch (_status) {
      case NfcStatus.scanning:
        return _buildAnimatedIcon(Icons.nfc, Colors.blue.shade700);
      case NfcStatus.success:
        return _buildAnimatedIcon(Icons.check_circle, Colors.green.shade700);
      case NfcStatus.error:
        return _buildAnimatedIcon(Icons.error, Colors.red.shade700);
    }
  }
  Widget _buildAnimatedIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 64, color: color),
    );
  }
}

