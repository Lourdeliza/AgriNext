import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class JobBoardPage extends StatefulWidget {
  const JobBoardPage({super.key});

  @override
  State<JobBoardPage> createState() => _JobBoardPageState();
}

class _JobBoardPageState extends State<JobBoardPage> {
  final _client = Supabase.instance.client;
  List<dynamic> _jobs = [];
  List<dynamic> _filteredJobs = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  static const Color primaryColor = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _jobs = [];
      _filteredJobs = [];
    });

    try {
      final res = await _client
          .from('jobs')
          .select('*, farms (id, name, location, contact)')
          .order('created_at', ascending: false);

      setState(() {
        _jobs = res;
        _filteredJobs = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading jobs: $e')),
      );
    }
  }

  void _onSearchChanged() {
  final query = _searchController.text.toLowerCase();
  setState(() {
    _filteredJobs = _jobs.where((job) {
      final title = (job['title'] ?? '').toString().toLowerCase();
      final location = (job['farms']?['location'] ?? '').toString().toLowerCase();
      return title.contains(query) || location.contains(query);
    }).toList();
  });
}

  void _launchPhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone call.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Job Board"), backgroundColor: primaryColor),
      body: RefreshIndicator(
        onRefresh: _loadJobs,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search jobs by title or location ...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredJobs.isEmpty
                      ? const Center(child: Text("No job listings found."))
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemCount: _filteredJobs.length,
                          itemBuilder: (context, index) {
                            final job = _filteredJobs[index];
                            final farm = job['farms'];
                            final String farmName = farm?['name'] ?? 'Unknown Farm';
                            final String farmLocation = farm?['location'] ?? 'No location provided';
                            final String? contact = farm?['contact'];

                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(job['title'] ?? 'Untitled Job',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(
                                      farmName,
                                      style: const TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                    ),
                                    Text(
                                      farmLocation,
                                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      job['description'] ?? 'No description available.',
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    if (job['salary'] != null)
                                      Text(
                                        "₱ ${job['salary'].toStringAsFixed(2)} / month",
                                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (contact != null && contact.isNotEmpty)
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.call, size: 18),
                                            label: const Text("Call"),
                                            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                                            onPressed: () => _launchPhoneCall(contact),
                                          ),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () => _showJobDetails(job, farm),
                                          child: const Text("View Details"),
                                        ),
                                      ],
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
      ),
    );
  }

  void _showJobDetails(dynamic job, dynamic farm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(job['title'] ?? 'Job Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Farm: ${farm?['name'] ?? 'Unknown Farm'}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (farm?['location'] != null) Text(farm['location']),
            const SizedBox(height: 8),
            Text(job['description'] ?? 'No description provided.'),
            if (job['salary'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Salary: ₱ ${job['salary'].toStringAsFixed(2)} / month",
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                ),
              ),
            if (farm?['contact'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text("Contact: ${farm['contact']}"),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }
}

