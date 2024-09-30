// lib/main.dart

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:carousel_slider/carousel_slider.dart';

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
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          color: Colors.white70,
        ),
        labelLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white70,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(
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
  String selectedCategory = 'memes'; // Default category

  final List<String> categories = [
    'memes',
    'funny',
    'dankmemes',
    'wholesomememes',
    'AdviceAnimals',
    'MemeEconomy',
    'ComedyCemetery',
    'PrequelMemes',
    'SequelMemes',
    'gamingmemes',
  ];

  @override
  void initState() {
    super.initState();
    fetchMemes(selectedCategory);
  }

  /// Fetches memes from Reddit's selected subreddit.
  Future<void> fetchMemes(String subreddit) async {
    final String url =
        'https://www.reddit.com/r/$subreddit.json?limit=50&after=$after';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          List fetchedMemes = data['data']['children'];
          fetchedMemes.shuffle(); // Randomize memes
          memes.addAll(fetchedMemes);
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
    await fetchMemes(selectedCategory);
  }

  /// Validates if the URL points to an image.
  bool isValidImageUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.gif');
  }

  /// Builds the category list.
  Widget buildCategoryList() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
                memes.clear();
                after = '';
                isLoading = true;
              });
              fetchMemes(category);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Chip(
                label: Text(
                  category,
                  style: TextStyle(
                    color: selectedCategory == category
                        ? Colors.white
                        : Colors.deepPurpleAccent,
                  ),
                ),
                backgroundColor: selectedCategory == category
                    ? Colors.deepPurpleAccent
                    : Colors.grey[800],
              ),
            ),
          );
        },
      ),
    );
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                          builder: (context) =>
                              ImageFullScreen(imageUrl: meme['url']),
                        ),
                      );
                    },
                    child: Hero(
                      tag: meme['url'], // Hero animation for smooth transition
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15)),
                        child: CachedNetworkImage(
                          imageUrl: meme['url'],
                          placeholder: (context, url) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child:
                                const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error,
                                size: 50, color: Colors.red),
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
                      style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                    const SizedBox(height: 16),
                    buildCategoryList(), // Moved below the carousel
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Be Happy',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.red,
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

  // Controllers for the two input fields
  final TextEditingController _textControllerTop = TextEditingController();
  final TextEditingController _textControllerBottom = TextEditingController();

  // Toggle between edit mode and preview mode
  bool isEditMode = true;

  @override
  void dispose() {
    _textControllerTop.dispose();
    _textControllerBottom.dispose();
    super.dispose();
  }

  /// Applies the text overlays and switches to preview mode.
  void _applyTextAndPreview() {
    setState(() {
      textOverlay = TextOverlay(
        topText: _textControllerTop.text.toUpperCase(),
        bottomText: _textControllerBottom.text.toUpperCase(),
      );
      isEditMode = false; // Switch to preview mode
    });
  }

  /// Returns to edit mode to modify texts.
  void _editText() {
    setState(() {
      isEditMode = true;
    });
  }

  /// Shares the meme with the added text overlays.
  Future<void> shareMemeWithTextOverlays(BuildContext context) async {
    try {
      final uri = Uri.parse(widget.imageUrl);
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

        // Draw text overlays if they exist
        if (textOverlay != null) {
          final double fontSize = image.width * 0.08;

          final textStyle = TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          );

          final strokeStyle = textStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize * 0.04
              ..color = Colors.black,
          );

          // Draw top text
          final topTextPainter = TextPainter(
            text: TextSpan(
              text: textOverlay!.topText,
              style: strokeStyle,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          );
          topTextPainter.layout(
            minWidth: image.width.toDouble(),
          );
          topTextPainter.paint(canvas, Offset(0, 10));

          final topTextFillPainter = TextPainter(
            text: TextSpan(
              text: textOverlay!.topText,
              style: textStyle,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          );
          topTextFillPainter.layout(
            minWidth: image.width.toDouble(),
          );
          topTextFillPainter.paint(canvas, Offset(0, 10));

          // Draw bottom text
          final bottomTextPainter = TextPainter(
            text: TextSpan(
              text: textOverlay!.bottomText,
              style: strokeStyle,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          );
          bottomTextPainter.layout(
            minWidth: image.width.toDouble(),
          );
          bottomTextPainter.paint(
              canvas, Offset(0, image.height - bottomTextPainter.height - 10));

          final bottomTextFillPainter = TextPainter(
            text: TextSpan(
              text: textOverlay!.bottomText,
              style: textStyle,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          );
          bottomTextFillPainter.layout(
            minWidth: image.width.toDouble(),
          );
          bottomTextFillPainter.paint(
              canvas, Offset(0, image.height - bottomTextFillPainter.height - 10));
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

  /// Draws the text overlays on the image.
  Widget _buildMemeImage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Hero(
              tag: widget.imageUrl,
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(color: Colors.white),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.error, color: Colors.red),
                fit: BoxFit.cover,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
            ),
            if (textOverlay != null) ...[
              // Top Text
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _editText,
                  child: Text(
                    textOverlay!.topText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: constraints.maxWidth * 0.08,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(2, 2),
                          blurRadius: 3,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom Text
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _editText,
                  child: Text(
                    textOverlay!.bottomText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: constraints.maxWidth * 0.08,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(2, 2),
                          blurRadius: 3,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meme Generator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!isEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editText,
              tooltip: 'Edit Text',
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              shareMemeWithTextOverlays(context);
            },
            tooltip: 'Share Meme',
          ),
        ],
      ),
      body: isEditMode
          ? Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Hero(
                        tag: widget.imageUrl,
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrl,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(
                                  color: Colors.white),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error, color: Colors.red),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      // Optionally display text overlays while editing
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _textControllerTop,
                        decoration: const InputDecoration(
                          labelText: 'Top Text',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _textControllerBottom,
                        decoration: const InputDecoration(
                          labelText: 'Bottom Text',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _applyTextAndPreview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Edit Meme'),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : _buildMemeImage(),
    );
  }
}

/// Represents text overlays with content.
class TextOverlay {
  final String topText;
  final String bottomText;

  TextOverlay({
    required this.topText,
    required this.bottomText,
  });
}
