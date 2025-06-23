import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminApprovalPage extends StatefulWidget {
  const AdminApprovalPage({super.key});

  @override
  State<AdminApprovalPage> createState() => _AdminApprovalPageState();
}

class _AdminApprovalPageState extends State<AdminApprovalPage> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _pendingFarms = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPendingFarms();
  }

  Future<void> _fetchPendingFarms() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('farms')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      setState(() => _pendingFarms = response);
    } catch (e) {
      debugPrint('Error fetching pending farms: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _getFarmOwnerProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', userId)
          .maybeSingle(); // safer in case no matching row
      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> _approveFarm(dynamic farmId) async {
  try {
    debugPrint('Approving farm with ID: $farmId');

    final updateResponse = await _supabase
  .from('farms')
  .update({'status': 'approved'})
  .eq('id', farmId)
  .select();

debugPrint('Update response: $updateResponse');


    if (updateResponse.isEmpty) {
      debugPrint('❗️ No matching farm found for approval. Check ID type/value.');
    }

    await _fetchPendingFarms();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Farm approved successfully')),
    );
  } catch (e) {
    debugPrint('Error approving farm: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error approving farm: $e')),
    );
  }
}



Future<void> _confirmRejectFarm(String farmId, String? imageUrl) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reject Farm'),
      content: const Text('Are you sure you want to reject and delete this farm?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject')),
      ],
    ),
  );

  if (confirm == true) {
    _rejectFarm(farmId, imageUrl);
  }
}

Future<void> _rejectFarm(String farmId, String? imageUrl) async {
  try {
    await _supabase.from('farms').delete().eq('id', farmId);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        await _supabase.storage.from('farm-images').remove([imageUrl]);
      } catch (e) {
        debugPrint('Error deleting image file: $e');
      }
    }

    await _fetchPendingFarms();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Farm rejected and removed')),
    );
  } catch (e) {
    debugPrint('Error rejecting farm: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error rejecting farm: $e')),
    );
  }
}


  String getPublicImageUrl(String filename) {
    return _supabase.storage.from('farm-images').getPublicUrl(filename);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Farm Approvals'),
        backgroundColor: Colors.green.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingFarms.isEmpty
              ? const Center(child: Text('No pending farms.'))
              : RefreshIndicator(
                  onRefresh: _fetchPendingFarms,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _pendingFarms.length,
                    itemBuilder: (context, index) {
                      final farm = _pendingFarms[index];
final imageUrl = (farm['image_url']?.isNotEmpty ?? false)
    ? getPublicImageUrl(farm['image_url'])
    : null;

final userId = farm['user_id']?.toString() ?? '';
debugPrint('farm id: ${farm['id']} | userId: $userId');

return FutureBuilder<Map<String, dynamic>?>(
  future: userId.isNotEmpty ? _getFarmOwnerProfile(userId) : Future.value(null),

                        builder: (context, snapshot) {
                          final owner = snapshot.data;
                          final avatarUrl = (owner?['avatar_url'] as String?) ?? '';

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (imageUrl != null)
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                        child: Image.network(
                                          imageUrl,
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundImage:
                                                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                              child: avatarUrl.isEmpty
                                                  ? const Icon(Icons.person, size: 18)
                                                  : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              (owner?['username'] ?? 'Unknown User').toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (farm['name'] ?? 'Unnamed Farm').toString(),
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (farm['location'] ?? '').toString(),
                                        style: const TextStyle(color: Colors.black54),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        (farm['description'] ?? '').toString(),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () {
    debugPrint('Approving: ${farm['id']} (${farm['id'].runtimeType})');
    _approveFarm(farm['id']);
  },
                                            icon: const Icon(Icons.check, color: Colors.green),
                                            label: const Text('Approve', style: TextStyle(color: Colors.green)),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton.icon(
                                            onPressed: () => _confirmRejectFarm(farm['id'].toString(), farm['image_url']),
                                            icon: const Icon(Icons.close, color: Colors.red),
                                            label: const Text('Reject', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

