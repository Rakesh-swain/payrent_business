import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Import GetX
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:payrent_business/controllers/mandate_controller.dart';
// Import your controller
// import 'path/to/mandate_controller.dart'; 
// import 'config/theme.dart';

class InstallmentsDialog extends StatefulWidget {
  final String mmsId; // 👈 Added mmsId to fetch data
  final int installments;
  final int amount;
  final String frequency;
  
  const InstallmentsDialog({
    Key? key,
    required this.mmsId, 
    required this.installments,
    required this.amount,
    required this.frequency,
  }) : super(key: key);

  @override
  State<InstallmentsDialog> createState() => _InstallmentsDialogState();
}

class _InstallmentsDialogState extends State<InstallmentsDialog> {
  late Future<List<dynamic>> _paymentListFuture;
  final MandateController _controller = Get.find<MandateController>();

  @override
  void initState() {
    super.initState();
    // ✅ Initialize the API call
    _paymentListFuture = _controller.fetchPaymentList(widget.mmsId);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total purely for the header (optional)
    final totalAmount = widget.amount * widget.installments;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 600, minWidth: 350),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Header Section ---
            Text(
              'Payment Schedule',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.installments} ${widget.frequency.toLowerCase()} payments',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // --- Summary Cards ---
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

            // --- Scrollable List from API ---
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _paymentListFuture,
                builder: (context, snapshot) {
                  // 1. Loading State
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 10),
                          Text("Fetching schedule...", style: GoogleFonts.poppins(fontSize: 12)),
                        ],
                      ),
                    );
                  }

                  // 2. Error State
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Failed to load payment list.",
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    );
                  }

                  // 3. Empty State
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        "No payment schedule found.",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    );
                  }

                  // 4. Data Success State
                  final payments = snapshot.data!;
                  
                  return Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: Column(
                        children: List.generate(payments.length, (index) {
                          final item = payments[index];
                          
                          // ⚠️ Parsing API Data: Adjust keys ('amount', 'dueDate', 'status') based on your actual response
                          final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
                          final dateString = item['dueDate'] ?? ''; // Expecting ISO format e.g. "2023-10-27"
                          DateTime paymentDate = DateTime.now();
                          try {
                            paymentDate = DateTime.parse(dateString);
                          } catch (_) {}

                          final status = item['status'] ?? 'Pending';
                          
                          final isFirst = index == 0;
                          final isLast = index == payments.length - 1;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              // Using hardcoded colors for demo, replace with AppTheme.primaryColor
                              color: isFirst ? Colors.blue.withOpacity(0.1) : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: isFirst
                                  ? Border.all(color: Colors.blue.withOpacity(0.3))
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Number Bubble
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isFirst ? Colors.blue : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: GoogleFonts.poppins(
                                            color: isFirst ? Colors.white : Colors.grey[700],
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Details Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Payment ${index + 1}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: isFirst ? Colors.blue : Colors.black,
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
                                              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text(
                                                DateFormat('MMM d, yyyy').format(paymentDate),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              if (isFirst) ...[
                                                const SizedBox(width: 8),
                                                _buildTag('First', Colors.blue),
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
                                
                                // Status Text (Directly from API)
                                Text(
                                  'Status: $status',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: status.toString().toLowerCase() == 'paid' 
                                        ? Colors.green[700] 
                                        : Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // --- Footer ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // AppTheme.primaryColor
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Close',
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

  // --- Helpers ---

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
}