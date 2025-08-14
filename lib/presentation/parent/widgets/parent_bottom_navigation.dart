import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ParentBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;

  const ParentBottomNavigation({
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavigationItem(
            icon: Icons.home,
            label: 'Home',
            isSelected: selectedIndex == 0,
            onTap: () => onTabChanged(0),
          ),
          _NavigationItem(
            icon: Icons.grade,
            label: 'Grades',
            isSelected: selectedIndex == 1,
            onTap: () => onTabChanged(1),
          ),
          _NavigationItem(
            icon: Icons.calendar_today,
            label: 'Schedule',
            isSelected: selectedIndex == 2,
            onTap: () => onTabChanged(2),
          ),
          _NavigationItem(
            icon: Icons.school,
            label: 'Teachers',
            isSelected: selectedIndex == 3,
            onTap: () => onTabChanged(3),
          ),
        ],
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
