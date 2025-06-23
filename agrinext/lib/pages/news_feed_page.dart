import 'dart:io';
import 'package:agrinext/pages/settings_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'add_friend_page.dart';
import 'login_page.dart';
import 'notification_page.dart';
import 'profile_page.dart';

class NewsFeedPage extends StatefulWidget {
  const NewsFeedPage({super.key});

  @override
  State<NewsFeedPage> createState() => _NewsFeedPageState();
}

class _NewsFeedPageState extends State<NewsFeedPage> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  XFile? _pickedVideo;
  VideoPlayerController? _videoPlayerController;
  bool _isPosting = false;
  Map<String, dynamic>? _profile;

  final Color agriNextGreen = const Color(0xFF4CAF50); // AgriNext main color

  final double _maxFileSizeMB = 100;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final profile = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user.id)
          .single();
      setState(() => _profile = profile);
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.length();
      if (bytes / (1024 * 1024) > _maxFileSizeMB) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video exceeds $_maxFileSizeMB MB limit')),
        );
        return;
      }
      _pickedVideo = pickedFile;

      if (!kIsWeb) {
        _videoPlayerController?.dispose();
        _videoPlayerController = VideoPlayerController.file(File(_pickedVideo!.path))
          ..initialize().then((_) {
            setState(() {});
          });
      }
      setState(() {});
    }
  }

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty && _pickedVideo == null) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      String? videoUrl;
      if (_pickedVideo != null) {
        final bytes = await _pickedVideo!.readAsBytes();
        final filePath = 'videos/${user.id}-${DateTime.now().millisecondsSinceEpoch}.mp4';
        await _supabase.storage.from('post-videos').uploadBinary(filePath, bytes);
        videoUrl = _supabase.storage.from('post-videos').getPublicUrl(filePath);
      }

      final profile = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user.id)
          .single();

      await _supabase.from('posts').insert({
        'user_id': user.id,
        'content': _postController.text.trim(),
        'video_url': videoUrl,
        'username': profile['username'],
        'avatar_url': profile['avatar_url'],
      });

      _postController.clear();
      _pickedVideo = null;
      _videoPlayerController?.dispose();
      _videoPlayerController = null;

      setState(() {
        _isPosting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post created!")));
    } catch (e) {
      setState(() {
        _isPosting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<List<dynamic>> _getPosts() async {
  final response = await _supabase.from('posts').select().order('created_at', ascending: false);

  // If search is not empty, filter locally:
  if (_searchController.text.trim().isNotEmpty) {
    final search = _searchController.text.trim().toLowerCase();
    return response.where((post) {
      final content = post['content']?.toString().toLowerCase() ?? '';
      final username = post['username']?.toString().toLowerCase() ?? '';
      return content.contains(search) || username.contains(search);
    }).toList();
  }

  return response;
}


  void _logout() async {
  await _supabase.auth.signOut();
  if (context.mounted) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}


  @override
  void dispose() {
    _postController.dispose();
    _videoPlayerController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_profile?['username'] ?? 'Loading...'),
              accountEmail: null,
              currentAccountPicture: _profile?['avatar_url'] != null
    ? CircleAvatar(
        backgroundImage: NetworkImage(
          _supabase.storage.from('avatars').getPublicUrl(_profile!['avatar_url']),
        ),
      )
    : const CircleAvatar(child: Icon(Icons.person)),

            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text("Follow"),
              onTap: () {
                Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddFriendPage()),
                  );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Log out"),
              onTap: _logout,
            ),
          ],
        ),
      ),
      appBar: AppBar(
  backgroundColor: agriNextGreen,
  title: Row(
    children: [
      const Text('AgriNext', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(width: 12),
      Expanded(
  child: SizedBox(
    height: 36,
    child: TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search...',
        hintStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white24,
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: () {
                  _searchController.clear();
                  setState(() {}); // Refresh list when cleared
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      onSubmitted: (value) {
        setState(() {}); // Refresh list on search submit
      },
      onChanged: (_) {
        setState(() {}); // Optional: update suffixIcon visibility as you type
      },
    ),
  ),
),

    ],
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.notifications),
      onPressed: () async {
  final user = _supabase.auth.currentUser;
  if (user != null) {
    final profile = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    final userRole = profile['role'] ?? 'user';

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NotificationsPage(userRole: userRole)),
      );
    }
  }
},

    ),
  ],
),

      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _profile?['avatar_url'] != null
    ? CircleAvatar(
        backgroundImage: NetworkImage(
          _supabase.storage.from('avatars').getPublicUrl(_profile!['avatar_url']),
        ),
      )
    : const CircleAvatar(child: Icon(Icons.person)),

                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _postController,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: "What's on your mind?",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_pickedVideo != null)
                    if (kIsWeb)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.videocam, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_pickedVideo!.name, overflow: TextOverflow.ellipsis)),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _pickedVideo = null;
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    else if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized)
  LayoutBuilder(
    builder: (context, constraints) {
      double maxWidth = constraints.maxWidth < 800 ? constraints.maxWidth : 800;
      double height = maxWidth * (4 / 3);

      return Stack(
        children: [
          Center(
            child: SizedBox(
              width: maxWidth,
              height: height,
              child: ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: Container(
    decoration: BoxDecoration(boxShadow: [
      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
    ]),
    child: AspectRatio(
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      child: VideoPlayer(_videoPlayerController!),
    ),
  ),
),

            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _pickedVideo = null;
                  _videoPlayerController?.dispose();
                  _videoPlayerController = null;
                });
              },
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: IconButton(
                icon: Icon(
                  _videoPlayerController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: () {
                  setState(() {
                    _videoPlayerController!.value.isPlaying
                        ? _videoPlayerController!.pause()
                        : _videoPlayerController!.play();
                  });
                },
              ),
            ),
          ),
        ],
      );
    },
  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _pickVideo,
                        icon: const Icon(Icons.video_library, color: Colors.green),
                      ),
                      ElevatedButton(
                        onPressed: _isPosting ? null : _createPost,
                        child: _isPosting
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text("Post"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _getPosts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final posts = snapshot.data!;
                if (posts.isEmpty) return const Center(child: Text("No posts yet."));
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
  children: [
    post['avatar_url'] != null
        ? CircleAvatar(
            backgroundImage: NetworkImage(
              _supabase.storage.from('avatars').getPublicUrl(post['avatar_url']),
            ),
          )
        : const CircleAvatar(child: Icon(Icons.person)),
    const SizedBox(width: 8),
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(userId: post['user_id']),
              ),
            );
          },
          child: Text(
            post['username'] ?? 'User',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 7, 100, 176), // 📌 optional for visual feedback
              // decoration: TextDecoration.underline, // 📌 optional: show it's clickable
            ),
          ),
        ),
        Text(
          DateFormat.yMMMd().add_jm().format(DateTime.parse(post['created_at'])),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    ),
  ],
),

                            const SizedBox(height: 8),
                            if (post['content'] != null && post['content'].toString().isNotEmpty)
                              Text(post['content']),
                            if (post['video_url'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: VideoPlayerWidget(videoUrl: post['video_url']),
                              ),
                          ],
                        ),
                      ),
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
                Center(
                  child: IconButton(
                    icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying ? _controller.pause() : _controller.play();
                      });
                    },
                  ),
                ),
              ],
            ),
          )
        : const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
  }
}
