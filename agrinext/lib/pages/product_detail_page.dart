import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailPage extends StatelessWidget {
  final String name;
  final String price;
  final String location;
  final String imageUrl;
  final String phone;

  const ProductDetailPage({
    super.key,
    required this.name,
    required this.price,
    required this.location,
    required this.imageUrl,
    required this.phone,
  });

  Future<void> _callSeller(BuildContext context) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800; // Threshold for web/tablet wide layout
    final maxContentWidth = 700.0; // Max content width on wide screens

    return Scaffold(
      appBar: AppBar(
        title: Text(name, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.green,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _callSeller(context),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.phone),
        label: const Text("Call Seller"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.grey[200],
                    child: Image.network(
                      imageUrl.isNotEmpty
                          ? imageUrl
                          : 'https://via.placeholder.com/600x400.png?text=No+Image',
                      fit: BoxFit.contain, // Keeps the original proportion; no cropping
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  name,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.attach_money, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      price,
                      style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Text(
                      phone,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 100), // Spacing for FAB
              ],
            ),
          ),
        ),
      ),
    );
  }
}
