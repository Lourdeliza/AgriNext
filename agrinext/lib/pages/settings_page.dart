import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'edit_profile_page.dart'; // ✅ Ensure correct casing for your file name

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _confirmAccountDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to permanently delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId != null) {
                await Supabase.instance.client
                    .from('profiles')
                    .delete()
                    .eq('id', userId);
                await Supabase.instance.client.auth.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Profile Settings',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            onTap: () {
              // TODO: Implement Change Password Page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon...')),
              );
            },
          ),
          const Divider(),
          const ListTile(
            title:
                Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _signOut(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account',
                style: TextStyle(color: Colors.red)),
            onTap: () => _confirmAccountDeletion(context),
          ),
        ],
      ),
    );
  }
}
