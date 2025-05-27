import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PlatformTutorialsPage extends StatefulWidget {
  final String platform;
  final String label;

  const PlatformTutorialsPage({
    super.key,
    required this.platform,
    required this.label,
  });

  @override
  State<PlatformTutorialsPage> createState() => _PlatformTutorialsPageState();
}

class _PlatformTutorialsPageState extends State<PlatformTutorialsPage> {
  final _supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> tutorials = [];

  @override
  void initState() {
    super.initState();
    fetchTutorials();
  }

  Future<void> fetchTutorials() async {
    setState(() => isLoading = true);
    try {
      final response = await _supabase
          .from('tutorial_files')
          .select()
          .eq('platform', widget.platform)
          .order('uploaded_at', ascending: false);
      setState(() {
        tutorials = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _openTutorial(Map<String, dynamic> tutorial) async {
    final url = tutorial['file_url'];
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open: $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.label)),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : tutorials.isEmpty
              ? const Center(child: Text('No tutorials found.'))
              : ListView.builder(
                itemCount: tutorials.length,
                itemBuilder: (context, index) {
                  final tutorial = tutorials[index];
                  final title =
                      tutorial['title'] ?? tutorial['file_name'] ?? 'Untitled';

                  return ListTile(
                    title: Text(title),
                    subtitle: Text(tutorial['description'] ?? ''),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openTutorial(tutorial),
                  );
                },
              ),
    );
  }
}
