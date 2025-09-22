import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:payrent_business/config/theme.dart';

class EarningsDetailPage extends StatefulWidget {
  const EarningsDetailPage({super.key});

  @override
  State<EarningsDetailPage> createState() => _EarningsDetailPageState();
}

class _EarningsDetailPageState extends State<EarningsDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Monthly';
  final List<String> _periods = ['Weekly', 'Monthly', 'Yearly', 'Custom'];
  
  final Map<String, dynamic> _earningsData = {
    'totalEarnings': 26400.0,
    'netIncome': 21360.0,
    'expenses': 5040.0,
    'pendingPayments': 4400.0,
    'monthlyGrowth': 3.5, // percentage
    'occupancyRate': 75, // percentage
  };
  
  // Sample transaction data
  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'TX001',
      'title': 'Rent Payment',
      'description': 'Monthly rent for Serene Apartments #102',
      'amount': 1600.0,
      'date': '2023-08-15',
      'type': 'income',
      'status': 'completed',
      'tenant': 'John Doe',
      'property': 'Serene Apartments',
      'unit': '102',
      'paymentMethod': 'Bank Transfer',
    },
    {
      'id': 'TX002',
      'title': 'Maintenance Cost',
      'description': 'Plumbing repairs at Urban Heights #201',
      'amount': 250.0,
      'date': '2023-08-12',
      'type': 'expense',
      'status': 'completed',
      'property': 'Urban Heights',
      'unit': '201',
      'vendor': 'ABC Plumbing Services',
    },
    {
      'id': 'TX003',
      'title': 'Rent Payment',
      'description': 'Monthly rent for Coastal Villa',
      'amount': 2200.0,
      'date': '2023-08-10',
      'type': 'income',
      'status': 'completed',
      'tenant': 'Emma Wilson',
      'property': 'Coastal Villa',
      'paymentMethod': 'Credit Card',
    },
    {
      'id': 'TX004',
      'title': 'Property Insurance',
      'description': 'Annual insurance premium for Suburban House',
      'amount': 1200.0,
      'date': '2023-08-05',
      'type': 'expense',
      'status': 'completed',
      'property': 'Suburban House',
      'vendor': 'State Farm Insurance',
    },
    {
      'id': 'TX005',
      'title': 'Rent Payment',
      'description': 'Monthly rent for Urban Heights #202',
      'amount': 1300.0,
      'date': '2023-08-01',
      'type': 'income',
      'status': 'completed',
      'tenant': 'Michael Brown',
      'property': 'Urban Heights',
      'unit': '202',
      'paymentMethod': 'Cash',
    },
    {
      'id': 'TX006',
      'title': 'Rent Payment',
      'description': 'Monthly rent for Serene Apartments #103',
      'amount': 1550.0,
      'date': '2023-07-31',
      'type': 'income',
      'status': 'completed',
      'tenant': 'Sarah Johnson',
      'property': 'Serene Apartments',
      'unit': '103',
      'paymentMethod': 'UPI',
    },
  ];
  
  // Sample monthly data for charts
  final List<Map<String, dynamic>> _monthlyData = [
    {'month': 'Jan', 'income': 5100, 'expense': 1200},
    {'month': 'Feb', 'income': 5100, 'expense': 1100},
    {'month': 'Mar', 'income': 5300, 'expense': 1250},
    {'month': 'Apr', 'income': 5300, 'expense': 1150},
    {'month': 'May', 'income': 5500, 'expense': 1300},
    {'month': 'Jun', 'income': 5500, 'expense': 1100},
    {'month': 'Jul', 'income': 5700, 'expense': 1400},
    {'month': 'Aug', 'income': 5700, 'expense': 1300},
    {'month': 'Sep', 'income': 0, 'expense': 0}, // Future months
    {'month': 'Oct', 'income': 0, 'expense': 0},
    {'month': 'Nov', 'income': 0, 'expense': 0},
    {'month': 'Dec', 'income': 0, 'expense': 0},
  ];
  
  // Sample property earnings breakdown
  final List<Map<String, dynamic>> _propertyEarnings = [
    {'property': 'Serene Apartments', 'income': 4650, 'percentage': 40},
    {'property': 'Coastal Villa', 'income': 2200, 'percentage': 25},
    {'property': 'Urban Heights', 'income': 1300, 'percentage': 20},
    {'property': 'Suburban House', 'income': 1800, 'percentage': 15},
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Earnings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () {
              // Show date picker for custom range
              _selectDateRange(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              _showExportOptions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Period Selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FadeInDown(
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _periods.map((period) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPeriod = period;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedPeriod == period
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          period,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _selectedPeriod == period
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Financial Overview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppTheme.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Earnings',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${NumberFormat("#,##0").format(_earningsData['totalEarnings'])}',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _earningsData['monthlyGrowth'] >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_earningsData['monthlyGrowth']}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFinancialStat(
                          label: 'Net Income',
                          value: '\$${NumberFormat("#,##0").format(_earningsData['netIncome'])}',
                          color: Colors.white,
                        ),
                        _buildFinancialStat(
                          label: 'Expenses',
                          value: '\$${NumberFormat("#,##0").format(_earningsData['expenses'])}',
                          color: Colors.white,
                        ),
                        _buildFinancialStat(
                          label: 'Pending',
                          value: '\$${NumberFormat("#,##0").format(_earningsData['pendingPayments'])}',
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.primaryColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Transactions'),
                    Tab(text: 'Analytics'),
                  ],
                ),
              ),
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                _buildOverviewTab(),
                
                // Transactions Tab
                _buildTransactionsTab(),
                
                // Analytics Tab
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFinancialStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
  
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Income vs Expense Chart
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Income vs Expenses',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 6000,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) =>  Colors.blueGrey.shade800,
                           
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              String label = _monthlyData[group.x.toInt()]['month'];
                              return BarTooltipItem(
                                '${label}\n',
                                GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: '\$${rod.toY.toInt()}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value < 0 || value >= _monthlyData.length) {
                                  return const SizedBox();
                                }
                                return  Text(
                                    _monthlyData[value.toInt()]['month'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) {
                                  return const SizedBox();
                                }
                                return  Text(
                                    value >= 1000
                                        ? '\$${(value / 1000).toStringAsFixed(0)}k'
                                        : '\$${value.toInt()}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(_monthlyData.length, (index) {
                          // Only include data for months that have values
                          if (_monthlyData[index]['income'] == 0 &&
                              _monthlyData[index]['expense'] == 0) {
                            return BarChartGroupData(x: index, barRods: []);
                          }
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: _monthlyData[index]['income'].toDouble(),
                                color: AppTheme.primaryColor,
                                width: 12,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                              BarChartRodData(
                                toY: _monthlyData[index]['expense'].toDouble(),
                                color: Colors.redAccent,
                                width: 12,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('Income', AppTheme.primaryColor),
                      const SizedBox(width: 24),
                      _buildLegendItem('Expenses', Colors.redAccent),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Property Earnings Breakdown
          Text(
            'Property Earnings Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Property Cards
          ...List.generate(_propertyEarnings.length, (index) {
            final property = _propertyEarnings[index];
            return FadeInUp(
              duration: Duration(milliseconds: 600 + (index * 100)),
              child: _buildPropertyEarningCard(property),
            );
          }),
          
          const SizedBox(height: 24),
          
          // Occupancy Rate Card
          FadeInUp(
            duration: const Duration(milliseconds: 700),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Occupancy Rate',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _earningsData['occupancyRate'] / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getOccupancyColor(_earningsData['occupancyRate']),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_earningsData['occupancyRate']}% Occupied',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _getOccupancyColor(_earningsData['occupancyRate']),
                        ),
                      ),
                      Text(
                        '${100 - _earningsData['occupancyRate']}% Vacant',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getOccupancyMessage(_earningsData['occupancyRate']),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTransactionsTab() {
    return Column(
      children: [
        // Search and Filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search transactions',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textLight,
                    ),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    _showFilterOptions();
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Transaction Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', true),
                _buildFilterChip('Income', false),
                _buildFilterChip('Expenses', false),
                _buildFilterChip('Pending', false),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Transactions List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final transaction = _transactions[index];
              return FadeInUp(
                duration: Duration(milliseconds: 500 + (index * 50)),
                child: _buildTransactionItem(transaction),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Earnings Trend
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earnings Trend',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value < 0 || value >= _monthlyData.length) {
                                  return const SizedBox();
                                }
                                return  Text(
                                    _monthlyData[value.toInt()]['month'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) {
                                  return const SizedBox();
                                }
                                return  Text(
                                    value >= 1000
                                        ? '\$${(value / 1000).toStringAsFixed(0)}k'
                                        : '\$${value.toInt()}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _getLineChartSpots(_monthlyData, 'income'),
                            isCurved: true,
                            color: AppTheme.primaryColor,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.primaryColor.withOpacity(0.1),
                            ),
                          ),
                          LineChartBarData(
                            spots: _getLineChartSpots(_monthlyData, 'expense'),
                            isCurved: true,
                            color: Colors.redAccent,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.redAccent.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('Income', AppTheme.primaryColor),
                      const SizedBox(width: 24),
                      _buildLegendItem('Expenses', Colors.redAccent),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Earnings by Category
          Text(
            'Earnings by Category',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Sample category breakdown
                  _buildCategoryItem(
                    'Residential Units',
                    8150,
                    85,
                    AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryItem(
                    'Commercial Units',
                    1200,
                    12,
                    const Color(0xFF8E44AD), // Purple
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryItem(
                    'Other Income',
                    300,
                    3,
                    const Color(0xFF2980B9), // Blue
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Expense Breakdown
          Text(
            'Expense Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          FadeInUp(
            duration: const Duration(milliseconds: 700),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: 45,
                            title: '45%',
                            color: Colors.redAccent,
                            radius: 80,
                            titleStyle: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: 30,
                            title: '30%',
                            color: const Color(0xFFE67E22), // Orange
                            radius: 80,
                            titleStyle: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: 15,
                            title: '15%',
                            color: const Color(0xFF2980B9), // Blue
                            radius: 80,
                            titleStyle: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: 10,
                            title: '10%',
                            color: const Color(0xFF8E44AD), // Purple
                            radius: 80,
                            titleStyle: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLegendItem('Maintenance', Colors.redAccent),
                      _buildLegendItem('Insurance', const Color(0xFFE67E22)),
                      _buildLegendItem('Taxes', const Color(0xFF2980B9)),
                      _buildLegendItem('Utilities', const Color(0xFF8E44AD)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPropertyEarningCard(Map<String, dynamic> property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                property['property'],
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${NumberFormat("#,##0").format(property['income'])}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: property['percentage'] / 100,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Text(
            '${property['percentage']}% of total earnings',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          // Handle filter selection
        },
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
  
  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final bool isIncome = transaction['type'] == 'income';
    final IconData transactionIcon = isIncome
        ? Icons.arrow_downward
        : Icons.arrow_upward;
    final Color transactionColor = isIncome
        ? AppTheme.successColor
        : Colors.redAccent;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: transactionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              transactionIcon,
              size: 20,
              color: transactionColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction['description'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTransactionDate(transaction['date']),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}\$${NumberFormat("#,##0.00").format(transaction['amount'])}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: transactionColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryItem(
    String category,
    double amount,
    int percentage,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '\$${NumberFormat("#,##0").format(amount)}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Container(
              height: 6,
              width: MediaQuery.of(context).size.width * (percentage / 100) * 0.75,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$percentage%',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
  
  String _formatTransactionDate(String date) {
    final DateTime transactionDate = DateTime.parse(date);
    final DateTime now = DateTime.now();
    final difference = now.difference(transactionDate).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(transactionDate);
    }
  }
  
  List<FlSpot> _getLineChartSpots(List<Map<String, dynamic>> data, String key) {
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      // Only include non-zero data points
      if (data[i][key] > 0) {
        spots.add(FlSpot(i.toDouble(), data[i][key].toDouble()));
      }
    }
    return spots;
  }
  
  Color _getOccupancyColor(int rate) {
    if (rate >= 80) {
      return AppTheme.successColor;
    } else if (rate >= 60) {
      return const Color(0xFFE67E22); // Orange
    } else {
      return Colors.redAccent;
    }
  }
  
  String _getOccupancyMessage(int rate) {
    if (rate >= 80) {
      return 'Great occupancy rate! Your properties are performing well.';
    } else if (rate >= 60) {
      return 'Good occupancy rate. Consider marketing available units to increase occupancy.';
    } else {
      return 'Low occupancy rate. Take action to find new tenants and increase occupancy.';
    }
  }
  
  void _showFilterOptions() {
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
                'Filter Transactions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              // Transaction Type
              Text(
                'Transaction Type',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip('All', true),
                  _buildFilterChip('Income', false),
                  _buildFilterChip('Expenses', false),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Date Range
              Text(
                'Date Range',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip('All Time', true),
                  _buildFilterChip('This Month', false),
                  _buildFilterChip('Last Month', false),
                  _buildFilterChip('Custom', false),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Property
              Text(
                'Property',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip('All Properties', true),
                  _buildFilterChip('Serene Apartments', false),
                  _buildFilterChip('Coastal Villa', false),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Apply Filter Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
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
                    'Apply Filters',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Reset Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Reset Filters',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showExportOptions() {
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
                'Export Report',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.table_chart_outlined,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                title: Text(
                  'Excel (.xlsx)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Export data as Excel spreadsheet',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Export as Excel
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Exporting report as Excel',
                        style: GoogleFonts.poppins(),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: Colors.red,
                  ),
                ),
                title: Text(
                  'PDF',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Export data as PDF document',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Export as PDF
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Exporting report as PDF',
                        style: GoogleFonts.poppins(),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.text_snippet_outlined,
                    color: Colors.blue,
                  ),
                ),
                title: Text(
                  'CSV',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Export data as CSV file',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Export as CSV
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Exporting report as CSV',
                        style: GoogleFonts.poppins(),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    
    final pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialDateRange,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDateRange != null) {
      // Handle selected date range
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Date range selected: ${DateFormat('MMM dd, yyyy').format(pickedDateRange.start)} - ${DateFormat('MMM dd, yyyy').format(pickedDateRange.end)}',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      setState(() {
        _selectedPeriod = 'Custom';
      });
    }
  }
}