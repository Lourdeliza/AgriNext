import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile_page.dart';
// import 'add_job_page.dart';

class FarmDetailsPage extends StatefulWidget {
  final Map<String, dynamic> farm;
  final String? imageUrl;

  const FarmDetailsPage({super.key, required this.farm, this.imageUrl});

  @override
  State<FarmDetailsPage> createState() => _FarmDetailsPageState();
}

class _FarmDetailsPageState extends State<FarmDetailsPage> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _posterProfile;
  bool _isFollowing = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id;
    _loadPosterProfile();
  }

  Future<void> _loadPosterProfile() async {
    try {
      if (widget.farm['user_id'] != null) {
        final response = await _supabase
            .from('profiles')
            .select('username, avatar_url')
            .eq('id', widget.farm['user_id'])
            .maybeSingle();
        if (response != null) {
          setState(() {
            _posterProfile = response;
          });
          await _checkIfFollowing();
        }
      }
    } catch (e) {
      debugPrint('Error fetching poster profile: $e');
      debugPrint("Farm User ID: ${widget.farm['user_id']}");
    }
  }

  Future<void> _checkIfFollowing() async {
    final userId = _currentUserId;
    if (userId != null &&
        widget.farm['user_id'] != null &&
        userId != widget.farm['user_id']) {
      final follow = await _supabase
          .from('subscriptions')
          .select()
          .eq('follower_id', userId)
    .eq('followed_id', widget.farm['user_id'])
          .maybeSingle();
      setState(() {
        _isFollowing = follow != null;
      });
    }
  }

  Future<void> _followUser() async {
    final userId = _currentUserId;
    if (userId != null && widget.farm['user_id'] != null) {
      await _supabase.from('subscriptions').insert({
  'follower_id': userId,
  'followed_id': widget.farm['user_id'],
});

    }
  }

  void _goToUserProfile() {
    if (widget.farm['user_id'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(userId: widget.farm['user_id']),
        ),
      );
    }
  }

  void _launchPhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      debugPrint('Could not launch phone call to $phoneNumber');
    }
  }

  Future<List<dynamic>> _loadJobs() async {
  final response = await _supabase
      .from('jobs')
      .select()
      .eq('farm_id', widget.farm['id'])
      .order('created_at', ascending: false);
  return response;
}


  String? getAvatarUrl(String? filename) {
    if (filename == null || filename.isEmpty) return null;
    return _supabase.storage.from('avatars').getPublicUrl(filename);
  }

  bool get _isOwnFarm => _currentUserId == widget.farm['user_id'];

  @override
  Widget build(BuildContext context) {
    final contact = widget.farm['contact'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.farm['name'] ?? 'Farm Details'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.imageUrl != null)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      widget.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.broken_image, size: 40)),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: getAvatarUrl(_posterProfile?['avatar_url']) != null
                              ? NetworkImage(getAvatarUrl(_posterProfile!['avatar_url'])!)
                              : null,
                          child: getAvatarUrl(_posterProfile?['avatar_url']) == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _goToUserProfile,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _posterProfile?['username'] ?? 'User',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isOwnFarm)
  Positioned(
    right: 16,
    bottom: 16,
    child: ElevatedButton(
      onPressed: _isFollowing ? null : _followUser, // Disable if already following
      style: ElevatedButton.styleFrom(
        backgroundColor: _isFollowing ? Colors.grey : Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(_isFollowing ? 'Following' : 'Follow'),
    ),
  ),

                ],
              ),
            SingleChildScrollView(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 20, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.farm['location'] ?? 'No location provided',
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.description, size: 20, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.farm['description'] ?? 'No description provided.',
                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 20, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        contact.isNotEmpty ? contact : 'No contact info',
                        style: TextStyle(
                          fontSize: 16,
                          color: contact.isNotEmpty ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                    if (contact.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () => _launchPhoneCall(contact),
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const Text(
          'Available Jobs',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),

      FutureBuilder<List<dynamic>>(
        future: _loadJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading jobs.'));
          }
          final jobs = snapshot.data!;
          if (jobs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No jobs available for this farm.', style: TextStyle(color: Colors.grey)),
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.work, size: 20, color: Colors.green),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              job['title'] ?? 'Untitled Job',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (job['salary'] != null && job['salary'].toString().isNotEmpty)
                        Text(
                          'Salary: ₱${job['salary']}',
                          style: const TextStyle(color: Colors.green, fontSize: 14),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        job['description'] ?? '',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      const SizedBox(height: 16),
    ],
  ),
),



          ],
        ),
      ),
    );
  }
}

