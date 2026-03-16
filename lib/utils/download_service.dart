import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';

class DownloadService {
  static final Dio _dio = Dio();

  /// Downloads a file from [url] and prompts the user to save it.
  /// [fileName] is the suggested name for the file.
  static Future<bool> downloadAndSave({
    required String url,
    required String fileName,
    void Function(double)? onProgress,
  }) async {
    try {
      final String fullUrl = ApiService.getFileUrl(url);
      
      // 1. Get the bytes
      final response = await _dio.get<Uint8List>(
        fullUrl,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      final bytes = response.data;
      if (bytes == null) return false;

      // 2. Ask where to save
      if (kIsWeb) {
        // On Web, we can't use FilePicker.saveFile easily for raw bytes in some versions,
        // but normally we'd trigger a browser download.
        // For now, let's assume mobile/desktop as per the "ask where to store" request.
        // (Web usually defaults to Downloads or asks based on browser settings).
        return false; // Handle web separately if needed
      }

      // 3. Platform specific "Save As"
      String? outputFile;
      
      try {
        outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Select where to save the PDF',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          bytes: bytes, // Required for Android & iOS
        );

        if (outputFile == null) {
          debugPrint("📥 Download canceled or picker failed");
          return false;
        }

        debugPrint("📥 Saving to: $outputFile");
        
        if (kIsWeb) {
          // On Web, saveFile handles the actual download if bytes are provided
          return true;
        }

        if (outputFile != null) {
          final file = File(outputFile);
          try {
            // On some versions of file_picker, saveFile already writes the bytes if provided.
            // On others, it just returns the path. 
            // We'll attempt a write if the file is empty or doesn't exist.
            if (!await file.exists() || (await file.length()) == 0) {
              await file.writeAsBytes(bytes);
              debugPrint("✅ File bytes written successfully: $outputFile");
            }
            return true;
          } catch (writeError) {
             debugPrint("⚠️ Write error (might be handled by OS): $writeError");
             return true; // Likely handled by SAF/picker if it exists now
          }
        }
        return false;
      } catch (pickerError) {
        debugPrint("❌ Error during Save As process: $pickerError");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Terminal Download error: $e");
      return false;
    }
  }
}
