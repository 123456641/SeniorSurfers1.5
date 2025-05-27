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
  String? profilePictureUrl;
  String firstName = 'Admin';
  String lastName = 'User';
  String email = 'admin@seniorSurfers.com';
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response =
          await supabase
              .from('users')
              .select('profile_picture_url, first_name, last_name, email')
              .eq('id', user.id)
              .single();

      // Force refresh profile picture URL by adding timestamp to prevent caching
      String? pictureUrl = response['profile_picture_url'];
      if (pictureUrl != null) {
        if (pictureUrl.contains('?')) {
          pictureUrl =
              '$pictureUrl&_cache=${DateTime.now().millisecondsSinceEpoch}';
        } else {
          pictureUrl =
              '$pictureUrl?_cache=${DateTime.now().millisecondsSinceEpoch}';
        }
      }

      setState(() {
        profilePictureUrl = pictureUrl;
        firstName = response['first_name'] ?? 'Admin';
        lastName = response['last_name'] ?? 'User';
        email = response['email'] ?? 'admin@seniorSurfers.com';
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Updated logout function with confirmation dialog
  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    // If user confirmed logout
    if (confirm == true) {
      try {
        await supabase.auth.signOut();
        // After logout, navigate to welcome page
        if (mounted) {
          context.go('/'); // Redirects to WelcomePage
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Helper method to get current route index
  int _getCurrentRouteIndex() {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.contains('/analysis')) {
      return 0;
    } else if (location.contains('/community')) {
      return 1;
    }
    return 0; // Default to analysis
  }

  // Navigate based on index
  void _navigateToPage(int index) {
    switch (index) {
      case 0:
        context.go('/admin/analysis');
        break;
      case 1:
        context.go('/admin/community');
        break;
    }
    // Close the drawer if it's open on mobile
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the screen width is for mobile or web
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final int currentIndex = _getCurrentRouteIndex();

    // List of titles for AppBar
    final List<String> _titles = ['Analysis', 'Community Forum'];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F9FB),

      // AppBar shown only on mobile
      appBar:
          isMobile
              ? AppBar(
                backgroundColor: const Color(0xFF3B6EA5),
                title: Text(_titles[currentIndex]),
                elevation: 0,
                actions: [
                  // Profile icon that shows user info in a popup menu
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : PopupMenuButton<String>(
                        icon: CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFE0E0E0),
                          backgroundImage:
                              profilePictureUrl != null
                                  ? NetworkImage(profilePictureUrl!)
                                  : null,
                          child:
                              profilePictureUrl == null
                                  ? const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Color(0xFF3B6EA5),
                                  )
                                  : null,
                        ),
                        onSelected: (value) {
                          if (value == 'logout') {
                            _handleLogout();
                          }
                        },
                        itemBuilder:
                            (context) => [
                              PopupMenuItem(
                                enabled: false,
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    '$firstName $lastName',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(email),
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, color: Colors.redAccent),
                                    SizedBox(width: 8),
                                    Text(
                                      'Log Out',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                  const SizedBox(width: 16),
                ],
              )
              : null,

      // Drawer for mobile navigation
      drawer:
          isMobile
              ? Drawer(
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF3B6EA5),
                          ),
                        )
                        : Column(
                          children: [
                            // User profile header
                            UserAccountsDrawerHeader(
                              decoration: const BoxDecoration(
                                color: Color(0xFF3B6EA5),
                              ),
                              accountName: Text(
                                '$firstName $lastName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              accountEmail: Text(email),
                              currentAccountPicture: CircleAvatar(
                                backgroundColor: const Color(0xFFE0E0E0),
                                backgroundImage:
                                    profilePictureUrl != null
                                        ? NetworkImage(profilePictureUrl!)
                                        : null,
                                child:
                                    profilePictureUrl == null
                                        ? const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Color(0xFF3B6EA5),
                                        )
                                        : null,
                              ),
                            ),

                            // Navigation menu items
                            _buildDrawerItem(
                              0,
                              'Analysis',
                              Icons.analytics,
                              currentIndex,
                            ),
                            _buildDrawerItem(
                              1,
                              'Community Forum',
                              Icons.forum,
                              currentIndex,
                            ),

                            const Divider(),

                            // Logout option
                            ListTile(
                              leading: const Icon(
                                Icons.logout,
                                color: Colors.redAccent,
                              ),
                              title: const Text(
                                'Log Out',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                              onTap: _handleLogout,
                            ),
                          ],
                        ),
              )
              : null,

      // Main content body
      body: Row(
        children: [
          // Sidebar for web view
          if (!isMobile)
            Container(
              width: 250,
              color: Colors.white,
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3B6EA5),
                        ),
                      )
                      : Column(
                        children: [
                          // Admin profile section
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: const Color(0xFFE0E0E0),
                                  backgroundImage:
                                      profilePictureUrl != null
                                          ? NetworkImage(profilePictureUrl!)
                                          : null,
                                  child:
                                      profilePictureUrl == null
                                          ? const Icon(
                                            Icons.person,
                                            size: 40,
                                            color: Color(0xFF3B6EA5),
                                          )
                                          : null,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$firstName $lastName',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                              ],
                            ),
                          ),

                          // Navigation menu items
                          _buildSidebarItem(
                            0,
                            'Analysis',
                            Icons.analytics,
                            currentIndex,
                          ),
                          _buildSidebarItem(
                            1,
                            'Community Forum',
                            Icons.forum,
                            currentIndex,
                          ),
                          const Spacer(), // Pushes logout to bottom
                          // Logout option
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: InkWell(
                              onTap: _handleLogout,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                  horizontal: 24.0,
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.logout,
                                      color: Colors.redAccent,
                                      size: 24,
                                    ),
                                    SizedBox(width: 16),
                                    Text(
                                      'Log Out',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
            ),

          // Vertical divider for web view
          if (!isMobile)
            Container(width: 1, color: Colors.grey.withOpacity(0.3)),

          // Main content area
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3B6EA5), Color(0xFF3B6EA5)],
                  stops: [0.0, 0.3],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: widget.child, // Display the current routed page
              ),
            ),
          ),
        ],
      ),

      // Bottom navigation for mobile view
      bottomNavigationBar:
          isMobile
              ? BottomNavigationBar(
                backgroundColor: Colors.white,
                currentIndex: currentIndex > 1 ? 0 : currentIndex,
                onTap: _navigateToPage,
                selectedItemColor: const Color(0xFF3B6EA5),
                unselectedItemColor: Colors.grey,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.analytics),
                    label: 'Analysis',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.forum),
                    label: 'Community',
                  ),
                ],
              )
              : null,
    );
  }

  // Widget for sidebar items in web view
  Widget _buildSidebarItem(
    int index,
    String title,
    IconData icon,
    int currentIndex,
  ) {
    bool isSelected = currentIndex == index;

    return InkWell(
      onTap: () => _navigateToPage(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2F6) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFF3B6EA5) : Colors.transparent,
              width: 4.0,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF3B6EA5) : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF3B6EA5) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for drawer items in mobile view
  Widget _buildDrawerItem(
    int index,
    String title,
    IconData icon,
    int currentIndex,
  ) {
    bool isSelected = currentIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF3B6EA5) : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF3B6EA5) : Colors.black87,
        ),
      ),
      selected: isSelected,
      onTap: () => _navigateToPage(index),
    );
  }
}
