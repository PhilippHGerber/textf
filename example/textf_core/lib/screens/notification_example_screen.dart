// example/lib/screens/notification_example_screen.dart
import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '../widgets/example_card.dart';

class NotificationExampleScreen extends StatelessWidget {
  // Add theme constructor parameters
  final ThemeMode currentThemeMode;
  final VoidCallback toggleThemeMode;

  const NotificationExampleScreen({
    super.key,
    required this.currentThemeMode,
    required this.toggleThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    // Add theme icon logic
    final Brightness currentBrightness = Theme.of(context).brightness;
    final IconData themeIcon =
        currentBrightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Example'),
        actions: [
          // Add actions here
          IconButton(
            icon: Icon(themeIcon),
            tooltip: 'Toggle Theme',
            onPressed: toggleThemeMode,
          ),
        ],
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ExampleCard(
              // Use const
              title: 'Notification',
              description: 'Formatted text in a notification using default styles', // Updated desc
              code: '''
ListTile( // ... code remains the same
)''',
              child: Card(
                // Card uses theme elevation/color automatically
                child: ListTile(
                  leading: const Icon(Icons.notifications), // Icon color adapts
                  title: const Text('System Update'), // Text color adapts
                  subtitle: Textf(
                    // Textf default styles adapt
                    'Your device will restart in **5 minutes**. Save your work ~~or else~~!',
                    style: Theme.of(context).textTheme.bodyMedium, // Inherit from theme
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'More Notification Examples',
              style: Theme.of(context).textTheme.titleLarge, // Use theme style
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // More notification examples (Semantic colors are OK)
            Card(
              // Use const if possible
              child: ListTile(
                leading: const Icon(Icons.warning_amber, color: Colors.orange),
                title: const Text('Battery Low'),
                subtitle: Textf(
                  'Your battery is at **15%**. Connect to a charger _soon_ to avoid shutdown.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              // Use const
              child: ListTile(
                leading: const Icon(Icons.update, color: Colors.blue),
                title: const Text('App Update Available'),
                subtitle: Textf(
                  'Version **2.0.1** is now available with _new features_, ~~bug~~ `fixes` and a [link](https://example.com).', // Added link/code
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                trailing: const Icon(Icons.download),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              // Use const
              child: ListTile(
                leading: const Icon(Icons.security, color: Colors.green),
                title: const Text('Security Alert'),
                subtitle: Textf(
                  'Your account was accessed from a **new device** in _New York_. Was this you?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                trailing: Row(
                  // Actions are OK
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(onPressed: () {}, child: const Text('Yes')),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: const Text('No'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Interactive notification system
            Text(
              'Interactive Notification System',
              style: Theme.of(context).textTheme.titleLarge, // Use theme style
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const NotificationSystem(), // Use const
          ],
        ),
      ),
    );
  }
}

class NotificationSystem extends StatefulWidget {
  const NotificationSystem({super.key});

  @override
  State<NotificationSystem> createState() => _NotificationSystemState();
}

class _NotificationSystemState extends State<NotificationSystem> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      icon: Icons.notifications,
      title: 'System Update',
      message: 'Your device will restart in **5 minutes**. Save your work ~~or else~~!',
      time: '10:45 AM',
    ),
    NotificationItem(
      icon: Icons.warning_amber,
      title: 'Battery Low',
      message: 'Your battery is at **15%**. Connect to a charger _soon_ to avoid shutdown.',
      time: '11:30 AM',
      iconColor: Colors.orange,
    ),
    NotificationItem(
      icon: Icons.update,
      title: 'App Update Available',
      message: 'Version **2.0.1** is now available with _new features_ and ~~bug~~ `fixes`.',
      time: '12:15 PM',
      iconColor: Colors.blue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            // Use theme colors
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: .5)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  // Use theme color for header
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Notifications',
                      style: theme.textTheme.titleSmall, // Use theme style
                    ),
                    const Spacer(),
                    TextButton(
                      // Use TextButton for Clear All
                      onPressed: () {
                        setState(() {
                          _notifications.clear();
                        });
                      },
                      style: TextButton.styleFrom(
                        textStyle: theme.textTheme.labelMedium,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
              // Use Material version of Divider which adapts to theme
              const Divider(height: 1, thickness: 1),
              if (_notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
                  child: Text(
                    'No notifications',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _notifications.length,
                  // Use Material Divider
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return Dismissible(
                      key: ValueKey(notification.hashCode + index), // More robust key
                      background: Container(
                        color: theme.colorScheme.errorContainer, // Use theme color for background
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.onErrorContainer,
                        ), // Use theme color
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        setState(() {
                          _notifications.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Notification "${notification.title}" dismissed.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: ListTile(
                        leading: Icon(
                          notification.icon,
                          color: notification.iconColor ?? theme.colorScheme.primary,
                        ), // Fallback icon color
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(notification.title),
                            Text(
                              notification.time,
                              style: theme.textTheme.bodySmall?.copyWith(
                                // Use theme style
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Textf(
                          notification.message,
                          style: theme.textTheme.bodyMedium, // Inherit base from theme
                        ),
                        dense: true, // Make tiles more compact
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          // ElevatedButton adapts to theme
          onPressed: () {
            setState(() {
              _notifications.insert(
                // Insert at top
                0,
                NotificationItem(
                  icon: Icons.security,
                  title: 'Security Alert',
                  message:
                      'Your account was accessed from a **new device** in _New York_. Was this you?',
                  time:
                      '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  iconColor: Colors.green, // Keep semantic color
                ),
              );
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add New Notification'),
        ),
      ],
    );
  }
}

// NotificationItem class remains the same
class NotificationItem {
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final Color? iconColor; // Make optional

  NotificationItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    this.iconColor, // Allow null
  });
}
