// lib/main.dart

import 'dart:async'; // For Completer
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart'; // Added for custom fonts

void main() {
  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define a modern and cohesive color scheme using ThemeData.
    final ThemeData theme = ThemeData(
      primarySwatch: Colors.deepPurple,
      fontFamily: 'Roboto',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: TextTheme(
        headlineMedium: GoogleFonts.lato(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.openSans(
          fontSize: 18,
          color: Colors.white70,
        ),
        labelLarge: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.openSans(
          fontSize: 16,
          color: Colors.white70,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
          shadowColor: Colors.black45,
        ),
      ),
    );

    return MaterialApp(
      title: 'Reddit Memes',
      theme: theme,
      home: const MemePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// The main page displaying memes fetched from Reddit.
class MemePage extends StatefulWidget {
  const MemePage({super.key});

  @override
  State<MemePage> createState() => _MemePageState();
}

class _MemePageState extends State<MemePage> {
  List memes = [];
  bool isLoading = true;
  String after = '';
  String userInput = '';

  @override
  void initState() {
    super.initState();
    fetchMemes();
  }

  /// Fetches memes from Reddit's r/memes subreddit.
  Future<void> fetchMemes() async {
    final String url = 'https://www.reddit.com/r/memes.json?limit=50&after=$after';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          memes.addAll(data['data']['children']);
          after = data['data']['after'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load memes');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching memes: $e')),
      );
    }
  }

  /// Refreshes the list of memes.
  Future<void> _refreshMemes() async {
    setState(() {
      memes.clear();
      after = '';
      isLoading = true;
    });
    await fetchMemes();
  }

  /// Validates if the URL points to an image.
  bool isValidImageUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.gif');
  }

  /// Builds the carousel slider displaying top memes.
  Widget buildCarousel(List memeList) {
    return CarouselSlider.builder(
      itemCount: memeList.length,
      options: CarouselOptions(
        height: MediaQuery.of(context).size.height * 0.35, // Responsive height
        enlargeCenterPage: true,
        enableInfiniteScroll: true,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        viewportFraction: 0.8,
      ),
      itemBuilder: (context, index, realIndex) {
        final meme = memeList[index]['data'];
        if (meme['post_hint'] == 'image' &&
            meme['url'] != null &&
            isValidImageUrl(meme['url'])) {
          return buildMemeCard(meme);
        } else {
          return const SizedBox();
        }
      },
    );
  }

  /// Builds individual meme cards for the carousel.
  Widget buildMemeCard(meme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageFullScreen(imageUrl: meme['url']),
              ),
            );
          },
          child: Hero(
            tag: meme['url'], // Hero animation for smooth transition
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.25,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(meme['url']),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.7),
                    blurRadius: 15,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Top Meme',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  /// Builds the list of memes as full-width cards.
  Widget buildMemeList(List memeList) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(), // Allows single scroll
      shrinkWrap: true,
      itemCount: memeList.length,
      itemBuilder: (context, index) {
        final meme = memeList[index]['data'];
        if (meme['post_hint'] == 'image' &&
            meme['url'] != null &&
            isValidImageUrl(meme['url'])) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              shadowColor: Colors.black.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageFullScreen(imageUrl: meme['url']),
                        ),
                      );
                    },
                    child: Hero(
                      tag: meme['url'], // Hero animation for smooth transition
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: CachedNetworkImage(
                          imageUrl: meme['url'],
                          placeholder: (context, url) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error, size: 50, color: Colors.red),
                          ),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'More Memes',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.deepPurpleAccent,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  /// Displays a dialog for user to input text.
  void _showInputDialog() {
    String inputText = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Your Text'),
          content: TextField(
            onChanged: (value) {
              inputText = value;
            },
            decoration: const InputDecoration(hintText: 'Type here'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  userInput = inputText;
                });
                Navigator.of(context).pop();
                _showSnackBar('You entered: $userInput');
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  /// Displays a SnackBar with the provided message.
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define how many memes to show in the carousel
    int carouselCount = 10;
    List carouselMemes = memes.take(carouselCount).toList();
    List listMemes = memes.skip(carouselCount).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reddit Memes'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMemes,
            tooltip: 'Refresh Memes',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurpleAccent,
              ),
            )
          : RefreshIndicator(
              color: Colors.deepPurpleAccent,
              backgroundColor: Colors.white,
              onRefresh: _refreshMemes,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    buildCarousel(carouselMemes),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'More Memes',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.deepPurpleAccent,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    buildMemeList(listMemes),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showInputDialog,
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.edit),
        tooltip: 'Add Text Overlay',
      ),
    );
  }
}

/// A full-screen view of the meme image with text overlay capabilities.
class ImageFullScreen extends StatefulWidget {
  final String imageUrl;
  const ImageFullScreen({super.key, required this.imageUrl});

  @override
  State<ImageFullScreen> createState() => _ImageFullScreenState();
}

class _ImageFullScreenState extends State<ImageFullScreen> {
  TextOverlay? textOverlay;
  Offset initialPosition = const Offset(100, 100); // Default position

  /// Displays a dialog to add or edit text overlay.
  void _showTextInputDialog({TextOverlay? existingOverlay}) {
    String inputText = existingOverlay?.text ?? '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existingOverlay == null ? 'Add Text' : 'Edit Text'),
          content: TextField(
            onChanged: (value) {
              inputText = value;
            },
            controller: TextEditingController(text: inputText),
            decoration: const InputDecoration(hintText: 'Type here'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  if (existingOverlay != null) {
                    textOverlay = TextOverlay(
                      text: inputText,
                      position: existingOverlay.position,
                    );
                  } else {
                    textOverlay = TextOverlay(
                      text: inputText,
                      position: initialPosition,
                    );
                  }
                });
                Navigator.of(context).pop();
              },
              child: Text(existingOverlay == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  /// Shares the meme with the added text overlay.
  Future<void> shareMemeWithText(String imageUrl, TextOverlay? overlay, BuildContext context) async {
    try {
      final uri = Uri.parse(imageUrl);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Decode the image
        final Completer<ui.Image> completer = Completer();
        ui.decodeImageFromList(bytes, (ui.Image img) {
          completer.complete(img);
        });
        final ui.Image image = await completer.future;

        // Create a canvas and draw the image
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(
          recorder,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        );
        final paint = Paint();
        canvas.drawImage(image, Offset.zero, paint);

        // Draw text overlay if exists
        if (overlay != null) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: overlay.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 3,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout(
            minWidth: 0,
            maxWidth: image.width.toDouble(),
          );
          textPainter.paint(canvas, overlay.position);
        }

        // Convert canvas to image
        final picture = recorder.endRecording();
        final img = await picture.toImage(image.width, image.height);
        final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

        // Save the image to a temporary file
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/shared_meme.png').create();
        await file.writeAsBytes(pngBytes!.buffer.asUint8List());

        // Share the image
        final XFile xFile = XFile(file.path);
        await Share.shareXFiles([xFile], text: 'Check out this meme!');
      } else {
        throw Exception('Failed to download image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing meme: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meme'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showTextInputDialog(existingOverlay: textOverlay),
            tooltip: 'Add/Edit Text',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              shareMemeWithText(widget.imageUrl, textOverlay, context);
            },
            tooltip: 'Share Meme',
          ),
        ],
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          if (textOverlay != null) {
            setState(() {
              textOverlay = TextOverlay(
                text: textOverlay!.text,
                position: textOverlay!.position + details.delta,
              );
            });
          }
        },
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: widget.imageUrl,
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (textOverlay != null)
              Positioned(
                left: textOverlay!.position.dx,
                top: textOverlay!.position.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      textOverlay = TextOverlay(
                        text: textOverlay!.text,
                        position: textOverlay!.position + details.delta,
                      );
                    });
                  },
                  child: Text(
                    textOverlay!.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 3,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTextInputDialog(),
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.text_fields),
        tooltip: 'Add Text Overlay',
      ),
    );
  }
}

/// Represents a text overlay with content and position.
class TextOverlay {
  final String text;
  final Offset position;

  TextOverlay({required this.text, required this.position});
}
