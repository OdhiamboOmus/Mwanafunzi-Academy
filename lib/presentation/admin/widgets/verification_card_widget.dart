import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/services/teacher_service.dart';

// Verification card widget following Flutter Lite rules (<150 lines)
class VerificationCardWidget extends StatefulWidget {
  final TeacherModel teacher;
  final VoidCallback onTeacherUpdated;

  const VerificationCardWidget({
    super.key,
    required this.teacher,
    required this.onTeacherUpdated,
  });

  @override
  State<VerificationCardWidget> createState() => _VerificationCardWidgetState();
}

class _VerificationCardWidgetState extends State<VerificationCardWidget> {
  final TeacherService _teacherService = TeacherService();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTeacherInfo(),
            const SizedBox(height: 16),
            _buildCertificatePreview(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[300],
          child: const Icon(
            Icons.person,
            color: Colors.grey,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.teacher.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.teacher.email,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.teacher.subjects.join(', ')} • ${widget.teacher.areaOfOperation}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Pending',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCertificatePreview() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.picture_as_pdf,
            color: Colors.red,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'TSC Certificate',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Click to view certificate',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            text: 'Approve',
            color: Colors.green,
            icon: Icons.check,
            onPressed: _approveTeacher,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            text: 'Reject',
            color: Colors.red,
            icon: Icons.close,
            onPressed: _rejectTeacher,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _approveTeacher() async {
    developer.log('VerificationCardWidget: Approving teacher ${widget.teacher.id}');
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final success = await _teacherService.updateVerificationStatus(
        widget.teacher.id,
        'verified',
      );

      if (success) {
        developer.log('VerificationCardWidget: Teacher ${widget.teacher.id} approved successfully');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Teacher approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onTeacherUpdated();
        }
      } else {
        throw Exception('Failed to approve teacher');
      }
    } catch (e) {
      developer.log('VerificationCardWidget: Error approving teacher ${widget.teacher.id}: $e');
      setState(() {
        _errorMessage = 'Error approving teacher: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _rejectTeacher() async {
    developer.log('VerificationCardWidget: Rejecting teacher ${widget.teacher.id}');
    
    // For simplicity, we'll use a default rejection reason
    // In a real app, you'd show a dialog to enter the reason
    final rejectionReason = 'Application does not meet requirements';
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final success = await _teacherService.updateVerificationStatus(
        widget.teacher.id,
        'rejected',
        rejectionReason: rejectionReason,
      );

      if (success) {
        developer.log('VerificationCardWidget: Teacher ${widget.teacher.id} rejected successfully');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Teacher rejected successfully'),
              backgroundColor: Colors.red,
            ),
          );
          widget.onTeacherUpdated();
        }
      } else {
        throw Exception('Failed to reject teacher');
      }
    } catch (e) {
      developer.log('VerificationCardWidget: Error rejecting teacher ${widget.teacher.id}: $e');
      setState(() {
        _errorMessage = 'Error rejecting teacher: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}