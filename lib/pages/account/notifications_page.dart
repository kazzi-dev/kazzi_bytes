import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/account_controllers.dart';
import '../../data/models.dart';
import '../../theme/context_ext.dart';
import '../../theme/tokens.dart';
import '../../widgets/account_widgets.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/surfaces.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  void _sendTest(BuildContext context) {
    showInAppNotification(
      context,
      title: 'Your order is ready! 🍔',
      body: 'KB-1234 is waiting at the counter. Enjoy your meal!',
      icon: Icons.room_service_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final NotificationSettingsController settings = AppScope.of(context)
        .notifications;

    return ListenableBuilder(
      listenable: settings,
      builder: (BuildContext context, Widget? _) {
        final bool allOff = settings.allOff;
        return AccountPageScaffold(
          title: 'Notifications',
          bottomAction: OutlinedButton.icon(
            onPressed: () => _sendTest(context),
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Send a test notification'),
          ),
          children: <Widget>[
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                value: !allOff,
                onChanged: (bool on) {
                  HapticFeedback.selectionClick();
                  settings.setAll(on);
                },
                secondary: Icon(
                  allOff
                      ? Icons.notifications_off_outlined
                      : Icons.notifications_active_rounded,
                  color: allOff
                      ? context.colors.onSurfaceVariant
                      : context.colors.primary,
                ),
                title: Text(
                  'Allow notifications',
                  style: context.text.titleSmall,
                ),
                subtitle: Text(
                  allOff ? 'You won’t hear from us' : 'You’re all set',
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const GroupLabel('What to notify you about'),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  for (
                    int i = 0;
                    i < NotificationTopic.values.length;
                    i++
                  ) ...<Widget>[
                    if (i > 0) const Divider(indent: 72),
                    _TopicTile(
                      topic: NotificationTopic.values[i],
                      enabled: settings.isEnabled(NotificationTopic.values[i]),
                      onChanged: (bool on) {
                        HapticFeedback.selectionClick();
                        settings.set(NotificationTopic.values[i], on);
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Kz.s5),
            const InfoNote(
              icon: Icons.info_outline_rounded,
              text:
                  'Order updates appear as banners while the app is open. '
                  'Push notifications will arrive once the app is connected '
                  'to a server.',
            ),
          ],
        );
      },
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.topic,
    required this.enabled,
    required this.onChanged,
  });

  final NotificationTopic topic;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: enabled,
      onChanged: onChanged,
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.colors.primaryContainer,
          borderRadius: BorderRadius.circular(Kz.rSm),
        ),
        child: Icon(
          topic.icon,
          size: 20,
          color: context.colors.onPrimaryContainer,
        ),
      ),
      title: Text(topic.label, style: context.text.titleSmall),
      subtitle: Text(
        topic.description,
        style: context.text.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
