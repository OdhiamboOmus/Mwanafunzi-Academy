import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TeacherBottomNavigationWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;

  const TeacherBottomNavigationWidget({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: const Color(0xFFE5E7EB), width: 1)),
    ),
    child: SafeArea(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _NavigationItem(
              icon: Icons.dashboard,
              label: 'Dashboard',
              isSelected: selectedIndex == 0,
              onTap: () => onTabChanged(0),
            ),
            _NavigationItem(
              icon: Icons.class_,
              label: 'Classes',
              isSelected: selectedIndex == 1,
              onTap: () => onTabChanged(1),
            ),
            _NavigationItem(
              icon: Icons.add_task,
              label: 'Assignments',
              isSelected: selectedIndex == 2,
              onTap: () => onTabChanged(2),
            ),
            _NavigationItem(
              icon: Icons.grade,
              label: 'Grades',
              isSelected: selectedIndex == 3,
              onTap: () => onTabChanged(3),
            ),
            _NavigationItem(
              icon: Icons.account_balance_wallet,
              label: 'Payouts',
              isSelected: selectedIndex == 4,
              onTap: () => onTabChanged(4),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeInOut,
    child: GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x1A50E801) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF50E801)
                  : const Color(0xFF6B7280),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF50E801)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}