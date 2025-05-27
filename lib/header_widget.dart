import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final Widget? action;

  const HeaderWidget({
    super.key,
    this.title = 'Senior Surfers',
    this.showBackButton = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading:
          showBackButton
              ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.pop(); // This goes back to the previous page
                },
              )
              : null,
      title: Row(
        children: [
          Image.asset(
            'assets/images/seniorsurfersLogoNoName.png',
            height: 50,
            width: 50,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'RobotoSerif',
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: action != null ? [action!] : null,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF528FC3), Color(0xFF27445D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
