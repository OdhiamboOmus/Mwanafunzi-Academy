import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GradeSelectorWidget extends StatelessWidget {
  final String selectedGrade;
  final Function(String) onGradeChanged;

  const GradeSelectorWidget({
    super.key,
    required this.selectedGrade,
    required this.onGradeChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
    ),
    child: InkWell(
      onTap: _showGradeSelector,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.grade,
                color: Color(0xFF50E801),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                selectedGrade.isEmpty ? 'Select Grade' : 'Grade $selectedGrade',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF6B7280),
            size: 24,
          ),
        ],
      ),
    ),
  );

  void _showGradeSelector() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _GradeSelectorBottomSheet(
          selectedGrade: selectedGrade,
          onGradeSelected: onGradeChanged,
        ),
      );
    }
  }
}

class _GradeSelectorBottomSheet extends StatelessWidget {
  final String selectedGrade;
  final Function(String) onGradeSelected;

  const _GradeSelectorBottomSheet({
    required this.selectedGrade,
    required this.onGradeSelected,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Select Grade',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: ListView.builder(
            itemCount: 12,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final grade = (index + 1).toString();
              final isSelected = grade == selectedGrade;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0x1A50E801) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF50E801) : const Color(0xFFE5E7EB),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    'Grade $grade',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? const Color(0xFF50E801) : Colors.black,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF50E801),
                          size: 24,
                        )
                      : null,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onGradeSelected(grade);
                    Navigator.pop(context);
                  },
                  selected: isSelected,
                  selectedTileColor: Colors.transparent,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    ),
  );
}

// Global key for accessing navigator context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();