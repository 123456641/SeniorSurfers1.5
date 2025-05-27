// lib/tutorial/pdf_viewer_page.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class PDFViewerPage extends StatefulWidget {
  final String title;
  final String fileUrl;
  final bool requiresAuth;

  const PDFViewerPage({
    Key? key,
    required this.title,
    required this.fileUrl,
    this.requiresAuth = true,
  }) : super(key: key);

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  late Future<Uint8List> _pdfFuture;
  final _supabase = Supabase.instance.client;
  final PdfViewerController _pdfController = PdfViewerController();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pdfFuture = _loadPdf();
  }

  Future<Uint8List> _loadPdf() async {
    try {
      final session = _supabase.auth.currentSession;
      Map<String, String> headers = {};

      if (widget.requiresAuth && session != null) {
        headers['Authorization'] = 'Bearer ${session.accessToken}';
      }

      final response = await http
          .get(Uri.parse(widget.fileUrl), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      setState(() => _error = e.toString());
      throw e;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildViewer(Uint8List data) {
    return SfPdfViewer.memory(
      data,
      controller: _pdfController,
      enableDoubleTapZooming: true,
      canShowScrollHead: true,
      scrollDirection:
          PdfScrollDirection.vertical, // Changed from Axis.vertical
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load PDF',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => launchUrl(Uri.parse(widget.fileUrl)),
            child: const Text('Open in Browser'),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  () => launchUrl(
                    Uri.parse(
                      'https://docs.google.com/viewer?url=${Uri.encodeComponent(widget.fileUrl)}',
                    ),
                  ),
              child: const Text('View with Google Viewer'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _pdfController.zoomLevel += 0.2,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => _pdfController.zoomLevel -= 0.2,
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfFuture,
        builder: (context, snapshot) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || _error != null) {
            return _buildError();
          }
          if (snapshot.hasData) {
            return _buildViewer(snapshot.data!);
          }
          return const Center(child: Text('No PDF data available'));
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'prev',
            mini: true,
            onPressed: () => _pdfController.previousPage(),
            child: const Icon(Icons.chevron_left),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'next',
            onPressed: () => _pdfController.nextPage(),
            child: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
