import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_product_page.dart';
import 'product_detail_page.dart';

final supabase = Supabase.instance.client;

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  String selectedCategory = 'All';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final categories = [
    'All',
    'Produce',
    'Tools & Equipment',
    'Seeds & Plants',
    'Fertilizers',
    'Pesticides',
    'Animal Feed & Supplies',
    'Machinery & Rentals',
  ];

  List<dynamic> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() => isLoading = true);
      final response = await supabase.from('products').select().order('created_at', ascending: false);
      setState(() {
        products = response;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching products: $e');
      setState(() => isLoading = false);
    }
  }

  String getPublicImageUrl(String filename) {
    if (filename.isEmpty) {
      return 'https://via.placeholder.com/300x300.png?text=No+Image';
    }
    return 'https://whoolrrnsvpynflzqoim.supabase.co/storage/v1/object/public/product_images/$filename';
  }

  List<dynamic> get filteredProducts {
    List<dynamic> filtered = selectedCategory == 'All'
        ? products
        : products.where((p) => p['category'] == selectedCategory).toList();

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        return name.contains(searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount = 2;
    if (screenWidth >= 900) {
      crossAxisCount = 4;
    } else if (screenWidth >= 600) {
      crossAxisCount = 3;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agri Marketplace'),
        backgroundColor: Colors.green,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddProductPage(onProductAdded: _fetchProducts),
            ),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Category Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: selectedCategory == cat,
                            onSelected: (_) => setState(() => selectedCategory = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                // Product Grid
                Expanded(
                  child: filteredProducts.isEmpty
                      ? const Center(child: Text('No products found.'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.6,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final p = filteredProducts[index];
                            final imageUrl = getPublicImageUrl(p['image_url'] ?? '');

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailPage(
                                      name: p['name'] ?? '',
                                      price: '₱ ${p['price'] ?? ''}',
                                      location: p['location'] ?? '',
                                      imageUrl: imageUrl,
                                      phone: p['contact'] ?? '',
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.broken_image, size: 50),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['name'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₱ ${p['price'] ?? ''}',
                                            style: const TextStyle(color: Colors.green, fontSize: 13),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  p['location'] ?? '',
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "📞 ${p['contact'] ?? ''}",
                                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}


