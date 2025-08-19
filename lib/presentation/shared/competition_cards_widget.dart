import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CompetitionCardsWidget extends StatelessWidget {
  const CompetitionCardsWidget({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Competitions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: 2,
          itemBuilder: (context, index) {
            final competition = index == 0
                ? _CompetitionData(
                    title: 'School vs School',
                    description: 'Compete with other schools for top rankings',
                    icon: Icons.school,
                    color: const Color(0xFF50E801),
                  )
                : _CompetitionData(
                    title: 'Student vs Student',
                    description: 'Challenge your peers in knowledge battles',
                    icon: Icons.person,
                    color: const Color(0xFF50E801),
                  );
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 260,
              margin: const EdgeInsets.only(right: 12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Row(
                        children: [
                          Icon(
                            competition.icon,
                            color: competition.color,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              competition.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        competition.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: competition.color,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Join Competition',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _CompetitionData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _CompetitionData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}