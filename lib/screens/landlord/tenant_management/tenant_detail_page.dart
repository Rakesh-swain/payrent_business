import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/screens/landlord/property_management/property_detail_page.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class TenantDetailPage extends StatefulWidget {
  final String tenantId;
  
  const TenantDetailPage({super.key, required this.tenantId});

  @override
  State<TenantDetailPage> createState() => _TenantDetailPageState();
}

class _TenantDetailPageState extends State<TenantDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Sample tenant data
  Map<String, dynamic>? _tenantData;
  bool _isLoading = true;
  
  // Sample payment history
  final List<Map<String, dynamic>> _paymentHistory = [
    {
      'id': '1',
      'title': 'Monthly Rent',
      'amount': 2200,
      'date': '2023-08-15',
      'dueDate': '2023-08-15',
      'status': 'Paid',
      'method': 'Credit Card',
    },
    {
      'id': '2',
      'title': 'Monthly Rent',
      'amount': 2200,
      'date': '2023-07-14',
      'dueDate': '2023-07-15',
      'status': 'Paid',
      'method': 'Bank Transfer',
    },
    {
      'id': '3',
      'title': 'Monthly Rent',
      'amount': 2200,
      'date': '2023-06-15',
      'dueDate': '2023-06-15',
      'status': 'Paid',
      'method': 'UPI',
    },
    {
      'id': '4',
      'title': 'Monthly Rent',
      'amount': 2200,
      'date': null,
      'dueDate': '2023-09-15',
      'status': 'Due',
      'method': null,
    },
  ];
  
  // Sample documents
  final List<Map<String, dynamic>> _documents = [
    {
      'id': '1',
      'title': 'Lease Agreement',
      'type': 'PDF',
      'size': '2.4 MB',
      'uploadDate': '2023-01-15',
      'url': 'https://example.com/documents/lease.pdf',
    },
    {
      'id': '2',
      'title': 'ID Proof',
      'type': 'JPG',
      'size': '1.2 MB',
      'uploadDate': '2023-01-15',
      'url': 'https://example.com/documents/id.jpg',
    },
    {
      'id': '3',
      'title': 'Background Verification',
      'type': 'PDF',
      'size': '3.8 MB',
      'uploadDate': '2023-01-12',
      'url': 'https://example.com/documents/verification.pdf',
    },
  ];
  
  // Sample requests
  final List<Map<String, dynamic>> _requests = [
    {
      'id': '1',
      'title': 'Leaking Faucet',
      'description': 'The kitchen sink faucet is leaking and needs repair.',
      'status': 'In Progress',
      'date': '2023-08-10',
      'priority': 'Medium',
    },
    {
      'id': '2',
      'title': 'Air Conditioner Not Cooling',
      'description': 'The bedroom AC is not cooling properly.',
      'status': 'Resolved',
      'date': '2023-07-25',
      'priority': 'High',
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch tenant data
    _fetchTenantData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchTenantData() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Sample data
    _tenantData = {
      'id': widget.tenantId,
      'name': 'John Doe',
      'email': 'john.doe@example.com',
      'phone': '+1 (123) 456-7890',
      'image': 'assets/profile.png',
      'property': 'Modern Apartment in Downtown',
      'propertyId': '1',
      'rent': 2200,
      'status': 'Active',
      'leaseStart': '2023-01-15',
      'leaseEnd': '2024-01-15',
      'paymentStatus': 'Paid',
      'nextDue': '2023-09-15',
      'address': '123 Main St, Apt 303, New York, NY 10001',
      'joinDate': '2023-01-15',
      'emergencyContact': {
        'name': 'Jane Doe',
        'relation': 'Spouse',
        'phone': '+1 (234) 567-8901',
      },
    };
    
    setState(() {
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title:Text('Tenant Details',style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Calculate lease progress
    final leaseStart = DateTime.parse(_tenantData!['leaseStart']);
    final leaseEnd = DateTime.parse(_tenantData!['leaseEnd']);
    final today = DateTime.now();
    
    final totalDays = leaseEnd.difference(leaseStart).inDays;
    final daysElapsed = today.difference(leaseStart).inDays;
    
    double progress = daysElapsed / totalDays;
    progress = progress.clamp(0.0, 1.0); // Ensure progress is between 0 and 1
    
    final remainingDays = leaseEnd.difference(today).inDays;
    
    // Determine status color
    Color statusColor;
    switch (_tenantData!['status']) {
      case 'Active':
        statusColor = AppTheme.successColor;
        break;
      case 'Inactive':
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusColor = AppTheme.textLight;
    }
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Tenant Details',style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptionsBottomSheet();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tenant Profile Card
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
                      // Tenant Image
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage(_tenantData!['image']),
                        onBackgroundImageError: (_, __) {},
                      ),
                      const SizedBox(width: 16),
                      // Tenant Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tenantData!['name'],
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
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _tenantData!['status'],
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.home_outlined,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _tenantData!['property'],
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
                                  Icons.attach_money_outlined,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '\$${_tenantData!['rent']}/month',
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
                  
                  const SizedBox(height: 16),
                  
                  const Divider(),
                  
                  const SizedBox(height: 16),
                  
                  // Contact Information
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildContactButton(
                        icon: Icons.call_outlined,
                        label: 'Call',
                        onTap: () {
                          // Implement call functionality
                        },
                      ),
                      _buildContactButton(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        onTap: () {
                          // Implement email functionality
                        },
                      ),
                      _buildContactButton(
                        icon: Icons.message_outlined,
                        label: 'Message',
                        onTap: () {
                          // Implement message functionality
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Lease Progress Card
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lease Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearPercentIndicator(
                    lineHeight: 8.0,
                    percent: progress,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    progressColor: AppTheme.primaryColor,
                    barRadius: const Radius.circular(4),
                    padding: EdgeInsets.zero,
                    animation: true,
                    animationDuration: 1000,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(_tenantData!['leaseStart']),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                      Text(
                        _formatDate(_tenantData!['leaseEnd']),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppTheme.infoColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$remainingDays days remaining in the current lease',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.infoColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tab Bar
          FadeInDown(
            duration: const Duration(milliseconds: 700),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryColor,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: const [
                  Tab(text: 'Details'),
                  Tab(text: 'Payments'),
                  Tab(text: 'Documents'),
                ],
              ),
            ),
          ),
          
          // Tab Content
          Expanded(
            child: FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Details Tab
                  _buildDetailsTab(),
                  
                  // Payments Tab
                  _buildPaymentsTab(),
                  
                  // Documents Tab
                  _buildDocumentsTab(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show action sheet with options
          _showActionsBottomSheet();
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailsTab() {
    return SingleChildScrollView( physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information
          _buildDetailSection(
            title: 'Personal Information',
            items: [
              _buildDetailItem(
                label: 'Email',
                value: _tenantData!['email'],
                icon: Icons.email_outlined,
              ),
              _buildDetailItem(
                label: 'Phone',
                value: _tenantData!['phone'],
                icon: Icons.phone_outlined,
              ),
              _buildDetailItem(
                label: 'Address',
                value: _tenantData!['address'],
                icon: Icons.home_outlined,
              ),
              _buildDetailItem(
                label: 'Since',
                value: _formatDate(_tenantData!['joinDate']),
                icon: Icons.calendar_today_outlined,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Emergency Contact
          _buildDetailSection(
            title: 'Emergency Contact',
            items: [
              _buildDetailItem(
                label: 'Name',
                value: _tenantData!['emergencyContact']['name'],
                icon: Icons.person_outline,
              ),
              _buildDetailItem(
                label: 'Relation',
                value: _tenantData!['emergencyContact']['relation'],
                icon: Icons.family_restroom_outlined,
              ),
              _buildDetailItem(
                label: 'Phone',
                value: _tenantData!['emergencyContact']['phone'],
                icon: Icons.phone_outlined,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Maintenance Requests
          _buildRequestsSection(),
        ],
      ),
    );
  }
  
  Widget _buildPaymentsTab() {
    return SingleChildScrollView( physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPaymentStat(
                      label: 'Monthly Rent',
                      value: '\$${_tenantData!['rent']}',
                      icon: Icons.attach_money_outlined,
                      iconColor: AppTheme.primaryColor,
                    ),
                    _buildPaymentStat(
                      label: 'Status',
                      value: _tenantData!['paymentStatus'],
                      icon: Icons.check_circle_outline,
                      iconColor: AppTheme.successColor,
                    ),
                    _buildPaymentStat(
                      label: 'Next Due',
                      value: _formatShortDate(_tenantData!['nextDue']),
                      icon: Icons.calendar_today_outlined,
                      iconColor: AppTheme.warningColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Payment History
          Text(
            'Payment History',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Payment Items
          ...List.generate(_paymentHistory.length, (index) {
            final payment = _paymentHistory[index];
            return _buildPaymentHistoryItem(payment);
          }),
        ],
      ),
    );
  }
  
  Widget _buildDocumentsTab() {
    return SingleChildScrollView( physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Documents',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Upload document functionality
                },
                icon: const Icon(
                  Icons.upload_file_outlined,
                  size: 16,
                ),
                label: const Text('Upload'),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Document Items
          ...List.generate(_documents.length, (index) {
            final document = _documents[index];
            return _buildDocumentItem(document);
          }),
        ],
      ),
    );
  }
  
  Widget _buildDetailSection({
    required String title,
    required List<Widget> items,
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
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }
  
  Widget _buildDetailItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
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
  
  Widget _buildRequestsSection() {
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
                'Maintenance Requests',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // View all requests
                },
                icon: const Icon(
                  Icons.arrow_forward,
                  size: 16,
                ),
                label: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_requests.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No maintenance requests yet',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...List.generate(_requests.length, (index) {
              final request = _requests[index];
              return _buildRequestItem(request);
            }),
        ],
      ),
    );
  }
  
  Widget _buildPaymentStat({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 8),
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
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPaymentHistoryItem(Map<String, dynamic> payment) {
    Color statusColor;
    IconData statusIcon;
    
    switch (payment['status']) {
      case 'Paid':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'Due':
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.access_time;
        break;
      case 'Overdue':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.warning_amber_rounded;
        break;
      default:
        statusColor = AppTheme.textLight;
        statusIcon = Icons.help_outline;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              statusIcon,
              size: 16,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  payment['status'] == 'Paid'
                      ? 'Paid on ${_formatDate(payment['date'])}'
                      : 'Due on ${_formatDate(payment['dueDate'])}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${NumberFormat('#,##0.00').format(payment['amount'])}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDocumentItem(Map<String, dynamic> document) {
    IconData fileIcon;
    Color fileColor;
    
    switch (document['type']) {
      case 'PDF':
        fileIcon = Icons.picture_as_pdf_outlined;
        fileColor = Colors.red;
        break;
      case 'JPG':
      case 'PNG':
        fileIcon = Icons.image_outlined;
        fileColor = Colors.blue;
        break;
      case 'DOC':
      case 'DOCX':
        fileIcon = Icons.description_outlined;
        fileColor = Colors.blue;
        break;
      default:
        fileIcon = Icons.insert_drive_file_outlined;
        fileColor = Colors.grey;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fileColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              fileIcon,
              size: 24,
              color: fileColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${document['type']} • ${document['size']} • ${_formatDate(document['uploadDate'])}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            color: AppTheme.primaryColor,
            onPressed: () {
              // Download document
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildRequestItem(Map<String, dynamic> request) {
    Color statusColor;
    
    switch (request['status']) {
      case 'Open':
        statusColor = AppTheme.warningColor;
        break;
      case 'In Progress':
        statusColor = AppTheme.infoColor;
        break;
      case 'Resolved':
        statusColor = AppTheme.successColor;
        break;
      default:
        statusColor = AppTheme.textLight;
    }
    
    Color priorityColor;
    
    switch (request['priority']) {
      case 'High':
        priorityColor = AppTheme.errorColor;
        break;
      case 'Medium':
        priorityColor = AppTheme.warningColor;
        break;
      case 'Low':
        priorityColor = AppTheme.successColor;
        break;
      default:
        priorityColor = AppTheme.textLight;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request['title'],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  request['status'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request['description'],
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(request['date']),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.flag_outlined,
                    size: 12,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${request['priority']} Priority',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: priorityColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tenant Options',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionItem(
                icon: Icons.edit_outlined,
                label: 'Edit Tenant Details',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit tenant page
                },
              ),
              _buildOptionItem(
                icon: Icons.home_outlined,
                label: 'View Property',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to property details
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertyDetailsPage(
                        propertyId: _tenantData!['propertyId'],
                      ),
                    ),
                  );
                },
              ),
              _buildOptionItem(
                icon: Icons.description_outlined,
                label: 'View Lease Agreement',
                onTap: () {
                  Navigator.pop(context);
                  // View lease agreement
                },
              ),
              if (_tenantData!['status'] == 'Active')
                _buildOptionItem(
                  icon: Icons.logout,
                  label: 'Mark as Inactive',
                  onTap: () {
                    Navigator.pop(context);
                    // Show confirmation dialog
                    _showConfirmationDialog(
                      title: 'Mark as Inactive',
                      message: 'Are you sure you want to mark this tenant as inactive?',
                      onConfirm: () {
                        // Update tenant status
                        setState(() {
                          _tenantData!['status'] = 'Inactive';
                        });
                      },
                    );
                  },
                  isDestructive: true,
                ),
            ],
          ),
        );
      },
    );
  }
  
  void _showActionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Actions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionItem(
                icon: Icons.attach_money_outlined,
                label: 'Record Payment',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to record payment page
                },
              ),
              _buildOptionItem(
                icon: Icons.description_outlined,
                label: 'Upload Document',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to upload document page
                },
              ),
              _buildOptionItem(
                icon: Icons.home_repair_service_outlined,
                label: 'Add Maintenance Request',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to add maintenance request page
                },
              ),
              _buildOptionItem(
                icon: Icons.message_outlined,
                label: 'Send Message',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to send message page
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppTheme.errorColor.withOpacity(0.1)
              : AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
        ),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppTheme.errorColor : null,
        ),
      ),
      onTap: onTap,
    );
  }
  
  void _showConfirmationDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
  
  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd MMM, yyyy').format(date);
  }
  
  String _formatShortDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd MMM').format(date);
  }
}