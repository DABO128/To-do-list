// main.dart
import 'package:flutter/material.dart';

import 'sql_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove the debug banner
        debugShowCheckedModeBanner: false,
        title: 'OUMAR.COM',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<Map<String, dynamic>> _journals = [];
  bool _isLoading = true;
  String _searchQuery = '';



  // This function is used to fetch all data from the database
  void _refreshJournals() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _journals = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshJournals(); // Loading the diary when the app starts
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  void _showForm(int? id) async {
    if (id != null) {
      final existingJournal = _journals.firstWhere((element) => element['id'] == id);
      _titleController.text = existingJournal['title'];
      _descriptionController.text = existingJournal['description'];
      _dateController.text = existingJournal['date'];
    } else {
      _titleController.text = '';
      _descriptionController.text = '';
      _dateController.text = '';
    }

    showModalBottomSheet(
        context: context,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
          padding: EdgeInsets.only(
            top: 15,
            left: 15,
            right: 15,
            // this will prevent the soft keyboard from covering the text fields
            bottom: MediaQuery.of(context).viewInsets.bottom + 120,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Title'),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(hintText: 'Description'),
              ),
              const SizedBox(
                height: 20,
              ),
              TextField(
                controller: _dateController,
                decoration: const InputDecoration(hintText: 'Date'),
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (selectedDate != null) {
                    _dateController.text =
                    selectedDate.toIso8601String().split('T')[0];
                  }
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  // Save new journal
                  if (id == null) {
                    await _addItem();
                  }

                  if (id != null) {
                    await _updateItem(id);
                  }

                  // Clear the text fields
                  _titleController.text = '';
                  _descriptionController.text = '';
                  _dateController.text = '';

                  // Close the bottom sheet
                  Navigator.of(context).pop();
                },
                child: Text(id == null ? 'Create New' : 'Update'),
              )
            ],
          ),
        ));
  }

// Insert a new journal to the database
  Future<void> _addItem() async {
    await SQLHelper.createItem(
      _titleController.text,
      _descriptionController.text,
      _dateController.text,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully added a journal!'),
      ),
    );
    _refreshJournals();
  }



  // Update an existing journal
  Future<void> _updateItem(int id) async {
    await SQLHelper.updateItem(
        id, _titleController.text,_descriptionController.text,_dateController.text );

    _refreshJournals();
  }

  // Delete an item
  void _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Successfully deleted a journal!'),
    ));
    _refreshJournals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DABO(TO DO LIST WITH SQFLITE)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _SearchDelegate(_journals),
              );
            },
          ),
        ],
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : (_searchQuery.isEmpty
          ? ListView.builder(
        itemCount: _journals.length,
        itemBuilder: (context, index) {
          return Card(
            color: Colors.lightBlue[200],
            margin: const EdgeInsets.all(15),
            child: ListTile(
              title: Text(_journals[index]['title']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_journals[index]['description']),
                  if (_journals[index]['date'] != null)
                    Text(_journals[index]['date']!),
                ],
              ),
              trailing: SizedBox(
                width: 100,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showForm(_journals[index]['id']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteItem(_journals[index]['id']),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      )
          : Builder(
        builder: (context) {
          return ListView.builder(
            itemCount: _journals.length,
            itemBuilder: (context, index) {
              // Perform search filtering based on _searchQuery here
              // ...
              return Card(
                color: Colors.orange[200],
                margin: const EdgeInsets.all(15),
                child: ListTile(
                  title: Text(_journals[index]['title']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_journals[index]['description']),
                      if (_journals[index]['date'] != null)
                        Text(_journals[index]['date']!),
                    ],
                  ),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showForm(_journals[index]['id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              _deleteItem(_journals[index]['id']),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      )
      ),


      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}

class _SearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> journals;

  _SearchDelegate(this.journals);

  @override
  String get searchFieldLabel => 'Search';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final filteredJournals = journals.where((journal) {
      final title = journal['title']?.toLowerCase() ?? '';
      final description = journal['description']?.toLowerCase() ?? '';
      return title.contains(query.toLowerCase()) ||
          description.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filteredJournals.length,
      itemBuilder: (context, index) {
        final journal = filteredJournals[index];
        return Card(
          color: Colors.orange[200],
          margin: const EdgeInsets.all(15),
          child: ListTile(
            title: Text(journal['title']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(journal['description']),
                if (journal['date'] != null) Text(journal['date']!),
              ],
            ),
            trailing: SizedBox(
              width: 100,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Open edit form for the selected journal
                      Navigator.of(context).pop();
                      final homePageState =
                      context.findAncestorStateOfType<_HomePageState>();
                      homePageState?._showForm(journal['id']);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      // Delete the selected journal
                      Navigator.of(context).pop();
                      final homePageState =
                      context.findAncestorStateOfType<_HomePageState>();
                      homePageState?._deleteItem(journal['id']);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredJournals = journals.where((journal) {
      final title = journal['title']?.toLowerCase() ?? '';
      final description = journal['description']?.toLowerCase() ?? '';
      return title.contains(query.toLowerCase()) ||
          description.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filteredJournals.length,
      itemBuilder: (context, index) {
        final journal = filteredJournals[index];
        return ListTile(
          title: Text(journal['title']),
          subtitle: Text(journal['description']),
          onTap: () {
            // Open edit form for the selected journal
            close(context, null);
            final homePageState =
            context.findAncestorStateOfType<_HomePageState>();
            homePageState?._showForm(journal['id']);
          },
        );
      },
    );
  }
}
