import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_approval_page.dart'; // ✅ Update this path accordingly

class NotificationsPage extends StatefulWidget {
  final String userRole; // 'admin' or 'user'

  const NotificationsPage({super.key, required this.userRole});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final notificationsRef = _supabase.from('notifications');

      final data = await (widget.userRole != 'admin'
          ? notificationsRef
              .select()
              .eq('user_id', _supabase.auth.currentUser!.id)
              .order('created_at', ascending: false)
          : notificationsRef.select().order('created_at', ascending: false));

      setState(() {
        _notifications = data;
        _isLoading = false;
      });

      // ✅ Mark notifications as read (optional: only for user, or for all if needed)
      if (widget.userRole != 'admin') {
        await notificationsRef
            .update({'is_read': true})
            .eq('user_id', _supabase.auth.currentUser!.id)
            .eq('is_read', false);
      } else {
        await notificationsRef.update({'is_read': true}).eq('is_read', false);
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic isoString) {
    try {
      final date = DateTime.parse(isoString.toString()).toLocal();
      return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  void _handleNotificationTap(dynamic notification) {
  debugPrint('Tapped notification: $notification');
  debugPrint('User role: ${widget.userRole}');
  if (notification['type'] == 'farm_submission' && widget.userRole.toLowerCase() == 'admin') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminApprovalPage()),
    );
  } else {
    debugPrint('Notification type or role did not match.');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return ListTile(
                      onTap: () => _handleNotificationTap(notification),
                      leading: Icon(
                        notification['type'] == 'farm_submission'
                            ? Icons.agriculture
                            : Icons.notifications,
                        color: Colors.green,
                      ),
                      title: Text(notification['title'] ?? ''),
                      subtitle: Text(notification['body'] ?? ''),
                      trailing: Text(
                        _formatDate(notification['created_at']),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  },
                ),
    );
  }
}
