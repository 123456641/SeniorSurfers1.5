import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  final Widget child;

  const AdminDashboard({Key? key, required this.child}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Design System Constants
  static const Color _primaryColor = Color(0xFF3B6EA5);
  static const Color _primaryLightColor = Color(0xFF5A8BC4);
  static const Color _primaryDarkColor =
      Color(0xFF2A5A87); // Added for consistency
  static const Color _backgroundColor = Color(0xFFF7F9FB);
  static const Color _surfaceColor = Colors.white;
  static const Color _errorColor = Color(0xFFE53E3E);
  static const Color _errorLightColor =
      Color(0xFFFC8181); // Added for consistency
  static const Color _successColor = Color(0xFF38A169);
  static const Color _successLightColor =
      Color(0xFF68D391); // Added for consistency
  static const Color _warningColor = Color(0xFFD69E2E);
  static const Color _warningLightColor =
      Color(0xFFF6E05E); // Added for consistency
  static const Color _dividerColor = Color(0xFFE2E8F0);
  static const Color _selectedBackgroundColor = Color(0xFFEDF2F7);
  static const Color _hoverColor = Color(0xFFF7FAFC);
  static const Color _textPrimaryColor = Color(0xFF2D3748);
  static const Color _textSecondaryColor = Color(0xFF718096);
  static const Color _textTertiaryColor = Color(0xFFA0AEC0);

  // Layout Constants
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900; // Added for consistency
  static const double _desktopBreakpoint = 1200; // Added for consistency
  static const double _sidebarWidth = 280;
  static const double _sidebarCollapsedWidth = 70; // Added for consistency

  // Spacing Constants
  static const double _spacingXs = 4.0;
  static const double _spacingS = 8.0;
  static const double _spacingM = 12.0;
  static const double _spacingL = 16.0;
  static const double _spacingXl = 20.0;
  static const double _spacingXxl = 24.0;
  static const double _spacingXxxl = 32.0;
  static const double _spacingXxxxl = 40.0; // Added for consistency

  // Size Constants
  static const double _profileAvatarRadius = 40;
  static const double _appBarAvatarRadius = 16;
  static const double _statusIndicatorSize = 16;
  static const double _borderRadius = 12.0;
  static const double _borderRadiusS = 8.0; // Added for consistency
  static const double _borderRadiusL = 16.0; // Added for consistency
  static const double _cardElevation = 2.0;
  static const double _cardElevationHigh = 4.0; // Added for consistency
  static const double _iconSize = 20;
  static const double _iconSizeS = 16; // Added for consistency
  static const double _iconSizeL = 22;
  static const double _iconSizeXl = 24; // Added for consistency

  // Typography Constants
  static const double _fontSizeXs = 11;
  static const double _fontSizeS = 12;
  static const double _fontSizeM = 13;
  static const double _fontSizeL = 15;
  static const double _fontSizeXl = 16;
  static const double _fontSizeXxl = 18;
  static const double _fontSizeXxxl = 20; // Added for consistency

  static const FontWeight _fontWeightLight =
      FontWeight.w300; // Added for consistency
  static const FontWeight _fontWeightRegular = FontWeight.w400;
  static const FontWeight _fontWeightMedium = FontWeight.w500;
  static const FontWeight _fontWeightSemiBold = FontWeight.w600;
  static const FontWeight _fontWeightBold = FontWeight.w700;
  static const FontWeight _fontWeightExtraBold =
      FontWeight.w800; // Added for consistency

  // Animation Constants - Added for consistency
  static const Duration _animationDurationFast = Duration(milliseconds: 150);
  static const Duration _animationDurationMedium = Duration(milliseconds: 200);
  static const Duration _animationDurationSlow = Duration(milliseconds: 300);

  // Elevation Constants - Added for consistency
  static const double _elevationLow = 1.0;
  static const double _elevationMedium = 2.0;
  static const double _elevationHigh = 4.0;
  static const double _elevationVeryHigh = 8.0;

  // User data
  String? profilePictureUrl;
  String firstName = 'Admin';
  String lastName = 'User';
  String email = 'admin@seniorSurfers.com';
  bool _isLoading = true;
  bool _isOffline = false; // Added for consistency
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final SupabaseClient supabase = Supabase.instance.client;

  // Navigation configuration
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      index: 0,
      title: 'Analysis',
      icon: Icons.analytics,
      route: '/admin/analysis',
    ),
    NavigationItem(
      index: 1,
      title: 'Community Forum',
      icon: Icons.forum,
      route: '/admin/community',
    ),
    NavigationItem(
      index: 2,
      title: 'Video Tutorials',
      icon: Icons.video_library_outlined,
      route: '/admin/tutorials',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Data fetching methods
  Future<void> _fetchUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _setLoadingState(false);
      return;
    }

    try {
      final response = await supabase
          .from('users')
          .select('profile_picture_url, first_name, last_name, email')
          .eq('id', user.id)
          .single();

      _updateUserData(response);
    } catch (e) {
      _handleError('Error fetching user data: $e');
    }
  }

  void _updateUserData(Map<String, dynamic> response) {
    String? pictureUrl = response['profile_picture_url'];
    if (pictureUrl != null) {
      pictureUrl = _addCacheBuster(pictureUrl);
    }

    setState(() {
      profilePictureUrl = pictureUrl;
      firstName = response['first_name'] ?? 'Admin';
      lastName = response['last_name'] ?? 'User';
      email = response['email'] ?? 'admin@seniorSurfers.com';
      _isLoading = false;
    });
  }

  String _addCacheBuster(String url) {
    final cacheBuster = '_cache=${DateTime.now().millisecondsSinceEpoch}';
    return url.contains('?') ? '$url&$cacheBuster' : '$url?$cacheBuster';
  }

  void _setLoadingState(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  void _handleError(String error) {
    print(error);
    _setLoadingState(false);
    if (mounted) {
      _showSnackBar(error, _errorColor);
    }
  }

  // Enhanced snackbar method for consistency
  void _showSnackBar(
    String message,
    Color backgroundColor, {
    SnackBarType type = SnackBarType.error,
    Duration duration = const Duration(seconds: 4),
  }) {
    IconData icon;
    switch (type) {
      case SnackBarType.success:
        icon = Icons.check_circle_rounded;
        break;
      case SnackBarType.warning:
        icon = Icons.warning_rounded;
        break;
      case SnackBarType.info:
        icon = Icons.info_rounded;
        break;
      case SnackBarType.error:
      default:
        icon = Icons.error_rounded;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: _surfaceColor,
              size: _iconSize,
            ),
            const SizedBox(width: _spacingM),
            Expanded(
              child: Text(
                message,
                style: _getTextStyle(
                  fontSize: _fontSizeL,
                  fontWeight: _fontWeightMedium,
                  color: _surfaceColor,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      ),
    );
  }

  // Helper methods for consistent snackbar usage
  void _showSuccessSnackBar(String message) {
    _showSnackBar(message, _successColor, type: SnackBarType.success);
  }

  void _showWarningSnackBar(String message) {
    _showSnackBar(message, _warningColor, type: SnackBarType.warning);
  }

  void _showInfoSnackBar(String message) {
    _showSnackBar(message, _primaryColor, type: SnackBarType.info);
  }

  void _showErrorSnackBar(String message) {
    _showSnackBar(message, _errorColor, type: SnackBarType.error);
  }

  // Navigation methods
  int _getCurrentRouteIndex() {
    final String location = GoRouterState.of(context).matchedLocation;
    for (final item in _navigationItems) {
      if (location.contains(item.route.split('/').last)) {
        return item.index;
      }
    }
    return 0;
  }

  void _navigateToPage(int index) {
    if (index >= 0 && index < _navigationItems.length) {
      context.go(_navigationItems[index].route);
      _closeDrawerIfOpen();
    }
  }

  void _closeDrawerIfOpen() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  // Authentication methods
  Future<void> _handleLogout() async {
    final bool? confirm = await _showLogoutDialog();
    if (confirm == true) {
      await _performLogout();
    }
  }

  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          title: Text(
            'Confirm Logout',
            style: _getTextStyle(
              fontSize: _fontSizeXxl,
              fontWeight: _fontWeightSemiBold,
              color: _textPrimaryColor,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: _getTextStyle(
              fontSize: _fontSizeL,
              fontWeight: _fontWeightRegular,
              color: _textSecondaryColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: _getTextStyle(
                  fontSize: _fontSizeL,
                  fontWeight: _fontWeightMedium,
                  color: _textSecondaryColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Logout',
                style: _getTextStyle(
                  fontSize: _fontSizeL,
                  fontWeight: _fontWeightMedium,
                  color: _errorColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error signing out: $e');
      }
    }
  }

  // UI Helper methods
  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < _mobileBreakpoint;
  }

  bool _isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _mobileBreakpoint && width < _desktopBreakpoint;
  }

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= _desktopBreakpoint;
  }

  String get _fullName => '$firstName $lastName';

  NavigationItem _getCurrentNavItem() {
    final currentIndex = _getCurrentRouteIndex();
    return currentIndex < _navigationItems.length
        ? _navigationItems[currentIndex]
        : _navigationItems[0];
  }

  String get _currentPageTitle => _getCurrentNavItem().title;

  // Consistent text style method
  TextStyle _getTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double letterSpacing = 0.1,
    double height = 1.2,
    TextDecoration decoration = TextDecoration.none,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }

  // Enhanced box decoration method for consistency
  BoxDecoration _getCardDecoration({
    Color? color,
    Color? borderColor,
    bool hasShadow = true,
    bool isSelected = false,
    double elevation = _elevationMedium,
    double borderRadius = _borderRadius,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      color: color ?? _surfaceColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: borderColor != null
          ? Border.all(color: borderColor, width: borderWidth)
          : isSelected
              ? Border.all(
                  color: _primaryColor.withOpacity(0.3), width: borderWidth)
              : null,
      boxShadow: hasShadow
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
                blurRadius: isSelected ? elevation * 2 : elevation,
                offset: Offset(0, isSelected ? elevation / 2 : elevation / 4),
              ),
            ]
          : null,
    );
  }

  // Enhanced container decoration method for consistency
  BoxDecoration _getContainerDecoration({
    required Color backgroundColor,
    bool isCircular = false,
    double borderRadius = _borderRadiusS,
    Color? borderColor,
    double borderWidth = 1.0,
    bool hasShadow = false,
    double elevation = _elevationLow,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: isCircular ? null : BorderRadius.circular(borderRadius),
      shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
      border: borderColor != null
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
      boxShadow: hasShadow
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: elevation,
                offset: Offset(0, elevation / 2),
              ),
            ]
          : null,
    );
  }

  // Enhanced gradient decoration method for consistency
  BoxDecoration _getGradientDecoration({
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    double borderRadius = _borderRadius,
    bool isCircular = false,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: begin,
        end: end,
        colors: colors,
      ),
      borderRadius: isCircular ? null : BorderRadius.circular(borderRadius),
      shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
    );
  }

  // Widget builders
  Widget _buildProfileAvatar({
    required double radius,
    bool isAppBar = false,
    bool hasBorder = false,
    Color borderColor = _primaryColor,
    double borderWidth = 2.0,
  }) {
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: _dividerColor,
      backgroundImage:
          profilePictureUrl != null ? NetworkImage(profilePictureUrl!) : null,
      child: profilePictureUrl == null
          ? Icon(
              Icons.person,
              size: radius,
              color: _primaryColor,
            )
          : null,
    );

    if (hasBorder) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildLoadingIndicator({
    Color? color,
    double strokeWidth = 2,
    double size = _iconSize,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: color ?? _primaryColor,
        strokeWidth: strokeWidth,
      ),
    );
  }

  Widget _buildStatusIndicator({
    bool isOnline = true,
    double size = _statusIndicatorSize,
    Color? onlineColor,
    Color? offlineColor,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: _getContainerDecoration(
        backgroundColor: isOnline
            ? (onlineColor ?? _successColor)
            : (offlineColor ?? _textTertiaryColor),
        isCircular: true,
        borderColor: _surfaceColor,
        borderWidth: 2,
      ),
    );
  }

  Widget _buildIconContainer({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    double size = _iconSize,
    double padding = _spacingS,
    bool isCircular = false,
    VoidCallback? onTap,
  }) {
    Widget container = Container(
      padding: EdgeInsets.all(padding),
      decoration: _getContainerDecoration(
        backgroundColor: backgroundColor,
        isCircular: isCircular,
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: size,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: isCircular ? null : BorderRadius.circular(_spacingS),
        child: container,
      );
    }

    return container;
  }

  Widget _buildNavigationItem({
    required int index,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isSidebar = false,
  }) {
    if (isSidebar) {
      return _buildSidebarItem(index, title, icon, isSelected, onTap);
    } else {
      return _buildDrawerItem(title, icon, isSelected, onTap);
    }
  }

  Widget _buildSidebarItem(
    int index,
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: _spacingM,
        vertical: _spacingXs,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_borderRadius),
          hoverColor: _hoverColor,
          child: AnimatedContainer(
            duration: _animationDurationMedium,
            padding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: _spacingL,
            ),
            decoration: _getCardDecoration(
              color: isSelected ? _selectedBackgroundColor : Colors.transparent,
              isSelected: isSelected,
              hasShadow: isSelected,
            ),
            child: Row(
              children: [
                _buildIconContainer(
                  icon: icon,
                  iconColor: isSelected ? _primaryColor : _textSecondaryColor,
                  backgroundColor: isSelected
                      ? _primaryColor.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                ),
                const SizedBox(width: _spacingM),
                Expanded(
                  child: Text(
                    title,
                    style: _getTextStyle(
                      fontSize: _fontSizeL,
                      fontWeight:
                          isSelected ? _fontWeightSemiBold : _fontWeightMedium,
                      color: isSelected ? _primaryColor : _textPrimaryColor,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: _getContainerDecoration(
                      backgroundColor: _primaryColor,
                      isCircular: true,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: _spacingS,
        vertical: 2.0,
      ),
      child: ListTile(
        leading: _buildIconContainer(
          icon: icon,
          iconColor: isSelected ? _primaryColor : _textSecondaryColor,
          backgroundColor: isSelected
              ? _primaryColor.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
        ),
        title: Text(
          title,
          style: _getTextStyle(
            fontSize: _fontSizeL,
            fontWeight: isSelected ? _fontWeightSemiBold : _fontWeightMedium,
            color: isSelected ? _primaryColor : _textPrimaryColor,
          ),
        ),
        selected: isSelected,
        selectedTileColor: _selectedBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutOption({bool isSidebar = false}) {
    if (isSidebar) {
      return Container(
        margin: const EdgeInsets.all(_spacingL),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleLogout,
            borderRadius: BorderRadius.circular(_borderRadius),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 14.0,
                horizontal: _spacingL,
              ),
              decoration: _getCardDecoration(
                color: _errorColor.withOpacity(0.05),
                borderColor: _errorColor.withOpacity(0.3),
                hasShadow: false,
              ),
              child: Row(
                children: [
                  _buildIconContainer(
                    icon: Icons.logout_rounded,
                    iconColor: _errorColor,
                    backgroundColor: _errorColor.withOpacity(0.1),
                  ),
                  const SizedBox(width: _spacingM),
                  Text(
                    'Log Out',
                    style: _getTextStyle(
                      fontSize: _fontSizeL,
                      fontWeight: _fontWeightMedium,
                      color: _errorColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return ListTile(
        leading: _buildIconContainer(
          icon: Icons.logout_rounded,
          iconColor: _errorColor,
          backgroundColor: _errorColor.withOpacity(0.1),
        ),
        title: Text(
          'Log Out',
          style: _getTextStyle(
            fontSize: _fontSizeL,
            fontWeight: _fontWeightMedium,
            color: _errorColor,
          ),
        ),
        onTap: _handleLogout,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = _isMobile(context);
    final int currentIndex = _getCurrentRouteIndex();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _backgroundColor,
      appBar: isMobile ? _buildMobileAppBar() : null,
      drawer: isMobile ? _buildMobileDrawer(currentIndex) : null,
      body: _buildBody(isMobile, currentIndex),
      bottomNavigationBar:
          isMobile ? _buildBottomNavigation(currentIndex) : null,
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: _primaryColor,
      elevation: 0,
      title: Row(
        children: [
          Icon(
            _getCurrentNavItem().icon,
            color: _surfaceColor,
            size: _fontSizeXxl,
          ),
          const SizedBox(width: _spacingS),
          Text(
            _currentPageTitle,
            style: _getTextStyle(
              fontSize: _fontSizeXxl,
              fontWeight: _fontWeightSemiBold,
              color: _surfaceColor,
            ),
          ),
        ],
      ),
      actions: [
        _isLoading
            ? Padding(
                padding: const EdgeInsets.all(_spacingL),
                child: _buildLoadingIndicator(color: _surfaceColor),
              )
            : _buildProfileMenuButton(),
        const SizedBox(width: _spacingL),
      ],
      flexibleSpace: Container(
        decoration: _getGradientDecoration(
          colors: [_primaryColor, _primaryLightColor],
        ),
      ),
    );
  }

  Widget _buildProfileMenuButton() {
    return PopupMenuButton<String>(
      icon: _buildProfileAvatar(radius: _appBarAvatarRadius, isAppBar: true),
      onSelected: (value) {
        if (value == 'logout') {
          _handleLogout();
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _fullName,
              style: _getTextStyle(
                fontSize: _fontSizeL,
                fontWeight: _fontWeightSemiBold,
                color: _textPrimaryColor,
              ),
            ),
            subtitle: Text(
              email,
              style: _getTextStyle(
                fontSize: _fontSizeS,
                fontWeight: _fontWeightRegular,
                color: _textSecondaryColor,
              ),
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: _errorColor, size: _iconSize),
              const SizedBox(width: _spacingS),
              Text(
                'Log Out',
                style: _getTextStyle(
                  fontSize: _fontSizeL,
                  fontWeight: _fontWeightMedium,
                  color: _errorColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileDrawer(int currentIndex) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(_borderRadius),
          bottomRight: Radius.circular(_borderRadius),
        ),
      ),
      child: _isLoading
          ? Center(child: _buildLoadingIndicator())
          : Column(
              children: [
                _buildDrawerHeader(),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ..._navigationItems.map((item) => _buildNavigationItem(
                            index: item.index,
                            title: item.title,
                            icon: item.icon,
                            isSelected: currentIndex == item.index,
                            onTap: () => _navigateToPage(item.index),
                          )),
                      const Divider(
                        color: _dividerColor,
                        thickness: 1,
                        indent: _spacingL,
                        endIndent: _spacingL,
                      ),
                      _buildLogoutOption(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      height: 200,
      decoration: _getGradientDecoration(
        colors: [_primaryColor, _primaryLightColor],
      ),
      child: Padding(
        padding: const EdgeInsets.all(_spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: _spacingXxxl + _spacingS),
            Row(
              children: [
                Stack(
                  children: [
                    _buildProfileAvatar(
                      radius: 30,
                      hasBorder: true,
                      borderColor: _surfaceColor,
                      borderWidth: 3,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _buildStatusIndicator(isOnline: !_isOffline),
                    ),
                  ],
                ),
                const SizedBox(width: _spacingL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fullName,
                        style: _getTextStyle(
                          fontSize: _fontSizeXxl,
                          fontWeight: _fontWeightSemiBold,
                          color: _surfaceColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: _spacingXs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _spacingS,
                          vertical: 2,
                        ),
                        decoration: _getContainerDecoration(
                          backgroundColor: _surfaceColor.withOpacity(0.2),
                          borderRadius: _spacingM,
                        ),
                        child: Text(
                          'Administrator',
                          style: _getTextStyle(
                            fontSize: _fontSizeXs,
                            fontWeight: _fontWeightMedium,
                            color: _surfaceColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: _spacingM),
            Text(
              email,
              style: _getTextStyle(
                fontSize: _fontSizeM,
                fontWeight: _fontWeightRegular,
                color: _surfaceColor.withOpacity(0.9),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isMobile, int currentIndex) {
    return Row(
      children: [
        if (!isMobile) _buildSidebar(currentIndex),
        if (!isMobile) _buildVerticalDivider(),
        _buildMainContent(isMobile),
      ],
    );
  }

  Widget _buildSidebar(int currentIndex) {
    return Container(
      width: _sidebarWidth,
      color: _surfaceColor,
      child: _isLoading
          ? Center(child: _buildLoadingIndicator())
          : Column(
              children: [
                _buildSidebarProfile(),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: _navigationItems
                        .map((item) => _buildNavigationItem(
                              index: item.index,
                              title: item.title,
                              icon: item.icon,
                              isSelected: currentIndex == item.index,
                              onTap: () => _navigateToPage(item.index),
                              isSidebar: true,
                            ))
                        .toList(),
                  ),
                ),
                _buildLogoutOption(isSidebar: true),
              ],
            ),
    );
  }

  Widget _buildSidebarProfile() {
    return Container(
      margin: const EdgeInsets.all(_spacingL),
      padding: const EdgeInsets.all(_spacingXl),
      decoration: _getCardDecoration(),
      child: Column(
        children: [
          Stack(
            children: [
              _buildProfileAvatar(
                radius: _profileAvatarRadius,
                hasBorder: true,
                borderColor: _primaryColor.withOpacity(0.2),
                borderWidth: 3,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: _buildStatusIndicator(isOnline: !_isOffline),
              ),
            ],
          ),
          const SizedBox(height: _spacingM),
          Text(
            _fullName,
            style: _getTextStyle(
              fontSize: _fontSizeXl,
              fontWeight: _fontWeightSemiBold,
              color: _textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: _spacingXs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: _spacingS,
              vertical: 2,
            ),
            decoration: _getContainerDecoration(
              backgroundColor: _primaryColor.withOpacity(0.1),
              borderRadius: _spacingM,
            ),
            child: Text(
              'Administrator',
              style: _getTextStyle(
                fontSize: _fontSizeXs,
                fontWeight: _fontWeightMedium,
                color: _primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: _spacingS),
          Text(
            email,
            style: _getTextStyle(
              fontSize: _fontSizeS,
              fontWeight: _fontWeightRegular,
              color: _textSecondaryColor,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(width: 1, color: _dividerColor);
  }

  Widget _buildMainContent(bool isMobile) {
    return Expanded(
      child: Container(
        decoration: _getGradientDecoration(
          colors: [
            _primaryColor.withOpacity(0.1),
            _backgroundColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        child: Container(
          margin: EdgeInsets.all(isMobile ? _spacingS : _spacingL),
          decoration: _getCardDecoration(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_borderRadius),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? _spacingL : _spacingXxl),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(int currentIndex) {
    return Container(
      decoration: _getCardDecoration(
        hasShadow: true,
        elevation: _elevationHigh,
      ).copyWith(
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: _surfaceColor,
        currentIndex: currentIndex > 2 ? 0 : currentIndex,
        onTap: _navigateToPage,
        selectedItemColor: _primaryColor,
        unselectedItemColor: _textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: _getTextStyle(
          fontSize: _fontSizeS,
          fontWeight: _fontWeightSemiBold,
          color: _primaryColor,
        ),
        unselectedLabelStyle: _getTextStyle(
          fontSize: _fontSizeXs,
          fontWeight: _fontWeightMedium,
          color: _textSecondaryColor,
        ),
        elevation: 0,
        items: _navigationItems
            .map((item) => BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(_spacingXs),
                    child: Icon(item.icon, size: _iconSizeL),
                  ),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(_spacingXs),
                    decoration: _getContainerDecoration(
                      backgroundColor: _primaryColor.withOpacity(0.1),
                    ),
                    child: Icon(item.icon, size: _iconSizeL),
                  ),
                  label: item.title.split(' ').first,
                ))
            .toList(),
      ),
    );
  }
}

// Helper class for navigation configuration
class NavigationItem {
  final int index;
  final String title;
  final IconData icon;
  final String route;

  const NavigationItem({
    required this.index,
    required this.title,
    required this.icon,
    required this.route,
  });
}

// Enum for snackbar types - Added for consistency
enum SnackBarType {
  success,
  error,
  warning,
  info,
}
