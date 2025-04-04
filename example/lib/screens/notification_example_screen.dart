import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '../widgets/example_card.dart';
import '../widgets/selectable_scaffold.dart';

class NotificationExampleScreen extends StatelessWidget {
  const NotificationExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectableScaffold(
      appBar: AppBar(
        title: const Text('Notification Example'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ExampleCard(
            title: 'Notification',
            description: 'Formatted text in a notification',
            code: '''ListTile(
  leading: Icon(Icons.notifications),
  title: Text('System Update'),
  subtitle: Textf(
    'Your device will restart in **5 minutes**. Save your work ~~or else~~!',
    style: TextStyle(fontSize: 14),
  ),
)''',
            child: Card(
              elevation: 2,
              child: ListTile(
                leading: Icon(Icons.notifications),
                title: Text('System Update'),
                subtitle: Textf(
                  'Your device will restart in **5 minutes**. Save your work ~~or else~~!',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'More Notification Examples',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // More notification examples
          const Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.warning_amber, color: Colors.orange),
              title: Text('Battery Low'),
              subtitle: Textf(
                'Your battery is at **15%**. Connect to a charger _soon_ to avoid shutdown.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.update, color: Colors.blue),
              title: Text('App Update Available'),
              subtitle: Textf(
                'Version **2.0.1** is now available with _new features_ and ~~bug~~ `fixes`.',
                style: TextStyle(fontSize: 14),
              ),
              trailing: Icon(Icons.download),
            ),
          ),
          const SizedBox(height: 12),

          const Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.security, color: Colors.green),
              title: Text('Security Alert'),
              subtitle: Textf(
                'Your account was accessed from a **new device** in _New York_. Was this you?',
                style: TextStyle(fontSize: 14),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Yes'),
                  SizedBox(width: 8),
                  Text('No', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Interactive notification system
          Text(
            'Interactive Notification System',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          const NotificationSystem(),
        ],
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
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: const Row(
                  children: [
                    Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                    Spacer(),
                    Text('Clear All'),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return Dismissible(
                    key: ValueKey(notification.toString() + index.toString()),
                    background: Container(
                      color: Colors.red.shade300,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      setState(() {
                        _notifications.removeAt(index);
                      });
                    },
                    child: ListTile(
                      leading: Icon(notification.icon, color: notification.iconColor),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(notification.title),
                          Text(
                            notification.time,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Textf(
                        notification.message,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _notifications.add(
                NotificationItem(
                  icon: Icons.security,
                  title: 'Security Alert',
                  message: 'Your account was accessed from a **new device** in _New York_. Was this you?',
                  time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  iconColor: Colors.green,
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

class NotificationItem {
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final Color iconColor;

  NotificationItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    this.iconColor = Colors.grey,
  });
}
