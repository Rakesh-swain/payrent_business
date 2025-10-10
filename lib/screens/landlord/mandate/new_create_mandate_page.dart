import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/widgets/dialog.dart';
import 'package:uuid/uuid.dart';
import '../../../config/theme.dart';
import '../../../controllers/mandate_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/property_model.dart';
import '../../../models/account_information_model.dart';
import 'installments_bottomsheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewCreateMandatePage extends StatefulWidget {
  final PropertyUnitModel unit;
  final DocumentSnapshot tenantDoc;
  final AccountInformation landlordAccountInfo;
  final String propertyId;

  const NewCreateMandatePage({
    Key? key,
    required this.unit,
    required this.tenantDoc,
    required this.landlordAccountInfo,
    required this.propertyId,
  }) : super(key: key);

  @override
  _NewCreateMandatePageState createState() => _NewCreateMandatePageState();
}

class _NewCreateMandatePageState extends State<NewCreateMandatePage> {
  final MandateController _mandateController = Get.find<MandateController>();
  final AuthController _authController = Get.find<AuthController>();
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  // State variables
  String _selectedFrequency = 'Monthly';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 365)); // Default 1 year
  int _numberOfInstallments = 0;
  int _paymentAmount = 0;
  bool _isLoading = false;
  
  final List<String> _frequencies = [
    'Monthly', 'Quarterly', 'Half-Yearly', 'Yearly'
  ];

  @override
  void initState() {
    super.initState();
    _paymentAmount = widget.unit.rent;
    _amountController.text = _paymentAmount.toString();
    _fetchLeaseDates();
    _calculateNumberOfInstallments();
    print(widget.tenantDoc.data());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
  Future<void> _fetchLeaseDates() async {
  try {
    final tenantId = widget.tenantDoc.id;
    final propertyId = widget.propertyId;
    final unitId = widget.unit.unitId;

    final unitSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('tenants')
        .doc(tenantId)
        .collection('properties')
        .where('propertyId', isEqualTo: propertyId,)
        .where('unitId', isEqualTo: unitId)
        .limit(1)
        .get();

    if (unitSnapshot.docs.isNotEmpty) {
      final unitData = unitSnapshot.docs.first.data();

      final leaseStart = unitData['leaseStartDate'];
      final leaseEnd = unitData['leaseEndate'];

      setState(() {
        _startDate = (leaseStart is Timestamp)
            ? leaseStart.toDate()
            : DateTime.tryParse(leaseStart.toString()) ?? DateTime.now();

        _endDate = (leaseEnd is Timestamp)
            ? leaseEnd.toDate()
            : DateTime.tryParse(leaseEnd.toString()) ??
                _startDate.add(const Duration(days: 365));
        print(_startDate);
        print(_endDate);
      });

      _calculateNumberOfInstallments();
    } else {
      debugPrint('No unit found with ID: $unitId');
    }
  } catch (e) {
    debugPrint('Error fetching lease dates: $e');
  }
}


  /// Calculate number of installments based on start date, end date and frequency
  void _calculateNumberOfInstallments() {
    if (_endDate.isBefore(_startDate) || _endDate.isAtSameMomentAs(_startDate)) {
      setState(() {
        _numberOfInstallments = 0;
      });
      return;
    }

    int installments = 0;
    DateTime currentDate = _startDate;

    while (currentDate.isBefore(_endDate) || currentDate.isAtSameMomentAs(_endDate)) {
      installments++;
      
      // Calculate next payment date based on frequency
      switch (_selectedFrequency) {
        case 'Monthly':
          currentDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
          break;
        case 'Quarterly':
          currentDate = DateTime(currentDate.year, currentDate.month + 3, currentDate.day);
          break;
        case 'Half-Yearly':
          currentDate = DateTime(currentDate.year, currentDate.month + 6, currentDate.day);
          break;
        case 'Yearly':
          currentDate = DateTime(currentDate.year + 1, currentDate.month, currentDate.day);
          break;
      }
      
      // Safety check to prevent infinite loops
      if (installments > 999) break;
    }

    setState(() {
      _numberOfInstallments = installments;
    });
  }

  /// Validate the form
  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_paymentAmount <= 0) {
      Get.snackbar('Error', 'Payment amount must be greater than 0');
      return false;
    }

    if (_startDate.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
      Get.snackbar('Error', 'Start date cannot be in the past');
      return false;
    }

    if (_endDate.isBefore(_startDate) || _endDate.isAtSameMomentAs(_startDate)) {
      Get.snackbar('Error', 'End date must be after start date');
      return false;
    }

    if (_numberOfInstallments <= 0) {
      Get.snackbar('Error', 'No payments calculated. Please adjust your dates.');
      return false;
    }

    if (_numberOfInstallments > 999) {
      Get.snackbar('Error', 'Maximum installments allowed is 999. Please adjust your dates or frequency.');
      return false;
    }

    return true;
  }

  /// Submit the mandate
  Future<void> _submitMandate() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tenantData = widget.tenantDoc.data() as Map<String, dynamic>;
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final mandate = await _mandateController.createMandate(
        landlordId: currentUser.uid,
        tenantId: widget.tenantDoc.id,
        propertyId: widget.propertyId,
        unitId: widget.unit.unitId,
        landlordAccountHolderName: widget.landlordAccountInfo.accountHolderName,
        landlordAccountNumber: widget.landlordAccountInfo.accountNumber,
        landlordIdType: 'CivilId',
        landlordIdNumber: '1584032',
        landlordBankBic: widget.landlordAccountInfo.bankBic,
        landlordBranchCode: widget.landlordAccountInfo.branchCode,
        tenantAccountHolderName: tenantData['db_account_holder_name'] ?? '',
        tenantAccountNumber: tenantData['db_account_number'] ?? '',
        tenantIdType: 'CivilId',
        tenantIdNumber: tenantData['db_civil_id'] ?? '120861567',
        tenantBankBic: tenantData['db_bank_bic'] ?? 'BSHROMRU',
        tenantBranchCode: tenantData['db_branch_code'] ?? '001',
        rentAmount: _paymentAmount,
        startDate: _startDate,
        noOfInstallments: _numberOfInstallments,
        paymentFrequency: _selectedFrequency,
        context: context
      );

      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      CustomDialogs.showErrorDialog(context, e.toString());
    } finally {
      setState(() {
        _isLoading = false;
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                              'Create Payment Mandate',
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

              // Payment Amount Card
              FadeInUp(
                duration: Duration(milliseconds: 400),
                child: _buildPaymentAmountCard(),
              ),

              SizedBox(height: 16),

              // Payment Frequency Card
              FadeInUp(
                duration: Duration(milliseconds: 500),
                child: _buildFrequencyCard(),
              ),

              SizedBox(height: 16),

              // Start Date Card
              FadeInUp(
                duration: Duration(milliseconds: 600),
                child: _buildStartDateCard(),
              ),

              SizedBox(height: 16),

              // End Date Card
              FadeInUp(
                duration: Duration(milliseconds: 700),
                child: _buildEndDateCard(),
              ),

              SizedBox(height: 16),

              // Account Information
              FadeInUp(
                duration: Duration(milliseconds: 800),
                child: _buildAccountInfoCard(),
              ),

              SizedBox(height: 16),

              // Payment Summary Card (Moved to last)
              FadeInUp(
                duration: Duration(milliseconds: 900),
                child: _buildPaymentSummaryCard(),
              ),

              SizedBox(height: 32),

              // Submit Button
              FadeInUp(
                duration: Duration(milliseconds: 1000),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitMandate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Create Mandate',
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
      ),
    );
  }

  Widget _buildPaymentAmountCard() {
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
                  child: Icon(Icons.attach_money, color: Colors.green, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Payment Amount',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Unit Rent: ',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'OMR${widget.unit.rent.toStringAsFixed(2)}',
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
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount per Payment',
                prefixText: 'OMR ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter payment amount';
                }
                final amount = int.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              onChanged: (value) {
                final amount = int.tryParse(value);
                if (amount != null) {
                  setState(() {
                    _paymentAmount = amount;
                  });
                }
              },
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
                      _calculateNumberOfInstallments();
                    });
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

  Widget _buildStartDateCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _selectStartDate(),
        borderRadius: BorderRadius.circular(16),
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
                    child: Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Start Date',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              SizedBox(height: 16),
              Text(
                DateFormat('EEEE, MMM d, yyyy').format(_startDate),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tap to change date',
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

  Widget _buildEndDateCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _selectEndDate(),
        borderRadius: BorderRadius.circular(16),
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
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.event_available, color: Colors.purple, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'End Date',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              SizedBox(height: 16),
              Text(
                DateFormat('EEEE, MMM d, yyyy').format(_endDate),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tap to change date',
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

  Widget _buildAccountInfoCard() {
    final tenantData = widget.tenantDoc.data() as Map<String, dynamic>;
    
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
                  child: Icon(Icons.account_balance_wallet, color: Colors.indigo, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Account Information',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Tenant Account Information
            _buildAccountSection(
              'Payer Account (Tenant)',
              tenantData['db_account_holder_name'] ?? '${tenantData['firstName']} ${tenantData['lastName']}',
              tenantData['db_account_number'] ?? '001020078676',
              tenantData['db_bank_bic'] ?? 'BSHROMRU',
              tenantData['db_branch_code'] ?? '001',
              Colors.red,
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
            
            // Landlord Account Information
            _buildAccountSection(
              'Receiver Account (Landlord)',
              widget.landlordAccountInfo.accountHolderName,
              widget.landlordAccountInfo.accountNumber,
              widget.landlordAccountInfo.bankBic,
              widget.landlordAccountInfo.branchCode,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(String title, String accountHolder, String accountNumber, String bankBic, String branchCode, Color color) {
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
          _buildAccountDetailRow('Account Holder', accountHolder),
          _buildAccountDetailRow('Account Number', accountNumber),
          _buildAccountDetailRow('Bank BIC', bankBic),
          _buildAccountDetailRow('Branch Code', branchCode, isLast: true),
        ],
      ),
    );
  }

  Widget _buildAccountDetailRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) SizedBox(height: 4),
      ],
    );
  }

  Widget _buildPaymentSummaryCard() {
    final totalAmount = _paymentAmount * _numberOfInstallments;
    final duration = _endDate.difference(_startDate).inDays;
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _numberOfInstallments > 0 ? () => _showInstallmentsBottomSheet() : null,
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
                  if (_numberOfInstallments > 0)
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              SizedBox(height: 16),
              
              if (_numberOfInstallments > 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Payments',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '$_numberOfInstallments payments',
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
                            'OMR${totalAmount.toStringAsFixed(2)}',
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
                SizedBox(height: 16),
                _buildSummaryRow('Frequency', _selectedFrequency),
                _buildSummaryRow('Amount per Payment', 'OMR${_paymentAmount.toStringAsFixed(2)}'),
                _buildSummaryRow('Duration', '${duration} days'),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$_numberOfInstallments ${_selectedFrequency.toLowerCase()} payments will be automatically collected',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blue[700],
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
              ] else ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please select start and end dates to calculate payments',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.orange[700],
                          ),
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
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showInstallmentsBottomSheet() {
    if (_numberOfInstallments <= 0) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => InstallmentsBottomSheet(
        installments: _numberOfInstallments,
        amount: _paymentAmount,
        frequency: _selectedFrequency,
        startDate: _startDate,
      ),
    );
  }

 

  Future<void> _selectStartDate() async {
    print(_startDate);
    print(DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(Duration(days: 365 * 5)),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
        // If end date is before new start date, adjust it
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(Duration(days: 365));
        }
        _calculateNumberOfInstallments();
      });
    }
  }

  Future<void> _selectEndDate() async {
    print(_endDate);
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate.add(Duration(days: 1)) : _endDate,
      firstDate: _startDate.add(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 365 * 10)),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
        _calculateNumberOfInstallments();
      });
    }
  }
}