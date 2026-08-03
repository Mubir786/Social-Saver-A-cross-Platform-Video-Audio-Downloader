import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

class DownloadService {
  // Default candidate hosts to try when running on mobile.
  // We avoid importing `dart:io` here so the file remains web-compatible.
  // - 10.0.2.2: Android emulator -> host localhost
  // - 127.0.0.1: iOS simulator / host loopback
  // You can override the resolved base URL at runtime using `setOverrideBaseUrl()`.
  static const List<String> _candidates = [
    'http://10.0.2.2:8000',
    'http://127.0.0.1:8000',
    'http://localhost:8000',
  ];

  static String? _overrideBaseUrl;
  static String? _resolvedBaseUrl;

  /// Set an explicit base URL (useful for physical devices, e.g. `http://192.168.x.y:8000`).
  static void setOverrideBaseUrl(String url) {
    _overrideBaseUrl = url;
    _resolvedBaseUrl = url;
  }

  /// Returns the best base URL for the current platform / environment.
  /// On web this is `http://localhost:8000` by default. On mobile we probe
  /// `_candidates` and pick the first that responds to `/docs` within a short timeout.
  static Future<String> _getBaseUrl() async {
    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;
    if (_overrideBaseUrl != null) return _overrideBaseUrl!;

    if (kIsWeb) {
      _resolvedBaseUrl = 'http://localhost:8000';
      return _resolvedBaseUrl!;
    }

    final dioProbe = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 2),
      receiveTimeout: const Duration(seconds: 2),
      sendTimeout: const Duration(seconds: 2),
    ));

    for (final candidate in _candidates) {
      try {
        final resp = await dioProbe.get('$candidate/docs');
        if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 400) {
          _resolvedBaseUrl = candidate;
          debugPrint('DownloadService: Resolved baseUrl -> $_resolvedBaseUrl');
          return _resolvedBaseUrl!;
        }
      } catch (_) {
        // ignore and try next candidate
      }
    }

    // Fallback to first candidate if none responded quickly.
    _resolvedBaseUrl = _candidates.first;
    debugPrint('DownloadService: Fallback baseUrl -> $_resolvedBaseUrl');
    return _resolvedBaseUrl!;
  }

  static Future<String?> selectDirectory() async {
    if (kIsWeb) return null; // Web handles downloads via browser
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    return selectedDirectory;
  }

  static Future<String?> downloadVideo({
    required String platform,
    required String url,
    required String format,
    String? quality,
    String? saveDirectory,
    Function(double progress, String status)? onProgress,
  }) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(minutes: 10),
      receiveTimeout: const Duration(minutes: 10),
      sendTimeout: const Duration(minutes: 10),
    ));
    final baseUrl = await _getBaseUrl();
    try {
      // Construct format_id based on selection
      // Note: We use 'best' instead of 'bestvideo+bestaudio' to avoid requiring FFmpeg for merging.
      String formatId = 'best';
      if (format == 'mp3') {
        formatId = 'bestaudio/best';
      } else if (quality != null && platform != 'instagram') {
        // Extract height from quality (e.g. '1080p' -> '1080')
        final height = quality.replaceAll(RegExp(r'[^0-9]'), '');
        if (height.isNotEmpty) {
          formatId = 'best[height<=$height]';
        }
      }

      // 1. Initiate Download
      debugPrint(
          'DownloadService: Requesting download for $url with format $formatId');
      onProgress?.call(0.0, 'Initiating...');

      final response = await dio.post('$baseUrl/api/download', data: {
        'url': url,
        'format_id': formatId,
      });

      if (response.statusCode != 200) {
        debugPrint(
            'DownloadService: Failed to initiate download. Status: ${response.statusCode}');
        onProgress?.call(0.0, 'Error initiating download');
        return null;
      }

      final downloadId = response.data['download_id'];
      debugPrint('DownloadService: Download initiated. ID: $downloadId');

      // 2. Poll for Progress
      String status = 'downloading';
      while (status == 'downloading') {
        await Future.delayed(const Duration(seconds: 1));
        final progressResponse =
          await dio.get('$baseUrl/api/progress/$downloadId');

        if (progressResponse.statusCode == 200) {
          final data = progressResponse.data;
          status = data['status'];
          final progressStr = data['progress'].toString().replaceAll('%', '');
          final progress = (double.tryParse(progressStr) ?? 0) / 100;

          debugPrint('DownloadService: Status: $status, Progress: $progress');
          onProgress?.call(progress * 0.5,
              'Processing: ${data['progress']}'); // First 50% is backend processing

          if (status == 'error') {
            debugPrint(
                'DownloadService: Backend reported error: ${data['error']}');
            onProgress?.call(0.0, 'Error: ${data['error']}');
            return null;
          }
        } else {
          debugPrint('DownloadService: Failed to get progress');
          return null;
        }
      }

      if (status == 'completed') {
        final downloadUrl = '$baseUrl/api/download-file/$downloadId';

        if (kIsWeb) {
          // Web: Trigger browser download
          debugPrint(
              'DownloadService: Launching download URL for Web: $downloadUrl');
          onProgress?.call(1.0, 'Starting browser download...');
          if (await canLaunchUrl(Uri.parse(downloadUrl))) {
            await launchUrl(Uri.parse(downloadUrl));
            return 'Download started in browser';
          } else {
            debugPrint('DownloadService: Could not launch $downloadUrl');
            return null;
          }
        } else {
          // Mobile: Download to file system
          String dirPath;
          if (saveDirectory != null) {
            dirPath = saveDirectory;
          } else {
            final dir = await getApplicationDocumentsDirectory();
            dirPath = dir.path;
          }

          final fileName =
              'video_${DateTime.now().millisecondsSinceEpoch}.${format == 'mp3' ? 'mp3' : 'mp4'}';
          final savePath = '$dirPath/$fileName';

          debugPrint('DownloadService: Downloading file to $savePath');
          onProgress?.call(0.5, 'Downloading to device...');

          await dio.download(
            downloadUrl,
            savePath,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                final downloadProgress = received / total;
                // Map download progress to 50%-100% range
                final totalProgress = 0.5 + (downloadProgress * 0.5);
                onProgress?.call(totalProgress,
                    'Downloading: ${(downloadProgress * 100).toStringAsFixed(0)}%');
                debugPrint(
                    'DownloadService: File transfer: ${(downloadProgress * 100).toStringAsFixed(0)}%');
              }
            },
          );
          onProgress?.call(1.0, 'Completed');
          return savePath;
        }
      }

      return null;
    } catch (e) {
      debugPrint('DownloadService: Error: $e');
      onProgress?.call(0.0, 'Error: $e');
      return null;
    }
  }
}
