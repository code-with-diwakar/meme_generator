// lib/main.dart

import 'package:flutter/material.dart';
import 'app.dart'; // Import the app.dart file

void main() {
  runApp(const MyInitialApp());
}

class MyInitialApp extends StatelessWidget {
  const MyInitialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Initial Screen',
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
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
        ),
      ),
      home: const MyWidget(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    
    super.initState();
    // Initialize AnimationController for fade-in effect
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Define the fade-in animation
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // Start the animation
    _animationController.forward();
  }

  m(initState) => initState;

  @override
  void dispose() {
    // Dispose the AnimationController to free resources
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToMemePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MemePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Extend body behind the app bar
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Welcome'),
        centerTitle: true,
        backgroundColor: Colors.transparent, // Make app bar transparent
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Image
          SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: Image.asset(
              'assets/images/4912917.jpg', // ✅ Corrected path
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Content with Fade-In Animation
          FadeTransition(
            opacity: _fadeInAnimation,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App Logo or Icon
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.mood,
                        size: 50,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // App Title
                    Text(
                      'Reddit Memes',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    // App Subtitle or Tagline
                    Text(
                      'Laugh out loud with the latest memes',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Navigation Button with Custom Styling
                    ElevatedButton(
                      onPressed: _navigateToMemePage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange, // Button background color
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        textStyle: Theme.of(context).textTheme.labelLarge,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                        shadowColor: Colors.black45,
                      ),
                      child: const Text('Enter Memes App'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
