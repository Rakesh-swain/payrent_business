import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:get/get.dart';
import 'package:payrent_business/controllers/user_profile_controller.dart';

class WebTopbar extends StatelessWidget {
  final String title;
  final String userType;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;
  final bool isMobile;

  const WebTopbar({
    super.key,
    required this.title,
    required this.userType,
    this.showMenuButton = false,
    this.onMenuPressed,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isMobile ? 56 : 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 8 : 12,
        ),
        child: Row(
          children: [
            // Menu button (for collapsible sidebar or mobile drawer)
            if (showMenuButton) ...[
              IconButton(
                onPressed: onMenuPressed,
                icon: const Icon(Icons.menu),
                color: Colors.grey[700],
                iconSize: isMobile ? 24 : 28,
              ),
              SizedBox(width: isMobile ? 8 : 16),
            ],
            
            // Page title
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            
            // Search bar (desktop only)
            if (!isMobile) ...[
              Container(
                width: 300,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
            
            // Notifications button
            _buildIconButton(
              icon: Icons.notifications_outlined,
              onPressed: () {
                // Handle notifications
              },
              hasNotification: true,
            ),
            
            SizedBox(width: isMobile ? 8 : 16),
            
            // Settings button
            _buildIconButton(
              icon: Icons.settings_outlined,
              onPressed: () {
                // Handle settings
              },
            ),
            
            SizedBox(width: isMobile ? 8 : 16),
            
            // User profile button
            _buildUserProfileButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool hasNotification = false,
  }) {
    return Stack(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: Colors.grey[600],
            size: isMobile ? 22 : 24,
          ),
          padding: EdgeInsets.all(isMobile ? 8 : 12),
        ),
        if (hasNotification)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserProfileButton() {
    return GetBuilder<UserProfileController>(
      builder: (profileController) {
        return PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'profile':
                // Navigate to profile
                break;
              case 'settings':
                // Navigate to settings
                break;
              case 'logout':
                // Handle logout
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Profile',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(
                    Icons.settings_outlined,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Settings',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(
                    Icons.logout,
                    size: 18,
                    color: Colors.red[600],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: isMobile ? 6 : 4,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: isMobile ? 14 : 16,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: isMobile ? 16 : 18,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profileController.name.value.isNotEmpty
                            ? profileController.name.value
                            : userType,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        userType,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}