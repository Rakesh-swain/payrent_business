import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/models/property_model.dart';
import 'package:payrent_business/models/account_information_model.dart';
import 'package:payrent_business/models/mandate_model.dart';
import 'package:payrent_business/screens/landlord/mandate/installment_bottomsheet.dart';
import 'package:payrent_business/screens/landlord/mandate/mandate_viewer_page.dart';

class CreateMandatePage extends StatefulWidget {
  final PropertyUnitModel unit;
  final DocumentSnapshot tenantDoc;
  final AccountInformation landlordAccountInfo;
  final String propertyId;

  const CreateMandatePage({
    Key? key,
    required this.unit,
    required this.tenantDoc,
    required this.landlordAccountInfo,
    required this.propertyId,
  }) : super(key: key);

  @override
  _CreateMandatePageState createState() => _CreateMandatePageState();
}

class _CreateMandatePageState extends State<CreateMandatePage> {
  String _selectedFrequency = 'Monthly';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 365));
  int _totalInstallments = 12;
  int _paymentAmount = 0; // Editable payment amount
  
  final List<String> _frequencies = ['Weekly', 'Monthly', 'Quarterly', 'Yearly'];
  final TextEditingController _amountController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _paymentAmount = widget.unit.rent; // Initialize with unit rent
    _amountController.text = _paymentAmount.toStringAsFixed(0);
    _calculateInstallments();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
  
  void _calculateInstallments() {
    final difference = _endDate.difference(_startDate).inDays;
    
    switch (_selectedFrequency) {
      case 'Weekly':
        _totalInstallments = (difference / 7).ceil();
        break;
      case 'Monthly':
        _totalInstallments = (difference / 30).ceil();
        break;
      case 'Quarterly':
        _totalInstallments = (difference / 90).ceil();
        break;
      case 'Yearly':
        _totalInstallments = (difference / 365).ceil();
        break;
    }
    
    if (mounted) setState(() {});
  }

  void _updatePaymentAmount(String value) {
    final amount = int.parse(value);
    if (amount != null && amount > 0) {
      setState(() {
        _paymentAmount = amount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantData = widget.tenantDoc.data() as Map<String, dynamic>;
    
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          'Create Payment Mandate',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            FadeInUp(
              duration: Duration(milliseconds: 300),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.account_balance, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Mandate Setup',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Unit ${widget.unit.unitNumber} - ${tenantData['firstName']} ${tenantData['lastName']}',
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
              ),
            ),
            
            SizedBox(height: 24),
            
            // Landlord Account Card
            FadeInUp(
              duration: Duration(milliseconds: 400),
              child: _buildAccountCard(
                title: 'Receiver Account (Landlord)',
                icon: Icons.account_balance_wallet,
                color: Colors.blue,
                accountHolderName: widget.landlordAccountInfo.accountHolderName,
                accountNumber: widget.landlordAccountInfo.accountNumber,
                bankBic: widget.landlordAccountInfo.bankBic,
                branchCode: widget.landlordAccountInfo.branchCode,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Tenant Account Card
            FadeInUp(
              duration: Duration(milliseconds: 500),
              child: _buildAccountCard(
                title: 'Payer Account (Tenant)',
                icon: Icons.person_outline,
                color: Colors.green,
                accountHolderName: tenantData['db_account_holder_name'],
                accountNumber: tenantData['db_account_number'],
                bankBic: tenantData['db_bank_bic'],
                branchCode: tenantData['db_branch_code'],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Payment Amount Card
            FadeInUp(
              duration: Duration(milliseconds: 550),
              child: _buildAmountCard(),
            ),
            
            SizedBox(height: 16),
            
            // Payment Frequency Card
            FadeInUp(
              duration: Duration(milliseconds: 600),
              child: _buildFrequencyCard(),
            ),
            
            SizedBox(height: 16),
            
            // Date Selection Cards
            Row(
              children: [
                Expanded(
                  child: FadeInUp(
                    duration: Duration(milliseconds: 700),
                    child: _buildDateCard(
                      title: 'Start Date',
                      date: _startDate,
                      onTap: () => _selectStartDate(),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: FadeInUp(
                    duration: Duration(milliseconds: 800),
                    child: _buildDateCard(
                      title: 'End Date',
                      date: _endDate,
                      onTap: () => _selectEndDate(),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Total Installments Card
            FadeInUp(
              duration: Duration(milliseconds: 900),
              child: _buildInstallmentsCard(),
            ),
            
            SizedBox(height: 32),
            
            // Next Button
            FadeInUp(
              duration: Duration(milliseconds: 1000),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showPreviewPage(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Preview & Create Mandate',
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
  
  Widget _buildAccountCard({
    required String title,
    required IconData icon,
    required Color color,
    required String accountHolderName,
    required String accountNumber,
    required String bankBic,
    required String branchCode,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildAccountDetailRow('Account Holder', accountHolderName),
            _buildAccountDetailRow('Account Number', accountNumber),
            _buildAccountDetailRow('Bank BIC', bankBic),
            _buildAccountDetailRow('Branch Code', branchCode),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAccountDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.teal.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.attach_money, color: Colors.teal, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Payment Amount',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Default Unit Rent: ',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '\$${widget.unit.rent.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: _updatePaymentAmount,
              decoration: InputDecoration(
                labelText: 'Custom Amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Enter the amount to be collected per payment',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFrequencyCard() {
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
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.schedule, color: Colors.orange, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Payment Frequency',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _frequencies.map((frequency) {
                final isSelected = frequency == _selectedFrequency;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFrequency = frequency;
                    });
                    _calculateInstallments();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      frequency,
                      style: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDateCard({
    required String title,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 16),
                  SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                DateFormat('MMM d, yyyy').format(date),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInstallmentsCard() {
    final totalAmount = _paymentAmount * _totalInstallments; // Use editable amount
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showInstallmentsBottomSheet(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.purple.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
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
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt_long, color: Colors.purple, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Payment Summary',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
                          'Total Installments',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '$_totalInstallments payments',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '\$${totalAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '\$${_paymentAmount.toStringAsFixed(2)} per payment × $_totalInstallments payments',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap to view installment breakdown',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(Duration(days: 365));
        }
      });
      _calculateInstallments();
    }
  }
  
  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: _startDate.add(Duration(days: 365 * 5)),
    );
    
    if (date != null) {
      setState(() {
        _endDate = date;
      });
      _calculateInstallments();
    }
  }
  
  void _showInstallmentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => InstallmentsBottomSheet(
        installments: _totalInstallments,
        amount: _paymentAmount, // Use editable amount
        frequency: _selectedFrequency,
        startDate: _startDate,
      ),
    );
  }
  
  void _showPreviewPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MandatePreviewPage(
          unit: widget.unit,
          tenantDoc: widget.tenantDoc,
          landlordAccountInfo: widget.landlordAccountInfo,
          propertyId: widget.propertyId,
          frequency: _selectedFrequency,
          startDate: _startDate,
          endDate: _endDate,
          totalInstallments: _totalInstallments,
          customAmount: _paymentAmount,
        ),
      ),
    );
  }
}