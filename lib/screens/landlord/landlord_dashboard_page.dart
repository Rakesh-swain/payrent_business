import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/auth_controller.dart';
import 'package:payrent_business/controllers/payment_controller.dart';
import 'package:payrent_business/controllers/property_controller.dart';
import 'package:payrent_business/controllers/tenant_controller.dart';
import 'package:payrent_business/controllers/user_profile_controller.dart';
import 'package:payrent_business/controllers/mandate_controller.dart';
import 'package:payrent_business/extensions/context_extension.dart';
import 'package:payrent_business/screens/landlord/earnings/earning_details_page.dart';
import 'package:payrent_business/screens/landlord/mandate/mandate_list_page.dart';
import 'package:payrent_business/screens/landlord/payments/payment_summary_page.dart';
import 'package:payrent_business/screens/landlord/property_management/add_property_page.dart';
import 'package:payrent_business/screens/landlord/property_management/bulk_upload_page.dart';
import 'package:payrent_business/screens/landlord/tenant_management/add_tenant_page.dart';
import 'package:payrent_business/screens/landlord/mandate/mandate_status_page.dart';
import 'package:payrent_business/widgets/action_button.dart';
import 'package:payrent_business/widgets/custom_card.dart';
import 'package:payrent_business/widgets/stat_card.dart';

class LandlordDashboardPage extends StatefulWidget {
  const LandlordDashboardPage({super.key});

  @override
  State<LandlordDashboardPage> createState() => _LandlordDashboardPageState();
}

class _LandlordDashboardPageState extends State<LandlordDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _chartTabController;
  int _selectedChartPeriod = 1; // 0: 1 month, 1: 3 months, 2: 6 months
  int _selectedTimeFrame = 1; // 0: 3 months, 1: 6 months, 2: 1 year

  // Get controllers for Firebase data
  final AuthController _authController = Get.find<AuthController>();
  final UserProfileController _profileController = Get.put(
    UserProfileController(),
  );
  final PropertyController _propertyController = Get.find<PropertyController>();
  final TenantController _tenantController = Get.find<TenantController>();
  final PaymentController _paymentController = Get.find<PaymentController>();
  final MandateController _mandateController = Get.find<MandateController>();

  // Track if initial data is loaded

  @override
  void initState() {
    super.initState();
    _chartTabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      await _profileController.getUserProfile();

      // Load properties, tenants and payments data in parallel for better performance
      await Future.wait([
        _propertyController.fetchProperties(),
        _tenantController.fetchTenants(),
        _paymentController.fetchPayments(),
      ]);

      print('Dashboard data loaded successfully');
      print('Properties: ${_propertyController.propertyCount}');
      print('Tenants: ${_tenantController.tenantCount}');
      print('Payments: ${_paymentController.payments.length}');
    } catch (e) {
      print('Error loading dashboard data: $e');
    }
  }

  @override
  void dispose() {
    _chartTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [Text('Dashboard', style: context.headingMedium)]),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28),
            onPressed: () {
              // Handle search action
            },
          ),
          IconButton(
            icon: const Badge(
              label: Text('3'),
              child: Icon(Icons.notifications_outlined, size: 28),
            ),
            onPressed: () {
              // Handle notifications
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                // Navigate to profile
              },
              child: Obx(() {
                final profileUrl = _profileController.profileImageUrl.value;
                return CircleAvatar(
                  radius: 18,
                  backgroundImage: profileUrl.isNotEmpty
                      ? NetworkImage(profileUrl)
                      : const AssetImage('assets/profile.png') as ImageProvider,
                );
              }),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async {
          // Refresh dashboard data
          await _loadDashboardData();
        },
        child: Obx(() {
          if (_profileController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wb_sunny_rounded,
                        color: Color(0xFFFCD34D),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Good Morning,',
                                style: context.bodyLarge.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Obx(
                                () => Text(
                                  _profileController.name.value,
                                  style: context.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Properties at a Glance
                // Properties at a Glance
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: CustomCard(
                    title: 'Properties at a Glance',
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Obx(() {
                        final int totalProperties =
                            _propertyController.propertyCount;

                        // Calculate fully occupied properties
                        int fullyOccupiedProperties = 0;
                        for (var property in _propertyController.properties) {
                          final totalUnits = property['units'].length;
                          if (totalUnits > 0) {
                            final occupiedUnits = property['units']
                                .where((unit) => unit['tenantId'] != null)
                                .length;
                            final isFullyOccupied = occupiedUnits == totalUnits;
                            if (isFullyOccupied) {
                              fullyOccupiedProperties++;
                            }
                          }
                        }

                        final occupancyRate = totalProperties > 0
                            ? (fullyOccupiedProperties / totalProperties * 100)
                                  .round()
                            : 0;

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'You have ',
                                          style: context.bodyMedium.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '$fullyOccupiedProperties Fully Occupied',
                                          style: context.titleMedium.copyWith(
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' properties out of ',
                                          style: context.bodyMedium.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '$totalProperties Total',
                                          style: context.titleMedium.copyWith(
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' properties',
                                          style: context.bodyMedium.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Occupancy Progress Bar
                            Container(
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey.shade200,
                              ),
                              child: Row(
                                children: [
                                  Flexible(
                                    flex: occupancyRate,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF7869E6),
                                            Color(0xFF4F287D),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    flex: 100 - occupancyRate,
                                    child: const SizedBox(),
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '$occupancyRate% fully occupied',
                                            style: context.bodySmall.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.home_filled,
                                          color: Color(0xFFFCD34D),
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '${100 - occupancyRate}% not fully occupied',
                                      style: context.bodySmall.copyWith(
                                        color: AppTheme.textLight,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Key Stats Cards
                FadeInUp(
                  duration: const Duration(milliseconds: 700),
                  child: Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => StatCard(
                            title: 'Total Properties',
                            value: '${_propertyController.propertyCount}',
                            icon: Icons.home_outlined,
                            color: AppTheme.infoColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(() {
                          final totalEarnings = _paymentController
                              .getTotalCollectedPayments();
                          final formatter = NumberFormat.currency(
                            symbol: '\$',
                            decimalDigits: 0,
                          );
                          return StatCard(
                            title: 'Total Earnings',
                            value: formatter.format(totalEarnings),
                            icon: Icons.attach_money_outlined,
                            color: AppTheme.successColor,
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PaymentSummaryPage(),
                              ),
                            );
                          },
                          child: Obx(() {
                            final dueRent = _paymentController
                                .getTotalPendingPayments();
                            final formatter = NumberFormat.currency(
                              symbol: '\$',
                              decimalDigits: 0,
                            );
                            return StatCard(
                              title: 'Due Rent',
                              value: formatter.format(dueRent),
                              icon: Icons.calendar_today_outlined,
                              color: AppTheme.warningColor,
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PaymentSummaryPage(),
                              ),
                            );
                          },
                          child: Obx(() {
                            final overdueRent = _paymentController
                                .getTotalOverduePayments();
                            final formatter = NumberFormat.currency(
                              symbol: '\$',
                              decimalDigits: 0,
                            );
                            return StatCard(
                              title: 'Overdue Rent',
                              value: formatter.format(overdueRent),
                              icon: Icons.warning_amber_outlined,
                              color: AppTheme.errorColor,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // View All Payments Button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentSummaryPage(),
                        ),
                      );
                    },
                    child: Text(
                      'View All Payments',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Income Chart
                FadeInUp(
                  duration: const Duration(milliseconds: 900),
                  child: CustomCard(
                    title: 'Track your Earnings',
                    child: Column(
                      children: [
                        // Period Selection Tabs
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: TabBar(
                                controller: _chartTabController,
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: AppTheme.primaryColor,
                                ),
                                indicatorSize: TabBarIndicatorSize
                                    .tab, // indicator fills tab width
                                indicatorColor: Colors.transparent,
                                dividerColor: Colors.transparent,
                                labelColor: Colors.white,
                                unselectedLabelColor: AppTheme.textSecondary,
                                tabs: const [
                                  Tab(text: '1 month'),
                                  Tab(text: '3 months'),
                                  Tab(text: '6 months'),
                                ],
                                onTap: (index) {
                                  setState(() {
                                    _selectedChartPeriod = index;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Stats Summary
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Obx(() {
                            final totalEarnings = _paymentController
                                .getTotalCollectedPayments();
                            final formatter = NumberFormat.currency(
                              symbol: '\$',
                              decimalDigits: 0,
                            );

                            return Row(
                              children: [
                                const Icon(
                                  Icons.celebration_outlined,
                                  color: AppTheme.successColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 4,
                                    children: [
                                      Text(
                                        'Great!',
                                        style: context.titleSmall.copyWith(
                                          color: AppTheme.successColor,
                                        ),
                                      ),
                                      Text(
                                        'You have earned',
                                        style: context.bodyMedium,
                                      ),
                                      Text(
                                        formatter.format(totalEarnings),
                                        style: context.titleMedium.copyWith(
                                          color: AppTheme.successColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),

                        const SizedBox(height: 8),

                        // Due Rent Info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Obx(() {
                            final dueRent = _paymentController
                                .getTotalPendingPayments();
                            final overdueRent = _paymentController
                                .getTotalOverduePayments();
                            final formatter = NumberFormat.currency(
                              symbol: '\$',
                              decimalDigits: 0,
                            );

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildRentInfoItem(
                                  label: 'Total Due Rent',
                                  value: formatter.format(dueRent),
                                  valueColor: AppTheme.warningColor,
                                ),
                                _buildRentInfoItem(
                                  label: 'Overdue Rent',
                                  value: formatter.format(overdueRent),
                                  valueColor: AppTheme.errorColor,
                                ),
                              ],
                            );
                          }),
                        ),

                        const SizedBox(height: 24),

                        // Time Frame Selection
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTimeFrameButton(0, '3 months'),
                              const SizedBox(width: 12),
                              _buildTimeFrameButton(1, '6 months'),
                              const SizedBox(width: 12),
                              _buildTimeFrameButton(2, '1 year'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Chart
                        SizedBox(
                          height: 200,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Obx(() {
                              final paymentChartData = _paymentController
                                  .getChartData(
                                    months: _selectedTimeFrame == 0
                                        ? 3
                                        : _selectedTimeFrame == 1
                                        ? 6
                                        : 12,
                                  );
                              return LineChart(
                                _createLineChartData(paymentChartData),
                              );
                            }),
                          ),
                        ),

                        // Chart Legend
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem(
                                color: AppTheme.primaryColor,
                                label: 'Total Income',
                              ),
                              const SizedBox(width: 24),
                              _buildLegendItem(
                                color: AppTheme.accentColor,
                                label: 'Net Income',
                              ),
                            ],
                          ),
                        ),

                        // Link to view all
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 16.0,
                              bottom: 16.0,
                            ),
                            child: TextButton(
                              onPressed: () {
                                Get.to(() => EarningsDetailPage());
                              },
                              child: const Text('Let\'s view all'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Property Status Summary
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: CustomCard(
                    title: 'Property Status',
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Obx(() {
                        // Get counts from controllers
                        final rentalApplications =
                            _paymentController.rentalApplicationCount;
                        final tenantRequests = _tenantController.tenantCount > 0
                            ? _tenantController.tenantCount ~/ 2
                            : 0; // Placeholder logic
                        final expiringLeases = _tenantController
                            .getTenantsWithExpiringLeases()
                            .length;
                        final overdueProperties = _paymentController
                            .getOverduePropertiesCount();

                        return Column(
                          children: [
                            _buildStatusItem(
                              icon: Icons.file_copy_outlined,
                              iconColor: Colors.blue,
                              iconBgColor: Colors.blue.shade50,
                              title: 'Rental Applications',
                              count: '$rentalApplications',
                              onTap: () {},
                            ),
                            _buildStatusItem(
                              icon: Icons.person_outline_rounded,
                              iconColor: Colors.purple,
                              iconBgColor: Colors.purple.shade50,
                              title: 'Tenant\'s Requests',
                              count: '$tenantRequests',
                              onTap: () {},
                            ),
                            _buildStatusItem(
                              icon: Icons.description_outlined,
                              iconColor: Colors.amber,
                              iconBgColor: Colors.amber.shade50,
                              title: 'Expiring Leases',
                              count: '$expiringLeases',
                              onTap: () {},
                            ),
                            _buildStatusItem(
                              icon: Icons.warning_amber_outlined,
                              iconColor: Colors.red,
                              iconBgColor: Colors.red.shade50,
                              title: 'Overdue Properties',
                              count: '$overdueProperties',
                              onTap: () {},
                              showDivider: false,
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // My Mandates Section
                FadeInUp(
                  duration: const Duration(milliseconds: 1050),
                  child: _buildMyMandatesCard(),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                FadeInUp(
                  duration: const Duration(milliseconds: 1100),
                  child: CustomCard(
                    title: 'Need Something Quick?',
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ActionButton(
                                icon: Icons.home_outlined,
                                label: 'Add Property',
                                color: Colors.blue,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AddPropertyPage(),
                                  ),
                                ),
                              ),
                              ActionButton(
                                icon: Icons.person_add_outlined,
                                label: 'Add Tenant',
                                color: Colors.purple,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddTenantPage(),
                                  ),
                                ),
                              ),
                              ActionButton(
                                icon: Icons.upload_file_outlined,
                                label: 'Bulk Upload',
                                color: Colors.green,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const BulkUploadPage(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ActionButton(
                                icon: Icons.attach_money_outlined,
                                label: 'Add Income',
                                color: Colors.amber,
                                onTap: () {
                                  // Navigate to add income
                                },
                              ),
                              ActionButton(
                                icon: Icons.task_alt_outlined,
                                label: 'Add Task',
                                color: Colors.deepOrange,
                                onTap: () {
                                  // Navigate to add task
                                },
                              ),
                              ActionButton(
                                icon: Icons.calendar_month_outlined,
                                label: 'Add Reminder',
                                color: Colors.teal,
                                onTap: () {
                                  // Navigate to add reminder
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeFrameButton(int index, String label) {
    final isSelected = _selectedTimeFrame == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTimeFrame = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textLight,
          ),
        ),
        child: Text(
          label,
          style: context.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: context.bodySmall.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildRentInfoItem({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(value, style: context.titleMedium.copyWith(color: valueColor)),
      ],
    );
  }

  Widget _buildMyMandatesCard() {
    return CustomCard(
      title: 'My Mandates',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          if (_mandateController.isLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (_mandateController.mandates.isEmpty) {
            return Column(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No mandates created yet',
                  style: context.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to create mandate page
                      // You can implement navigation to a list of properties/tenants
                      // to select for mandate creation
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Create Your First Mandate',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            );
          }

          // Show mandate cards
          final activeMandates = _mandateController.getActiveMandates();
          final pendingMandates = _mandateController.getPendingMandates();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildMandateStatCard(
                      'Active',
                      activeMandates.length.toString(),
                      Colors.green,
                      Colors.green.shade50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMandateStatCard(
                      'Pending',
                      pendingMandates.length.toString(),
                      Colors.orange,
                      Colors.orange.shade50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMandateStatCard(
                      'Total',
                      _mandateController.mandateCount.toString(),
                      Colors.blue,
                      Colors.blue.shade50,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Recent Mandates List (show up to 3)
              if (_mandateController.mandates.isNotEmpty) ...[
                Text(
                  'Recent Mandates',
                  style: context.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...(_mandateController.mandates.take(3).map((mandate) {
                  return _buildMandateListItem(mandate);
                })),

                const SizedBox(height: 12),

                // View All Button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                     Get.to(MandateListPage());
                    },
                    child: const Text('View All Mandates'),
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMandateStatCard(
    String title,
    String count,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: context.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: context.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMandateListItem(mandate) {
    final statusColor = _getMandateStatusColor(mandate.mmsStatus);

    return GestureDetector(
      onTap: () {
        if (mandate.id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MandateStatusPage(mandateId: mandate.id!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mandate.tenantAccountHolderName,
                    style: context.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '\$${mandate.rentAmount} × ${mandate.noOfInstallments} payments',
                    style: context.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                mandate.mmsStatus ?? 'PENDING',
                style: context.bodySmall.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                // Navigate to mandate details/view status page
                if (mandate.id != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MandateStatusPage(mandateId: mandate.id!),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.visibility,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMandateStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String count,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: context.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count,
                    style: context.titleSmall.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textLight,
                ),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(),
      ],
    );
  }

  LineChartData _createLineChartData(Map<String, List<FlSpot>> chartData) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 10,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: AppTheme.dividerColor, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const style = TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              );

              // Get month name based on current date minus months
              final now = DateTime.now();
              final month =
                  now.month -
                  (6 - value.toInt()); // Adjust according to your data points
              String text;

              if (month <= 0) {
                // Handle previous year months
                text = DateFormat(
                  'MMM',
                ).format(DateTime(now.year - 1, month + 12, 1));
              } else {
                text = DateFormat('MMM').format(DateTime(now.year, month, 1));
              }

              return Text(text, style: style);
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 10,
            getTitlesWidget: (value, meta) {
              if (value == 0) {
                return Container();
              }
              return Text(
                '${value.toInt()}K',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              );
            },
            reservedSize: 30,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 6,
      minY: 0,
      maxY: 50,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBorder: const BorderSide(color: AppTheme.dividerColor),
          getTooltipItems: (List<LineBarSpot> spots) {
            return spots.map((spot) {
              return LineTooltipItem(
                '\$${spot.y.toInt()}K',
                GoogleFonts.poppins(
                  color: spot.barIndex == 0
                      ? AppTheme.primaryColor
                      : AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: chartData['totalIncome'] ?? const [],
          isCurved: true,
          color: AppTheme.primaryColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.primaryColor.withOpacity(0.15),
          ),
        ),
        LineChartBarData(
          spots: chartData['netIncome'] ?? const [],
          isCurved: true,
          color: AppTheme.accentColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.accentColor.withOpacity(0.15),
          ),
        ),
      ],
    );
  }
}
