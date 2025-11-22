import 'package:flutter/material.dart';

class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key});

  final List<Map<String, String>> steps = const [
    {
      "title": "Upload Images",
      "icon": "assets/step01.jpg",
      "desc": "Upload intraoral or panoramic images."
    },
    {
      "title": "AI Diagnosis",
      "icon": "assets/step02.jpg",
      "desc": "AI analyzes for caries, periodontal issues."
    },
    {
      "title": "Get Results",
      "icon": "assets/step03.jpg",
      "desc": "Receive a diagnostic report in seconds."
    },
    {
      "title": "Take Action",
      "icon": "assets/step04.jpg",
      "desc": "Plan treatment securely and privately."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How it Works",
            style: TextStyle(
              color: Colors.cyan,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "From Image to Insight in Just a Few Steps",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: MediaQuery.of(context).size.width < 600 ? 0.75 : 0.85,
            ),
            itemBuilder: (context, index) {
              final step = steps[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12), // Reduced padding
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center, // Changed to center
                    children: [
                      // Image and text content
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              step["icon"]!,
                              height: 60, // Further reduced image height
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              step["title"]!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // Smaller font
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              step["desc"]!,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10, // Smaller font for description
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Number at the bottom
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(
                              color: Colors.cyan,
                              fontSize: 18, // Smaller number
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}