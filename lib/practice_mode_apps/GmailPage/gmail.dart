import 'package:flutter/material.dart';

void main() => runApp(MyGmailSimApp());

class MyGmailSimApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gmail Simulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: GmailPage(),
    );
  }
}

class GmailPage extends StatelessWidget {
  final List<Map<String, String>> fakeEmails = [
    {'sender': 'Ana Reyes', 'subject': 'Meeting Reminder', 'message': 'Don’t forget our meeting tomorrow at 10 AM.'},
    {'sender': 'Bank Alert', 'subject': 'Account Notification', 'message': 'Your balance has been updated.'},
    {'sender': 'Lyresh Ann', 'subject': 'Hello!', 'message': 'Just wanted to say hi and check in with you.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inbox'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text('Menu'),
              decoration: BoxDecoration(color: Colors.red),
            ),
            ListTile(
              title: Text('Inbox'),
              onTap: () {},
            ),
            ListTile(
              title: Text('Sent'),
              onTap: () {},
            ),
            ListTile(
              title: Text('Drafts'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: fakeEmails.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.email),
            title: Text(fakeEmails[index]['sender']!),
            subtitle: Text(fakeEmails[index]['subject']!),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmailDetailPage(email: fakeEmails[index]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.create),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComposeEmailPage(),
            ),
          );
        },
      ),
    );
  }
}

class EmailDetailPage extends StatelessWidget {
  final Map<String, String> email;

  EmailDetailPage({required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(email['subject']!)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${email['sender']}', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(email['message']!),
          ],
        ),
      ),
    );
  }
}

class ComposeEmailPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController toController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Compose Email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: toController,
                decoration: InputDecoration(labelText: 'To'),
              ),
              TextFormField(
                controller: subjectController,
                decoration: InputDecoration(labelText: 'Subject'),
              ),
              Expanded(
                child: TextFormField(
                  controller: messageController,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(labelText: 'Message'),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Email "sent" (simulated)')),
                  );
                  Navigator.pop(context);
                },
                child: Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
