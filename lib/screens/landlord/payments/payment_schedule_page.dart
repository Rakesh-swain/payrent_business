import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/screens/landlord/payments/payment_detail_page.dart';
import 'package:table_calendar/table_calendar.dart';

class PaymentSchedulePage extends StatefulWidget {
  const PaymentSchedulePage({super.key});

  @override
  State<PaymentSchedulePage> createState() => _PaymentSchedulePageState();
}

class _PaymentSchedulePageState extends State<PaymentSchedulePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Sample payment schedule data
  final List<Map<String, dynamic>> _scheduleData = [
    {
      'id': '1',
      'tenantName': 'John Doe',
      'tenantId': '1',
      'propertyName': 'Modern Apartment in Downtown',
      'propertyId': '1',
      'amount': 2200,
      'status': 'Completed',
      'dueDate': '2023-08-15',
      'tenantImage': 'assets/tenant1.jpg',
    },
    {
      'id': '2',
      'tenantName': 'Jane Smith',
      'tenantId': '2',
      'propertyName': 'Luxury Condo with View',
      'propertyId': '3',
      'amount': 3500,
      'status': 'Due',
      'dueDate': '2023-09-01',
      'tenantImage': 'assets/tenant2.jpg',
    },
    {
      'id': '3',
      'tenantName': 'Robert Johnson',
      'tenantId': '3',
      'propertyName': '2-Bedroom Townhouse',
      'propertyId': '4',
      'amount': 2800,
      'status': 'Overdue',
      'dueDate': '2023-08-15',
      'tenantImage': 'assets/tenant3.jpg',
    },
    {
      'id': '4',
      'tenantName': 'Michael Brown',
      'tenantId': '4',
      'propertyName': 'Penthouse Apartment',
      'propertyId': '5',
      'amount': 4200,
      'status': 'Due',
      'dueDate': '2023-09-10',
      'tenantImage': 'assets/tenant4.jpg',
    },
    {
      'id': '5',
      'tenantName': 'Sarah Wilson',
      'tenantId': '5',
      'propertyName': 'Studio Apartment',
      'propertyId': '6',
      'amount': 1800,
      'status': 'Due',
      'dueDate': '2023-09-05',
      'tenantImage': 'assets/tenant5.jpg',
    },
    {
      'id': '6',
      'tenantName': 'David Lee',
      'tenantId': '6',
      'propertyName': 'Garden Apartment',
      'propertyId': '7',
      'amount': 2100,
      'status': 'Due',
      'dueDate': '2023-09-15',
      'tenantImage': 'assets/tenant6.jpg',
    },
  ];
  
  Map<DateTime, List<Map<String, dynamic>>> _groupedEvents = {};
  List<Map<String, dynamic>> _selectedEvents = [];
  
  @override
  void initState() {
    super.initState();
    _groupEvents();
    _selectedDay = _focusedDay;
    _selectedEvents = _getEventsForDay(_selectedDay!);
  }
  
  void _groupEvents() {
    _groupedEvents = {};
    
    for (final schedule in _scheduleData) {
      final dueDate = DateTime.parse(schedule['dueDate']);
      final dateKey = DateTime(dueDate.year, dueDate.month, dueDate.day);
      
      if (_groupedEvents[dateKey] == null) {
        _groupedEvents[dateKey] = [];
      }
      
      _groupedEvents[dateKey]!.add(schedule);
    }
  }
  
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _groupedEvents[dateKey] ?? [];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Payment Schedule'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar
          FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TableCalendar(
                  firstDay: DateTime.utc(2023, 1, 1),
                  lastDay: DateTime.utc(2023, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  eventLoader: _getEventsForDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      _selectedEvents = _getEventsForDay(selectedDay);
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: CalendarStyle(
                    markersMaxCount: 3,
                    markersAlignment: Alignment.bottomCenter,
                    markerDecoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: GoogleFonts.poppins(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    leftChevronIcon: const Icon(
                      Icons.chevron_left,
                      color: AppTheme.primaryColor,
                    ),
                    rightChevronIcon: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Events for selected day
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payments for ${DateFormat('dd MMM, yyyy').format(_selectedDay!)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedEvents.length} Payments',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Events List
          Expanded(
            child: _selectedEvents.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = _selectedEvents[index];
                      return FadeInUp(
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        child: _buildEventCard(event),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEventCard(Map<String, dynamic> event) {
    Color statusColor;
    IconData statusIcon;
    
    switch (event['status']) {
      case 'Completed':
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
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentDetailPage(paymentId: event['id']),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Tenant Image
              CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage(event['tenantImage']),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 12),
              // Event Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['tenantName'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event['propertyName'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Amount and Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'OMR${event['amount']}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 12,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event['status'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 80,
            color: AppTheme.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No payments due today',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select another day to view payments',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}