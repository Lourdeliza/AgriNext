import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_farm_page.dart';
import 'farm_details_page.dart';
import 'admin_approval_page.dart'; // Import your AdminApprovalPage here
import 'my_farm_page.dart';

class FarmFinderPage extends StatefulWidget {
  const FarmFinderPage({super.key});

  @override
  State<FarmFinderPage> createState() => _FarmFinderPageState();
}

class _FarmFinderPageState extends State<FarmFinderPage> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _farms = [];
  List<dynamic> _filteredFarms = [];
  final TextEditingController _searchController = TextEditingController();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _getUserRole();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _getUserRole() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', _supabase.auth.currentUser!.id)
          .single();

      setState(() {
        _userRole = response['role'];
      });

      _loadFarms(); // Load farms after getting role
    } catch (e) {
      debugPrint('Error fetching role: $e');
    }
  }

  Future<void> _loadFarms() async {
    try {
      final response = await _supabase
          .from('farms')
          .select()
          .eq('status', 'approved')
          .order('created_at', ascending: false);
      setState(() {
        _farms = response;
        _filteredFarms = response;
      });
    } catch (e) {
      debugPrint('Error loading farms: $e');
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFarms = _farms.where((farm) {
        final name = (farm['name'] ?? '').toLowerCase();
        final location = (farm['location'] ?? '').toLowerCase();
        return name.contains(query) || location.contains(query);
      }).toList();
    });
  }

  String getPublicImageUrl(String filename) {
    const bucketName = 'farm-images';
    return _supabase.storage.from(bucketName).getPublicUrl(filename);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Finder'),
        backgroundColor: Colors.green,
        actions: [
          if (_userRole != null)
  IconButton(
    icon: const Icon(Icons.agriculture),
    tooltip: 'My Farms',
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyFarmPage()),
      );
    },
  ),

          if (_userRole != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddFarmPage(
                      onFarmAdded: _loadFarms,
                      userRole: _userRole!, // Pass role to AddFarmPage
                    ),
                  ),
                );
              },
            ),
          if (_userRole == 'admin') // 👈 Approve Farms button (admin only)
            IconButton(
              icon: const Icon(Icons.verified, color: Colors.white),
              tooltip: 'Approve Farms',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminApprovalPage()),
                );
                _loadFarms();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search farms by name or location...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: _filteredFarms.isEmpty
                ? const Center(child: Text('No farms found.'))
                : RefreshIndicator(
                    onRefresh: _loadFarms,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: _filteredFarms.length,
                      itemBuilder: (context, index) {
                        final farm = _filteredFarms[index];
                        final imageUrl = (farm['image_url'] != null && farm['image_url'] != '')
                            ? getPublicImageUrl(farm['image_url'])
                            : null;

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 3,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FarmDetailsPage(farm: farm, imageUrl: imageUrl),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
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
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          farm['location'] ?? '',
                                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                                        ),
                                        const SizedBox(height: 6),
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
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}



