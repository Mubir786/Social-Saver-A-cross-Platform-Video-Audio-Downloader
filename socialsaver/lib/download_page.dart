import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'download_service.dart';

class DownloadPage extends StatefulWidget {
  final String platform;
  final String videoUrl;

  const DownloadPage({
    super.key,
    required this.platform,
    required this.videoUrl,
  });

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  String? _selectedFormat;
  String? _selectedQuality;
  bool _isDownloading = false;
  String? _downloadedFile;
  double _progress = 0.0;
  String _statusMessage = '';
  String? _saveDirectory;

  final List<String> formats = ['mp4', 'mp3'];
  final List<String> qualities = ['1080p', '720p', '480p', '360p'];

  Future<void> _selectLocation() async {
    final dir = await DownloadService.selectDirectory();
    if (dir != null) {
      setState(() {
        _saveDirectory = dir;
      });
    }
  }

  Future<void> _startDownload() async {
    if (_selectedFormat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a format')),
      );
      return;
    }

    if (_selectedFormat == 'mp4' && _selectedQuality == null && widget.platform != 'instagram') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a quality')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusMessage = 'Starting...';
      _downloadedFile = null;
    });

    final path = await DownloadService.downloadVideo(
      platform: widget.platform,
      url: widget.videoUrl,
      format: _selectedFormat!,
      quality: _selectedQuality,
      saveDirectory: _saveDirectory,
      onProgress: (progress, status) {
        setState(() {
          _progress = progress;
          _statusMessage = status;
        });
      },
    );

    if (!mounted) return;

    setState(() {
      _isDownloading = false;
      _downloadedFile = path;
    });

    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded successfully: $path')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.platform} Downloader'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Video URL: ${widget.videoUrl}',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 20),

            // Format selection
            const Text('Select Format:', style: TextStyle(fontSize: 18)),
            Wrap(
              spacing: 10,
              children: formats.map((f) {
                return ChoiceChip(
                  label: Text(f.toUpperCase()),
                  selected: _selectedFormat == f,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFormat = selected ? f : null;
                      _selectedQuality = null; // reset quality
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Quality selection (only if MP4 and not Instagram)
            if (_selectedFormat == 'mp4' && widget.platform != 'instagram') ...[
              const Text('Select Quality:', style: TextStyle(fontSize: 18)),
              Wrap(
                spacing: 10,
                children: qualities.map((q) {
                  return ChoiceChip(
                    label: Text(q),
                    selected: _selectedQuality == q,
                    onSelected: (selected) {
                      setState(() => _selectedQuality = selected ? q : null);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Location Selection (Mobile only)
            if (!kIsWeb) ...[
              OutlinedButton.icon(
                onPressed: _selectLocation,
                icon: const Icon(Icons.folder),
                label: Text(_saveDirectory ?? 'Select Download Location'),
              ),
              const SizedBox(height: 20),
            ],

            // Download button
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : _startDownload,
              icon: const Icon(Icons.download),
              label: Text(_isDownloading ? 'Downloading...' : 'Download'),
            ),

            const SizedBox(height: 20),

            // Progress bar (if downloading)
            if (_isDownloading) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 10),
              Text(_statusMessage),
            ],

            // Downloaded file info
            if (_downloadedFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  'Saved to: $_downloadedFile',
                  style: const TextStyle(color: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
