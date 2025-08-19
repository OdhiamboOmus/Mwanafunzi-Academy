import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import '../../../data/models/booking_model.dart';
import '../../../data/services/booking_service.dart';

/// Booking confirmation widget with comprehensive logging
class BookingConfirmationWidget extends StatefulWidget {
  final BookingModel booking;
  final String teacherName;
  final String zoomLink;

  const BookingConfirmationWidget({
    super.key,
    required this.booking,
    required this.teacherName,
    required this.zoomLink,
  });

  @override
  State<BookingConfirmationWidget> createState() => _BookingConfirmationWidgetState();
}

class _BookingConfirmationWidgetState extends State<BookingConfirmationWidget> {
  bool _isGeneratingZoomLink = false;
  String _currentZoomLink = '';
  
  final BookingService _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    developer.log('BookingConfirmationWidget: Initializing for booking ${widget.booking.id}');
    _currentZoomLink = widget.zoomLink;
  }

  @override
  void dispose() {
    developer.log('BookingConfirmationWidget: Screen disposed for booking ${widget.booking.id}');
    super.dispose();
  }

  // Generate new Zoom link with logging
  Future<void> _generateNewZoomLink() async {
    developer.log('BookingConfirmationWidget: Generating new Zoom link for booking ${widget.booking.id}');
    
    setState(() {
      _isGeneratingZoomLink = true;
    });

    try {
      final newZoomLink = await _bookingService.generateZoomLink(widget.booking.id);
      
      developer.log('BookingConfirmationWidget: New Zoom link generated - $newZoomLink');
      
      setState(() {
        _currentZoomLink = newZoomLink;
        _isGeneratingZoomLink = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New Zoom link generated: $newZoomLink'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('BookingConfirmationWidget: Error generating Zoom link - Error: $e');
      
      setState(() {
        _isGeneratingZoomLink = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate Zoom link: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Copy Zoom link to clipboard with logging
  void _copyZoomLink() {
    developer.log('BookingConfirmationWidget: Copying Zoom link to clipboard');
    
    Clipboard.setData(ClipboardData(text: _currentZoomLink));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Zoom link copied to clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Share booking details with logging
  void _shareBookingDetails() {
    developer.log('BookingConfirmationWidget: Sharing booking details');
    
    final bookingText = '''
Booking Confirmation
==================
Teacher: ${widget.teacherName}
Subject: ${widget.booking.subject}
Duration: ${widget.booking.numberOfWeeks} weeks
Start Date: ${widget.booking.startDate.day}/${widget.booking.startDate.month}/${widget.booking.startDate.year}
Time: ${widget.booking.startTime}
Total Amount: Ksh ${widget.booking.totalAmount.toStringAsFixed(0)}
Zoom Link: $_currentZoomLink
''';

    // Use Flutter's built-in share functionality
    // In production, you might want to implement a custom share dialog
    // For now, we'll copy to clipboard as a fallback
    Clipboard.setData(ClipboardData(text: bookingText));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking details copied to clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF50E801),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Confirmed!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Your sessions with ${widget.teacherName} are scheduled',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Booking Details
          _buildBookingDetails(),
          
          const SizedBox(height: 20),
          
          // Zoom Link Section
          _buildZoomLinkSection(),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  // Build booking details section
  Widget _buildBookingDetails() {
    developer.log('BookingConfirmationWidget: Building booking details section');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Teacher', widget.teacherName),
          _buildDetailRow('Subject', widget.booking.subject),
          _buildDetailRow('Duration', '${widget.booking.numberOfWeeks} weeks'),
          _buildDetailRow('Schedule', '${widget.booking.dayOfWeek} at ${widget.booking.startTime}'),
          _buildDetailRow('Start Date', '${widget.booking.startDate.day}/${widget.booking.startDate.month}/${widget.booking.startDate.year}'),
          _buildDetailRow('Total Amount', 'Ksh ${widget.booking.totalAmount.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  // Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
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

  // Build Zoom link section
  Widget _buildZoomLinkSection() {
    developer.log('BookingConfirmationWidget: Building Zoom link section');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.video_call,
                color: Color(0xFF50E801),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Zoom Link',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              if (_isGeneratingZoomLink)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF50E801),
                    strokeWidth: 2,
                  ),
                )
              else
                TextButton(
                  onPressed: _generateNewZoomLink,
                  child: const Text(
                    'Generate New',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF50E801),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _currentZoomLink.isNotEmpty ? _currentZoomLink : 'No Zoom link available',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
                if (_currentZoomLink.isNotEmpty)
                  IconButton(
                    onPressed: _copyZoomLink,
                    icon: const Icon(
                      Icons.copy,
                      color: Color(0xFF50E801),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check your email for the Zoom link and schedule details.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  // Build action buttons
  Widget _buildActionButtons() {
    developer.log('BookingConfirmationWidget: Building action buttons');
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _currentZoomLink.isNotEmpty ? _shareBookingDetails : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF50E801),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Share Booking Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              developer.log('BookingConfirmationWidget: Done button tapped');
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF50E801),
              side: const BorderSide(color: Color(0xFF50E801)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}