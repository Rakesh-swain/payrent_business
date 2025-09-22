import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';

class MaintenanceRequestPage extends StatefulWidget {
  const MaintenanceRequestPage({super.key});

  @override
  State<MaintenanceRequestPage> createState() => _MaintenanceRequestPageState();
}

class _MaintenanceRequestPageState extends State<MaintenanceRequestPage> {
  bool _isLoading = false;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'In Progress', 'Resolved'];
  
  // Sample maintenance requests
  final List<Map<String, dynamic>> _maintenanceRequests = [
    {
      'id': '1',
      'title': 'Leaking Faucet',
      'description': 'The kitchen sink faucet is leaking and needs repair.',
      'status': 'In Progress',
      'priority': 'Medium',
      'date': '2023-08-10',
      'scheduledDate': '2023-08-15',
      'images': ['assets/maintenance1.jpg'],
      'comments': [
        {
          'user': 'Sarah Thompson',
          'role': 'landlord',
          'text': 'We\'ve scheduled a plumber to visit on August 15th between 10AM and 12PM. Please ensure someone is available at the property.',
          'date': '2023-08-11T14:30:00Z',
        },
        {
          'user': 'John Doe',
          'role': 'tenant',
          'text': 'Thank you. I\'ll be available during that time.',
          'date': '2023-08-11T15:45:00Z',
        },
      ],
    },
    {
      'id': '2',
      'title': 'AC Not Cooling',
      'description': 'The bedroom air conditioner is not cooling properly, even when set to the lowest temperature.',
      'status': 'Resolved',
      'priority': 'High',
      'date': '2023-07-25',
      'resolvedDate': '2023-07-28',
      'images': ['assets/maintenance2.jpg'],
      'comments': [
        {
          'user': 'Sarah Thompson',
          'role': 'landlord',
          'text': 'We\'ll send an HVAC technician tomorrow to check it.',
          'date': '2023-07-25T16:20:00Z',
        },
        {
          'user': 'John Doe',
          'role': 'tenant',
          'text': 'Thank you for the quick response.',
          'date': '2023-07-25T16:45:00Z',
        },
        {
          'user': 'Sarah Thompson',
          'role': 'landlord',
          'text': 'The issue has been resolved. The technician cleaned the filters and recharged the refrigerant.',
          'date': '2023-07-28T13:15:00Z',
        },
      ],
    },
    {
      'id': '3',
      'title': 'Broken Window Latch',
      'description': 'The latch on the living room window is broken and doesn\'t lock properly.',
      'status': 'Pending',
      'priority': 'Low',
      'date': '2023-08-18',
      'images': [],
      'comments': [],
    },
  ];
  
  List<Map<String, dynamic>> _filteredRequests = [];
  
  @override
  void initState() {
    super.initState();
    _filterRequests();
  }
  
  void _filterRequests() {
    if (_selectedFilter == 'All') {
      _filteredRequests = List.from(_maintenanceRequests);
    } else {
      _filteredRequests = _maintenanceRequests
          .where((request) => request['status'] == _selectedFilter)
          .toList();
    }
    
    // Sort by date, most recent first
    _filteredRequests.sort((a, b) {
      final aDate = DateTime.parse(a['date']);
      final bDate = DateTime.parse(b['date']);
      return bDate.compareTo(aDate);
    });
    
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Maintenance Requests'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _selectedFilter == filter
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                      selected: _selectedFilter == filter,
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: Colors.white,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                          _filterRequests();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Requests List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredRequests.length,
                        itemBuilder: (context, index) {
                          final request = _filteredRequests[index];
                          return FadeInUp(
                            duration: Duration(milliseconds: 300 + (index * 100)),
                            child: _buildRequestCard(request),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create new request page
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => const CreateMaintenanceRequest(),
        //     ),
        //   ).then((_) {
        //     // Refresh list when returning from create page
        //     _filterRequests();
        //   });
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_repair_service_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'No maintenance requests',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'Tap the + button to create a new request'
                : 'No ${_selectedFilter.toLowerCase()} requests found',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildRequestCard(Map<String, dynamic> request) {
    Color statusColor;
    switch (request['status']) {
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'In Progress':
        statusColor = AppTheme.infoColor;
        break;
      case 'Resolved':
        statusColor = AppTheme.successColor;
        break;
      default:
        statusColor = AppTheme.textSecondary;
    }
    
    Color priorityColor;
    switch (request['priority']) {
      case 'High':
        priorityColor = AppTheme.errorColor;
        break;
      case 'Medium':
        priorityColor = Colors.orange;
        break;
      case 'Low':
        priorityColor = AppTheme.successColor;
        break;
      default:
        priorityColor = AppTheme.textSecondary;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to request details
          _showRequestDetails(request);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      request['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
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
              const SizedBox(height: 12),
              Text(
                request['description'],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 12,
                          color: priorityColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${request['priority']} Priority',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: priorityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (request['status'] == 'In Progress' && request['scheduledDate'] != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.infoColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.event_outlined,
                        size: 16,
                        color: AppTheme.infoColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Scheduled for ${_formatDate(request['scheduledDate'])}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.infoColor,
                      ),
                    ),
                  ],
                ),
              ],
              if (request['comments'] != null && request['comments'].isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.comment_outlined,
                      size: 14,
                      color: AppTheme.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${request['comments'].length} ${request['comments'].length == 1 ? 'comment' : 'comments'}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  void _showRequestDetails(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Status color
        Color statusColor;
        switch (request['status']) {
          case 'Pending':
            statusColor = Colors.orange;
            break;
          case 'In Progress':
            statusColor = AppTheme.infoColor;
            break;
          case 'Resolved':
            statusColor = AppTheme.successColor;
            break;
          default:
            statusColor = AppTheme.textSecondary;
        }
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Request Details',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              request['title'],
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
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
                      const SizedBox(height: 12),
                      
                      // Date and Priority
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(request['priority']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.flag_outlined,
                                  size: 12,
                                  color: _getPriorityColor(request['priority']),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${request['priority']} Priority',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _getPriorityColor(request['priority']),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      Text(
                        'Description',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          request['description'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Images (if any)
                      if (request['images'] != null && request['images'].isNotEmpty) ...[
                        Text(
                          'Images',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: request['images'].length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 120,
                                height: 120,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: AssetImage(request['images'][index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Schedule info (if in progress)
                      if (request['status'] == 'In Progress' && request['scheduledDate'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.infoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.infoColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.event_outlined,
                                  size: 24,
                                  color: AppTheme.infoColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Service Scheduled',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.infoColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'A maintenance visit has been scheduled for ${_formatDate(request['scheduledDate'])}. Please ensure someone is available.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Resolution info (if resolved)
                      if (request['status'] == 'Resolved' && request['resolvedDate'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.successColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_circle_outline,
                                  size: 24,
                                  color: AppTheme.successColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Issue Resolved',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.successColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'This maintenance request was resolved on ${_formatDate(request['resolvedDate'])}.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Comments
                      if (request['comments'] != null && request['comments'].isNotEmpty) ...[
                        Text(
                          'Comments',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...request['comments'].map<Widget>((comment) {
                          final bool isLandlord = comment['role'] == 'landlord';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isLandlord
                                  ? AppTheme.primaryColor.withOpacity(0.05)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isLandlord
                                    ? AppTheme.primaryColor.withOpacity(0.2)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      comment['user'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isLandlord
                                            ? AppTheme.primaryColor
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      _formatCommentDate(comment['date']),
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment['text'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      
                      // Add Comment (if not resolved)
                      if (request['status'] != 'Resolved') ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add a Comment',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'Type your comment here...',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppTheme.textLight,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Add comment functionality
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Comment added successfully',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: AppTheme.successColor,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('Submit Comment'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  String _formatDate(String date) {
    final DateTime parsedDate = DateTime.parse(date);
    return DateFormat('MMM dd, yyyy').format(parsedDate);
  }
  
  String _formatCommentDate(String date) {
    final DateTime parsedDate = DateTime.parse(date);
    return DateFormat('MMM dd, yyyy • h:mm a').format(parsedDate);
  }
  
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppTheme.errorColor;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return AppTheme.successColor;
      default:
        return AppTheme.textSecondary;
    }
  }
}