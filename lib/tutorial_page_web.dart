import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:provider/provider.dart';
import 'providers/font_size_provider.dart';
import 'dashboardsidebar.dart';
import 'interactivegames/gmeet.dart';

class TutorialPageWeb extends StatefulWidget {
  const TutorialPageWeb({Key? key}) : super(key: key);

  @override
  State<TutorialPageWeb> createState() => _TutorialPageWebState();
}

class _TutorialPageWebState extends State<TutorialPageWeb> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tutorials = [];
  bool isLoading = true;
  String? selectedPlatform;
  Map<String, dynamic>? selectedTutorial;

  // PDF viewing states for web
  bool isPdfViewVisible = false;
  String? currentPdfUrl;
  String? currentPdfTitle;
  bool isPdfLoading = false;
  String? _iframeViewerId;

  // Map platform names to their image paths
  final Map<String, String> platformImages = {
    'google_meet': 'assets/images/practice/gmeet.png',
    'zoom': 'assets/images/practice/zoom.png',
    'gmail': 'assets/images/practice/gmail.png',
    'viber': 'assets/images/practice/viber.png',
    'whatsapp': 'assets/images/practice/whatsapp.png',
    'cliqq': 'assets/images/practice/cliqq.png',
  };

  // Map platform keys to display names
  final Map<String, String> platformDisplayNames = {
    'google_meet': 'Google Meet',
    'zoom': 'Zoom',
    'gmail': 'Gmail',
    'viber': 'Viber',
    'whatsapp': 'WhatsApp',
    'cliqq': 'CliQQ',
  };

  @override
  void initState() {
    super.initState();
    fetchTutorials();
  }

  @override
  void dispose() {
    if (_iframeViewerId != null) {
      final element = web.document.getElementById(_iframeViewerId!);
      if (element != null) {
        element.remove();
      }
    }
    super.dispose();
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

  // Web-specific PDF handling using modern APIs
  Future<void> _handlePdfFile(String url, String title) async {
    setState(() {
      isPdfLoading = true;
      isPdfViewVisible = true;
      currentPdfTitle = title;
      currentPdfUrl = url;
    });

    _displayPdfInWebView(url);
    setState(() {
      isPdfLoading = false;
    });
  }

  void _displayPdfInWebView(String url) {
    if (_iframeViewerId != null) {
      final oldElement = web.document.getElementById(_iframeViewerId!);
      if (oldElement != null) {
        oldElement.remove();
      }
    }

    _iframeViewerId = 'pdf-iframe-${DateTime.now().millisecondsSinceEpoch}';

    // Register the view factory using the modern API
    ui_web.platformViewRegistry.registerViewFactory(_iframeViewerId!, (
      int viewId,
    ) {
      final iframe =
          web.HTMLIFrameElement()
            ..style.border = 'none'
            ..style.height = '100%'
            ..style.width = '100%'
            ..src = url;

      return iframe;
    });

    setState(() {
      isPdfLoading = false;
    });
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              isPdfViewVisible = false;
              if (_iframeViewerId != null) {
                final element = web.document.getElementById(_iframeViewerId!);
                if (element != null) {
                  element.remove();
                }
                _iframeViewerId = null;
              }
            });
          },
        ),
        title: Text(
          currentPdfTitle ?? 'PDF Viewer',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading PDF...'),
                  ],
                ),
              )
              : _iframeViewerId != null
              ? HtmlElementView(viewType: _iframeViewerId!)
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

  @override
  Widget build(BuildContext context) {
    return SidebarLayoutWrapper(
      currentPage: '/tutorials',
      pageTitle: 'Tutorials',
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Consumer<FontSizeProvider>(
            builder:
                (context, fontSizeProvider, _) => Text(
                  'Tutorials',
                  style: TextStyle(
                    fontSize: fontSizeProvider.fontSize * 2,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF27445D),
                  ),
                ),
          ),
        ),
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar
              Container(
                width: 320,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: _buildSidebarContent(),
              ),
              // Main content
              Expanded(child: _buildMainContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Platform',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF27445D),
            ),
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('ALL'),
                selected: selectedPlatform == null,
                onSelected: (selected) {
                  setState(() {
                    selectedPlatform = null;
                  });
                  fetchTutorials();
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: const Color(0xFF27445D),
                labelStyle: TextStyle(
                  color: selectedPlatform == null ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              ...platformImages.keys.map((platform) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      platformDisplayNames[platform] ?? platform.toUpperCase(),
                    ),
                    selected: selectedPlatform == platform,
                    onSelected: (selected) {
                      setState(() {
                        selectedPlatform = selected ? platform : null;
                      });
                      fetchTutorials();
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: const Color(0xFF27445D),
                    labelStyle: TextStyle(
                      color:
                          selectedPlatform == platform
                              ? Colors.white
                              : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : tutorials.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            selectedPlatform != null
                                ? 'No tutorials found for ${platformDisplayNames[selectedPlatform] ?? selectedPlatform}'
                                : 'No tutorials available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: tutorials.length,
                    itemBuilder: (context, index) {
                      final tutorial = tutorials[index];
                      final isSelected =
                          selectedTutorial?['id'] == tutorial['id'];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tileColor:
                            isSelected
                                ? const Color(0xFF27445D).withOpacity(0.1)
                                : null,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildThumbnailImage(tutorial, size: 50),
                        ),
                        title: Text(
                          tutorial['title'] ??
                              tutorial['file_name'] ??
                              'Untitled',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          platformDisplayNames[tutorial['platform']] ??
                              tutorial['platform'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: const Color(
                          0xFF27445D,
                        ).withOpacity(0.1),
                        onTap: () => _openTutorial(tutorial),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    if (selectedTutorial == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a tutorial to get started',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose from the tutorials on the left to begin learning',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildThumbnailImage(selectedTutorial!, size: 80),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedTutorial!['title'] ??
                          selectedTutorial!['file_name'] ??
                          'Untitled',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF27445D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Platform: ${platformDisplayNames[selectedTutorial!['platform']] ?? selectedTutorial!['platform']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (selectedTutorial!['description'] != null &&
                        selectedTutorial!['description'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        selectedTutorial!['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _openTutorial(selectedTutorial!),
              icon: const Icon(Icons.play_arrow),
              label: Text(
                selectedTutorial!['file_type'] == 'pdf'
                    ? 'View Tutorial'
                    : 'Open Tutorial',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27445D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
