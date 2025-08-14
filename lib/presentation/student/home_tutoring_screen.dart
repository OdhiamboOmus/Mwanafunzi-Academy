import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeTutoringScreen extends StatelessWidget {
  const HomeTutoringScreen({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const SizedBox(height: 40),

        // Mascot and icons section
        _buildMascotSection(),

        const SizedBox(height: 40),

        // Coming Soon title
        const Text(
          'Coming Soon!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF50E801),
          ),
        ),

        const SizedBox(height: 16),

        // Subtitle
        const Text(
          'Home Tutoring Services',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 24),

        // Description
        const Text(
          'We\'re working hard to bring you personalized home tutoring services. Soon you\'ll be able to book qualified teachers to come to your home for one-on-one learning sessions.',
          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280), height: 1.5),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Features list
        _buildFeaturesList(),

        const SizedBox(height: 40),

        // Notify button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _showNotificationDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF50E801),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications, size: 20),
                SizedBox(width: 12),
                Text(
                  'Notify Me When Available',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    ),
  );

  Widget _buildMascotSection() => Column(
    children: [
      // House icon (main mascot)
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF50E801).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.home, size: 80, color: Color(0xFF50E801)),
      ),

      const SizedBox(height: 24),

      // Supporting icons row
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSupportIcon(Icons.computer, Colors.orange),
          const SizedBox(width: 20),
          _buildSupportIcon(Icons.school, Colors.blue),
        ],
      ),

      const SizedBox(height: 20),

      // Educational items row
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSupportIcon(Icons.menu_book, Colors.green),
          const SizedBox(width: 20),
          _buildSupportIcon(Icons.folder, Colors.grey),
          const SizedBox(width: 20),
          _buildSupportIcon(Icons.edit, Colors.orange),
        ],
      ),
    ],
  );

  Widget _buildSupportIcon(IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, size: 24, color: color),
  );

  Widget _buildFeaturesList() => Column(
    children: [
      _buildFeatureItem('Qualified TSC certified teachers', Icons.verified),
      const SizedBox(height: 16),
      _buildFeatureItem('Flexible scheduling', Icons.schedule),
      const SizedBox(height: 16),
      _buildFeatureItem('Personalized learning plans', Icons.person),
      const SizedBox(height: 16),
      _buildFeatureItem('Safe and secure service', Icons.security),
    ],
  );

  Widget _buildFeatureItem(String text, IconData icon) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFF50E801),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
      ),
    ],
  );

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.notifications_active,
              color: Color(0xFF50E801),
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Notification Set!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: const Text(
          'We\'ll notify you as soon as home tutoring services become available in your area.',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Got it!',
              style: TextStyle(
                color: Color(0xFF50E801),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
