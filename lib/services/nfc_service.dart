// lib/services/nfc_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:nftsam/api/api_caysam.dart';
import 'package:nftsam/models/vuontrong/caysam_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndef/ndef.dart' as ndef;
// ✅ CHỈ IMPORT CÁC LỚP TỒN TẠI
import 'package:ndef_record/ndef_record.dart'
    show NdefMessage, NdefRecord, TypeNameFormat;
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart'; // Cho Ndef.from(tag)
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

// Imports khác của ứng dụng
import 'package:nftsam/api/api.dart'; // Đảm bảo import API của bạn
import 'package:nftsam/screens/plant_detail_screen.dart';


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
  // Thêm tham số hardwareId
  static Future<void> _handleCaySamId(String caySamId, BuildContext context) async {
    if (_isProcessingTag) return;
    _isProcessingTag = true;

    try {


      // 1. Tắt Dialog Quét (Android)
      if (Platform.isAndroid) {
        if (Navigator.canPop(context)) Navigator.of(context).pop();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (context.mounted) {
        _showLoadingDialog(context, message: 'Đang xác thực thẻ...');
      }

      // --- [VÍ DỤ CHECK ID THẺ TRÊN SERVER] ---
      // final result = await API().verifyTag(caySamId, hardwareId);
      // if (!result.isValid) throw "Thẻ giả mạo!";

      final CaySamModel? plant = await API().getCaySamById(caySamId);

      if (context.mounted) {
        Navigator.of(context).pop(); // Tắt Loading

        if (plant != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              // Truyền tiếp hardwareId vào màn hình chi tiết nếu cần hiển thị
              builder: (context) => PlantDetailScreen(plant: plant, onBack: () => Navigator.pop(context)),
            ),
          );
        } else {
          _showError(context, 'Không tìm thấy thông tin cây sâm');
        }
      }
    } catch (e) {
      print('Lỗi tải dữ liệu: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // Tắt Loading
        _showError(context, 'Lỗi: ${e.toString()}');
      }
    } finally {
      _isProcessingTag = false;
    }
  }
  static Future<void> processDeepLinkUri(Uri uri, BuildContext context) async {
    if (uri.host == 'nft.samnghigia.com' &&
        uri.pathSegments.length == 2 &&
        uri.pathSegments.first == 'caysam') {
      final String caySamId = uri.pathSegments[1];
      BuildContext? dialogContext;
      if (Platform.isAndroid) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            dialogContext = ctx; // Lưu lại context của dialog để lát nữa đóng cho chuẩn
            return WillPopScope( // Chặn nút Back vật lý để tránh lỗi logic
              onWillPop: () async => false,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.nfc_outlined, size: 60, color: Colors.blue),
                    SizedBox(height: 20),
                    Text("Đang tải chi tiết cây",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text(
                      "Vui lòng chạm lại thẻ...",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    LinearProgressIndicator(),
                  ],
                ),
              ),
            );
          },
        );
      }

      try {
        if (Platform.isAndroid) {
          // Android: Cần 2s để phần cứng reset sau khi mở Deep Link
          await Future.delayed(const Duration(seconds: 2));
        } else {
          // iOS: Chỉ cần delay cực ngắn (0.5s) để UI App load xong hoàn toàn
          // giúp bảng quét NFC hiện lên mượt mà hơn, không bị giật.
          await Future.delayed(const Duration(milliseconds: 500));
        }
        try {
          await FlutterNfcKit.finish();
        } catch (_) {}

        // Bắt đầu quét mới
        var tag = await FlutterNfcKit.poll(
          timeout: const Duration(seconds: 10),
          iosAlertMessage: "Vui lòng chạm lại thẻ...",
          readIso14443A: true,
          readIso15693: true,
        );

        String realHardwareId = tag.id;
        // print("UIDUIDUID $realHardwareId");

        // Đóng Dialog (Nếu đang hiển thị)
        if (Platform.isAndroid && dialogContext != null && Navigator.canPop(dialogContext!)) {
          Navigator.pop(dialogContext!);
        }

        if (realHardwareId.isNotEmpty) {
          final checkuid = await API().CheckNFCCaySam(serialNumber: realHardwareId);
          if(checkuid?.message == "Thẻ NFC đã tồn tại!" ){
            // Kết thúc session NFC
            await FlutterNfcKit.finish(iosAlertMessage: "Thành công");
            // Xử lý logic
            await _handleCaySamId(caySamId, context);
          }else{
            if (Platform.isAndroid && dialogContext != null && Navigator.canPop(dialogContext!)) {
              Navigator.pop(dialogContext!);
            }
            await FlutterNfcKit.finish(iosAlertMessage: "Quét không thành công!");
          }
        }

      } catch (e) {
        print("Lỗi quét NFC: $e");

        // Đóng Dialog nếu có lỗi xảy ra
        if (Platform.isAndroid && dialogContext != null && Navigator.canPop(dialogContext!)) {
          Navigator.pop(dialogContext!);
        }

        // Luôn nhớ finish session dù lỗi
        await FlutterNfcKit.finish(iosAlertMessage: "Lỗi, Quét thẻ không thành công!");
      }
    }
  }

  static Future<void> _handleTagDiscovered(NfcTag tag, BuildContext context) async {
    try {

      final String hardwareId = _extractTagId(tag);
      if (hardwareId == "UNKNOWN_ID" || hardwareId.isEmpty) {
        if (context.mounted) _showError(context, "Không đọc được ID vật lý của thẻ!");
        return;
      }
      final Ndef? ndef = Ndef.from(tag);
      if (ndef == null) {
        print("⚠️ Thẻ không hỗ trợ định dạng NDEF");
        return;
      }

      NdefMessage? message = ndef.cachedMessage;
      if (message == null) {
        try {
          message = await ndef.read();
        } catch (e) {
          // Lỗi đọc thẻ trực tiếp
        }
      }
      if (message == null || message.records.isEmpty) {
        if (context.mounted) _showError(context, 'Thẻ trắng hoặc không đọc được dữ liệu.');
        return;
      }
      String? foundCaySamId;
      for (var record in message.records) {
        if (record.typeNameFormat == TypeNameFormat.wellKnown &&
            record.type.length == 1 &&
            record.type.first == 0x55) {
          try {
            final uriString = _parseUriPayload(record.payload);
            final Uri uri = Uri.parse(uriString);
            if (uri.host.contains('samnghigia.com') &&
                uri.pathSegments.length >= 2 &&
                uri.pathSegments[0] == 'caysam') {
              foundCaySamId = uri.pathSegments[1];
              break;
            }
          } catch (e) {
            print("⚠️ Lỗi parse record này: $e");
          }
        }
      }
      if (foundCaySamId != null) {
        await _verifyAndNavigate(foundCaySamId, hardwareId, context);
      } else {
        if (context.mounted) _showError(context, "Thẻ này không chứa thông tin Sâm hợp lệ.");
      }
    } catch (e) {
      print('❌ Lỗi xử lý thẻ: $e');
      if (context.mounted) {
        _showError(context, 'Lỗi đọc thẻ: ${e.toString()}');
      }
    }
  }

  static Future<void> _verifyAndNavigate(String caySamId, String hardwareId, BuildContext context) async {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final checkResult = await API().CheckNFCCaySam(serialNumber: hardwareId);
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (!context.mounted) return;
      if (checkResult?.message == "Thẻ NFC đã tồn tại!") {
        await _handleCaySamId(caySamId, context);
      } else {
        _showError(context, "Thẻ chưa được kích hoạt hoặc không hợp lệ!");
      }
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (context.mounted) _showError(context, "Lỗi kết nối Server: $e");
    }
  }

  static String _extractTagId(NfcTag tag) {
    final dynamic data = tag.data;
    List<int> idBytes = [];
    try {
      if (Platform.isAndroid) {
        if (data['nfcA'] != null) {
          idBytes = List<int>.from(data['nfcA']['identifier'] ?? []);
        }
        else if (data['isodep'] != null) {
          idBytes = List<int>.from(data['isodep']['identifier'] ?? []);
        }
        else if (data['nfcV'] != null) {
          idBytes = List<int>.from(data['nfcV']['identifier'] ?? []);
        }
      }
      // 3. Kiểm tra iOS
      else if (Platform.isIOS) {
        if (data['mifare'] != null) {
          idBytes = List<int>.from(data['mifare']['identifier'] ?? []);
        }
        else if (data['iso15693'] != null) {
          idBytes = List<int>.from(data['iso15693']['identifier'] ?? []);
        }
        else if (data['feliCa'] != null) {
          idBytes = List<int>.from(data['feliCa']['currentIDm'] ?? []);
        }
      }
    } catch (e) {
      print("⚠️ Lỗi trích xuất UID: $e");
      return "";
    }

    if (idBytes.isEmpty) return "";
    return idBytes.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
  }
  static String _parseUriPayloadFromBytes(List<int> payload) {
    if (payload.isEmpty) return "";
    // Byte đầu tiên là mã tiền tố (Prefix Code)
    int prefixCode = payload[0];
    String prefix = _getNdefUriPrefix(prefixCode);
    // Các byte còn lại là nội dung
    String body = utf8.decode(payload.sublist(1));
    return prefix + body;
  }

  static String _parseTextPayloadFromBytes(List<int> payload) {
    if (payload.isEmpty) return "";
    // Byte đầu tiên chứa thông tin mã hóa và độ dài mã ngôn ngữ
    int statusByte = payload[0];
    bool isUtf16 = (statusByte & 0x80) != 0;
    int languageCodeLength = statusByte & 0x3F;

    // Bỏ qua byte trạng thái và mã ngôn ngữ để lấy nội dung thực
    if (payload.length > 1 + languageCodeLength) {
      var contentBytes = payload.sublist(1 + languageCodeLength);
      return isUtf16 ? utf8.decode(contentBytes) : utf8.decode(contentBytes);
      // Lưu ý: Dart hỗ trợ utf8 tốt, utf16 ít dùng trong NDEF web nhưng nếu cần có thể convert
    }
    return "";
  }

// Bảng mã tiền tố URI chuẩn NDEF
  static String _getNdefUriPrefix(int code) {
    const prefixes = [
      '', 'http://www.', 'https://www.', 'http://', 'https://', 'tel:', 'mailto:',
      'ftp://anonymous:anonymous@', 'ftp://ftp.', 'ftps://', 'sftp://', 'smb://',
      'nfs://', 'ftp://', 'dav://', 'news:', 'telnet://', 'imap:', 'rtsp://', 'urn:',
      'pop:', 'sip:', 'sips:', 'tftp:', 'btspp://', 'btl2cap://', 'btgoep://',
      'tcpobex://', 'irdaobex://', 'file://', 'urn:epc:id:', 'urn:epc:tag:',
      'urn:epc:pat:', 'urn:epc:raw:', 'urn:epc:', 'urn:nfc:'
    ];
    if (code >= 0 && code < prefixes.length) {
      return prefixes[code];
    }
    return "";
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
    // 1. Chặn spam nút
    if (_isNfcSessionRunning) return;
    bool isAvailable = false;
    try {
      isAvailable = await NfcManager.instance.isAvailable();
    } catch (_) {}

    if (!isAvailable) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thiết bị không hỗ trợ NFC'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    if (Platform.isAndroid) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.nfc, size: 60, color: Colors.green),
              SizedBox(height: 20),
              Text("Đang quét thẻ...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Vui lòng chạm thẻ vào mặt lưng điện thoại", textAlign: TextAlign.center),
              SizedBox(height: 20),
              LinearProgressIndicator(color: Colors.green),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                _isNfcSessionRunning = false;
                await NfcManager.instance.stopSession();
                if (ctx.mounted && Navigator.canPop(ctx)) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Hủy", style: TextStyle(color: Colors.red)),
            )
          ],
        ),
      );
    }

    _isNfcSessionRunning = true;
    bool isScanSuccess = false;

    try {
      await NfcManager.instance.stopSession().catchError((_) {});
      await NfcManager.instance.startSession(
          pollingOptions: {
            NfcPollingOption.iso14443,
            NfcPollingOption.iso15693,
          },
          alertMessageIos: "Vui lòng đưa thẻ lại gần điện thoại...",
          onDiscovered: (NfcTag tag) async {
            try {
              await _handleTagDiscovered(tag, context);
              isScanSuccess = true;
            } catch (e) {
              isScanSuccess = false;
              print("Lỗi xử lý thẻ: $e");
            } finally {
              _isNfcSessionRunning = false;

              if (Platform.isIOS) {
                NfcManager.instance.stopSession(
                  alertMessageIos: isScanSuccess ? "Thành công!" : "Lỗi đọc thẻ",
                  errorMessageIos: isScanSuccess ? null : "Thử lại",
                );
              } else {
                NfcManager.instance.stopSession();
                if (!isScanSuccess) {
                  if (context.mounted && Navigator.canPop(context)) {
                    Navigator.pop(context); // Tắt Dialog "Đang quét"
                  }
                  // Hiện thông báo lỗi nếu cần
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Không đọc được thẻ hoặc thẻ lỗi"), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            }
          },
      );

    } catch (e) {
      _isNfcSessionRunning = false;
      // Tắt dialog nếu khởi động lỗi
      if (Platform.isAndroid && context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      print("Lỗi khởi động NFC: $e");
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