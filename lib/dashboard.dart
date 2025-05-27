import 'package:flutter/material.dart';
import 'package:senior_surfers/header_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  bool _isSidebarExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _sidebarAnimation;
  String _selectedSection = 'Tutorials';
  int _selectedBottomIndex = 0;

  // Onboarding state
  bool _showOnboarding = false;
  int _currentOnboardingStep = 0;
  OverlayEntry? _overlayEntry;
  final GlobalKey _tutorialsNavKey = GlobalKey();
  final GlobalKey _practiceNavKey = GlobalKey();
  final GlobalKey _gamesNavKey = GlobalKey();
  final GlobalKey _communityNavKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _startLearningKey = GlobalKey();
  final GlobalKey _moreOptionsKey = GlobalKey();

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      title: 'Tutorials',
      icon: Icons.play_circle_outline,
      imagePath: 'assets/images/tutorial.png',
      route: '/tutorials',
    ),
    NavigationItem(
      title: 'Practice',
      icon: Icons.fitness_center,
      imagePath: 'assets/images/practice.png',
      route: '/practice',
    ),
    NavigationItem(
      title: 'Tech Glossary',
      icon: Icons.book,
      imagePath: 'assets/images/tech_glossary.png',
      route: '/techglossary',
    ),
    NavigationItem(
      title: 'Games',
      icon: Icons.games,
      imagePath: 'assets/images/games.png',
      route: '/games',
    ),
    NavigationItem(
      title: 'Community',
      icon: Icons.forum,
      imagePath: 'assets/images/community_forum.png',
      route: '/community',
    ),
    NavigationItem(
      title: 'Achievements',
      icon: Icons.emoji_events,
      imagePath: 'assets/images/achievements.png',
      route: '/achievements',
    ),
  ];

  // Items for bottom navigation (mobile)
  List<NavigationItem> get _bottomNavItems => [
    _navigationItems[0], // Tutorials
    _navigationItems[1], // Practice
    _navigationItems[3], // Games
    _navigationItems[4], // Community
    NavigationItem(
      title: 'More',
      icon: Icons.more_horiz,
      imagePath: '',
      route: '/more',
    ),
  ];

  // Onboarding steps for seniors
  List<OnboardingStep> get _onboardingSteps => [
    OnboardingStep(
      title: "Welcome to Senior Surfers!",
      description:
          "Let's take a quick tour to help you get started. This will only take a minute and will make everything much easier to use!",
      targetKey: null,
      isIntro: true,
    ),
    OnboardingStep(
      title: "Start Your Learning Journey",
      description:
          "This big blue button will take you to our step-by-step tutorials. It's the best place to begin learning!",
      targetKey: _startLearningKey,
      position: TooltipPosition.top,
    ),
    OnboardingStep(
      title: "Tutorials - Learn Step by Step",
      description:
          "Tutorials teach you new technology skills with easy-to-follow instructions. Perfect for beginners!",
      targetKey: _tutorialsNavKey,
      position: TooltipPosition.top,
    ),
    OnboardingStep(
      title: "Practice What You Learn",
      description:
          "Practice lets you try what you've learned in a safe environment. No pressure, just practice!",
      targetKey: _practiceNavKey,
      position: TooltipPosition.top,
    ),
    OnboardingStep(
      title: "Fun Learning Games",
      description:
          "Games make learning fun! Play simple games that help you remember what you've learned.",
      targetKey: _gamesNavKey,
      position: TooltipPosition.top,
    ),
    OnboardingStep(
      title: "Connect with Others",
      description:
          "Community is where you can ask questions and share experiences with other learners just like you.",
      targetKey: _communityNavKey,
      position: TooltipPosition.top,
    ),
    OnboardingStep(
      title: "More Options Available",
      description:
          "Tap 'More' to find additional features like Tech Glossary, Achievements, and Settings.",
      targetKey: _moreOptionsKey,
      position: TooltipPosition.top,
    ),
    OnboardingStep(
      title: "You're All Set!",
      description:
          "Great job! You now know how to navigate Senior Surfers. You can replay this tour anytime by tapping the help button. Happy learning!",
      targetKey: null,
      isOutro: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sidebarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Check for first time and show onboarding
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    // Small delay to ensure widgets are built
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (!hasSeenOnboarding) {
      _startOnboarding();
    }
  }

  void _startOnboarding() {
    setState(() {
      _showOnboarding = true;
      _currentOnboardingStep = 0;
    });
    _showOnboardingOverlay();
  }

  void _showOnboardingOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder:
          (context) => OnboardingOverlay(
            step: _onboardingSteps[_currentOnboardingStep],
            stepNumber: _currentOnboardingStep + 1,
            totalSteps: _onboardingSteps.length,
            onNext: _nextOnboardingStep,
            onSkip: _skipOnboarding,
            onPrevious:
                _currentOnboardingStep > 0 ? _previousOnboardingStep : null,
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _nextOnboardingStep() {
    if (_currentOnboardingStep < _onboardingSteps.length - 1) {
      setState(() {
        _currentOnboardingStep++;
      });
      _showOnboardingOverlay();
    } else {
      _completeOnboarding();
    }
  }

  void _previousOnboardingStep() {
    if (_currentOnboardingStep > 0) {
      setState(() {
        _currentOnboardingStep--;
      });
      _showOnboardingOverlay();
    }
  }

  void _skipOnboarding() async {
    _completeOnboarding();
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    _removeOverlay();
    setState(() {
      _showOnboarding = false;
      _currentOnboardingStep = 0;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // Add method to restart onboarding
  void _restartOnboarding() {
    _startOnboarding();
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  // Responsive breakpoints - adjusted for seniors (larger breakpoints)
  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024; // Lowered from 1200
  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 && // Lowered from 768
      MediaQuery.of(context).size.width < 1024;
  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600; // Lowered from 768

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
      if (_isSidebarExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _selectSection(String section, {int? bottomIndex}) {
    setState(() {
      _selectedSection = section;
      if (bottomIndex != null) {
        _selectedBottomIndex = bottomIndex;
      }
    });
  }

  void _onBottomNavTap(int index) {
    if (index < _bottomNavItems.length) {
      final item = _bottomNavItems[index];
      if (item.title == 'More') {
        _showMoreOptionsBottomSheet();
      } else {
        _selectSection(item.title, bottomIndex: index);
        if (item.route.isNotEmpty) {
          context.go(item.route);
        }
      }
    }
  }

  void _showMoreOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Better for seniors
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar - larger for seniors
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 6, // Thicker handle
                    width: 50, // Wider handle
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Title - larger text
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Text(
                      'More Options',
                      style: TextStyle(
                        fontSize: 24, // Larger for seniors
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF27445D),
                      ),
                    ),
                  ),
                  // Show remaining navigation items with larger touch areas
                  _buildMoreOptionTile(
                    icon: _navigationItems[2].icon,
                    title: _navigationItems[2].title, // Tech Glossary
                    onTap: () {
                      Navigator.pop(context);
                      _selectSection(_navigationItems[2].title);
                      context.go(_navigationItems[2].route);
                    },
                  ),
                  _buildMoreOptionTile(
                    icon: _navigationItems[5].icon,
                    title: _navigationItems[5].title, // Achievements
                    onTap: () {
                      Navigator.pop(context);
                      _selectSection(_navigationItems[5].title);
                      context.go(_navigationItems[5].route);
                    },
                  ),
                  _buildMoreOptionTile(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      _selectSection('Settings');
                      context.go('/settingsD');
                    },
                  ),
                  _buildMoreOptionTile(
                    icon: Icons.help_outline,
                    title: 'Help & Tour',
                    onTap: () {
                      Navigator.pop(context);
                      _restartOnboarding();
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildMoreOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ), // Larger padding
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF27445D),
              size: 28, // Larger icons
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20, // Larger text
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop(context);
    final isTablet = _isTablet(context);
    final isMobile = _isMobile(context);

    return Scaffold(
      // Mobile app bar with help button
      appBar: isMobile ? _buildMobileAppBar() : null,

      // Bottom navigation for mobile
      bottomNavigationBar: isMobile ? _buildBottomNavigation() : null,

      body: SafeArea(
        child: Row(
          children: [
            // Sidebar - Hide on mobile, show on tablet/desktop
            if (!isMobile)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width:
                    _isSidebarExpanded
                        ? (isDesktop ? 300 : 280)
                        : (isDesktop ? 90 : 80),
                child: _buildSidebar(context),
              ),

            // Main Content Area
            Expanded(
              child: Container(
                color: Colors.grey[50],
                height: double.infinity,
                child: _buildMainContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      title: const Text(
        'Senior Surfers',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22), // Larger
      ),
      backgroundColor: const Color(0xFF27445D),
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          iconSize: 28, // Larger for seniors
          onPressed: () {
            // Handle notifications
          },
        ),
        IconButton(
          icon: const Icon(Icons.help_outline),
          iconSize: 28,
          onPressed: _restartOnboarding,
          tooltip: 'Help & Tour',
        ),
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          iconSize: 28, // Larger for seniors
          onPressed: () {
            // Handle profile
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12), // More padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                _bottomNavItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = _selectedBottomIndex == index;

                  // Assign keys for onboarding
                  GlobalKey? navKey;
                  if (index == 0)
                    navKey = _tutorialsNavKey;
                  else if (index == 1)
                    navKey = _practiceNavKey;
                  else if (index == 2)
                    navKey = _gamesNavKey;
                  else if (index == 3)
                    navKey = _communityNavKey;
                  else if (index == 4)
                    navKey = _moreOptionsKey;

                  return GestureDetector(
                    key: navKey,
                    onTap: () => _onBottomNavTap(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12, // Larger touch area
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color(0xFF27445D).withOpacity(0.1)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            color:
                                isSelected
                                    ? const Color(0xFF27445D)
                                    : Colors.grey[600],
                            size: 28, // Larger icons
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.title,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? const Color(0xFF27445D)
                                      : Colors.grey[600],
                              fontSize: 14, // Larger text
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final isDesktop = _isDesktop(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF27445D),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sidebar Header
          Container(
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isSidebarExpanded ? Icons.menu_open : Icons.menu,
                    color: Colors.white,
                    size: isDesktop ? 32 : 28, // Larger for seniors
                  ),
                  onPressed: _toggleSidebar,
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Senior Surfers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 24 : 22, // Larger text
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Colors.white24),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                return SidebarNavigationTile(
                  item: item,
                  isExpanded: _isSidebarExpanded,
                  isSelected: _selectedSection == item.title,
                  isDesktop: isDesktop,
                  onTap: () {
                    _selectSection(item.title);
                    if (item.route.isNotEmpty) {
                      context.go(item.route);
                    }
                  },
                );
              },
            ),
          ),

          // Settings and Help at bottom
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                SidebarNavigationTile(
                  item: NavigationItem(
                    title: 'Settings',
                    icon: Icons.settings,
                    imagePath: '',
                    route: '/settingsD',
                  ),
                  isExpanded: _isSidebarExpanded,
                  isSelected: _selectedSection == 'Settings',
                  isDesktop: isDesktop,
                  onTap: () {
                    _selectSection('Settings');
                    context.go('/settingsD');
                  },
                ),
                const SizedBox(height: 8),
                SidebarNavigationTile(
                  item: NavigationItem(
                    title: 'Help & Tour',
                    icon: Icons.help_outline,
                    imagePath: '',
                    route: '',
                  ),
                  isExpanded: _isSidebarExpanded,
                  isSelected: false,
                  isDesktop: isDesktop,
                  onTap: _restartOnboarding,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final isDesktop = _isDesktop(context);
    final isTablet = _isTablet(context);
    final isMobile = _isMobile(context);

    return Column(
      children: [
        // Page Header (hidden on mobile if app bar exists)
        if (!isMobile) ...[
          Container(
            padding: EdgeInsets.all(isDesktop ? 32 : 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedSection,
                  style: TextStyle(
                    fontSize: isDesktop ? 52 : 40, // Larger for seniors
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF27445D),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Learn technology step by step',
                      style: TextStyle(
                        fontSize: isDesktop ? 20 : 18, // Larger for seniors
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      iconSize: 32,
                      color: const Color(0xFF27445D),
                      onPressed: _restartOnboarding,
                      tooltip: 'Help & Tour',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Content Area - Show a welcome message
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 20 : (isDesktop ? 32 : 24), // More padding
              isMobile ? 20 : 0,
              isMobile ? 20 : (isDesktop ? 32 : 24),
              isMobile ? 20 : (isDesktop ? 32 : 24),
            ),
            child: _buildWelcomeContent(context),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeContent(BuildContext context) {
    final isDesktop = _isDesktop(context);
    final isMobile = _isMobile(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school,
            size: isMobile ? 100 : (isDesktop ? 140 : 120), // Larger icons
            color: const Color(0xFF27445D),
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to Senior Surfers!',
            style: TextStyle(
              fontSize:
                  isMobile ? 28 : (isDesktop ? 42 : 36), // Much larger text
              fontWeight: FontWeight.bold,
              color: const Color(0xFF27445D),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            constraints: BoxConstraints(maxWidth: isMobile ? 300 : 500),
            child: Text(
              'Learn technology at your own pace with our step-by-step tutorials, practice exercises, and helpful community.',
              style: TextStyle(
                fontSize: isMobile ? 18 : (isDesktop ? 24 : 20), // Larger text
                color: Colors.grey[600],
                height: 1.6, // Better line spacing
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            key: _startLearningKey, // Key for onboarding
            onPressed: () {
              context.go('/tutorials');
            },
            icon: const Icon(
              Icons.play_circle_outline,
              color: Colors.white,
              size: 24,
            ),
            label: Text(
              'Start Learning',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 20 : 24, // Much larger text
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27445D),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 32 : 40, // Larger buttons
                vertical: isMobile ? 20 : 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// Navigation Item Model
class NavigationItem {
  final String title;
  final IconData icon;
  final String imagePath;
  final String route;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.imagePath,
    required this.route,
  });
}

// Onboarding Step Model
class OnboardingStep {
  final String title;
  final String description;
  final GlobalKey? targetKey;
  final TooltipPosition position;
  final bool isIntro;
  final bool isOutro;

  OnboardingStep({
    required this.title,
    required this.description,
    this.targetKey,
    this.position = TooltipPosition.bottom,
    this.isIntro = false,
    this.isOutro = false,
  });
}

enum TooltipPosition { top, bottom, left, right }

// Onboarding Overlay Widget
class OnboardingOverlay extends StatelessWidget {
  final OnboardingStep step;
  final int stepNumber;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback? onPrevious;

  const OnboardingOverlay({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
    this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.75), // Slightly darker overlay
      child: Stack(
        children: [
          // Highlight target if it exists
          if (step.targetKey != null) _buildHighlight(context),

          // Tooltip
          _buildTooltip(context),
        ],
      ),
    );
  }

  Widget _buildHighlight(BuildContext context) {
    final RenderBox? renderBox =
        step.targetKey!.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox();

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    return Positioned(
      left: position.dx - 12, // Larger highlight area
      top: position.dy - 12,
      child: Container(
        width: size.width + 24,
        height: size.height + 24,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white,
            width: 4, // Thicker border
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.4),
              blurRadius: 25,
              spreadRadius: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(BuildContext context) {
    if (step.isIntro || step.isOutro) {
      return _buildCenterTooltip(context);
    }

    final RenderBox? renderBox =
        step.targetKey?.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return _buildCenterTooltip(context);

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    double left = 0;
    double top = 0;

    switch (step.position) {
      case TooltipPosition.bottom:
        left = position.dx + (size.width / 2) - 175;
        top = position.dy + size.height + 30;
        break;
      case TooltipPosition.top:
        left = position.dx + (size.width / 2) - 175;
        top = position.dy - 240;
        break;
      case TooltipPosition.left:
        left = position.dx - 370;
        top = position.dy + (size.height / 2) - 120;
        break;
      case TooltipPosition.right:
        left = position.dx + size.width + 30;
        top = position.dy + (size.height / 2) - 120;
        break;
    }

    // Keep tooltip on screen with more padding
    left = left.clamp(20.0, screenSize.width - 370);
    top = top.clamp(20.0, screenSize.height - 240);

    return Positioned(
      left: left,
      top: top,
      child: _buildTooltipContent(context),
    );
  }

  Widget _buildCenterTooltip(BuildContext context) {
    return Center(child: _buildTooltipContent(context));
  }

  Widget _buildTooltipContent(BuildContext context) {
    return Container(
      width: 350, // Wider for more text
      padding: const EdgeInsets.all(28), // More padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          Row(
            children: [
              Text(
                'Step $stepNumber of $totalSteps',
                style: const TextStyle(
                  fontSize: 18, // Larger text
                  color: Color(0xFF27445D),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF27445D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${(stepNumber / totalSteps * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF27445D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 26, // Much larger text
              fontWeight: FontWeight.bold,
              color: Color(0xFF27445D),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 20, // Much larger text
              color: Colors.black87,
              height: 1.5, // Better line spacing
            ),
          ),
          const SizedBox(height: 28),

          // Buttons - larger and more spaced
          Row(
            children: [
              if (onPrevious != null) ...[
                TextButton(
                  onPressed: onPrevious,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(fontSize: 18, color: Color(0xFF27445D)),
                  ),
                ),
                const SizedBox(width: 16),
              ],

              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Skip Tour',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27445D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  stepNumber == totalSteps ? 'Finish' : 'Next',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Sidebar Navigation Tile Widget (updated for seniors)
class SidebarNavigationTile extends StatefulWidget {
  final NavigationItem item;
  final bool isExpanded;
  final bool isSelected;
  final bool isDesktop;
  final VoidCallback onTap;

  const SidebarNavigationTile({
    super.key,
    required this.item,
    required this.isExpanded,
    required this.isSelected,
    required this.isDesktop,
    required this.onTap,
  });

  @override
  State<SidebarNavigationTile> createState() => _SidebarNavigationTileState();
}

class _SidebarNavigationTileState extends State<SidebarNavigationTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isDesktop ? 12 : 8,
        vertical: 6, // More spacing
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal:
                    widget.isExpanded ? (widget.isDesktop ? 20 : 16) : 12,
                vertical: widget.isDesktop ? 20 : 18, // More padding
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color:
                    widget.isSelected
                        ? Colors.white.withOpacity(0.15)
                        : _isHovered
                        ? Colors.white.withOpacity(0.1)
                        : Colors.transparent,
                border:
                    widget.isSelected
                        ? Border.all(color: Colors.white.withOpacity(0.3))
                        : null,
              ),
              child: Row(
                mainAxisAlignment:
                    widget.isExpanded
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.item.icon,
                    color: Colors.white,
                    size: widget.isDesktop ? 30 : 28, // Larger icons
                  ),
                  if (widget.isExpanded) ...[
                    SizedBox(width: widget.isDesktop ? 20 : 16),
                    Expanded(
                      child: Text(
                        widget.item.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.isDesktop ? 20 : 18, // Larger text
                          fontWeight:
                              widget.isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
