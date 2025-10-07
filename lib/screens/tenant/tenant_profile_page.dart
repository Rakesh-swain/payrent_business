import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/screens/auth/login_page.dart';
import 'package:payrent_business/services/tenant_auth_service.dart';
import 'package:payrent_business/widgets/logout_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:payrent_business/widgets/common/app_loading_indicator.dart';

class TenantProfilePage extends StatefulWidget {
  const TenantProfilePage({super.key});

  @override
  State<TenantProfilePage> createState() => _TenantProfilePageState();
}

class _TenantProfilePageState extends State<TenantProfilePage> {
  final TenantAuthService _tenantAuthService = TenantAuthService();
  
  // Controllers for edit mode
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  // State variables
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String _tenantId = '';
  String _landlordId = '';
  Map<String, dynamic> _tenantData = {};
  
  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() => _isLoading = true);
      
      // Get tenant info from shared preferences
      final prefs = await SharedPreferences.getInstance();
      _tenantId = prefs.getString('tenantId') ?? '';
      _landlordId = prefs.getString('landlordId') ?? '';
      
      if (_tenantId.isEmpty || _landlordId.isEmpty) {
        print('Tenant or landlord ID not found');
        setState(() => _isLoading = false);
        return;
      }
      
      // Fetch tenant full data
      final tenantData = await _tenantAuthService.getTenantFullData(_landlordId, _tenantId);
      if (tenantData != null) {
        setState(() {
          _tenantData = tenantData;
          _nameController.text = tenantData['name'] ?? '';
          _emailController.text = tenantData['email'] ?? '';
          _phoneController.text = tenantData['phone'] ?? '';
          _addressController.text = tenantData['address'] ?? '';
        });
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading profile data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_isEditing) return;
    
    try {
      setState(() => _isSaving = true);
      
      final updates = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      };
      
      final success = await _tenantAuthService.updateTenantProfile(
        _landlordId, 
        _tenantId, 
        updates,
      );
      
      if (success) {
        setState(() {
          _isEditing = false;
          _tenantData = {..._tenantData, ...updates};
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      setState(() => _isSaving = false);
    } catch (e) {
      print('Error saving profile: $e');
      setState(() => _isSaving = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => LogoutDialog(
        onLogout: () async {
          // Clear shared preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          
          // Sign out from Firebase
          await FirebaseAuth.instance.signOut();
          
          // Navigate to login page
          Get.offAll(LoginPage());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Profile Avatar
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryColor.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                (_tenantData['name'] ?? 'T')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
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
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Profile Form
                  FadeInUp(
                    duration: const Duration(milliseconds: 700),
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        children: [
                          _buildProfileField(
                            'Full Name',
                            _nameController,
                            Icons.person_outline,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 20),
                          _buildProfileField(
                            'Email',
                            _emailController,
                            Icons.email_outlined,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 20),
                          _buildProfileField(
                            'Phone Number',
                            _phoneController,
                            Icons.phone_outlined,
                            enabled: false, // Phone number can't be edited
                          ),
                          const SizedBox(height: 20),
                          _buildProfileField(
                            'Address',
                            _addressController,
                            Icons.location_on_outlined,
                            enabled: _isEditing,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Tenant Info Card
                  FadeInUp(
                    duration: const Duration(milliseconds: 700),
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tenant Information',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            'Lease Status',
                            _tenantData['leaseStatus'] ?? 'Active',
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Properties Assigned',
                            '${_tenantData['assignedProperties']?.length ?? 0}',
                          ),
                          if (_tenantData['leaseStartDate'] != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Lease Start',
                              _tenantData['leaseStartDate'].toString(),
                            ),
                          ],
                          if (_tenantData['leaseEndDate'] != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Lease End',
                              _tenantData['leaseEndDate'].toString(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  if (_isEditing) ...[
                    FadeInUp(
                      duration: const Duration(milliseconds: 700),
                      delay: const Duration(milliseconds: 300),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () {
                                      setState(() {
                                        _isEditing = false;
                                        // Reset controllers
                                        _nameController.text = _tenantData['name'] ?? '';
                                        _emailController.text = _tenantData['email'] ?? '';
                                        _phoneController.text = _tenantData['phone'] ?? '';
                                        _addressController.text = _tenantData['address'] ?? '';
                                      });
                                    },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: AppTheme.primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 26,
                                      width: 26,
                                      child: AppLoadingIndicator(size: 26),
                                    )
                                  : Text(
                                      'Save Changes',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    FadeInUp(
                      duration: const Duration(milliseconds: 700),
                      delay: const Duration(milliseconds: 300),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
  
  Widget _buildProfileField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Column(
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
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.textSecondary),
            filled: true,
            fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}