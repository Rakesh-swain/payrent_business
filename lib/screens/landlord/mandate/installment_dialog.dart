import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../../../config/theme.dart';

class InstallmentsDialog extends StatefulWidget {
  final int installments;
  final int amount;
  final String frequency;
  final DateTime startDate;
  final String status; // 👈 passed status text (e.g. "Pending")

  const InstallmentsDialog({
    Key? key,
    required this.installments,
    required this.amount,
    required this.frequency,
    required this.startDate,
    required this.status,
  }) : super(key: key);

  @override
  State<InstallmentsDialog> createState() => _InstallmentsDialogState();
}

class _InstallmentsDialogState extends State<InstallmentsDialog> {
  /// Tracks which payment index has shown its status
  late List<bool> _showStatus;

  @override
  void initState() {
    super.initState();
    _showStatus = List.generate(widget.installments, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.amount * widget.installments;

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
              '${widget.installments} ${widget.frequency.toLowerCase()} payments of OMR ${widget.amount.toStringAsFixed(2)} each',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Summary cards
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
                    'OMR ${widget.amount.toStringAsFixed(2)}',
                    Colors.blue,
                    Icons.payment,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Scrollable list
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(widget.installments, (index) {
                      final paymentDate = _calculatePaymentDate(index);
                      final isFirst = index == 0;
                      final isLast = index == widget.installments - 1;

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            'OMR ${widget.amount.toStringAsFixed(2)}',
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
                                              size: 16,
                                              color: Colors.grey[600]),
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
                                            _buildTag('First',
                                                AppTheme.primaryColor),
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

                            const SizedBox(height: 12),

                            // ✅ Check Status button for each payment
                             DateUtils.isSameDay(paymentDate, DateTime.now())?SizedBox(
                              // width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _handleCheckStatus(index),
                                icon: const Icon(Icons.sync,
                                    color: Colors.white),
                                label: Text(
                                  'Check Status',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15,horizontal: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ):Container(),

                            const SizedBox(height: 8),

                            // ✅ Show Status below button for that payment only
                            if (_showStatus[index])
                              Text(
                                'Status: ${widget.status}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
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

            // Info + Close
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

  Future<void> _handleCheckStatus(int index) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 80,
              width: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF6200EE)),
                    strokeWidth: 6,
                  ),
                  const Icon(Icons.description,
                      size: 40, color: Color(0xFF6200EE)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText('Checking status.',
                    textStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                    speed: const Duration(milliseconds: 100)),
                TypewriterAnimatedText('Checking status..',
                    textStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                    speed: const Duration(milliseconds: 100)),
                TypewriterAnimatedText('Checking status...',
                    textStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                    speed: const Duration(milliseconds: 100)),
              ],
              totalRepeatCount: 100,
              repeatForever: true,
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.pop(context);
      setState(() {
        _showStatus[index] = true;
      });
    }
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon) {
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
    switch (widget.frequency.toLowerCase()) {
      case 'daily':
        return widget.startDate.add(Duration(days: index));
      case 'weekly':
        return widget.startDate.add(Duration(days: index * 7));
      case 'monthly':
        return DateTime(widget.startDate.year,
            widget.startDate.month + index, widget.startDate.day);
      case 'quarterly':
        return DateTime(widget.startDate.year,
            widget.startDate.month + (index * 3), widget.startDate.day);
      case 'half-yearly':
      case 'half yearly':
        return DateTime(widget.startDate.year,
            widget.startDate.month + (index * 6), widget.startDate.day);
      case 'yearly':
        return DateTime(widget.startDate.year + index, widget.startDate.month,
            widget.startDate.day);
      default:
        return widget.startDate.add(Duration(days: index * 7));
    }
  }
}
