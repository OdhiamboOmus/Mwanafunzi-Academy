import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'quiz_challenge_section.dart';

class QuizCardWidget extends StatelessWidget {
  final QuizCardData card;
  final VoidCallback onTap;

  const QuizCardWidget({super.key, required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 8),
    child: Card(
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
          border: Border.all(
            color: const Color(0xFF50E801).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      card.icon,
                      color: const Color(0xFF6B7280),
                      size: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF50E801).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.diamond,
                      color: Color(0xFF50E801),
                      size: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                card.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                card.description,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF6B7280),
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip('${card.questionCount} Questions', Icons.quiz),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoChip(card.duration, Icons.access_time),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Best Score',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 2),
              LinearProgressIndicator(
                value: card.bestScore / 100,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF50E801),
                ),
                minHeight: 2,
                borderRadius: BorderRadius.circular(1),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 28,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onTap();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF50E801),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  Widget _buildInfoChip(String text, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF50E801).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF50E801)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF50E801),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
