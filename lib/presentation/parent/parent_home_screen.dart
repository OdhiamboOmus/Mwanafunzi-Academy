import 'package:flutter/material.dart';
import 'parent_home_logic.dart';
import 'parent_home_widgets.dart';

// Parent home screen following Flutter Lite rules (<150 lines)
class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final ParentHomeLogic _logic = ParentHomeLogic();

  @override
  void initState() {
    super.initState();
    _logic.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Parent Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _logic.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ParentHomeWidgets.buildWelcomeSection(_logic.parentName),
                  const SizedBox(height: 32),
                  
                  if (_logic.linkedChildren.isEmpty)
                    ParentHomeWidgets.buildLinkStudentCard(
                      () => _logic.showLinkStudentDialog(context, _linkChild),
                      _logic.isCheckingLinks,
                    )
                  else
                    ParentHomeWidgets.buildLinkedChildrenSection(_logic.linkedChildren),
                  const SizedBox(height: 32),
                  
                  // Quiz Progress Section
                  if (_logic.linkedChildren.isNotEmpty) _buildQuizProgressSection(),
                  const SizedBox(height: 32),
                  
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ParentHomeWidgets.buildMainActionCard(
                    title: 'View Grades',
                    icon: Icons.grade,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  ParentHomeWidgets.buildMainActionCard(
                    title: 'Attendance',
                    icon: Icons.calendar_today,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  ParentHomeWidgets.buildMainActionCard(
                    title: 'Assignments',
                    icon: Icons.assignment,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  ParentHomeWidgets.buildMainActionCard(
                    title: 'Teacher Communication',
                    icon: Icons.message,
                    onTap: () {},
                  ),
                ],
              ),
            ),
    );
  }

  void _linkChild(String email) {
    _logic.linkChildByEmail(email, context);
  }
  
  /// Build quiz progress section for all linked children
  Widget _buildQuizProgressSection() {
    if (_logic.isQuizAnalyticsLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quiz Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () => _logic.refreshQuizAnalytics(),
              child: const Text(
                'Refresh',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Build quiz progress cards for each child
        ..._logic.linkedChildren.map((child) {
          final analytics = _logic.childQuizAnalytics[child.childId];
          if (analytics == null) return const SizedBox();
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.quiz,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.childName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '${analytics.totalQuizzesTaken} quizzes taken • ${(analytics.averageScore * 100).round()}% average',
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
                
                // Subject performance
                if (analytics.subjectPerformance.isNotEmpty) ...[
                  const Text(
                    'Subject Performance',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 30,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: analytics.subjectPerformance.length,
                      itemBuilder: (context, index) {
                        final subject = analytics.subjectPerformance.keys.elementAt(index);
                        final score = analytics.subjectPerformance[subject]!;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: score >= 0.8
                                ? Colors.green.withValues(alpha: 0.1)
                                : score >= 0.6
                                    ? Colors.orange.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: score >= 0.8
                                  ? Colors.green
                                  : score >= 0.6
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                          child: Text(
                            '$subject: ${(score * 100).round()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: score >= 0.8
                                  ? Colors.green
                                  : score >= 0.6
                                      ? Colors.orange
                                      : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Recent attempts
                if (analytics.recentAttempts.isNotEmpty) ...[
                  const Text(
                    'Recent Attempts',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...analytics.recentAttempts.take(2).map((attempt) {
                    final scorePercentage = (attempt.score / attempt.totalQuestions * 100).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${attempt.subject} - ${attempt.topic}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Text(
                            '$scorePercentage%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scorePercentage >= 80
                                  ? Colors.green
                                  : scorePercentage >= 60
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else ...[
                  const Text(
                    'No quiz attempts yet',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}