import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lip_reading/screens/lip_reading/lip_reading_screen.dart';
import 'package:lip_reading/screens/lip_reading/history_screen.dart';

/// Modern app shell with bottom navigation
/// Provides clean architecture for navigation between main app sections
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static const String routeName = '/app-shell';

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const LipReadingScreen(),
    const HistoryScreen(),
    const HelpScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Add haptic feedback for better user experience
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            ),
          );
        },
        child: IndexedStack(
          key: ValueKey<int>(_selectedIndex),
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: colorScheme.surface,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurfaceVariant,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_selectedIndex == 0 ? 8 : 4),
                decoration: BoxDecoration(
                  color: _selectedIndex == 0
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _selectedIndex == 0
                      ? Icons.videocam
                      : Icons.videocam_outlined,
                  semanticLabel: 'Record video for lip reading',
                ),
              ),
              label: 'Record',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_selectedIndex == 1 ? 8 : 4),
                decoration: BoxDecoration(
                  color: _selectedIndex == 1
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _selectedIndex == 1 ? Icons.history : Icons.history_outlined,
                  semanticLabel: 'View video history',
                ),
              ),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_selectedIndex == 2 ? 8 : 4),
                decoration: BoxDecoration(
                  color: _selectedIndex == 2
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _selectedIndex == 2 ? Icons.help : Icons.help_outline,
                  semanticLabel: 'Get help and support',
                ),
              ),
              label: 'Help',
            ),
          ],
        ),
      ),
    );
  }
}

/// Help screen with information about the app
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpCard(
              context,
              icon: Icons.videocam,
              title: 'How to Record',
              description:
                  'Tap the record button to capture a video for lip reading analysis. Make sure to speak clearly and face the camera directly.',
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              context,
              icon: Icons.model_training,
              title: 'AI Models',
              description:
                  'Choose between different AI models (MSTCN, DSTCN, Conformer) for different accuracy levels and processing speeds.',
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              context,
              icon: Icons.text_fields,
              title: 'Diacritized Text',
              description:
                  'Toggle the diacritized option to get Arabic text with or without diacritical marks (harakat).',
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              context,
              icon: Icons.history,
              title: 'History',
              description:
                  'Access your previous recordings and results in the History tab. You can edit, delete, or share your results.',
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Lip Reading App v1.0',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
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
