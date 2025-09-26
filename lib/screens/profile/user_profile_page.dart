import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/screens/auth/login_page.dart';
import 'dart:io';

import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:payrent_business/controllers/user_profile_controller.dart';
import 'package:payrent_business/controllers/auth_controller.dart';
import 'package:payrent_business/services/storage_service.dart';

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
  
  // Controllers
  final UserProfileController _userProfileController = Get.find<UserProfileController>();
  final AuthController _authController = Get.find<AuthController>();
  
  // User data
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
    
    // Initialize default data structure
    _userData = {
      'name': '',
      'email': '',
      'phone': '',
      'address': '',
      'businessName': '',
      'accountType': widget.isLandlord ? 'Landlord' : 'Tenant',
      'joinDate': DateTime.now().toString(),
      'isUploading': false,
    };
    
    if (widget.isLandlord) {
      _userData['properties'] = 0;
      _userData['tenants'] = 0;
    } else {
      _userData['property'] = '';
      _userData['landlord'] = '';
      _userData['leaseStart'] = '';
      _userData['leaseEnd'] = '';
    }
    
    // Fetch user data from Firestore
    _fetchUserData();
  }
  
  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    try {
      await _userProfileController.getUserProfile();
      
      setState(() {
        _userData['name'] = _userProfileController.name.value;
        _userData['email'] = _userProfileController.email.value;
        _userData['phone'] = _userProfileController.phone.value;
        _userData['businessName'] = _userProfileController.businessName.value;
        _userData['accountType'] = _userProfileController.userType.value.capitalizeFirst;
        _userData['address'] = _userProfileController.address.value;
        // If profile image URL exists, update it
        if (_userProfileController.profileImageUrl.value.isNotEmpty) {
          _userData['profileImage'] = _userProfileController.profileImageUrl.value;
        }
      });
      
      // Update completion status based on data
      _updateCompletionStatus();
      
    } catch (e) {
      print('Error fetching user data: $e');
      // Show an error snackbar
      Get.snackbar(
        'Error',
        'Failed to load profile data',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.errorColor.withOpacity(0.1),
        colorText: AppTheme.errorColor,
      );
    }
  }
  
  // Update completion status based on user data
  void _updateCompletionStatus() {
    setState(() {
      _completionStatus['personalInfo'] = _userData['name'] != null && _userData['name'].isNotEmpty;
      _completionStatus['contact'] = (_userData['email'] != null && _userData['email'].isNotEmpty) || 
                                     (_userData['phone'] != null && _userData['phone'].isNotEmpty);
      // You can add more completion status logic here
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
          _userData['isUploading'] = true;
        });
        
        // Upload the image to Firebase Storage
        await _uploadProfileImage(File(pickedFile.path));
      }
    } catch (e) {
      print('Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.errorColor.withOpacity(0.1),
        colorText: AppTheme.errorColor,
      );
    }
  }
  
  // Upload profile image to Firebase Storage
  Future<void> _uploadProfileImage(File imageFile) async {
    try {
      await _userProfileController.uploadProfileImage(imageFile);
      
      setState(() {
        _userData['profileImage'] = _userProfileController.profileImageUrl.value;
        _userData['isUploading'] = false;
      });
      
      Get.snackbar(
        'Success',
        'Profile image updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successColor.withOpacity(0.1),
        colorText: AppTheme.successColor,
      );
    } catch (e) {
      setState(() {
        _userData['isUploading'] = false;
      });
      
      print('Error uploading profile image: $e');
      Get.snackbar(
        'Error',
        'Failed to upload profile image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.errorColor.withOpacity(0.1),
        colorText: AppTheme.errorColor,
      );
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
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                    backgroundImage: _getProfileImage(),
                                  ),
                                  if (_userData['isUploading'] == true)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
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
                    _showEditBottomSheet(context, title, fields);
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
  // Logout dialog implementation
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
            onPressed: () async {
              Get.back();
              await _authController.signOut(); // Use the AuthController to sign out
              Get.offAll(() => const LoginPage());
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
  
  // Show bottom sheet for editing profile sections
  void _showEditBottomSheet(BuildContext context, String title, List<Widget> fields) {
    // Extract field data from widgets
    final Map<String, String> fieldData = {};
    final Map<String, TextEditingController> controllers = {};
    
    // Process field widgets to extract data for editing
    for (var field in fields) {
      if (field is Padding) {
        final row = field.child as Row;
        final expanded = row.children.last as Expanded;
        final column = expanded.child as Column;
        final labelWidget = column.children.first as Text;
        final valueWidget = column.children.last as Text;
        
        final label = labelWidget.data!;
        final value = valueWidget.data!;
        
        fieldData[label] = value;
        
        // Create controllers for editable fields
        if (label != 'Email' && label != 'Phone') {
          controllers[label] = TextEditingController(text: value);
        }
      }
    }
    
    showModalBottomSheet(
  context: context,
  isScrollControlled: true, // important
  backgroundColor: Colors.transparent,
  builder: (context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5, // half height
      minChildSize: 0.3,
      maxChildSize: 0.9, // can expand near full screen
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            controller: controller,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16, // ✅ keyboard safe
              top: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),

                Text(
                  'Edit $title',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(height: 24),

                // Fields
                ...fieldData.entries.map((entry) {
                  final label = entry.key;
                  final value = entry.value;

                  if (label == 'Email' || label == 'Phone') {
                    return _buildNonEditableField(label, value);
                  } else {
                    return _buildEditableField(label, controllers[label]!);
                  }
                }).toList(),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _saveProfileData(title, controllers);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  },
);

  }
  
  // Build a non-editable field for email and phone
  Widget _buildNonEditableField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.lock_outline,
                size: 16,
                color: Colors.grey.shade500,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build an editable field with text controller
  Widget _buildEditableField(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              hintText: 'Enter $label',
              hintStyle: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  // Get profile image
  ImageProvider _getProfileImage() {
    // First check if we have a just-selected image file
    if (_profileImage != null) {
      return FileImage(_profileImage!) as ImageProvider;
    }
    
    // Then check if we have a URL from Firestore
    if (_userData['profileImage'] != null && _userData['profileImage'].toString().isNotEmpty) {
      return NetworkImage(_userData['profileImage'].toString());
    }
    
    // Default image
    return const AssetImage('assets/profile.png');
  }
  
  // Save profile data after editing
  void _saveProfileData(String sectionTitle, Map<String, TextEditingController> controllers) {
    // Update the local state with the new values
    setState(() {
      controllers.forEach((key, controller) {
        if (key == 'Full Name') {
          _userData['name'] = controller.text;
        } else if (key == 'Business Name') {
          _userData['businessName'] = controller.text;
        } else if (key == 'Address') {
          _userData['address'] = controller.text;
        }
        // Add other fields as needed
      });
    });
    
    // Show success message
    Get.snackbar(
      'Success',
      '$sectionTitle updated successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.successColor.withOpacity(0.1),
      colorText: AppTheme.successColor,
      duration: const Duration(seconds: 2),
    );
    
    // Update data in Firestore
    if (Get.find<UserProfileController>() != null) {
      try {
        final UserProfileController controller = Get.find<UserProfileController>();
        if (sectionTitle.contains('Personal')) {
          controller.updateProfile(
            name: _userData['name'],
          );
        } else if (sectionTitle.contains('Business')) {
          controller.updateProfile(
            businessName: _userData['businessName'],
          );
        } else if (sectionTitle.contains('Address')) {
          // If your controller supports updating address
          // controller.updateUserAddress(_userData['address']);
          
          // Or store in additionalInfo field
          controller.updateProfile(
           address:  _userData['address'],
          );
        }
      } catch (e) {
        print('Error updating profile in Firestore: $e');
      }
    }
  }
}