import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_product_page.dart';

class MyMarketPage extends StatefulWidget {
  const MyMarketPage({super.key});

  @override
  State<MyMarketPage> createState() => _MyMarketPageState();
}

class _MyMarketPageState extends State<MyMarketPage> {
  final _supabase = Supabase.instance.client;
  late final String currentUserId;
  late Future<List<dynamic>> _productsFuture;
  final Color agriNextGreen = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    currentUserId = _supabase.auth.currentUser?.id ?? '';
    _refreshProducts();
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = _fetchMyProducts();
    });
  }

  Future<List<dynamic>> _fetchMyProducts() async {
    return await _supabase
        .from('products')
        .select()
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false);
  }

  String getPublicImageUrl(String filename) {
    const bucketName = 'product_images';
    return _supabase.storage.from(bucketName).getPublicUrl(filename);
  }

  void _showProductForm({Map<String, dynamic>? product}) {
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final priceController = TextEditingController(text: product?['price']?.toString() ?? '');
    final locationController = TextEditingController(text: product?['location'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(product == null ? "Add Product" : "Edit Product"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Product Name")),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: "Location")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: agriNextGreen),
            onPressed: () async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? 0;
              final location = locationController.text.trim();

              if (name.isEmpty || location.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields required.')));
                return;
              }

              if (product == null) {
                await _supabase.from('products').insert({
                  'user_id': currentUserId,
                  'name': name,
                  'price': price,
                  'location': location,
                  'image_url': '',
                });
              } else {
                await _supabase.from('products').update({
                  'name': name,
                  'price': price,
                  'location': location,
                }).eq('id', product['id']);
              }

              Navigator.pop(context);
              _refreshProducts();
            },
            child: Text(product == null ? "Add" : "Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(String productId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Delete Product'),
      content: const Text('Are you sure you want to delete this product?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await _deleteProduct(productId);
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

Future<void> _deleteProduct(String productId) async {
  try {
    await _supabase.from('products').delete().eq('id', productId);
    _refreshProducts();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted.')));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Market"),
        backgroundColor: agriNextGreen,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.add),
        //     onPressed: () => _showProductForm(),
        //   ),
        // ],
      ),
      floatingActionButton: FloatingActionButton(
  onPressed: () async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductPage(
          onProductAdded: _refreshProducts, // ✅ FIXED
        ),
      ),
    );
  },
  backgroundColor: Colors.green,
  child: const Icon(Icons.add),
),


      body: FutureBuilder<List<dynamic>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text("No products found."));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 2;
              if (constraints.maxWidth >= 900) {
                crossAxisCount = 4; // 4 columns on wide screens (tablet/web)
              }

              return Padding(
  padding: const EdgeInsets.all(8),
  child: GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.6,
    ),
    itemCount: products.length,
    itemBuilder: (context, index) {
      final product = products[index]; // ✅ Define product here
      return ProductCard(
        product: product,
        getPublicImageUrl: getPublicImageUrl,
        onEdit: () => _showProductForm(product: product),
        onDelete: () => _confirmDeleteProduct(product['id']), // ✅ Now works
      );
    },
  ),
);

            },
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final dynamic product;
  final String Function(String filename) getPublicImageUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.getPublicImageUrl,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = getPublicImageUrl(product['image_url'] ?? '');

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain, // preserves aspect ratio, doesn't crop/stretch
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
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
                  product['name'] ?? 'Product',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₱${product['price'] ?? ''}',
                  style: const TextStyle(fontSize: 14, color: Colors.green),
                ),
                Text(
                  product['location'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: onEdit),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
