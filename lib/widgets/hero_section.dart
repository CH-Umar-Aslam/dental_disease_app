import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  final List<String> phrases = [
    "AI-Powered Dental Disease Diagnosis",
    "Revolutionary AI Dental Diagnosis",
    "Dental Care AI",
  ];

  int textIndex = 0;
  String displayedText = '';
  bool isTyping = true;

  Timer? _timer;

  final List<Map<String, String>> slideImages = [
    {
      "src": "assets/img1.jpg",
      "title": "Panoramic X-Ray Analysis",
      "description": "Complete oral cavity overview"
    },
    {
      "src": "assets/img2.jpg",
      "title": "Intraoral Imaging",
      "description": "Detailed tooth examination"
    },
    {
      "src": "assets/img3.jpg",
      "title": "Caries Detection",
      "description": "Early cavity identification"
    },
  ];

  int currentSlide = 0;
  bool isPlaying = true;
  final PageController _pageController = PageController(viewportFraction: 0.7);

  @override
  void initState() {
    super.initState();
    startTyping();
    startAutoSlide();
  }

  void startTyping() {
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      setState(() {
        final currentPhrase = phrases[textIndex];
        if (isTyping) {
          if (displayedText.length < currentPhrase.length) {
            displayedText =
                currentPhrase.substring(0, displayedText.length + 1);
          } else {
            isTyping = false;
          }
        } else {
          if (displayedText.isNotEmpty) {
            displayedText =
                currentPhrase.substring(0, displayedText.length - 1);
          } else {
            isTyping = true;
            textIndex = (textIndex + 1) % phrases.length;
          }
        }
      });
    });
  }

  void startAutoSlide() {
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (isPlaying && mounted) {
        setState(() {
          currentSlide = (currentSlide + 1) % slideImages.length;
          _pageController.animateToPage(
            currentSlide,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
      }
    });
  }

  void toggleAutoplay() {
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void goToPrevious() {
    setState(() {
      currentSlide =
          (currentSlide - 1 + slideImages.length) % slideImages.length;
      _pageController.animateToPage(
        currentSlide,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void goToNext() {
    setState(() {
      currentSlide = (currentSlide + 1) % slideImages.length;
      _pageController.animateToPage(
        currentSlide,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Circles
        Positioned(
          top: 50,
          left: 20,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          right: 20,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.cyan.withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.3),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        ),

        // Main Content
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated Text
                SizedBox(
                  height: 80, // Fixed height for text area
                  child: Center(
                    child: Text(
                      displayedText,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.push('/diagnosis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                      ),
                      child: const Text("Get AI Report"),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () =>
                          context.push('/diagnosis'), // can go back
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                      ),
                      child: const Text("Learn More"),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Slider with fixed height
                SizedBox(
                  height: 350, // Increased height to accommodate content
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        currentSlide = index;
                      });
                    },
                    itemCount: slideImages.length,
                    itemBuilder: (context, index) {
                      final slide = slideImages[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Image section
                              Expanded(
                                flex: 3,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  child: Image.asset(
                                    slide["src"]!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                              // Text section
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        slide["title"]!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        slide["description"]!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Slider Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: goToPrevious,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    IconButton(
                      onPressed: toggleAutoplay,
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    ),
                    IconButton(
                      onPressed: goToNext,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
