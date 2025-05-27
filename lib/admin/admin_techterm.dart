import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminTechTermsPage extends StatefulWidget {
  const AdminTechTermsPage({super.key});

  @override
  State<AdminTechTermsPage> createState() => _AdminTechTermsPageState();
}

class _AdminTechTermsPageState extends State<AdminTechTermsPage> {
  final TextEditingController termController = TextEditingController();
  final TextEditingController definitionController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  bool isLoading = false;
  bool isDeleting = false;
  bool isAdding = false;
  bool isEditing = false;
  String? errorMessage;
  String searchQuery = '';

  List<Map<String, dynamic>> allTerms = [];
  Map<String, dynamic>? editingTerm;
  String? confirmDeleteId;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadExistingTerms();
  }

  @override
  void dispose() {
    termController.dispose();
    definitionController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingTerms() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await Supabase.instance.client
          .from('tech_glossary')
          .select()
          .order('term');

      final terms = response.whereType<Map<String, dynamic>>().toList();

      print('Loaded ${terms.length} terms');

      setState(() {
        allTerms = terms;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading terms: $e');
      setState(() {
        errorMessage = 'Error loading terms: $e';
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredTerms {
    if (searchQuery.isEmpty) {
      return allTerms;
    }

    return allTerms.where((term) {
      return term['term'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          term['definition'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          );
    }).toList();
  }

  Future<void> _addTechTerm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isAdding = true;
      errorMessage = null;
    });

    try {
      final term = termController.text.trim();
      final definition = definitionController.text.trim();

      // Check for duplicate terms
      final duplicate =
          allTerms
              .where(
                (item) =>
                    item['term'].toString().toLowerCase() == term.toLowerCase(),
              )
              .toList();

      if (duplicate.isNotEmpty) {
        throw Exception('A term with this name already exists');
      }

      // Insert new term
      await Supabase.instance.client.from('tech_glossary').insert({
        'term': term,
        'definition': definition,
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tech term added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload terms and clear form
      await _loadExistingTerms();
      termController.clear();
      definitionController.clear();
    } catch (e) {
      setState(() {
        errorMessage = 'Error adding term: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        isAdding = false;
      });
    }
  }

  Future<void> _updateTechTerm() async {
    if (!_formKey.currentState!.validate() || editingTerm == null) {
      return;
    }

    setState(() {
      isEditing = true;
      errorMessage = null;
    });

    try {
      final term = termController.text.trim();
      final definition = definitionController.text.trim();

      // Check for duplicate terms (excluding current term)
      final duplicate =
          allTerms
              .where(
                (item) =>
                    item['term'].toString().toLowerCase() ==
                        term.toLowerCase() &&
                    item['id'] != editingTerm!['id'],
              )
              .toList();

      if (duplicate.isNotEmpty) {
        throw Exception('A term with this name already exists');
      }

      // Update term
      await Supabase.instance.client
          .from('tech_glossary')
          .update({'term': term, 'definition': definition})
          .eq('id', editingTerm!['id']);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tech term updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload terms and clear form
      await _loadExistingTerms();
      _cancelEditing();
    } catch (e) {
      setState(() {
        errorMessage = 'Error updating term: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        isEditing = false;
      });
    }
  }

  Future<void> _deleteTerm(String id) async {
    if (id != confirmDeleteId) {
      setState(() {
        confirmDeleteId = id;
      });
      return;
    }

    setState(() {
      isDeleting = true;
      errorMessage = null;
    });

    try {
      // Delete term
      await Supabase.instance.client
          .from('tech_glossary')
          .delete()
          .eq('id', id);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tech term deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload terms
      await _loadExistingTerms();
      setState(() {
        confirmDeleteId = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error deleting term: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        isDeleting = false;
      });
    }
  }

  void _startEditing(Map<String, dynamic> term) {
    setState(() {
      editingTerm = term;
      termController.text = term['term'].toString();
      definitionController.text = term['definition'].toString();
    });
  }

  void _cancelEditing() {
    setState(() {
      editingTerm = null;
      termController.clear();
      definitionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tech Terms'),
        backgroundColor: const Color(0xFF3B6EA5),
      ),
      body: Column(
        children: [
          // Input Form
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    editingTerm == null
                        ? 'Add New Tech Term'
                        : 'Edit Tech Term',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: termController,
                    decoration: const InputDecoration(
                      labelText: 'Tech Term',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.computer),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a term';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: definitionController,
                    decoration: const InputDecoration(
                      labelText: 'Definition',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a definition';
                      }
                      return null;
                    },
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              isAdding || isEditing
                                  ? null
                                  : (editingTerm == null
                                      ? _addTechTerm
                                      : _updateTechTerm),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B6EA5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child:
                              isAdding || isEditing
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    editingTerm == null
                                        ? 'Add Term'
                                        : 'Update Term',
                                  ),
                        ),
                      ),
                      if (editingTerm != null) const SizedBox(width: 8),
                      if (editingTerm != null)
                        ElevatedButton(
                          onPressed: _cancelEditing,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel Edit'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          // Search Field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search for a term...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          // Term List
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                    ? Center(child: Text(errorMessage!))
                    : ListView.builder(
                      itemCount: filteredTerms.length,
                      itemBuilder: (context, index) {
                        final term = filteredTerms[index];
                        return ListTile(
                          title: Text(term['term']),
                          subtitle: Text(term['definition']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _startEditing(term),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteTerm(term['id']),
                              ),
                            ],
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
