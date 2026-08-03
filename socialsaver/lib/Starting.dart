// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'download_page.dart';

// -----------------------------------------------------------------------------
// Starting Page
// -----------------------------------------------------------------------------
class StartingPage extends StatelessWidget {
  const StartingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/5cfe14_30977ca5f4d04cc2a8977a980baf19a9~mv2.gif',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(204, 0, 110, 255),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.5),
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.download, color: Colors.white, size: 40),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NextPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'SocialSaver',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Next Page
// -----------------------------------------------------------------------------
class NextPage extends StatelessWidget {
  const NextPage({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color.fromARGB(255, 255, 255, 255);
    final cardColor = const Color.fromARGB(255, 106, 106, 106);
    const iconColor = Colors.blueAccent;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Icon(Icons.menu, color: iconColor),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 0, 53, 77),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.download, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 12),
            const Text(
              'SocialSaver',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Download videos from YouTube, Instagram,\nand Facebook in MP3 or MP4 format',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 25),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.download, color: Color.fromARGB(255, 121, 170, 255), size: 40),
                  const SizedBox(height: 10),
                  const Text(
                    'Choose one of the following\nto download video',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      platformButton(
                        color: const Color.fromARGB(255, 151, 10, 0),
                        icon: Icons.play_circle_fill,
                        label: 'YouTube',
                        onTap: () => goToPlatform(context, 'YouTube'),
                      ),
                      platformButton(
                        color: const Color.fromARGB(255, 255, 64, 249),
                        icon: Icons.camera_alt,
                        label: 'Instagram',
                        onTap: () => goToPlatform(context, 'Instagram'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      platformButton(
                        color: const Color.fromARGB(255, 0, 125, 227),
                        icon: Icons.facebook,
                        label: 'Facebook',
                        onTap: () => goToPlatform(context, 'Facebook'),
                      ),
                      platformButton(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        icon: Icons.music_note,
                        label: 'TikTok',
                        onTap: () => goToPlatform(context, 'TikTok'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget platformButton({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void goToPlatform(BuildContext context, String platform) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlatformPage(platform: platform),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Platform Page
// -----------------------------------------------------------------------------
class PlatformPage extends StatefulWidget {
  final String platform;
  const PlatformPage({super.key, required this.platform});

  @override
  State<PlatformPage> createState() => _PlatformPageState();
}

class _PlatformPageState extends State<PlatformPage> {
  final TextEditingController _urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final platformColor = {
      'YouTube': Colors.red,
      'Instagram': Colors.pinkAccent,
      'Facebook': Colors.blue,
      'TikTok': Colors.black,
    }[widget.platform]!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: platformColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.platform, style: TextStyle(color: platformColor)),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download, size: 40, color: platformColor),
              const SizedBox(height: 10),
              const Text(
                "Paste your video link below:",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  hintText: "Enter video URL",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_urlController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a video URL")),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DownloadPage(
                        platform: widget.platform,
                        videoUrl: _urlController.text.trim(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: platformColor,
                  padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Next", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}