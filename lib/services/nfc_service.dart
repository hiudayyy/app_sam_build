// lib/services/nfc_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csam_mobile/api/api_caysam.dart';
import 'package:csam_mobile/models/vuontrong/caysam_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ✅ CHỈ IMPORT CÁC LỚP TỒN TẠI
import 'package:ndef_record/ndef_record.dart'
    show NdefMessage, NdefRecord, TypeNameFormat;
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart'; // Cho Ndef.from(tag)

// Imports khác của ứng dụng
import 'package:csam_mobile/api/api.dart'; // Đảm bảo import API của bạn
import 'package:csam_mobile/screens/plant_detail_screen.dart';


class NfcService {
  static bool _isProcessingTag = false;
  static bool _isNfcSessionRunning = false;


  static void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static void _showLoadingDialog(BuildContext context, {required String message}) {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(message),
              ]),
            ),
          );
        },
      );
    }
  }


  // static String _parseTextPayload(Uint8List recordPayload) {
  //   try {
  //     List<int> payload = recordPayload.toList();
  //     int statusByte = payload.removeAt(0);
  //     int langCodeLength = (statusByte & 0x3F);
  //     List<int> textPayload = payload.sublist(langCodeLength);
  //     return utf8.decode(textPayload);
  //   } catch (e) {
  //     print('Lỗi parse NDEF Text payload: $e');
  //     throw Exception('Không thể giải mã NDEF Text record');
  //   }
  // }

  // static String _parseUriPayload(Uint8List payload) {
  //   if (payload.isEmpty) return "";
  //   final prefixCode = payload[0];
  //   final restOfPayload = payload.sublist(1);
  //   final payloadString = utf8.decode(restOfPayload);
  //   switch (prefixCode) {
  //     case 0x00: return payloadString;
  //     case 0x01: return "http://www." + payloadString;
  //     case 0x02: return "https://www." + payloadString;
  //     case 0x03: return "http://" + payloadString;
  //     case 0x04: return "https://" + payloadString;
  //     case 0x05: return "tel:" + payloadString;
  //     case 0x06: return "mailto:" + payloadString;
  //     default: return payloadString;
  //   }
  // }

  // (Giữ nguyên: _handleCaySamId)
  static Future<void> _handleCaySamId(String caySamId, BuildContext context) async {
    if (_isProcessingTag) return;
    _isProcessingTag = true;
    try {
      if (context.mounted) {
        _showLoadingDialog(context, message: 'Đang tải thông tin sâm...');
      }

      final CaySamModel? plant = await API().getCaySamById(caySamId);

      if (context.mounted) {
        Navigator.of(context).pop();
        if (plant != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PlantDetailScreen(plant: plant, onBack: () => Navigator.pop(context)),
            ),
          );
        } else {
          _showError(context, 'Không tìm thấy thông tin cây sâm');
        }
      }
    } catch (e) {
      print('Lỗi tải dữ liệu cây sâm: $e');
      if (context.mounted) {
        Navigator.of(context).pop();
        _showError(context, 'Lỗi kết nối khi tải dữ liệu.');
      }
    } finally {
      _isProcessingTag = false;
    }
  }

  static Future<void> processDeepLinkUri(Uri uri, BuildContext context) async {
    // Logic mới: Kiểm tra host và path segments
    if (uri.host == 'nft.samnghigia.com' &&
        uri.pathSegments.length == 2 && // Mong đợi 2 phần: ['caysam', 'ID']
        uri.pathSegments.first == 'caysam') {
      final String caySamId = uri.pathSegments[1]; // Lấy phần tử thứ hai (ID)
      if (caySamId.isNotEmpty) {
        // print("✅ Xử lý Deep Link URI: Đã tách được caySamId=$caySamId");
        await _handleCaySamId(caySamId, context);
      }
    } else {
      _showError(context, 'Link không hợp lệ hoặc thiếu ID cây sâm.');
    }
  }


  static Future<void> _handleTagDiscovered(NfcTag tag, BuildContext context) async {
    try {
      // 1. Ép kiểu NDEF
      final Ndef? ndef = Ndef.from(tag);
      if (ndef == null) {
        print("❌ iOS/Android: Thẻ không hỗ trợ NDEF");
        // _showError(context, 'Thẻ không đúng định dạng.');
        return;
      }

      // 2. Đọc dữ liệu (iOS thường cần đọc trực tiếp thay vì dùng cachedMessage ngay)
      NdefMessage? message = ndef.cachedMessage;
      if (message == null) {
        try {
          // Cố gắng đọc lại từ thẻ nếu cache rỗng (iOS hay bị case này)
          message = await ndef.read();
        } catch (e) {
          print("⚠️ Lỗi khi đọc thẻ trực tiếp: $e");
        }
      }

      if (message == null || message.records.isEmpty) {
        _showError(context, 'Thẻ trắng hoặc không đọc được dữ liệu.');
        return;
      }

      print("📡 Đã đọc được ${message.records.length} bản ghi từ thẻ.");
      String? extractedCaySamId;

      for (var record in message.records) {
        print("🔍 Đang check record: TNF=${record.typeNameFormat}, Type=${record.type}");

        // --- Ưu tiên 1: URI Record (Link) ---
        // Chuẩn NDEF: TypeNameFormat = 0x01 (WellKnown) và Type = 0x55 ('U')
        if (record.typeNameFormat == TypeNameFormat.wellKnown &&
            record.type.isNotEmpty &&
            record.type.first == 0x55) {

          try {
            // QUAN TRỌNG: Dùng hàm parse chuẩn cho iOS
            final uriString = _parseUriPayload(record.payload);
            print("🔗 URI tìm thấy: $uriString");

            final Uri uri = Uri.parse(uriString);

            // Kiểm tra đúng domain của bạn
            if (uri.host.contains('samnghigia.com') &&
                uri.pathSegments.length >= 2 &&
                uri.pathSegments[0] == 'caysam') {

              extractedCaySamId = uri.pathSegments[1];
              print("✅ [SUCCESS] Tìm thấy ID từ Link: $extractedCaySamId");
              break;
            }
          } catch (e) {
            print("⚠️ Lỗi parse URI Record: $e");
          }
        }

        // --- Ưu tiên 2: Text Record (JSON) ---
        // Chuẩn NDEF: TypeNameFormat = 0x01 (WellKnown) và Type = 0x54 ('T')
        if (extractedCaySamId == null &&
            record.typeNameFormat == TypeNameFormat.wellKnown &&
            record.type.isNotEmpty &&
            record.type.first == 0x54) {

          try {
            // QUAN TRỌNG: Dùng hàm parse chuẩn cho iOS
            final jsonPayload = _parseTextPayload(record.payload);
            print("📄 Text tìm thấy: $jsonPayload");

            final Map<String, dynamic> data = jsonDecode(jsonPayload);
            if (data.containsKey('caySamId')) {
              extractedCaySamId = data['caySamId'];
              print("✅ [SUCCESS] Tìm thấy ID từ JSON Text.");
              break;
            }
          } catch (e) {
            print("⚠️ Lỗi parse Text Record: $e");
          }
        }
      }

      // 3. Điều hướng hoặc báo lỗi
      if (extractedCaySamId != null && extractedCaySamId.isNotEmpty) {
        await _handleCaySamId(extractedCaySamId, context);
      } else {
        _showError(context, 'Thẻ không chứa thông tin cây sâm hợp lệ.');
      }

    } catch (e) {
      print('❌ Lỗi nghiêm trọng (Main Catch): $e');
      if (context.mounted) {
        _showError(context, 'Lỗi đọc thẻ: ${e.toString()}');
      }
    }
  }

// ============================================================
// CÁC HÀM HELPER QUAN TRỌNG (PHẢI CÓ ĐỂ CHẠY TRÊN IOS)
// ============================================================

  /// Giải mã URI Record theo chuẩn NFC Forum
  static String _parseUriPayload(Uint8List payload) {
    if (payload.isEmpty) return "";

    // Byte đầu tiên là mã định danh giao thức (Prefix)
    final int prefixCode = payload[0];

    // Phần còn lại là nội dung link
    final String body = utf8.decode(payload.sublist(1));

    String prefix = "";
    switch (prefixCode) {
      case 0x01: prefix = "http://www."; break;
      case 0x02: prefix = "https://www."; break;
      case 0x03: prefix = "http://"; break;
      case 0x04: prefix = "https://"; break; // Đây là cái bạn dùng nhiều nhất
      case 0x00: prefix = ""; break;
      default: prefix = ""; // Các prefix ít dùng khác
    }

    return prefix + body;
  }

  /// Giải mã Text Record theo chuẩn NFC Forum
  static String _parseTextPayload(Uint8List payload) {
    if (payload.isEmpty) return "";

    // Byte đầu tiên là Status Byte
    final int statusByte = payload[0];

    // Bit 7 kiểm tra encoding (0 = UTF-8, 1 = UTF-16) - Thường là UTF-8
    // final bool isUtf16 = (statusByte & 0x80) != 0;

    // Bit 0-5 là độ dài mã ngôn ngữ (ví dụ 'en' là 2)
    final int languageCodeLength = statusByte & 0x3F;

    // Nội dung thực tế bắt đầu sau (1 byte status + độ dài mã ngôn ngữ)
    final int textStartIndex = 1 + languageCodeLength;

    return utf8.decode(payload.sublist(textStartIndex));
  }

  // --- QUẢN LÝ PHIÊN NFC ---
  // (Giữ nguyên: startNfcSession, stopNfcSession)

  static Future<void> startNfcSession(BuildContext context) async {
    // 1. Nếu đang có cờ chạy, chặn luôn để tránh spam nút
    if (_isNfcSessionRunning) return;
    _isNfcSessionRunning = true;

    try {
      // 2. BƯỚC QUAN TRỌNG NHẤT: Force Stop session cũ (nếu còn sót lại)
      // Dùng catchError để bỏ qua lỗi nếu không có session nào
      await NfcManager.instance.stopSession().catchError((_) {});

      // 3. Đợi một chút cho hệ điều hành dọn dẹp tài nguyên (iOS cần cái này)
      await Future.delayed(const Duration(milliseconds: 200));

      // 4. Bắt đầu phiên mới
      await NfcManager.instance.startSession(
        alertMessageIos: "Vui lòng đưa thẻ lại gần điện thoại...",
        onDiscovered: (NfcTag tag) async {
          print("📡 Đã phát hiện thẻ...");

          bool isSuccess = false;
          String resultMessage = "";

          try {
            // Xử lý thẻ
            await _handleTagDiscovered(tag, context);
            isSuccess = true;
            resultMessage = "Thành công!";
          } catch (e) {
            isSuccess = false;
            resultMessage = "Lỗi: ${e.toString()}";
          } finally {
            // Đóng session sau khi xử lý xong
            _isNfcSessionRunning = false; // Reset cờ

            if (Platform.isIOS) {
              NfcManager.instance.stopSession(
                alertMessageIos: isSuccess ? resultMessage : null,
                errorMessageIos: isSuccess ? null : resultMessage,
              );
            } else {
              NfcManager.instance.stopSession();
            }
          }
        },
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        onSessionErrorIos: (NfcReaderSessionErrorIos? e) {
          _isNfcSessionRunning = false;
          // Bỏ qua lỗi nếu do người dùng hủy hoặc timeout hoặc đang bận
          if (e != null && e.code != '200' && e.code != '201' && e.code != '202') {
            _showError(context, 'Lỗi NFC: ${e.message} ${e.code.toString()}') ;
          }
        },
      );

      print("✅ NFC Session đã khởi động.");

    } catch (e) {
      _isNfcSessionRunning = false;

      // Xử lý riêng lỗi "session_already_exists" nếu nó vẫn lọt qua
      if (e is PlatformException && e.code == 'session_already_exists') {
        print("⚠️ Phát hiện Session cũ bị kẹt. Đang thử reset...");
        // Đệ quy gọi lại chính nó sau 1 giây để thử lại
        Future.delayed(const Duration(seconds: 1), () {
          startNfcSession(context);
        });
      } else if (e is PlatformException && e.code == 'not_supported') {
        // _showError(context, 'Thiết bị không hỗ trợ NFC.');
      } else {
        print("Lỗi khởi động NFC: $e");
      }
    }
  }

  static void stopNfcSession() {
    NfcManager.instance.stopSession().then((_) {
      _isNfcSessionRunning = false;
      print("Đã dừng NFC session.");
    }).catchError((e) {
      if (e is PlatformException && e.code != 'not_supported' && e.code != 'session_stopped') {
        print("Lỗi khi dừng NFC session: $e");
      }
    });
  }
}