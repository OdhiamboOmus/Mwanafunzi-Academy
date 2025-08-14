import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/models/child_summary_model.dart';

/// UI widgets for ParentHomeScreen
/// Following Flutter Lite rules with separation of concerns
class ParentHomeWidgets {
  /// Build welcome section
  static Widget buildWelcomeSection(String parentName) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppConstants.brandColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, $parentName!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor your child\'s progress',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Build link student card
  static Widget buildLinkStudentCard(VoidCallback onPressed, bool isCheckingLinks) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppConstants.brandColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.brandColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.add_circle, color: AppConstants.brandColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Link Your Child',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connect to your child\'s account to monitor their progress',
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCheckingLinks ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.brandColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              child: isCheckingLinks
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Link Student'),
            ),
          ),
        ],
      ),
    );
  }

  /// Build linked children section
  static Widget buildLinkedChildrenSection(List<ChildSummary> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Children',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...children.map((child) => buildChildCard(
          child,
          onViewProgress: () {},
          onViewComments: () {},
          onUnlink: () {},
        )),
      ],
    );
  }

  /// Build child card
  static Widget buildChildCard(ChildSummary child, {
    required VoidCallback onViewProgress,
    required VoidCallback onViewComments,
    required VoidCallback onUnlink,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppConstants.brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.person,
                  color: AppConstants.brandColor,
                  size: 24,
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
                      '${child.grade} • ${child.schoolName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${child.totalPoints} pts',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '${child.completedLessons} lessons',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: buildActionCard(
                  title: 'View Progress',
                  icon: Icons.trending_up,
                  onTap: onViewProgress,
                  isSmall: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: buildActionCard(
                  title: 'View Comments',
                  icon: Icons.comment,
                  onTap: onViewComments,
                  isSmall: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: buildActionCard(
                  title: 'Unlink',
                  icon: Icons.link_off,
                  onTap: onUnlink,
                  isSmall: true,
                  isDestructive: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build action card
  static Widget buildActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isSmall = false,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmall ? 8 : AppConstants.defaultPadding),
        decoration: BoxDecoration(
          border: Border.all(color: isDestructive ? Colors.red[300]! : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          color: isDestructive ? Colors.red.withValues(alpha: 0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: isSmall ? 32 : 48,
              height: isSmall ? 32 : 48,
              decoration: BoxDecoration(
                color: (isDestructive ? Colors.red : AppConstants.brandColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : AppConstants.brandColor,
                size: isSmall ? 16 : 24,
              ),
            ),
            SizedBox(width: isSmall ? 8 : 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isSmall ? 12 : 16,
                  fontWeight: isSmall ? FontWeight.w500 : FontWeight.w600,
                  color: isDestructive ? Colors.red : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build main action card
  static Widget buildMainActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppConstants.brandColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppConstants.brandColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}