import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'providers/font_size_provider.dart';
import 'dashboardsidebar.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPage();
}

class _TutorialPage extends State<TutorialPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tutorials = [];
  bool isLoading = true;
  String? selectedPlatform;
  Map<String, dynamic>? selectedTutorial;

  // PDF viewing states for mobile
  bool isPdfViewVisible = false;
  String? currentPdfUrl;
  String? currentPdfTitle;
  bool isPdfLoading = false;
  String? pdfFilePath;

  // Map platform names to their image paths
  final Map<String, String> platformImages = {
    'google_meet': 'assets/images/practice/gmeet.png',
    'zoom': 'assets/images/practice/zoom.png',
    'gmail': 'assets/images/practice/gmail.png',
    'viber': 'assets/images/practice/viber.png',
    'whatsapp': 'assets/images/practice/whatsapp.png',
    'cliqq': 'assets/images/practice/cliqq.png',
  };

  @override
  void initState() {
    super.initState();
    fetchTutorials();
  }

  Future<void> fetchTutorials() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await _supabase
          .from('tutorial_files')
          .select()
          .order('uploaded_at', ascending: false);

      List<Map<String, dynamic>> filteredTutorials = [];
      if (selectedPlatform != null) {
        for (var tutorial in response as List) {
          if (tutorial['platform'] == selectedPlatform) {
            filteredTutorials.add(tutorial);
          }
        }
      } else {
        filteredTutorials = List<Map<String, dynamic>>.from(response);
      }

      setState(() {
        tutorials = filteredTutorials;
        isLoading = false;

        if (selectedTutorial != null) {
          bool tutorialExists = false;
          for (var tutorial in filteredTutorials) {
            if (tutorial['id'] == selectedTutorial!['id']) {
              tutorialExists = true;
              break;
            }
          }
          if (!tutorialExists) {
            selectedTutorial = null;
          }
        }
      });
    } catch (e) {
      print('Error fetching tutorials: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading tutorials: $e')));
      }
    }
  }

  // Mobile-specific PDF handling
  Future<void> _handlePdfFile(String url, String title) async {
    setState(() {
      isPdfLoading = true;
      isPdfViewVisible = true;
      currentPdfTitle = title;
      currentPdfUrl = url;
      pdfFilePath = null;
    });

    await _downloadAndOpenPdfMobile(url);
  }

  Future<void> _downloadAndOpenPdfMobile(String url) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          pdfFilePath = filePath;
          isPdfLoading = false;
        });
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading PDF: $e');
      setState(() {
        isPdfLoading = false;
        isPdfViewVisible = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load PDF: $e. Opening in external app.'),
            duration: const Duration(seconds: 4),
          ),
        );
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _openTutorial(Map<String, dynamic> tutorial) async {
    setState(() {
      selectedTutorial = tutorial;
    });

    final fileType = tutorial['file_type'];
    final fileUrl = tutorial['file_url'];
    final title = tutorial['title'] ?? tutorial['file_name'] ?? 'Untitled';

    if (fileType == 'link') {
      if (!await launchUrl(
        Uri.parse(fileUrl),
        mode: LaunchMode.externalApplication,
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $fileUrl')),
          );
        }
      }
    } else if (fileType == 'pdf') {
      try {
        final response = await http
            .head(Uri.parse(fileUrl))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _handlePdfFile(fileUrl, title);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'PDF URL returned error ${response.statusCode}. Opening in external app.',
                ),
                duration: const Duration(seconds: 4),
              ),
            );
            launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Issue checking PDF URL: $e. Attempting to open anyway.',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          _handlePdfFile(fileUrl, title);
        }
      }
    } else {
      if (!await launchUrl(
        Uri.parse(fileUrl),
        mode: LaunchMode.externalApplication,
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open file: $fileUrl')),
          );
        }
      }
    }
  }

  Widget _buildPdfViewer() {
    // For PDF viewing, we need to override the wrapper and create our own Scaffold
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF27445D),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              isPdfViewVisible = false;
              pdfFilePath = null;
            });
          },
        ),
        title: Consumer<FontSizeProvider>(
          builder:
              (context, fontSizeProvider, _) => Text(
                currentPdfTitle ?? 'PDF Viewer',
                style: TextStyle(
                  fontSize: fontSizeProvider.fontSize,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () {
              if (currentPdfUrl != null) {
                launchUrl(
                  Uri.parse(currentPdfUrl!),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            tooltip: 'Open in external app',
          ),
        ],
      ),
      body:
          isPdfLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Consumer<FontSizeProvider>(
                      builder:
                          (context, fontSizeProvider, _) => Text(
                            'Loading PDF...',
                            style: TextStyle(
                              fontSize: fontSizeProvider.fontSize,
                            ),
                          ),
                    ),
                  ],
                ),
              )
              : pdfFilePath != null
              ? PDFView(
                filePath: pdfFilePath!,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: true,
                pageFling: true,
                pageSnap: true,
                fitPolicy: FitPolicy.BOTH,
                onError: (error) {
                  print('Error loading PDF: $error');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error loading PDF: $error')),
                  );
                },
                onPageError: (page, error) {
                  print('Error loading page $page: $error');
                },
              )
              : const Center(child: Text('Failed to load PDF')),
    );
  }

  Widget _buildThumbnailImage(
    Map<String, dynamic> tutorial, {
    double size = 64,
  }) {
    final platform = tutorial['platform'] as String;
    final fallbackImagePath =
        platformImages[platform] ?? 'assets/images/practice/document.png';
    final thumbnailUrl = tutorial['thumbnail_url'];

    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder:
            (context, url) => Center(
              child: SizedBox(
                width: size / 2,
                height: size / 2,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        errorWidget:
            (context, url, error) => Image.asset(
              fallbackImagePath,
              fit: BoxFit.contain,
              width: size,
              height: size,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.description,
                  size: size * 0.75,
                  color: Colors.grey.shade400,
                );
              },
            ),
      );
    } else {
      return Image.asset(
        fallbackImagePath,
        fit: BoxFit.contain,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.description,
            size: size * 0.75,
            color: Colors.grey.shade400,
          );
        },
      );
    }
  }

  Widget _buildPlatformFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Consumer<FontSizeProvider>(
              builder:
                  (context, fontSizeProvider, _) => FilterChip(
                    label: Text(
                      'ALL',
                      style: TextStyle(
                        fontSize: fontSizeProvider.fontSize * 0.8,
                      ),
                    ),
                    selected: selectedPlatform == null,
                    onSelected: (selected) {
                      setState(() {
                        selectedPlatform = selected ? null : selectedPlatform;
                      });
                      fetchTutorials();
                    },
                    selectedColor: const Color(0xFF27445D).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF27445D),
                  ),
            ),
          ),
          ...platformImages.keys.map(
            (platform) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Consumer<FontSizeProvider>(
                builder:
                    (context, fontSizeProvider, _) => FilterChip(
                      label: Text(
                        platform.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: fontSizeProvider.fontSize * 0.8,
                        ),
                      ),
                      selected: selectedPlatform == platform,
                      onSelected: (selected) {
                        setState(() {
                          selectedPlatform = selected ? platform : null;
                        });
                        fetchTutorials();
                      },
                      selectedColor: _getPlatformColor(
                        platform,
                      ).withOpacity(0.2),
                      checkmarkColor: _getPlatformColor(platform),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialDetail(Map<String, dynamic> tutorial) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button for mobile
          if (MediaQuery.of(context).size.width < 600)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    selectedTutorial = null;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to List'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: const Color(0xFF27445D),
                ),
              ),
            ),

          // Tutorial image
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width:
                    MediaQuery.of(context).size.width *
                    (MediaQuery.of(context).size.width < 600 ? 0.8 : 0.4),
                height:
                    MediaQuery.of(context).size.width *
                    (MediaQuery.of(context).size.width < 600 ? 0.6 : 0.3),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: _buildThumbnailImage(
                  tutorial,
                  size: MediaQuery.of(context).size.width * 0.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Consumer<FontSizeProvider>(
            builder:
                (context, fontSizeProvider, _) => Text(
                  tutorial['title'] ?? tutorial['file_name'] ?? 'Untitled',
                  style: TextStyle(
                    fontSize: fontSizeProvider.fontSize * 1.4,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF27445D),
                  ),
                  textAlign: TextAlign.center,
                ),
          ),
          const SizedBox(height: 12),

          // Platform badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getPlatformColor(tutorial['platform']),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Consumer<FontSizeProvider>(
                builder:
                    (context, fontSizeProvider, _) => Text(
                      tutorial['platform']
                          .toString()
                          .replaceAll('_', ' ')
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: fontSizeProvider.fontSize * 0.9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Description
          if (tutorial['description'] != null &&
              tutorial['description'].toString().isNotEmpty)
            Consumer<FontSizeProvider>(
              builder:
                  (context, fontSizeProvider, _) => Text(
                    tutorial['description'].toString(),
                    style: TextStyle(
                      fontSize: fontSizeProvider.fontSize,
                      height: 1.5,
                      color: Colors.grey[700],
                    ),
                  ),
            ),
          const SizedBox(height: 32),

          // Action button
          SizedBox(
            width: double.infinity,
            child: Consumer<FontSizeProvider>(
              builder:
                  (context, fontSizeProvider, _) => ElevatedButton.icon(
                    icon: Icon(
                      tutorial['file_type'] == 'pdf'
                          ? Icons.picture_as_pdf
                          : Icons.open_in_new,
                      color: Colors.white,
                    ),
                    label: Text(
                      tutorial['file_type'] == 'pdf'
                          ? 'Open PDF'
                          : 'Open Tutorial',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSizeProvider.fontSize,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27445D),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      final fileType = tutorial['file_type'];
                      final fileUrl = tutorial['file_url'];
                      final title =
                          tutorial['title'] ??
                          tutorial['file_name'] ??
                          'Untitled';

                      if (fileType == 'pdf') {
                        _handlePdfFile(fileUrl, title);
                      } else {
                        launchUrl(
                          Uri.parse(fileUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialsList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tutorials.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Consumer<FontSizeProvider>(
                builder:
                    (context, fontSizeProvider, _) => Text(
                      'No tutorials available',
                      style: TextStyle(
                        fontSize: fontSizeProvider.fontSize * 1.2,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
              ),
              const SizedBox(height: 8),
              Consumer<FontSizeProvider>(
                builder:
                    (context, fontSizeProvider, _) => Text(
                      selectedPlatform != null
                          ? 'Try selecting a different platform or clear filters'
                          : 'Check back later for new content',
                      style: TextStyle(
                        fontSize: fontSizeProvider.fontSize * 0.9,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: tutorials.length,
      itemBuilder: (context, index) {
        final tutorial = tutorials[index];
        final bool isSelected =
            selectedTutorial != null &&
            tutorial['id'] == selectedTutorial!['id'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side:
                isSelected
                    ? const BorderSide(color: Color(0xFF27445D), width: 2)
                    : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildThumbnailImage(tutorial, size: 56),
            ),
            title: Consumer<FontSizeProvider>(
              builder:
                  (context, fontSizeProvider, _) => Text(
                    tutorial['title'] ?? tutorial['file_name'] ?? 'Untitled',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: fontSizeProvider.fontSize,
                    ),
                  ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPlatformColor(
                        tutorial['platform'],
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getPlatformColor(
                          tutorial['platform'],
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Consumer<FontSizeProvider>(
                      builder:
                          (context, fontSizeProvider, _) => Text(
                            tutorial['platform']
                                .toString()
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: fontSizeProvider.fontSize * 0.75,
                              color: _getPlatformColor(tutorial['platform']),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
            trailing: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF27445D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                tutorial['file_type'] == 'pdf'
                    ? Icons.picture_as_pdf
                    : Icons.open_in_new,
                color: const Color(0xFF27445D),
                size: 20,
              ),
            ),
            onTap: () => _openTutorial(tutorial),
          ),
        );
      },
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'google_meet':
        return Colors.green.shade700;
      case 'zoom':
        return Colors.blue.shade700;
      case 'gmail':
        return Colors.red.shade700;
      case 'viber':
        return Colors.purple.shade700;
      case 'whatsapp':
        return Colors.green.shade700;
      case 'cliqq':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If PDF is being viewed, show the PDF viewer directly (bypassing the wrapper)
    if (isPdfViewVisible) {
      return _buildPdfViewer();
    }

    // Otherwise, use the sidebar wrapper
    return SidebarLayoutWrapper(
      currentPage: '/tutorials',
      pageTitle: 'Tutorials',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Platform filters
        _buildPlatformFilters(),

        // Main content area
        Expanded(
          child:
              selectedTutorial == null
                  ? _buildTutorialsList()
                  : _buildTutorialDetail(selectedTutorial!),
        ),
      ],
    );
  }
}
