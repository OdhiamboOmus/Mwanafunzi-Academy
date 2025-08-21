import 'package:flutter/material.dart';
import 'package:mwanafunzi_academy/presentation/shared/widgets.dart';
import '../../services/firebase/school_competition_service.dart';
import '../shared/grade_selector_widget.dart';
import '../../../routes.dart';

// School competition screen following Flutter Lite rules (<150 lines)
class SchoolCompetitionScreen extends StatefulWidget {
  const SchoolCompetitionScreen({super.key});

  @override
  State<SchoolCompetitionScreen> createState() => _SchoolCompetitionScreenState();
}

class _SchoolCompetitionScreenState extends State<SchoolCompetitionScreen> {
  String _selectedGrade = 'Grade 1';
  String _studentSchool = '';
  List<Map<String, dynamic>> _activeCompetitions = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildSchoolInput(),
            const SizedBox(height: 16),
            GradeSelectorWidget(
              selectedGrade: _selectedGrade,
              onGradeChanged: (grade) => setState(() => _selectedGrade = grade),
            ),
            const SizedBox(height: 24),
            _buildCompetitionList(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    automaticallyImplyLeading: false, // Remove back arrow
    title: const Text(
      'School Competitions',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    ),
  );

  Widget _buildWelcomeSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Compete with Other Schools',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Join school competitions and earn points for your school',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
        ),
      ),
    ],
  );

  Widget _buildSchoolInput() => TextField(
    decoration: InputDecoration(
      labelText: 'Your School Name',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.all(16),
    ),
    onChanged: (value) => setState(() => _studentSchool = value),
  );

  Widget _buildCompetitionList() => _isLoading
      ? const Center(child: CircularProgressIndicator())
      : _errorMessage.isNotEmpty
          ? _buildErrorMessage()
          : _activeCompetitions.isEmpty
              ? _buildEmptyState()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Competitions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _activeCompetitions.length,
                      itemBuilder: (context, index) => _buildCompetitionCard(
                        _activeCompetitions[index],
                        index,
                      ),
                    ),
                  ],
                );

  Widget _buildCompetitionCard(Map<String, dynamic> competition, int index) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF50E801).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school,
                  color: Color(0xFF50E801),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      competition['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${competition['subject']} - ${competition['topic']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCompetitionInfo(competition),
          const SizedBox(height: 16),
          BrandButton(
            text: 'Join Competition',
            onPressed: () => _joinCompetition(competition),
          ),
        ],
      ),
    ),
  );

  Widget _buildCompetitionInfo(Map<String, dynamic> competition) => Row(
    children: [
      Expanded(
        child: _buildInfoItem(
          'Grade',
          competition['grade'],
          Icons.grade,
        ),
      ),
      Expanded(
        child: _buildInfoItem(
          'Questions',
          '${(competition['questions'] as List).length}',
          Icons.quiz,
        ),
      ),
      Expanded(
        child: _buildInfoItem(
          'Deadline',
          _formatDeadline(competition['deadline']),
          Icons.schedule,
        ),
      ),
    ],
  );

  Widget _buildInfoItem(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFF50E801), size: 16),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _buildErrorMessage() => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.red[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red[200]!),
    ),
    child: Row(
      children: [
        const Icon(Icons.error, color: Colors.red, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _errorMessage,
            style: TextStyle(color: Colors.red[700]),
          ),
        ),
      ],
    ),
  );

  Widget _buildEmptyState() => Container(
    padding: const EdgeInsets.all(32),
    child: Column(
      children: [
        Icon(
          Icons.school_outlined,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          'No Active Competitions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Check back later for new competitions',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
      ],
    ),
  );

  String _formatDeadline(String deadline) {
    final deadlineDate = DateTime.parse(deadline);
    final now = DateTime.now();
    final difference = deadlineDate.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} days left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes left';
    } else {
      return 'Expired';
    }
  }

  Future<void> _loadCompetitions() async {
    if (_studentSchool.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your school name');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final competitions = await SchoolCompetitionService.getActiveCompetitions(
        grade: _selectedGrade,
        school: _studentSchool,
      );

      setState(() {
        _activeCompetitions = competitions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load competitions: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinCompetition(Map<String, dynamic> competition) async {
    try {
      // In a real app, we would get student ID from authentication
      final studentId = 'student_${DateTime.now().millisecondsSinceEpoch}';
      final studentName = 'Student'; // In real app, get from profile

      await SchoolCompetitionService.joinCompetition(
        competitionId: competition['id'],
        studentId: studentId,
        studentName: studentName,
        school: _studentSchool,
      );

      // Navigate to competition quiz screen
      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.competitionQuiz,
          arguments: {
            'competitionId': competition['id'],
            'studentId': studentId,
            'questions': competition['questions'],
            'challenge': null,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCompetitions();
  }
}