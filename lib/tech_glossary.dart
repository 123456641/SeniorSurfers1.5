// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'providers/font_size_provider.dart';
import 'dashboardsidebar.dart';

class TechGlossaryPage extends StatefulWidget {
  const TechGlossaryPage({super.key});

  @override
  State<TechGlossaryPage> createState() => _TechGlossaryPageState();
}

class _TechGlossaryPageState extends State<TechGlossaryPage> {
  final FlutterTts _tts = FlutterTts();
  String? _activeLetterFilter;
  bool _isPlaying = false;
  String? _playingTerm;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      setState(() {
        _isPlaying = false;
        _playingTerm = null;
      });
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speakDefinition(String term, String definition) async {
    if (_isPlaying) {
      await _tts.stop();

      // If we're stopping the currently playing term, reset the state
      if (_playingTerm == term) {
        setState(() {
          _isPlaying = false;
          _playingTerm = null;
        });
        return;
      }
    }

    setState(() {
      _isPlaying = true;
      _playingTerm = term;
    });

    await _tts.speak(definition);
  }

  @override
  Widget build(BuildContext context) {
    return SidebarLayoutWrapper(
      currentPage: '/techglossary',
      pageTitle: 'Tech Glossary',
      child: _buildGlossaryList(),
    );
  }

  Widget _buildGlossaryList() {
    // Group glossary items by first letter for more efficient rendering
    Map<String, List<Map<String, String>>> groupedGlossary = {};

    for (var entry in glossaryData) {
      final letter = entry['term']![0].toUpperCase();
      if (!groupedGlossary.containsKey(letter)) {
        groupedGlossary[letter] = [];
      }
      groupedGlossary[letter]!.add(entry);
    }

    // Get sorted letters for the alphabet sidebar
    final List<String> availableLetters = groupedGlossary.keys.toList()..sort();

    return Row(
      children: [
        _buildAlphabetSidebar(availableLetters),
        Expanded(
          child:
              _activeLetterFilter != null
                  ? _buildFilteredList(groupedGlossary)
                  : _buildFullGlossaryList(groupedGlossary, availableLetters),
        ),
      ],
    );
  }

  Widget _buildAlphabetSidebar(List<String> availableLetters) {
    return Container(
      width: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: ListView.builder(
        itemCount: 26,
        itemBuilder: (context, index) {
          String letter = String.fromCharCode(65 + index);
          bool isAvailable = availableLetters.contains(letter);
          bool isActive = letter == _activeLetterFilter;

          return InkWell(
            onTap:
                isAvailable
                    ? () => setState(() {
                      _activeLetterFilter = isActive ? null : letter;
                    })
                    : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color:
                    isActive
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: TextStyle(
                  fontWeight: isAvailable ? FontWeight.bold : FontWeight.normal,
                  color:
                      isAvailable
                          ? (isActive
                              ? Theme.of(context).colorScheme.primary
                              : null)
                          : Colors.grey[400],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilteredList(
    Map<String, List<Map<String, String>>> groupedGlossary,
  ) {
    if (_activeLetterFilter == null ||
        !groupedGlossary.containsKey(_activeLetterFilter)) {
      return const Center(child: Text('No terms found'));
    }

    final terms = groupedGlossary[_activeLetterFilter]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _activeLetterFilter!,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: terms.length,
            itemBuilder: (context, index) {
              final term = terms[index]['term']!;
              final definition = terms[index]['definition']!;
              final isPlaying = _isPlaying && _playingTerm == term;

              return _buildGlossaryCard(term, definition, isPlaying);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFullGlossaryList(
    Map<String, List<Map<String, String>>> groupedGlossary,
    List<String> sortedLetters,
  ) {
    return ListView.builder(
      itemCount: sortedLetters.length,
      itemBuilder: (context, letterIndex) {
        final letter = sortedLetters[letterIndex];
        final terms = groupedGlossary[letter]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ...terms.map((entry) {
              final term = entry['term']!;
              final definition = entry['definition']!;
              final isPlaying = _isPlaying && _playingTerm == term;

              return _buildGlossaryCard(term, definition, isPlaying);
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildGlossaryCard(String term, String definition, bool isPlaying) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    term,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.stop : Icons.volume_up,
                    color:
                        isPlaying
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[600],
                  ),
                  onPressed: () => _speakDefinition(term, definition),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(definition, style: TextStyle(color: Colors.grey[800])),
          ],
        ),
      ),
    );
  }
}

// Data moved outside of the widget to avoid rebuilding it on every state change
final List<Map<String, String>> glossaryData = [
  {
    'term': 'App (Application)',
    'definition':
        'A program on your phone or tablet that helps you do specific tasks, like sending messages or watching videos.',
  },
  {
    'term': 'Browser',
    'definition':
        'Software used to access websites on the internet, like Chrome, Safari, or Firefox.',
  },
  {
    'term': 'Click / Tap',
    'definition':
        'Click – Pressing a button on a computer mouse. Tap – Touching the screen with your finger on a phone or tablet.',
  },
  {
    'term': 'Computer',
    'definition':
        'A machine used to browse the internet, type documents, watch videos, and more.',
  },
  {
    'term': 'Delete',
    'definition': 'To remove something from your device or app.',
  },
  {
    'term': 'Email',
    'definition':
        'A way to send and receive digital letters over the internet.',
  },
  {
    'term': 'File',
    'definition':
        'A digital document, picture, or other data stored on a computer or mobile device.',
  },
  {
    'term': 'GPS (Global Positioning System)',
    'definition':
        'Technology that uses satellites to find your exact location on Earth, used in maps and navigation apps.',
  },
  {
    'term': 'Help Button',
    'definition':
        'A button you press when you need help or want to ask a question in the app.',
  },
  {
    'term': 'Internet',
    'definition':
        'A network that connects computers and phones to websites and apps all over the world.',
  },
  {
    'term': 'JPEG',
    'definition':
        'A common file format used for photos and images that compresses the file to make it smaller.',
  },
  {
    'term': 'Keyboard',
    'definition':
        'The set of buttons you use to type on a computer or the digital version that appears on your phone screen.',
  },
  {
    'term': 'Link',
    'definition':
        'Text or an image you can click or tap that takes you to another webpage or section.',
  },
  {
    'term': 'Menu',
    'definition':
        'A list of options or commands you can select in an app or website.',
  },
  {
    'term': 'Network',
    'definition':
        'A system that connects computers and devices together, like WiFi or cellular data.',
  },
  {
    'term': 'Online',
    'definition':
        'Being connected to the internet and able to access websites and services.',
  },
  {
    'term': 'Password',
    'definition':
        'A secret word or phrase that keeps your accounts safe. Only you should know it!',
  },
  {
    'term': 'QR Code',
    'definition':
        'A square-shaped barcode that can be scanned with your phone camera to open a website or app.',
  },
  {
    'term': 'Router',
    'definition':
        'A device that allows multiple computers and phones to connect to the internet at the same time.',
  },
  {
    'term': 'Save',
    'definition':
        'To keep your work or information so you can look at it again later.',
  },
  {
    'term': 'Search',
    'definition':
        'To look for something on your phone, computer, or the internet.',
  },
  {
    'term': 'Settings',
    'definition':
        'A place in your phone, computer, or app where you can change how things work.',
  },
  {
    'term': 'Smartphone',
    'definition':
        'A phone that can connect to the internet and run apps, take pictures, and do many things a computer can do.',
  },
  {
    'term': 'Tech Support',
    'definition':
        'People who help you fix problems with your computer, phone, or apps.',
  },
  {
    'term': 'Upload',
    'definition':
        'To send files, photos, or videos from your device to the internet or another service.',
  },
  {
    'term': 'Video Call',
    'definition':
        'A call where you can see and talk to someone using your camera and internet.',
  },
  {
    'term': 'WiFi',
    'definition':
        'A wireless way to connect your devices to the internet without using cables.',
  },
  {
    'term': 'XML',
    'definition':
        'A formatting language used to structure data on websites and in apps.',
  },
  {
    'term': 'YouTube',
    'definition':
        'A website and app where you can watch, create, and share videos.',
  },
  {
    'term': 'Zoom',
    'definition':
        'A video calling app used for meetings, classes, and talking with friends and family online.',
  },
];
