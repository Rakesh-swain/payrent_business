import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';

class InstallmentsDialog extends StatelessWidget {
  final int installments;
  final int amount;
  final String frequency;
  final DateTime startDate;

  const InstallmentsDialog({
    Key? key,
    required this.installments,
    required this.amount,
    required this.frequency,
    required this.startDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalAmount = amount * installments;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 600, minWidth: 350),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              'Payment Schedule',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$installments ${frequency.toLowerCase()} payments of OMR ${amount.toStringAsFixed(2)} each',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Summary
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Amount',
                    'OMR ${totalAmount.toStringAsFixed(2)}',
                    Colors.green,
                    Icons.attach_money,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Per Payment',
                    'OMR ${amount.toStringAsFixed(2)}',
                    Colors.blue,
                    Icons.payment,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Scrollable List
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(installments, (index) {
                      final paymentDate = _calculatePaymentDate(index);
                      final isFirst = index == 0;
                      final isLast = index == installments - 1;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isFirst
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: isFirst
                              ? Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isFirst
                                    ? AppTheme.primaryColor
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.poppins(
                                    color: isFirst
                                        ? Colors.white
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Payment ${index + 1}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isFirst
                                              ? AppTheme.primaryColor
                                              : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'OMR ${amount.toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.schedule,
                                          size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('MMM d, yyyy')
                                            .format(paymentDate),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (isFirst) ...[
                                        const SizedBox(width: 8),
                                        _buildTag('First', AppTheme.primaryColor),
                                      ],
                                      if (isLast) ...[
                                        const SizedBox(width: 8),
                                        _buildTag('Last', Colors.orange),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Info + Close Button
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Payments will be automatically collected on the scheduled dates.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  DateTime _calculatePaymentDate(int index) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return startDate.add(Duration(days: index));
      case 'weekly':
        return startDate.add(Duration(days: index * 7));
      case 'monthly':
        return DateTime(startDate.year, startDate.month + index, startDate.day);
      case 'quarterly':
        return DateTime(startDate.year, startDate.month + (index * 3), startDate.day);
      case 'half-yearly':
      case 'half yearly':
        return DateTime(startDate.year, startDate.month + (index * 6), startDate.day);
      case 'yearly':
        return DateTime(startDate.year + index, startDate.month, startDate.day);
      default:
        return startDate.add(Duration(days: index * 7));
    }
  }
}
