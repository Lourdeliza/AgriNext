import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'my_market_page.dart';
import 'package:video_player/video_player.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  final String userId; // 👈 Accept userId for dynamic profile view

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  late final String currentUserId;
  late final bool _isOwnProfile;
  Map<String, dynamic>? _profile;
  int _followersCount = 0;

  static const Color primaryColor = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    final authUserId = _supabase.auth.currentUser?.id ?? '';
    currentUserId = widget.userId;
    _isOwnProfile = currentUserId == authUserId;
    _loadUserProfile();
    _loadFollowersCount();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', currentUserId)
          .single();
      setState(() {
        _profile = profile;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _loadFollowersCount() async {
    try {
      final response = await _supabase
          .from('subscriptions')
          .select('id')
          .eq('followed_id', currentUserId);
      setState(() {
        _followersCount = response.length;
      });
    } catch (e) {
      debugPrint('Error loading followers count: $e');
    }
  }

  Future<List<dynamic>> _fetchUserPosts() async {
    try {
      final response = await _supabase
          .from('posts')
          .select('id, video_url, thumbnail_url, content, created_at, file_size, username, avatar_url')
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      return [];
    }
  }

  String? getAvatarUrl(String? filename) {
    if (filename == null || filename.isEmpty) return null;
    return _supabase.storage.from('avatars').getPublicUrl(filename);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: Text(_profile?['username'] ?? 'Profile'),
      backgroundColor: primaryColor,
    ),
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 180,
                color: primaryColor,
              ),
              Positioned(
  bottom: 16,
  left: 16,
  right: 16,
  child: LayoutBuilder(
    builder: (context, constraints) {
      bool isNarrow = constraints.maxWidth < 400;

      return isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: _profile != null && getAvatarUrl(_profile!['avatar_url']) != null
                          ? NetworkImage(getAvatarUrl(_profile!['avatar_url'])!)
                          : null,
                      backgroundColor: Colors.grey[300],
                      child: _profile == null || getAvatarUrl(_profile!['avatar_url']) == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _profile?['username'] ?? '',
                            style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_followersCount followers',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isOwnProfile)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfilePage()));
                        },
                        child: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyMarketPage()));
                        },
                        child: const Text("My Market", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _profile != null && getAvatarUrl(_profile!['avatar_url']) != null
                      ? NetworkImage(getAvatarUrl(_profile!['avatar_url'])!)
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: _profile == null || getAvatarUrl(_profile!['avatar_url']) == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile?['username'] ?? '',
                        style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_followersCount followers',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (_isOwnProfile)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfilePage()));
                        },
                        child: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyMarketPage()));
                        },
                        child: const Text("My Market", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
              ],
            );
    },
  ),
),

            ],
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _fetchUserPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return const Center(child: Text("No posts yet."));
                }
                return ListView.builder(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
  itemCount: posts.length + 1, // +1 for the "Posts" header
  itemBuilder: (context, index) {
    if (index == 0) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(8, 12, 8, 4),
        child: Text(
          "Posts",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }
    final post = posts[index - 1]; // Shift index for posts
    return PostCard(
  post: post,
  isOwnProfile: _isOwnProfile,
  key: ValueKey(post['id']), // helpful for rebuilding individual items
);
  },
);

              },
            ),
          ),
        ],
      ),
    );
  }
}


class PostCard extends StatelessWidget {
  final dynamic post;
  final bool isOwnProfile;

  const PostCard({super.key, required this.post, this.isOwnProfile = false});

  String? getAvatarUrl(String? filename) {
    if (filename == null || filename.isEmpty) return null;
    return Supabase.instance.client.storage.from('avatars').getPublicUrl(filename);
  }

  Future<void> _deletePost(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await Supabase.instance.client
          .from('posts')
          .delete()
          .eq('id', post['id']);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _editPost(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _editController =
            TextEditingController(text: post['content'] ?? '');
        return AlertDialog(
          title: const Text("Edit Post"),
          content: TextField(
            controller: _editController,
            maxLines: null,
            decoration: const InputDecoration(hintText: 'Write something...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                try {
                  await Supabase.instance.client
                      .from('posts')
                      .update({'content': _editController.text})
                      .eq('id', post['id']);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post updated')));
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = post['content'] ?? '';
    final createdAt = post['created_at'];
    final thumbnailUrl = post['thumbnail_url'];
    final videoUrl = post['video_url'];
    final username = post['username'] ?? '';
    final avatarFilename = post['avatar_url'];
  final avatarUrl = Supabase.instance.client
      .storage
      .from('avatars')
      .getPublicUrl(avatarFilename ?? '');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture + Username Row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                radius: 20,
                backgroundImage: avatarFilename != null && avatarFilename.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarFilename == null || avatarFilename.isEmpty
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (createdAt != null)
                        Text(
                          DateTime.parse(createdAt)
                              .toLocal()
                              .toString()
                              .substring(0, 16),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                if (isOwnProfile) // ✅ Show 3-dots menu only if viewing own profile
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editPost(context);
                      } else if (value == 'delete') {
                        _deletePost(context);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit Post')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Post')),
                    ],
                  ),
              ],
            ),
          ),
          // Thumbnail
          if (thumbnailUrl != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(thumbnailUrl,
                  fit: BoxFit.cover, width: double.infinity, height: 200),
            ),
          // Content Text
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(content, style: const TextStyle(fontSize: 16)),
            ),
          // Video (if exists)
          if (videoUrl != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VideoPlayerWidget(videoUrl: videoUrl),
              ),
            ),
        ],
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                VideoPlayer(_controller),
                VideoProgressIndicator(_controller, allowScrubbing: true),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause_circle
                          : Icons.play_circle,
                      color: Colors.white,
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                  ),
                ),
              ],
            ),
          )
        : const SizedBox(
            height: 200, child: Center(child: CircularProgressIndicator()));
  }
}
