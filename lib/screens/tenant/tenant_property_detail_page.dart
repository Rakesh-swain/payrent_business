import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';

class TenantPropertyDetailPage extends StatefulWidget {
  final Map<String, dynamic> propertyData;

  const TenantPropertyDetailPage({
    super.key,
    required this.propertyData,
  });

  @override
  State<TenantPropertyDetailPage> createState() => _TenantPropertyDetailPageState();
}

class _TenantPropertyDetailPageState extends State<TenantPropertyDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.propertyData;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.8),
                          AppTheme.primaryColor,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Icon(
                      Icons.home,
                      size: 100,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  if (property['isMultiUnit'] == true)
                    Positioned(
                      top: 50,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.apartment,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Unit ${property['unitNumber']}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Title Section
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property['propertyName'] ?? 
                          property['address'] ?? 
                          'Property Details',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${property['address'] ?? ''}, ${property['city']}, ${property['state']} ${property['pincode']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Rent Card
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppTheme.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Rent',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(property['rentAmount'] ?? 0),
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Tab Bar
                FadeInUp(
                  duration: const Duration(milliseconds: 700),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppTheme.textSecondary,
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'Property Info'),
                        Tab(text: 'Lease Details'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Tab Bar View Content
                SizedBox(
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Property Info Tab
                      _buildPropertyInfoTab(property),
                      
                      // Lease Details Tab
                      _buildLeaseDetailsTab(property),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyInfoTab(Map<String, dynamic> property) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Specifications
          FadeInUp(
            duration: const Duration(milliseconds: 800),
            child: _buildInfoCard(
              'Property Specifications',
              [
                if (property['propertyType'] != null)
                  _buildInfoRow(Icons.house_outlined, 'Type', property['propertyType']),
                if (property['bedrooms'] != null)
                  _buildInfoRow(Icons.bed_outlined, 'Bedrooms', '${property['bedrooms']}'),
                if (property['bathrooms'] != null)
                  _buildInfoRow(Icons.bathtub_outlined, 'Bathrooms', '${property['bathrooms']}'),
                if (property['area'] != null)
                  _buildInfoRow(Icons.square_foot, 'Area', '${property['area']} sqft'),
                if (property['floor'] != null)
                  _buildInfoRow(Icons.layers_outlined, 'Floor', '${property['floor']}'),
                if (property['furnished'] != null)
                  _buildInfoRow(Icons.chair_outlined, 'Furnishing', 
                    property['furnished'] ? 'Furnished' : 'Unfurnished'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Address Details
          FadeInUp(
            duration: const Duration(milliseconds: 900),
            child: _buildInfoCard(
              'Address Details',
              [
                _buildInfoRow(Icons.location_on_outlined, 'Address', property['address'] ?? 'N/A'),
                _buildInfoRow(Icons.location_city, 'City', property['city'] ?? 'N/A'),
                _buildInfoRow(Icons.map_outlined, 'State', property['state'] ?? 'N/A'),
                _buildInfoRow(Icons.pin_drop_outlined, 'Pincode', property['pincode'] ?? 'N/A'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Amenities
          if (property['amenities'] != null && (property['amenities'] as List).isNotEmpty)
            FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: _buildInfoCard(
                'Amenities',
                [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (property['amenities'] as List)
                        .map((amenity) => Chip(
                              label: Text(
                                amenity.toString(),
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Description
          if (property['description'] != null && property['description'].toString().isNotEmpty)
            FadeInUp(
              duration: const Duration(milliseconds: 1100),
              child: _buildInfoCard(
                'Description',
                [
                  Text(
                    property['description'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLeaseDetailsTab(Map<String, dynamic> property) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lease Period
          FadeInUp(
            duration: const Duration(milliseconds: 800),
            child: _buildInfoCard(
              'Lease Period',
              [
                _buildInfoRow(Icons.calendar_today_outlined, 'Start Date', 
                  _formatDate(property['leaseStartDate'])),
                _buildInfoRow(Icons.event_outlined, 'End Date', 
                  _formatDate(property['leaseEndDate'])),
                _buildInfoRow(Icons.access_time, 'Duration', 
                  _calculateLeaseDuration(property['leaseStartDate'], property['leaseEndDate'])),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Payment Details
          FadeInUp(
            duration: const Duration(milliseconds: 900),
            child: _buildInfoCard(
              'Payment Details',
              [
                _buildInfoRow(Icons.payments_outlined, 'Rent Amount', 
                  currencyFormat.format(property['rentAmount'] ?? 0)),
                if (property['paymentFrequency'] != null)
                  _buildInfoRow(Icons.repeat, 'Payment Frequency', 
                    property['paymentFrequency']),
                if (property['rentDueDay'] != null)
                  _buildInfoRow(Icons.today_outlined, 'Due Day', 
                    'Day ${property['rentDueDay']} of month'),
                if (property['securityDeposit'] != null)
                  _buildInfoRow(Icons.account_balance_wallet_outlined, 'Security Deposit', 
                    currencyFormat.format(property['securityDeposit'])),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Landlord Contact (if available)
          if (property['landlordName'] != null || property['landlordPhone'] != null)
            FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: _buildInfoCard(
                'Landlord Contact',
                [
                  if (property['landlordName'] != null)
                    _buildInfoRow(Icons.person_outlined, 'Name', 
                      property['landlordName']),
                  if (property['landlordPhone'] != null)
                    _buildInfoRow(Icons.phone_outlined, 'Phone', 
                      property['landlordPhone']),
                  if (property['landlordEmail'] != null)
                    _buildInfoRow(Icons.email_outlined, 'Email', 
                      property['landlordEmail']),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Additional Info
          if (property['notes'] != null && property['notes'].toString().isNotEmpty)
            FadeInUp(
              duration: const Duration(milliseconds: 1100),
              child: _buildInfoCard(
                'Additional Information',
                [
                  Text(
                    property['notes'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
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
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
              size: 20,
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) return date;
      return DateFormat('dd MMM yyyy').format(date.toDate());
    } catch (e) {
      return 'N/A';
    }
  }

  String _calculateLeaseDuration(dynamic startDate, dynamic endDate) {
    if (startDate == null || endDate == null) return 'N/A';
    try {
      DateTime start = startDate is String 
          ? DateTime.parse(startDate) 
          : startDate.toDate();
      DateTime end = endDate is String 
          ? DateTime.parse(endDate) 
          : endDate.toDate();
      
      final months = ((end.year - start.year) * 12 + end.month - start.month);
      if (months >= 12) {
        final years = months ~/ 12;
        final remainingMonths = months % 12;
        if (remainingMonths == 0) {
          return '$years ${years == 1 ? 'year' : 'years'}';
        }
        return '$years ${years == 1 ? 'year' : 'years'} $remainingMonths ${remainingMonths == 1 ? 'month' : 'months'}';
      }
      return '$months ${months == 1 ? 'month' : 'months'}';
    } catch (e) {
      return 'N/A';
    }
  }
}
