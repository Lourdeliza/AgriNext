import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late final String currentUserId;
  late Future<List<dynamic>> _suggestedFuture;
  late Future<List<dynamic>> _followingFuture;
  late Future<List<dynamic>> _followersFuture;
  final Color agriNextGreen = const Color(0xFF4CAF50);

  Map<String, bool> _subscriptionStatus = {};

  @override
  void initState() {
    super.initState();
    currentUserId = _supabase.auth.currentUser?.id ?? '';
    _suggestedFuture = _fetchSuggestedUsers();
    _followingFuture = _fetchFollowingUsers();
    _followersFuture = _fetchFollowers();
  }

  Future<List<dynamic>> _fetchSuggestedUsers() async {
    final allUsers = await _supabase
        .from('profiles')
        .select('id, username, avatar_url')
        .neq('id', currentUserId);

    final following = await _supabase
        .from('subscriptions')
        .select('followed_id')
        .eq('follower_id', currentUserId);

    final followedIds = following.map((sub) => sub['followed_id']).toSet();

    final suggested = allUsers.where((user) => !followedIds.contains(user['id'])).toList();

    setState(() {
      _subscriptionStatus = {
        for (var user in allUsers) user['id']: followedIds.contains(user['id']),
      };
    });

    return suggested;
  }

  Future<List<dynamic>> _fetchFollowingUsers() async {
    final followingSubs = await _supabase
        .from('subscriptions')
        .select('followed_id')
        .eq('follower_id', currentUserId);

    final followedIds = followingSubs.map((sub) => sub['followed_id']).toList();

    if (followedIds.isEmpty) return [];

    final profiles = await _supabase
        .from('profiles')
        .select('id, username, avatar_url')
        .inFilter('id', followedIds);

    return profiles;
  }

  Future<List<dynamic>> _fetchFollowers() async {
    final followerSubs = await _supabase
        .from('subscriptions')
        .select('follower_id')
        .eq('followed_id', currentUserId);

    final followerIds = followerSubs.map((sub) => sub['follower_id']).toList();

    if (followerIds.isEmpty) return [];

    final profiles = await _supabase
        .from('profiles')
        .select('id, username, avatar_url')
        .inFilter('id', followerIds);

    return profiles;
  }

  Future<void> _toggleSubscription(String friendId) async {
    final isFollowing = _subscriptionStatus[friendId] ?? false;

    try {
      if (isFollowing) {
        await _supabase
            .from('subscriptions')
            .delete()
            .match({'follower_id': currentUserId, 'followed_id': friendId});
      } else {
        await _supabase.from('subscriptions').insert({
          'follower_id': currentUserId,
          'followed_id': friendId,
        });
      }
      setState(() {
        _suggestedFuture = _fetchSuggestedUsers();
        _followingFuture = _fetchFollowingUsers();
        _subscriptionStatus[friendId] = !isFollowing;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Widget _buildUserTile(dynamic user) {
    final isFollowing = _subscriptionStatus[user['id']] ?? false;

    return ListTile(
      leading: user['avatar_url'] != null
          ? CircleAvatar(backgroundImage: NetworkImage(user['avatar_url']))
          : const CircleAvatar(child: Icon(Icons.person)),
      title: Text(user['username'] ?? 'User'),
      trailing: ElevatedButton(
        onPressed: () => _toggleSubscription(user['id']),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing ? Colors.grey[400] : agriNextGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(isFollowing ? "Following" : "Follow"),
      ),
    );
  }

  Widget _buildUserList(Future<List<dynamic>> future) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(child: Text("No users found."));
        }
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) => _buildUserTile(users[index]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Add Friend / Follow"),
          backgroundColor: agriNextGreen,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Suggested'),
              Tab(text: 'Following'),
              Tab(text: 'Followers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList(_suggestedFuture),
            _buildUserList(_followingFuture),
            _buildUserList(_followersFuture),
          ],
        ),
      ),
    );
  }
}

