import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'farmdetails_addjob.dart';

class MyFarmPage extends StatefulWidget {
  const MyFarmPage({super.key});

  @override
  State<MyFarmPage> createState() => _MyFarmPageState();
}

class _MyFarmPageState extends State<MyFarmPage> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  List<dynamic> _approvedFarms = [];
  List<dynamic> _pendingFarms = [];
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _userId = _supabase.auth.currentUser?.id;
    _loadMyFarms();
  }

  Future<void> _loadMyFarms() async {
    if (_userId == null) return;

    try {
      final response = await _supabase
          .from('farms')
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false);

      setState(() {
        _approvedFarms = response.where((f) => f['status'] == 'approved').toList();
        _pendingFarms = response.where((f) => f['status'] == 'pending').toList();
      });
    } catch (e) {
      debugPrint('Error loading my farms: $e');
    }
  }

  String? getPublicImageUrl(String? filename) {
    if (filename == null || filename.isEmpty) return null;
    return _supabase.storage.from('farm-images').getPublicUrl(filename);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Farms'),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Approved'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFarmList(_approvedFarms),
          _buildFarmList(_pendingFarms),
        ],
      ),
    );
  }

  Widget _buildFarmList(List<dynamic> farms) {
    if (farms.isEmpty) {
      return const Center(child: Text('No farms found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadMyFarms,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: farms.length,
        itemBuilder: (context, index) {
          final farm = farms[index];
          final imageUrl = getPublicImageUrl(farm['image_url']);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FarmDetailsAddJobPage(farm: farm, imageUrl: imageUrl)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            farm['name'] ?? 'Unnamed Farm',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            farm['location'] ?? '',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            farm['description'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  farm['contact'] ?? 'No contact info',
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
