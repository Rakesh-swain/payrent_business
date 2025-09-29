import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';

class InstallmentsBottomSheet extends StatelessWidget {
  final int installments;
  final int amount;
  final String frequency;
  final DateTime startDate;

  const InstallmentsBottomSheet({
    Key? key,
    required this.installments,
    required this.amount,
    required this.frequency,
    required this.startDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final installmentList = _generateInstallmentList();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Payment Schedule',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$installments $frequency payments of \$${amount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Installments List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20),
              itemCount: installmentList.length,
              itemBuilder: (context, index) {
                final installment = installmentList[index];
                return _buildInstallmentItem(
                  installment['number'],
                  installment['date'],
                  installment['amount'],
                  index == 0, // First installment
                );
              },
            ),
          ),
          
          // Summary Footer
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Collection',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '\$${(amount * installments).toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Got it'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  List<Map<String, dynamic>> _generateInstallmentList() {
    List<Map<String, dynamic>> installmentList = [];
    DateTime currentDate = startDate;
    
    for (int i = 1; i <= installments; i++) {
      installmentList.add({
        'number': i,
        'date': currentDate,
        'amount': amount,
      });
      
      // Calculate next payment date based on frequency
      switch (frequency) {
        case 'Weekly':
          currentDate = currentDate.add(Duration(days: 7));
          break;
        case 'Monthly':
          currentDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
          break;
        case 'Quarterly':
          currentDate = DateTime(currentDate.year, currentDate.month + 3, currentDate.day);
          break;
        case 'Yearly':
          currentDate = DateTime(currentDate.year + 1, currentDate.month, currentDate.day);
          break;
      }
    }
    
    return installmentList;
  }
  
  Widget _buildInstallmentItem(int number, DateTime date, int amount, bool isFirst) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final isOverdue = date.isBefore(DateTime.now()) && !isFirst;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFirst ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFirst 
              ? AppTheme.primaryColor.withOpacity(0.3)
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          // Installment Number
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isFirst 
                  ? AppTheme.primaryColor 
                  : isOverdue 
                      ? Colors.red.withOpacity(0.1)
                      : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isFirst 
                      ? Colors.white 
                      : isOverdue 
                          ? Colors.red
                          : Colors.grey[600],
                ),
              ),
            ),
          ),
          
          SizedBox(width: 16),
          
          // Date and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(date),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isFirst)
                  Text(
                    'First Payment',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (isOverdue)
                  Text(
                    'Would be overdue',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  )
                else
                  Text(
                    'Scheduled',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          
          // Amount
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isFirst ? AppTheme.primaryColor : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}