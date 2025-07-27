import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Instagram Share Demo',
      theme: ThemeData.dark(),
      home: const SharePreviewWidget(),
    );
  }
}

// Widget to handle the sharing process
class SharePreviewWidget extends StatefulWidget {
  const SharePreviewWidget({super.key});

  @override
  State<SharePreviewWidget> createState() => _SharePreviewWidgetState();
}

class _SharePreviewWidgetState extends State<SharePreviewWidget> {
  final GlobalKey _contentKey = GlobalKey();
  bool _isLoading = false;

  // Platform channel for native communication
  static const platform = MethodChannel('com.yourapp/instagram_share');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: Color(0xFF1A237E),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  key: _contentKey,
                  child: const LinkSharePage(
                    message: "ask me anything  anonymously",
                    profileImageUrl: "https://i.imgur.com/BoN9kdC.png",
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _shareToInstagram,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A148C),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text(
                        'Share to Instagram',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareToInstagram() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Capture the widget as an image
      final imageBytes = await _captureWidgetAsImage();
      if (imageBytes == null) {
        _showErrorMessage('Failed to capture image');
        return;
      }

      // Step 2: Save image to a temporary file
      final imagePath = await _saveImageToTemporaryFile(imageBytes);
      if (imagePath == null) {
        _showErrorMessage('Failed to save image');
        return;
      }

      // Step 3 & 4: Share to Instagram via the method channel
      await _shareToInstagramStory(imagePath);
      
    } catch (e) {
      _showErrorMessage('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Uint8List?> _captureWidgetAsImage() async {
    try {
      RenderRepaintBoundary boundary = _contentKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing widget as image: $e');
      return null;
    }
  }

  Future<String?> _saveImageToTemporaryFile(Uint8List imageBytes) async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/share_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);
      return imagePath;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  Future<void> _shareToInstagramStory(String imagePath) async {
    try {
      final result = await platform.invokeMethod('shareToInstagramStory', {
        'imagePath': imagePath,
      });
      print('Share result: $result');
    } on PlatformException catch (e) {
      print('Error sharing to Instagram: ${e.message}');
      if (e.message?.contains('Instagram') ?? false) {
        _showErrorMessage('Instagram app not installed');
      } else {
        _showErrorMessage('Error sharing to Instagram');
      }
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

// Modified LinkSharePage widget with increased font size, shadow effect, and smaller link width
class LinkSharePage extends StatelessWidget {
  final String message;
  final String profileImageUrl;

  const LinkSharePage({
    super.key,
    required this.message,
    required this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF1A237E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(profileImageUrl),
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 20),

              // Message Text - MODIFIED: Increased font size and added shadow
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 30, // Increased from 24 to 30
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(2.0, 2.0),
                        blurRadius: 3.0,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Link Box - MODIFIED: Made width smaller
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 70), // Increased margin to make it narrower
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "Paste your ",
                      style: TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                    Text(
                      "LINK",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    Text(
                      " here!",
                      style: TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.link, color: Colors.blue, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Arrows
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.arrow_upward, color: Colors.white, size: 28),
                  SizedBox(width: 16),
                  Icon(Icons.arrow_upward, color: Colors.white, size: 28),
                  SizedBox(width: 16),
                  Icon(Icons.arrow_upward, color: Colors.white, size: 28),
                ],
              ),

              const SizedBox(height: 40),

              // Branding
              Column(
                children: const [
                  Text(
                    "NGL",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "anonymous q&a",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}