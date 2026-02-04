import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndef_record/ndef_record.dart';
import 'package:ndef_record/ndef_record.dart' as ndef hide TypeNameFormat;

// --- IMPORT TỪ FILE CỦA BẠN ---
import 'package:nfc_manager/nfc_manager.dart';
// Nếu IDE báo lỗi không tìm thấy NdefFormatableAndroid, hãy bỏ comment dòng dưới:
import 'package:nfc_manager/nfc_manager_android.dart';

import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:ndef/ndef.dart' as ndef; // Alias 'ndef' để tránh trùng tên
import 'package:vibration/vibration.dart';

class SeederToolScreen extends StatefulWidget {
  const SeederToolScreen({Key? key}) : super(key: key);

  @override
  State<SeederToolScreen> createState() => _SeederToolScreenState();
}

class _SeederToolScreenState extends State<SeederToolScreen> {
  // --- TRẠNG THÁI ---
  bool _isScanning = false;
  String _statusMessage = "Sẵn sàng ghi Text";
  String _lastWrittenInfo = "";
  int _successCount = 0; // Đếm số lượng thẻ đã ghi thành công

  // --- BIẾN CHỐNG LẶP ---
  String? _lastTagHardwareId;
  DateTime? _lastWriteTime;

  @override
  void dispose() {
    NfcManager.instance.stopSession().catchError((_) {});
    super.dispose();
  }

  void _toggleScanning() {
    if (_isScanning) {
      _stopScanning();
    } else {
      _startContinuousSeeding();
    }
  }

  void _stopScanning() {
    NfcManager.instance.stopSession().catchError((_) {});
    setState(() {
      _isScanning = false;
      _statusMessage = "Đã dừng.";
    });
  }

  // --- LOGIC CHÍNH ---
  Future<void> _startContinuousSeeding() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      _showErrorFeedback('NFC chưa bật hoặc không hỗ trợ.');
      return;
    }

    setState(() {
      _isScanning = true;
      _statusMessage = "Đang chạy... (Ốp thẻ vào lưng máy)";
    });

    NfcManager.instance.startSession(
      alertMessageIos: "Chế độ ghi Text liên tục.\nVui lòng giữ yên điện thoại.",
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      onDiscovered: (NfcTag tag) async {
        try {
          String uid = _getTagId(tag);
          if (_lastTagHardwareId == uid &&
              _lastWriteTime != null &&
              DateTime.now().difference(_lastWriteTime!) < const Duration(seconds: 2)) {
            return;
          }
          final String content = "chào mừng đến nfc";
          final textRecord = _createNdefTextRecord(content);
          final message = ndef.NdefMessage( records: [textRecord]);
          var ndefObj = Ndef.from(tag);

          if (ndefObj != null) {
            if (!ndefObj.isWritable) {
              throw Exception('Thẻ bị khóa (Read-only)!');
            }
            await ndefObj.write(message: message);
          } else {
            // Trường hợp 2: Thẻ chưa format (Android)
            if (Platform.isAndroid) {
              var ndefFormatable = NdefFormatableAndroid.from(tag);
              if (ndefFormatable != null) {
                await ndefFormatable.format(message);
              } else {
                throw Exception('Thẻ không hỗ trợ format NDEF.');
              }
            } else {
              throw Exception('Thẻ chưa format.');
            }
          }

          // 5. Phản hồi thành công
          _showSuccessFeedback();

          // Cập nhật trạng thái
          _lastTagHardwareId = uid;
          _lastWriteTime = DateTime.now();
          _successCount++;

          if (mounted) {
            setState(() {
              _lastWrittenInfo = "Nội dung: \"$content\"\nUID Thẻ: $uid";
              _statusMessage = "✅ Đã ghi xong thẻ thứ $_successCount. \n--> VÀO THẺ TIẾP THEO";
            });
          }

        } catch (e) {
          _showErrorFeedback("Lỗi: $e");
        }
      },
    );
  }

  // --- HÀM TẠO TEXT RECORD (THAY THẾ HÀM URI CŨ) ---
  ndef.NdefRecord _createNdefTextRecord(String text) {
    // Mã ngôn ngữ: "en" (tiếng Anh) hoặc "vi" (tiếng Việt)
    // Cấu trúc Text Record: [Status Byte] + [Language Code] + [Text Data]
    final languageCode = 'vi';
    final languageCodeBytes = ascii.encode(languageCode);
    final textBytes = utf8.encode(text);

    // Status byte: Bit 7 = 0 (UTF-8), Bit 5..0 = len(languageCode)
    final statusByte = languageCodeBytes.length;

    final payload = Uint8List.fromList([
      statusByte,
      ...languageCodeBytes,
      ...textBytes,
    ]);

    return ndef.NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x54]), // 0x54 = 'T' (Text)
      identifier: Uint8List(0),
      payload: payload,
    );
  }

  // --- HÀM LẤY ID THẺ (GIỮ NGUYÊN) ---
  String _getTagId(dynamic rawData) {
    List<int>? identifier;
    try {
      if (rawData is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(rawData);
        const techKeys = ['nfcA', 'mifare', 'mifareClassic', 'isodep', 'nfcB', 'nfcF', 'nfcV', 'iso15693'];
        for (var key in techKeys) {
          if (data.containsKey(key) && data[key] is Map) {
            final techData = data[key] as Map;
            if (techData.containsKey('identifier')) {
              identifier = List<int>.from(techData['identifier']);
              break;
            }
          }
        }
        if (identifier == null && data.containsKey('identifier')) {
          identifier = List<int>.from(data['identifier']);
        }
      } else {
        if (identifier == null) { try { final dynamic obj = rawData.miFare; if (obj?.identifier != null) identifier = List<int>.from(obj.identifier); } catch (_) {} }
        if (identifier == null) { try { final dynamic obj = rawData.iso15693; if (obj?.identifier != null) identifier = List<int>.from(obj.identifier); } catch (_) {} }
        if (identifier == null) { try { final dynamic obj = rawData.feliCa; if (obj?.currentIDm != null) identifier = List<int>.from(obj.currentIDm); } catch (_) {} }
        if (identifier == null) { try { final dynamic obj = rawData.iso7816; if (obj?.identifier != null) identifier = List<int>.from(obj.identifier); } catch (_) {} }
      }
    } catch (e) {
      return "";
    }

    if (identifier != null && identifier.isNotEmpty) {
      return identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join('').toUpperCase();
    }
    return "";
  }

  void _showSuccessFeedback() {
    // Cách 1: Dùng âm thanh hệ thống có sẵn của Flutter (Tiếng "tách" nhẹ)
    SystemSound.play(SystemSoundType.click);
    try {
      if (Vibration.hasVibrator() != null) {
        Vibration.vibrate(duration: 100);
      }
    } catch (_) {}
  }

  void _showErrorFeedback(String error) {
    try {
      if (Vibration.hasVibrator() != null) {
        Vibration.vibrate(pattern: [0, 200, 100, 200]);
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _statusMessage = "LỖI: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ghi Text \"chào mừng...\"")),
      backgroundColor: _isScanning ? Colors.green[50] : Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Hiển thị nội dung sẽ ghi
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    Text("NỘI DUNG SẼ GHI:", style: TextStyle(fontSize: 16, color: Colors.grey)),
                    SizedBox(height: 10),
                    Text(
                      "chào mừng đến nfc",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isScanning ? Icons.nfc : Icons.nfc_outlined, size: 80, color: _isScanning ? Colors.green : Colors.grey),
                    const SizedBox(height: 10),
                    Text(_isScanning ? "ĐANG CHẠY..." : "ĐÃ DỪNG", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _isScanning ? Colors.green : Colors.grey)),
                    const SizedBox(height: 20),
                    Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 30),
                    if (_lastWrittenInfo.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.blue, width: 2), borderRadius: BorderRadius.circular(10)),
                        child: Text(_lastWrittenInfo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 70,
              child: ElevatedButton.icon(
                onPressed: _toggleScanning,
                style: ElevatedButton.styleFrom(backgroundColor: _isScanning ? Colors.red : Colors.blueAccent),
                icon: Icon(_isScanning ? Icons.stop_circle : Icons.play_circle_fill, size: 35, color: Colors.white),
                label: Text(_isScanning ? "DỪNG LẠI" : "BẮT ĐẦU GHI", style: const TextStyle(fontSize: 22, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}