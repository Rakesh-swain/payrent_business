import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';

class MakePaymentPage extends StatefulWidget {
  final String? paymentId; // Optional, for pre-filled payment details
  
  const MakePaymentPage({super.key, this.paymentId});

  @override
  State<MakePaymentPage> createState() => _MakePaymentPageState();
}

class _MakePaymentPageState extends State<MakePaymentPage> {
  final _formKey = GlobalKey<FormState>();
  
  String _selectedPaymentMethod = 'Credit Card';
  final List<String> _paymentMethods = ['Credit Card', 'Bank Transfer', 'UPI'];
  
  // Sample card data controllers
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  
  // Sample bank data controllers
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _accountHolderController = TextEditingController();
  
  // Sample UPI data controller
  final _upiIdController = TextEditingController();
  
  // Sample payment data
  final Map<String, dynamic> _paymentData = {
    'id': '1',
    'title': 'Monthly Rent',
    'amount': 2200.00,
    'dueDate': '2023-09-15',
    'status': 'Due',
    'property': 'Modern Apartment in Downtown',
    'landlord': 'Sarah Thompson',
  };
  
  bool _isProcessing = false;
  bool _agreeTOS = false;
  
  @override
  void initState() {
    super.initState();
    
    // Prefill data if payment ID is provided
    if (widget.paymentId != null) {
      // In a real app, you would fetch payment details based on ID
    }
  }
  
  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _accountHolderController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }
  
  void _processPayment() {
    if (_formKey.currentState!.validate() && _agreeTOS) {
      setState(() {
        _isProcessing = true;
      });
      
      // Simulate payment processing
      Future.delayed(const Duration(seconds: 2), () {
        // Show success dialog
        _showPaymentResultDialog(true);
      });
    } else if (!_agreeTOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please agree to the terms and conditions',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  void _showPaymentResultDialog(bool isSuccess) {
    setState(() {
      _isProcessing = false;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSuccess
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.errorColor.withOpacity(0.1),
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.error_outline,
                  size: 48,
                  color: isSuccess ? AppTheme.successColor : AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSuccess ? 'Payment Successful' : 'Payment Failed',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isSuccess ? AppTheme.successColor : AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSuccess
                    ? 'Your payment has been processed successfully.'
                    : 'There was an issue processing your payment. Please try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              if (isSuccess)
                Text(
                  'Transaction ID: TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isSuccess) {
                      // Navigate back to dashboard or payment history
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? AppTheme.primaryColor : AppTheme.errorColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(isSuccess ? 'Back to Dashboard' : 'Try Again'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Make Payment'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView( physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Summary
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Details',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Property', _paymentData['property']),
                        _buildDetailRow('Landlord', _paymentData['landlord']),
                        _buildDetailRow('Due Date', _formatDate(_paymentData['dueDate'])),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Amount to Pay',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '\$${NumberFormat('#,##0.00').format(_paymentData['amount'])}',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Payment Method Selection
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Method',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentMethodSelection(),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Payment Form
              FadeInDown(
                duration: const Duration(milliseconds: 700),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Information',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentForm(),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Terms and Conditions Checkbox
              FadeInDown(
                duration: const Duration(milliseconds: 800),
                child: Row(
                  children: [
                    Checkbox(
                      value: _agreeTOS,
                      onChanged: (value) {
                        setState(() {
                          _agreeTOS = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: GoogleFonts.poppins(
                                color: AppTheme.primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                              // Add GestureDetector for Terms & Conditions
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Pay Button
              FadeInUp(
                duration: const Duration(milliseconds: 900),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppTheme.primaryGradient,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        alignment: Alignment.center,
                        child: _isProcessing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Pay \$${NumberFormat('#,##0.00').format(_paymentData['amount'])}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMethodSelection() {
    return Column(
      children: _paymentMethods.map((method) {
        return RadioListTile<String>(
          title: Row(
            children: [
              Image.asset(
                'assets/${method.toLowerCase().replaceAll(' ', '_')}.png',
                height: 24,
                width: 24,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image doesn't exist
                  IconData icon;
                  switch (method) {
                    case 'Credit Card':
                      icon = Icons.credit_card;
                      break;
                    case 'Bank Transfer':
                      icon = Icons.account_balance;
                      break;
                    case 'UPI':
                      icon = Icons.smartphone;
                      break;
                    default:
                      icon = Icons.payment;
                  }
                  
                  return Icon(icon, size: 24);
                },
              ),
              const SizedBox(width: 12),
              Text(
                method,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          value: method,
          groupValue: _selectedPaymentMethod,
          activeColor: AppTheme.primaryColor,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }
  
  Widget _buildPaymentForm() {
    switch (_selectedPaymentMethod) {
      case 'Credit Card':
        return _buildCreditCardForm();
      case 'Bank Transfer':
        return _buildBankTransferForm();
      case 'UPI':
        return _buildUPIForm();
      default:
        return _buildCreditCardForm();
    }
  }
  
  Widget _buildCreditCardForm() {
    return Column(
      children: [
        TextFormField(
          controller: _cardNumberController,
          decoration: const InputDecoration(
            labelText: 'Card Number',
            prefixIcon: Icon(Icons.credit_card_outlined),
            hintText: 'XXXX XXXX XXXX XXXX',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CardNumberFormatter(),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter card number';
            }
            if (value.replaceAll(' ', '').length < 16) {
              return 'Please enter a valid card number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cardHolderController,
          decoration: const InputDecoration(
            labelText: 'Cardholder Name',
            prefixIcon: Icon(Icons.person_outline),
            hintText: 'Name as on card',
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter cardholder name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryDateController,
                decoration: const InputDecoration(
                  labelText: 'Expiry Date',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  hintText: 'MM/YY',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryDateFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter expiry date';
                  }
                  if (value.length < 5) {
                    return 'Enter valid date';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  prefixIcon: Icon(Icons.lock_outline),
                  hintText: 'XXX',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter CVV';
                  }
                  if (value.length < 3) {
                    return 'Enter valid CVV';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildBankTransferForm() {
    return Column(
      children: [
        TextFormField(
          controller: _accountNumberController,
          decoration: const InputDecoration(
            labelText: 'Account Number',
            prefixIcon: Icon(Icons.account_balance_outlined),
            hintText: 'Enter your account number',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter account number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _ifscCodeController,
          decoration: const InputDecoration(
            labelText: 'IFSC Code',
            prefixIcon: Icon(Icons.confirmation_number_outlined),
            hintText: 'Enter IFSC code',
          ),
          textCapitalization: TextCapitalization.characters,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter IFSC code';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _accountHolderController,
          decoration: const InputDecoration(
            labelText: 'Account Holder Name',
            prefixIcon: Icon(Icons.person_outline),
            hintText: 'Enter account holder name',
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter account holder name';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildUPIForm() {
    return TextFormField(
      controller: _upiIdController,
      decoration: const InputDecoration(
        labelText: 'UPI ID',
        prefixIcon: Icon(Icons.smartphone_outlined),
        hintText: 'name@bankname',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter UPI ID';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid UPI ID';
        }
        return null;
      },
    );
  }
  
  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd MMM, yyyy').format(date);
  }
}

// Helper classes for card input formatting

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write(' ');
      }
    }
    
    final formattedText = buffer.toString();
    
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && i != text.length - 1) {
        buffer.write('/');
      }
    }
    
    final formattedText = buffer.toString();
    
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}