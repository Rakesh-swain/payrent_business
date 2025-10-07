import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../controllers/mandate_controller.dart';
import '../../../models/mandate_model.dart';
import 'package:payrent_business/widgets/common/app_loading_indicator.dart';

class MandateStatusPage extends StatefulWidget {
  final String mandateId;

  const MandateStatusPage({
    Key? key,
    required this.mandateId,
  }) : super(key: key);

  @override
  _MandateStatusPageState createState() => _MandateStatusPageState();
}

class _MandateStatusPageState extends State<MandateStatusPage> {
  final MandateController _mandateController = Get.find<MandateController>();
  MandateModel? _mandate;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadMandate();
  }

  void _loadMandate() {
    _mandate = _mandateController.getMandateById(widget.mandateId);
    if (mounted) setState(() {});
  }

  Future<void> _updateMandateStatus() async {
    if (_mandate == null) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    final success = await _mandateController.updateMandateStatus(widget.mandateId);
    
    if (success) {
      // Reload mandate data to get updated status
      _loadMandate();
    }

    setState(() {
      _isUpdatingStatus = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_mandate == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Mandate Status',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
        body: const Center(
          child: Text('Mandate not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          'Mandate Status',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isUpdatingStatus ? null : _updateMandateStatus,
            icon: _isUpdatingStatus
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: const AppLoadingIndicator(size: 24),
                  )
                : Icon(Icons.refresh, color: AppTheme.primaryColor),
            tooltip: 'Update Status',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            FadeInUp(
              duration: Duration(milliseconds: 300),
              child: _buildHeaderCard(),
            ),

            SizedBox(height: 20),

            // Status Card
            FadeInUp(
              duration: Duration(milliseconds: 400),
              child: _buildStatusCard(),
            ),

            SizedBox(height: 20),

            // Mandate Details
            FadeInUp(
              duration: Duration(milliseconds: 500),
              child: _buildMandateDetailsCard(),
            ),

            SizedBox(height: 20),

            // Payment Information
            FadeInUp(
              duration: Duration(milliseconds: 600),
              child: _buildPaymentInfoCard(),
            ),

            SizedBox(height: 20),

            // Account Information
            FadeInUp(
              duration: Duration(milliseconds: 700),
              child: _buildAccountInfoCard(),
            ),

            SizedBox(height: 32),

            // Update Status Button
            FadeInUp(
              duration: Duration(milliseconds: 800),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdatingStatus ? null : _updateMandateStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isUpdatingStatus
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 26,
                              height: 26,
                              child: AppLoadingIndicator(size: 26),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Updating Status...',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Update Status',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final statusColor = _getStatusColor(_mandate!.mmsStatus);
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [statusColor, statusColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Mandate',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Reference: ${_mandate!.referenceNumber ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tenant',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _mandate!.tenantAccountHolderName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _mandate!.mmsStatus ?? 'PENDING',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor(_mandate!.mmsStatus);
    final statusIcon = _getStatusIcon(_mandate!.mmsStatus);
    final statusMessage = _getStatusMessage(_mandate!.mmsStatus);
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Current Status',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _mandate!.mmsStatus ?? 'PENDING',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Spacer(),
                      if (_mandate!.mmsId != null)
                        Text(
                          'ID: ${_mandate!.mmsId}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    statusMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: statusColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Last updated: ${DateFormat('MMM d, yyyy at h:mm a').format(_mandate!.updatedAt)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMandateDetailsCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, color: Colors.blue, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Mandate Details',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildDetailRow('Frequency', 'Weekly'),
            _buildDetailRow('Start Date', DateFormat('MMM d, yyyy').format(_mandate!.startDate)),
            _buildDetailRow('End Date', _mandate!.endDate != null 
                ? DateFormat('MMM d, yyyy').format(_mandate!.endDate!) 
                : 'N/A'),
            _buildDetailRow('Total Installments', '${_mandate!.noOfInstallments}'),
            _buildDetailRow('Amount per Payment', '\$${_mandate!.rentAmount.toStringAsFixed(2)}'),
            _buildDetailRow('Total Amount', '\$${(_mandate!.rentAmount * _mandate!.noOfInstallments).toStringAsFixed(2)}'),
            _buildDetailRow('Created', DateFormat('MMM d, yyyy').format(_mandate!.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.payment, color: Colors.green, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Payment Schedule',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${_mandate!.noOfInstallments}',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Payments',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '\$${_mandate!.rentAmount}',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'Each',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Weekly',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        Text(
                          'Frequency',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.account_balance, color: Colors.indigo, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Account Information',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Payer (Tenant) Account
            _buildAccountSection(
              title: 'Payer Account (Tenant)',
              accountHolder: _mandate!.tenantAccountHolderName,
              accountNumber: _mandate!.tenantAccountNumber,
              bankBic: _mandate!.tenantBankBic,
              branchCode: _mandate!.tenantBranchCode,
              color: Colors.red,
            ),
            
            SizedBox(height: 16),
            
            // Arrow indicating direction
            Center(
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_downward, color: Colors.grey[600], size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Transfers to',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Receiver (Landlord) Account
            _buildAccountSection(
              title: 'Receiver Account (Landlord)',
              accountHolder: _mandate!.landlordAccountHolderName,
              accountNumber: _mandate!.landlordAccountNumber,
              bankBic: _mandate!.landlordBankBic,
              branchCode: _mandate!.landlordBranchCode,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection({
    required String title,
    required String accountHolder,
    required String accountNumber,
    required String bankBic,
    required String branchCode,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          _buildDetailRow('Account Holder', accountHolder, isCompact: true),
          _buildDetailRow('Account Number', accountNumber, isCompact: true),
          _buildDetailRow('Bank BIC', bankBic, isCompact: true),
          _buildDetailRow('Branch Code', branchCode, isCompact: true, showDivider: false),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isCompact = false, bool showDivider = true}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: isCompact ? 100 : 120,
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: isCompact ? 12 : 13,
                  color: Colors.grey[600],
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: isCompact ? 12 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          SizedBox(height: 8),
          if (!isCompact) Divider(height: 1, color: Colors.grey[200]),
          if (!isCompact) SizedBox(height: 8),
          if (isCompact) SizedBox(height: 4),
        ],
      ],
    );
  }

  Color _getStatusColor(String? status) {
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

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusMessage(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return 'Your mandate has been accepted and is now active. Automatic payments will be processed according to the schedule.';
      case 'pending':
        return 'Your mandate is currently being processed. This may take some time for approval from the bank.';
      case 'rejected':
        return 'Your mandate has been rejected. Please contact support or create a new mandate with correct information.';
      default:
        return 'Status is currently unknown. Please update the status to get the latest information.';
    }
  }
}