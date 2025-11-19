// lib/services/nfc_service.dart

import 'dart:async';
import 'dart:convert';
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


  static String _parseTextPayload(Uint8List recordPayload) {
    try {
      List<int> payload = recordPayload.toList();
      int statusByte = payload.removeAt(0);
      int langCodeLength = (statusByte & 0x3F);
      List<int> textPayload = payload.sublist(langCodeLength);
      return utf8.decode(textPayload);
    } catch (e) {
      print('Lỗi parse NDEF Text payload: $e');
      throw Exception('Không thể giải mã NDEF Text record');
    }
  }

  static String _parseUriPayload(Uint8List payload) {
    if (payload.isEmpty) return "";
    final prefixCode = payload[0];
    final restOfPayload = payload.sublist(1);
    final payloadString = utf8.decode(restOfPayload);
    switch (prefixCode) {
      case 0x00: return payloadString;
      case 0x01: return "http://www." + payloadString;
      case 0x02: return "https://www." + payloadString;
      case 0x03: return "http://" + payloadString;
      case 0x04: return "https://" + payloadString;
      case 0x05: return "tel:" + payloadString;
      case 0x06: return "mailto:" + payloadString;
      default: return payloadString;
    }
  }

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
      final Ndef? ndef = Ndef.from(tag);
      if (ndef == null) {
        _showError(context, 'Thẻ không hỗ trợ NDEF.');
        return;
      }

      final NdefMessage? message = ndef.cachedMessage ?? await ndef.read();

      if (message == null || message.records.isEmpty) {
        _showError(context, 'Thẻ không chứa dữ liệu NDEF.');
        return;
      }

      String? extractedCaySamId;

      for (var record in message.records) {
        // Ưu tiên 1: Tìm Text Record (JSON) - Vẫn giữ để phòng hờ
        if (record.typeNameFormat == TypeNameFormat.wellKnown && record.type.isNotEmpty && record.type.first == 0x54) { // Mã 'T'
          try {
            final jsonPayload = _parseTextPayload(record.payload);
            final Map<String, dynamic> data = jsonDecode(jsonPayload);
            if (data.containsKey('caySamId')) {
              extractedCaySamId = data['caySamId'];
              print("✅ [NFC Scan] Đã tìm thấy ID từ Text Record (JSON).");
              break;
            }
          } catch (e) { /* Lỗi parse JSON, bỏ qua */ }
        }

        // Ưu tiên 2: Tìm URI Record (Link)
        if (extractedCaySamId == null && record.typeNameFormat == TypeNameFormat.wellKnown && record.type.isNotEmpty && record.type.first == 0x55) { // Mã 'U' (URI)
          try {
            final uriString = _parseUriPayload(record.payload);
            final Uri uri = Uri.parse(uriString);

            // Logic mới: Kiểm tra host và path segments
            if (uri.host == 'nft.samnghigia.com' &&
                uri.pathSegments.length == 2 &&
                uri.pathSegments.first == 'caysam') {

              extractedCaySamId = uri.pathSegments[1]; // Lấy ID
              print("✅ [NFC Scan] Đã tìm thấy ID từ URI Record (Link).");
              break;
            }
          } catch (e) { /* Lỗi parse URI */ }
        }
      }

      // Xử lý ID đã tìm thấy
      if (extractedCaySamId != null && extractedCaySamId.isNotEmpty) {
        await _handleCaySamId(extractedCaySamId, context);
      } else {
        _showError(context, 'Không tìm thấy dữ liệu cây sâm hợp lệ trong thẻ.');
      }

    } catch (e) {
      print('Lỗi nghiêm trọng khi xử lý thẻ: $e');
      if (context.mounted) {
        _showError(context, 'Lỗi không xác định: ${e.toString()}');
      }
    }
  }

  // --- QUẢN LÝ PHIÊN NFC ---
  // (Giữ nguyên: startNfcSession, stopNfcSession)

  static void startNfcSession(BuildContext context) {
    if (!_isNfcSessionRunning) {
      try {
        NfcManager.instance.startSession(
          onDiscovered: (NfcTag tag) async {
            print("Đã phát hiện một thẻ NFC. Đang xử lý...");

            NfcManager.instance.stopSession();
            _isNfcSessionRunning = false;

            await _handleTagDiscovered(tag, context);

            startNfcSession(context);
          },
          pollingOptions: {
            NfcPollingOption.iso14443,
            NfcPollingOption.iso15693,
            NfcPollingOption.iso18092,
          },
          onSessionErrorIos: (NfcReaderSessionErrorIos? e) {
            if (e != null) {
              print('NFC Session Error (iOS): $e');
              if (e.code != '201') {
                _showError(context, 'Lỗi NFC: ${e.message}');
              }
            }
          },
        ).then((_) {
          _isNfcSessionRunning = true;
          print("NFC start: Bắt đầu lắng nghe session thành công.");
        }).catchError((e) {
          if (e is PlatformException && e.code == 'not_supported') {
            print('NFC không được hỗ trợ hoặc chưa bật.');
          } else {
            print("Lỗi khi bắt đầu NFC session: $e");
          }
        });
      } on PlatformException catch (e) {
        if (e.code == 'not_supported') {
          print('NFC không được hỗ trợ (lỗi sync).');
        } else {
          print("Lỗi PlatformException khi bắt đầu NFC: $e");
        }
      } catch (e) {
        print("Lỗi không xác định khi bắt đầu NFC: $e");
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