import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../shared/bottom_navigation_widget.dart';
import '../../data/models/booking_model.dart';
import '../../data/services/booking_service.dart';
import '../../data/services/payment_service.dart';
import '../../core/constants.dart';
import 'widgets/booking_form_widget.dart';
import 'widgets/payment_widget.dart';
import '../shared/notification_integration_widget.dart';

/// Booking screen for weekly package selection and scheduling with booking flow logging
class BookingScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String subject;
  final double weeklyRate;

  const BookingScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.subject,
    required this.weeklyRate,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedBottomNavIndex = 3;
  bool _isLoading = false;
  bool _isBookingComplete = false;
  
  // Booking details
  int _selectedWeeks = 4;
  String _selectedDay = AppConstants.weekDays[0];
  String _selectedTime = '14:00';
  DateTime _startDate = DateTime.now();
  
  // Services
  final BookingService _bookingService = BookingService();
  final PaymentService _paymentService = PaymentService();
  
  // Cost calculation
  double _totalAmount = 0;
  double _platformFee = 0;
  double _teacherPayout = 0;

  @override
  void initState() {
    super.initState();
    developer.log('BookingScreen: Initializing for teacher ${widget.teacherName}');
    _calculateCost();
    _calculateStartDate();
  }

  @override
  void dispose() {
    developer.log('BookingScreen: Screen disposed for teacher ${widget.teacherName}');
    super.dispose();
  }

  void _calculateCost() {
    developer.log('BookingScreen: Calculating booking cost - WeeklyRate: ${widget.weeklyRate}, SelectedWeeks: $_selectedWeeks');
    
    _totalAmount = BookingService.calculateBookingCost(widget.weeklyRate, _selectedWeeks);
    _platformFee = _totalAmount * 0.20;
    _teacherPayout = _totalAmount - _platformFee;
    
    developer.log('BookingScreen: Cost calculated - Total: $_totalAmount, PlatformFee: $_platformFee, TeacherPayout: $_teacherPayout');
    
    if (mounted) setState(() {});
  }

  void _calculateStartDate() {
    developer.log('BookingScreen: Calculating start date - SelectedDay: $_selectedDay');
    
    int targetDay = _getDayOfWeekNumber(_selectedDay);
    int currentDay = DateTime.now().weekday;
    
    int daysToAdd = targetDay - currentDay;
    if (daysToAdd < 0) daysToAdd += 7;
    
    _startDate = DateTime.now().add(Duration(days: daysToAdd));
    developer.log('BookingScreen: Start date calculated - $_startDate');
    
    if (mounted) setState(() {});
  }

  int _getDayOfWeekNumber(String dayOfWeek) {
    switch (dayOfWeek.toLowerCase()) {
      case 'monday': return 1;
      case 'tuesday': return 2;
      case 'wednesday': return 3;
      case 'thursday': return 4;
      case 'friday': return 5;
      case 'saturday': return 6;
      case 'sunday': return 7;
      default: return 1;
    }
  }

  void _onWeeksChanged(int weeks) {
    developer.log('BookingScreen: Week selection changed - New value: $weeks');
    setState(() {
      _selectedWeeks = weeks;
      _calculateCost();
      _calculateStartDate();
    });
  }

  void _onDayChanged(String day) {
    developer.log('BookingScreen: Day selection changed - New value: $day');
    setState(() {
      _selectedDay = day;
      _calculateStartDate();
    });
  }

  void _onTimeChanged(String time) {
    developer.log('BookingScreen: Time selection changed - New value: $time');
    setState(() {
      _selectedTime = time;
    });
  }

  Future<void> _createBooking() async {
    developer.log('BookingScreen: Starting booking creation process');
    
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      final endDate = _startDate.add(Duration(days: _selectedWeeks * 7));
      
      final booking = BookingModel(
        id: '',
        teacherId: widget.teacherId,
        parentId: 'current_user_id',
        studentId: 'current_student_id',
        subject: widget.subject,
        numberOfWeeks: _selectedWeeks,
        weeklyRate: widget.weeklyRate,
        totalAmount: _totalAmount,
        platformFee: _platformFee,
        teacherPayout: _teacherPayout,
        dayOfWeek: _selectedDay,
        startTime: _selectedTime,
        duration: 120,
        startDate: _startDate,
        endDate: endDate,
        status: 'draft',
        paymentId: null,
        zoomLink: null,
        createdAt: DateTime.now(),
        paidAt: null,
        completedAt: null,
      );

      developer.log('BookingScreen: Creating booking with details - Weeks: ${booking.numberOfWeeks}, Amount: ${booking.totalAmount}');

      final bookingId = await _bookingService.createWeeklyBooking(booking);
      
      developer.log('BookingScreen: Booking created successfully - ID: $bookingId');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isBookingComplete = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking created successfully! Proceeding to payment...'),
            backgroundColor: Colors.green,
          ),
        );

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWidget(
              bookingId: bookingId,
              amount: _totalAmount,
              teacherName: widget.teacherName,
              subject: widget.subject,
            ),
          ),
        );

        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      developer.log('BookingScreen: Error creating booking - Error: $e');
      
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create booking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => NotificationIntegrationWidget(
    userId: 'current_user_id', // In a real app, this would come from authentication
    userType: 'student',
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Book Session',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.showNotification(
              title: 'Notifications',
              message: 'You have no new notifications',
              type: 'info',
            ),
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: _isBookingComplete
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 80),
                  SizedBox(height: 16),
                  Text(
                    'Booking Complete!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Proceeding to payment...',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            )
          : _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF50E801)),
                      SizedBox(height: 16),
                      Text(
                        'Creating booking...',
                        style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                )
              : _buildBookingForm(),
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: _selectedBottomNavIndex,
        onTabChanged: (index) => setState(() => _selectedBottomNavIndex = index),
      ),
    ),
  );

  Widget _buildBookingForm() {
    developer.log('BookingScreen: Building booking form for teacher ${widget.teacherName}');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTeacherInfo(),
          const SizedBox(height: 24),
          BookingFormWidget(
            selectedWeeks: _selectedWeeks,
            selectedDay: _selectedDay,
            selectedTime: _selectedTime,
            startDate: _startDate,
            totalAmount: _totalAmount,
            onWeeksChanged: _onWeeksChanged,
            onDayChanged: _onDayChanged,
            onTimeChanged: _onTimeChanged,
          ),
          const SizedBox(height: 24),
          _buildCostBreakdown(),
          const SizedBox(height: 32),
          _buildBookButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTeacherInfo() {
    developer.log('BookingScreen: Building teacher info section');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF50E801), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.teacherName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
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
              Text(
                widget.subject,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
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
                'Ksh ${widget.weeklyRate.toStringAsFixed(0)} per week',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdown() {
    developer.log('BookingScreen: Building cost breakdown - Total: $_totalAmount, PlatformFee: $_platformFee, TeacherPayout: $_teacherPayout');
    
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
            'Cost Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildCostRow('Weekly Rate', 'Ksh ${widget.weeklyRate.toStringAsFixed(0)}'),
          _buildCostRow('Number of Weeks', '$_selectedWeeks weeks'),
          const Divider(height: 16),
          _buildCostRow('Subtotal', 'Ksh ${(_totalAmount - _platformFee).toStringAsFixed(0)}'),
          _buildCostRow('Platform Fee (20%)', 'Ksh ${_platformFee.toStringAsFixed(0)}'),
          const Divider(height: 16),
          _buildCostRow('Total Amount', 'Ksh ${_totalAmount.toStringAsFixed(0)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? Colors.black : Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? Colors.black : Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    developer.log('BookingScreen: Building book button - Total amount: $_totalAmount');
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createBooking,
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
                'Book Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}