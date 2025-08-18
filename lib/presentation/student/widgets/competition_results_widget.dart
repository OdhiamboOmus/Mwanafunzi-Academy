import 'package:flutter/material.dart';

class CompetitionResultsWidget extends StatelessWidget {
  final String opponentName;
  final Map<String, dynamic> results;
  final String studentId;
  final VoidCallback onBackToChallenges;

  const CompetitionResultsWidget({
    super.key,
    required this.opponentName,
    required this.results,
    required this.studentId,
    required this.onBackToChallenges,
  });

  @override
  Widget build(BuildContext context) {
    String resultText;
    Color resultColor;
    IconData resultIcon;
    
    if (results['winner'] == 'draw') {
      resultText = 'It\'s a Draw!';
      resultColor = const Color(0xFFF59E0B);
      resultIcon = Icons.handshake;
    } else if (results['winner'] == studentId) {
      resultText = 'You Won!';
      resultColor = const Color(0xFF50E801);
      resultIcon = Icons.emoji_events;
    } else {
      resultText = 'You Lost';
      resultColor = const Color(0xFFEF4444);
      resultIcon = Icons.sentiment_very_dissatisfied;
    }

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: resultColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          resultIcon,
                          color: resultColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resultText,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: resultColor,
                              ),
                            ),
                            Text(
                              'vs $opponentName',
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
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Your Score',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${results['yourScore']}/${results['totalQuestions'] ?? 10}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Opponent Score',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${results['opponentScore']}/${results['totalQuestions'] ?? 10}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (results['pointsAwarded'] != null && 
                      (results['pointsAwarded'] as Map).isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF50E801).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFF50E801),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Points Awarded: ${(results['pointsAwarded'] as Map)[studentId] ?? 0}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF50E801),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: onBackToChallenges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF50E801),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Back to Challenges'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}