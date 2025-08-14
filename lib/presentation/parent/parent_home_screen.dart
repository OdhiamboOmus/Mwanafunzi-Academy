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
}