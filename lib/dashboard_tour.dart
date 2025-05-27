// File: dashboard_tour.dart - Interactive overlay tour
import 'package:flutter/material.dart';

class DashboardTour extends StatefulWidget {
  final Widget child;
  final VoidCallback onTourComplete;

  const DashboardTour({
    Key? key,
    required this.child,
    required this.onTourComplete,
  }) : super(key: key);

  @override
  State<DashboardTour> createState() => _DashboardTourState();
}

class _DashboardTourState extends State<DashboardTour> {
  int currentStep = 0;
  final List<TourStep> tourSteps = [
    TourStep(
      title: "Welcome to Your Dashboard! 🏠",
      message:
          "This is your home base. From here, you can access all features of Senior Surfers.",
      targetKey: 'dashboard_home',
      position: TourPosition.center,
    ),
    TourStep(
      title: "Start Learning Here 📚",
      message:
          "Click on Tutorials to access step-by-step guides for different apps and features.",
      targetKey: 'tutorials_button',
      position: TourPosition.bottom,
    ),
    TourStep(
      title: "Practice Safely 🛡️",
      message:
          "Use Practice Mode to try apps without any real consequences. It's completely safe!",
      targetKey: 'practice_button',
      position: TourPosition.bottom,
    ),
    TourStep(
      title: "Have Fun Learning 🎮",
      message:
          "Games make learning enjoyable! Try our interactive games to reinforce what you've learned.",
      targetKey: 'games_button',
      position: TourPosition.bottom,
    ),
    TourStep(
      title: "Get Help Anytime 💬",
      message:
          "Visit the Community Forum to ask questions and connect with other learners.",
      targetKey: 'community_button',
      position: TourPosition.bottom,
    ),
    TourStep(
      title: "Customize Your Experience ⚙️",
      message:
          "Access Settings to adjust text size, enable audio reading, and personalize your experience.",
      targetKey: 'settings_button',
      position: TourPosition.top,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (currentStep < tourSteps.length) _buildTourOverlay(),
      ],
    );
  }

  Widget _buildTourOverlay() {
    final step = tourSteps[currentStep];

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Stack(
        children: [
          // Spotlight effect (you'd implement this based on targetKey)
          _buildSpotlight(step),

          // Tour content
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: 20,
            right: 20,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF27445D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      step.message,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (currentStep > 0)
                          TextButton(
                            onPressed: () => setState(() => currentStep--),
                            child: const Text('Previous'),
                          )
                        else
                          const SizedBox(),

                        Text(
                          '${currentStep + 1} of ${tourSteps.length}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            if (currentStep < tourSteps.length - 1) {
                              setState(() => currentStep++);
                            } else {
                              widget.onTourComplete();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF27445D),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            currentStep < tourSteps.length - 1
                                ? 'Next'
                                : 'Get Started',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: widget.onTourComplete,
                      child: const Text('Skip Tour'),
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

  Widget _buildSpotlight(TourStep step) {
    // This would create a circular spotlight effect
    // Implementation depends on your specific UI layout
    return Container();
  }
}

class TourStep {
  final String title;
  final String message;
  final String targetKey;
  final TourPosition position;

  TourStep({
    required this.title,
    required this.message,
    required this.targetKey,
    required this.position,
  });
}

enum TourPosition { top, bottom, center }
