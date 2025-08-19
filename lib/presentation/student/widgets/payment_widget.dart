import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../../data/services/payment_service.dart';
import '../../../data/services/booking_service.dart';
import '../../../core/constants.dart';

/// Payment widget for M-Pesa STK Push integration with payment request/response logging
class PaymentWidget extends StatefulWidget {
  final String bookingId;
  final double amount;
  final String teacherName;
  final String subject;

  const PaymentWidget({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.teacherName,
    required this.subject,
  });

  @override
  State<PaymentWidget> createState() => _PaymentWidgetState();
}

class _PaymentWidgetState extends State<PaymentWidget> {
  bool _isLoading = false;
  bool _isPaymentComplete = false;
  bool _isPaymentFailed = false;
  String _phoneNumber = '';
  String _paymentStatus = 'pending';
  String _transactionId = '';
  String _errorMessage = '';
  
  // Services
  final PaymentService _paymentService = PaymentService();
  final BookingService _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    developer.log('PaymentWidget: Initializing for booking ${widget.bookingId}, amount: ${widget.amount}');
  }

  @override
  void dispose() {
    developer.log('PaymentWidget: Screen disposed for booking ${widget.bookingId}');
    super.dispose();
  }

  // Handle phone number input change with logging
  void _onPhoneNumberChanged(String value) {
    developer.log('PaymentWidget: Phone number changed - New value: $value');
    setState(() {
      _phoneNumber = value;
    });
  }

  // Initiate STK Push with comprehensive logging
  Future<void> _initiatePayment() async {
    developer.log('PaymentWidget: Initiating STK Push - Amount: ${widget.amount}, Phone: $_phoneNumber');
    
    if (_isLoading || _phoneNumber.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _isPaymentFailed = false;
      _errorMessage = '';
    });

    try {
      // Validate phone number
      if (!_isValidPhoneNumber(_phoneNumber)) {
        throw 'Please enter a valid phone number';
      }

      // Initiate STK Push
      final response = await _paymentService.initiateSTKPush(widget.amount, _phoneNumber);
      
      developer.log('PaymentWidget: STK Push response received - $response');
      
      if (response['success'] == true) {
        // Store transaction ID
        _transactionId = response['transactionId'] ?? '';
        
        // Update booking status to payment pending
        await _bookingService.updateBookingStatus(widget.bookingId, 'payment_pending');
        
        developer.log('PaymentWidget: STK Push initiated successfully - TransactionID: $_transactionId');
        
        // Start payment polling
        _startPaymentPolling();
        
        setState(() {
          _isLoading = false;
          _paymentStatus = 'pending';
        });
      } else {
        throw response['message'] ?? 'Failed to initiate payment';
      }
    } catch (e) {
      developer.log('PaymentWidget: Error initiating STK Push - Error: $e');
      
      setState(() {
        _isLoading = false;
        _isPaymentFailed = true;
        _errorMessage = e.toString();
      });
    }
  }

  // Start payment polling with logging
  void _startPaymentPolling() {
    developer.log('PaymentWidget: Starting payment polling for transaction $_transactionId');
    
    // In a real implementation, this would poll the payment status
    // For demo purposes, we'll simulate a successful payment after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _handlePaymentSuccess();
      }
    });
  }

  // Handle payment success with logging
  Future<void> _handlePaymentSuccess() async {
    developer.log('PaymentWidget: Handling payment success for transaction $_transactionId');
    
    try {
      // Update booking status to paid
      await _bookingService.updateBookingStatus(widget.bookingId, 'paid');
      
      // Generate Zoom link
      final zoomLink = await _bookingService.generateZoomLink(widget.bookingId);
      
      developer.log('PaymentWidget: Payment processed successfully - ZoomLink: $zoomLink');
      
      setState(() {
        _isPaymentComplete = true;
        _paymentStatus = 'completed';
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful! Zoom link sent to your email.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('PaymentWidget: Error handling payment success - Error: $e');
      
      setState(() {
        _isPaymentFailed = true;
        _errorMessage = 'Failed to process payment: ${e.toString()}';
      });
    }
  }

  // Validate phone number format
  bool _isValidPhoneNumber(String phone) {
    final phoneRegex = r'^\+?[\d\s-]{10,15}$';
    final regex = RegExp(phoneRegex);
    return regex.hasMatch(phone);
  }

  // Format phone number for display
  String _formatPhoneNumber(String phone) {
    if (phone.startsWith('254')) {
      return '+$phone';
    } else if (phone.startsWith('0')) {
      return '+254${phone.substring(1)}';
    } else if (phone.startsWith('+')) {
      return phone;
    } else {
      return '+254$phone';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Payment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isPaymentComplete
          ? _buildPaymentSuccessScreen()
          : _isPaymentFailed
              ? _buildPaymentFailedScreen()
              : _buildPaymentForm(),
    );
  }

  // Build payment form with comprehensive logging
  Widget _buildPaymentForm() {
    developer.log('PaymentWidget: Building payment form for booking ${widget.bookingId}');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment information
          _buildPaymentInfo(),
          
          const SizedBox(height: 24),
          
          // Phone number input
          _buildPhoneNumberInput(),
          
          const SizedBox(height: 24),
          
          // Payment details
          _buildPaymentDetails(),
          
          const SizedBox(height: 32),
          
          // Pay button
          _buildPayButton(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Build payment information section
  Widget _buildPaymentInfo() {
    developer.log('PaymentWidget: Building payment info section');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF50E801), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.teacherName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.book, color: Color(0xFF50E801), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.subject,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.attach_money, color: Color(0xFF50E801), size: 20),
              const SizedBox(width: 8),
              Text(
                'Ksh ${widget.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build phone number input
  Widget _buildPhoneNumberInput() {
    developer.log('PaymentWidget: Building phone number input');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'M-Pesa Phone Number',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: _onPhoneNumberChanged,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Enter your M-Pesa phone number',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF50E801)),
            ),
            prefixIcon: const Icon(
              Icons.phone,
              color: Color(0xFF6B7280),
            ),
            suffixIcon: _phoneNumber.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.check, color: Color(0xFF50E801)),
                    onPressed: () {
                      developer.log('PaymentWidget: Phone number validation triggered');
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your M-Pesa registered phone number',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  // Build payment details section
  Widget _buildPaymentDetails() {
    developer.log('PaymentWidget: Building payment details section');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentDetailRow(
            'Payment Method',
            'M-Pesa STK Push',
            Icons.mobile_friendly,
          ),
          _buildPaymentDetailRow(
            'Amount',
            'Ksh ${widget.amount.toStringAsFixed(0)}',
            Icons.attach_money,
          ),
          _buildPaymentDetailRow(
            'Platform Fee',
            'Ksh ${(widget.amount * 0.20).toStringAsFixed(0)} (20%)',
            Icons.percent,
          ),
          _buildPaymentDetailRow(
            'Teacher Payout',
            'Ksh ${(widget.amount * 0.80).toStringAsFixed(0)}',
            Icons.person,
          ),
        ],
      ),
    );
  }

  // Build payment detail row
  Widget _buildPaymentDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF50E801), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Build pay button
  Widget _buildPayButton() {
    developer.log('PaymentWidget: Building pay button - Amount: ${widget.amount}');
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _initiatePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF50E801),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Pay with M-Pesa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // Build payment success screen
  Widget _buildPaymentSuccessScreen() {
    developer.log('PaymentWidget: Building payment success screen');
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 80,
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment Successful!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your booking has been confirmed',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Next Steps',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Check your email for the Zoom link and schedule details.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                developer.log('PaymentWidget: Done button tapped');
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF50E801),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build payment failed screen
  Widget _buildPaymentFailedScreen() {
    developer.log('PaymentWidget: Building payment failed screen');
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error,
            color: Colors.red,
            size: 80,
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment Failed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Please check your phone number and try again.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                developer.log('PaymentWidget: Retry button tapped');
                setState(() {
                  _isPaymentFailed = false;
                  _errorMessage = '';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF50E801),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}