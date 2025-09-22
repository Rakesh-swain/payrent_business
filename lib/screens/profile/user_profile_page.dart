import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/screens/auth/login_page.dart';
import 'dart:io';

import 'package:percent_indicator/linear_percent_indicator.dart';

class UserProfilePage extends StatefulWidget {
  final bool isLandlord;
  const UserProfilePage({super.key, this.isLandlord = true});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  
  // Sample user data
  Map<String, dynamic> _userData = {};
  
  // Sample completion data
  final Map<String, bool> _completionStatus = {
    'personalInfo': true,
    'address': true,
    'contact': false,
    'paymentInfo': false,
    'verification': false,
  };
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize with mock data
    if (widget.isLandlord) {
      _userData = {
        'name': 'Sarah Thompson',
        'email': 'sarah.thompson@example.com',
        'phone': '+1 (234) 567-8901',
        'address': '123 Business Ave, Suite 200, San Francisco, CA 94107',
        'businessName': 'Thompson Properties LLC',
        'accountType': 'Landlord',
        'joinDate': '2022-05-15',
        'properties': 8,
        'tenants': 6,
      };
    } else {
      _userData = {
        'name': 'John Doe',
        'email': 'john.doe@example.com',
        'phone': '+1 (123) 456-7890',
        'address': '456 Park Avenue, Apt 303, New York, NY 10022',
        'property': 'Modern Apartment in Downtown',
        'landlord': 'Sarah Thompson',
        'accountType': 'Tenant',
        'leaseStart': '2023-01-15',
        'leaseEnd': '2024-01-15',
      };
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }
  
  double get _profileCompletionPercent {
    int completed = _completionStatus.values.where((value) => value).length;
    return completed / _completionStatus.length;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title:  Text('My Profile',style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              )),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView( physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Profile Image
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                backgroundImage: _profileImage != null
                                    ? FileImage(_profileImage!) as ImageProvider
                                    : const AssetImage('assets/profile.png'),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userData['name'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _userData['accountType'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.mail_outline,
                                    size: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _userData['email'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone_outlined,
                                    size: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _userData['phone'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Profile Completion
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Profile Completion',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${(_profileCompletionPercent * 100).toInt()}%',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearPercentIndicator(
                          padding: EdgeInsets.zero,
                          lineHeight: 8.0,
                          percent: _profileCompletionPercent,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          progressColor: AppTheme.primaryColor,
                          barRadius: const Radius.circular(4),
                          animation: true,
                          animationDuration: 1000,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildCompletionChip(
                              'Personal Info',
                              _completionStatus['personalInfo'] ?? false,
                            ),
                            _buildCompletionChip(
                              'Address',
                              _completionStatus['address'] ?? false,
                            ),
                            _buildCompletionChip(
                              'Contact',
                              _completionStatus['contact'] ?? false,
                            ),
                            _buildCompletionChip(
                              'Payment Info',
                              _completionStatus['paymentInfo'] ?? false,
                            ),
                            _buildCompletionChip(
                              'Verification',
                              _completionStatus['verification'] ?? false,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Profile Tabs
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.primaryColor,
                  tabs: [
                    Tab(
                      text: widget.isLandlord ? 'Details' : 'Personal',
                    ),
                    Tab(
                      text: widget.isLandlord ? 'Business' : 'Lease',
                    ),
                    const Tab(
                      text: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(
              height: 500, // Set a fixed height or use a different approach for dynamic height
              child: TabBarView(
                controller: _tabController,
                children: [
                  // First Tab: Personal Details
                  _buildPersonalDetailsTab(),
                  
                  // Second Tab: Business/Lease Details
                  widget.isLandlord
                      ? _buildBusinessDetailsTab()
                      : _buildLeaseDetailsTab(),
                  
                  // Third Tab: Settings
                  _buildSettingsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompletionChip(String label, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppTheme.successColor.withOpacity(0.1)
            : AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? AppTheme.successColor.withOpacity(0.3)
              : AppTheme.warningColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.pending_outlined,
            size: 14,
            color: isCompleted ? AppTheme.successColor : AppTheme.warningColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isCompleted ? AppTheme.successColor : AppTheme.warningColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPersonalDetailsTab() {
    return SingleChildScrollView( physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection(
            title: 'Personal Information',
            fields: [
              _buildDetailItem('Full Name', _userData['name'] ?? '', Icons.person_outline),
              _buildDetailItem('Email', _userData['email'] ?? '', Icons.mail_outline),
              _buildDetailItem('Phone', _userData['phone'] ?? '', Icons.phone_outlined),
            ],
            canEdit: true,
          ),
          const SizedBox(height: 16),
          _buildDetailSection(
            title: 'Address',
            fields: [
              _buildDetailItem('Address', _userData['address'] ?? '', Icons.home_outlined),
            ],
            canEdit: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildBusinessDetailsTab() {
    return SingleChildScrollView( physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection(
            title: 'Business Information',
            fields: [
              _buildDetailItem('Business Name', _userData['businessName'] ?? '', Icons.business_outlined),
              _buildDetailItem('Member Since', _formatDate(_userData['joinDate'] ?? ''), Icons.calendar_today_outlined),
            ],
            canEdit: true,
          ),
          const SizedBox(height: 16),
          _buildDetailSection(
            title: 'Portfolio Summary',
            fields: [
              _buildDetailItem('Properties', '${_userData['properties'] ?? 0}', Icons.home_work_outlined),
              _buildDetailItem('Tenants', '${_userData['tenants'] ?? 0}', Icons.people_outline),
            ],
            canEdit: false,
          ),
        ],
      ),
    );
  }
  
  Widget _buildLeaseDetailsTab() {
    return SingleChildScrollView( physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection(
            title: 'Lease Information',
            fields: [
              _buildDetailItem('Property', _userData['property'] ?? '', Icons.home_outlined),
              _buildDetailItem('Landlord', _userData['landlord'] ?? '', Icons.person_outline),
              _buildDetailItem('Lease Start', _formatDate(_userData['leaseStart'] ?? ''), Icons.calendar_today_outlined),
              _buildDetailItem('Lease End', _formatDate(_userData['leaseEnd'] ?? ''), Icons.calendar_today_outlined),
            ],
            canEdit: false,
          ),
        ],
      ),
    );
  }
  
  // Widget _buildSettingsTab() {
  //   return SingleChildScrollView( physics: const BouncingScrollPhysics(),
  //     padding: const EdgeInsets.all(16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         _buildSettingItem('Change Password', Icons.lock_outline, () {}),
  //         _buildSettingItem('Notifications', Icons.notifications_outlined, () {}),
  //         _buildSettingItem('Payment Methods', Icons.payment_outlined, () {}),
  //         _buildSettingItem('Privacy Settings', Icons.security_outlined, () {}),
  //         _buildSettingItem('Terms & Conditions', Icons.description_outlined, () {}),
  //         _buildSettingItem('Help & Support', Icons.help_outline, () {}),
  //         const Divider(height: 32),
  //         _buildSettingItem('Logout', Icons.logout_outlined, () {}, isDestructive: true),
  //       ],
  //     ),
  //   );
  // }
  
  Widget _buildDetailSection({
    required String title,
    required List<Widget> fields,
    required bool canEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (canEdit)
                TextButton.icon(
                  onPressed: () {
                    // Handle edit action
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                  ),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...fields,
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // lib/modules/profile/user_profile_page.dart (update)

// Add logout method to the UserProfilePage
void _logout(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.offAll(LoginPage());
            
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    },
  );
}
// lib/modules/profile/user_profile_page.dart (updated profile settings section)

Widget _buildSettingsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     
      const SizedBox(height: 16),
      _buildSettingItem(
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        subtitle: 'Manage notification preferences',
        onTap: () {
          // Navigate to notifications settings
        },
      ),
      _buildSettingItem(
        icon: Icons.lock_outline,
        title: 'Privacy & Security',
        subtitle: 'Manage privacy settings and security options',
        onTap: () {
          // Navigate to privacy settings
        },
      ),
      _buildSettingItem(
        icon: Icons.help_outline,
        title: 'Help & Support',
        subtitle: 'Get help and contact support',
        onTap: () {
          // Navigate to help & support
        },
      ),
      _buildSettingItem(
        icon: Icons.info_outline,
        title: 'About',
        subtitle: 'App version, terms of service, and privacy policy',
        onTap: () {
          // Navigate to about page
        },
      ),
      _buildSettingItem(
        icon: Icons.logout,
        title: 'Logout',
        subtitle: 'Sign out from your account',
        onTap: () {
          _logout(context);
        },
        isDestructive: true,
      ),
    ],
  );
}

Widget _buildSettingItem({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  bool isDestructive = false,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16,horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDestructive
                  ? AppTheme.errorColor.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDestructive ? AppTheme.errorColor : AppTheme.textSecondary,
          ),
        ],
      ),
    ),
  );
}
  
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}