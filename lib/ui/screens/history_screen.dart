import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import '../../data/history_database.dart';

/// [HistoryScreen]
/// A screen that displays a list of previous AI diagnostic history.
/// It fetches data from the local SQLite database and allows users to view details or delete records.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Holds the list of history records fetched from DB (includes id, imagePath, result, timestamp)
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    // Fetch stored history records when the screen is initialized
    _refreshHistory();
  }

  /// Fetches all records from the database and updates the UI state.
  void _refreshHistory() async {
    final data = await HistoryDatabase.instance.getAllHistory();
    setState(() {
      _history = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Medical History"),
        backgroundColor: Colors.black,
      ),
      body: _history.isEmpty
          ? const Center(child: Text("No records found.", style: TextStyle(color: Colors.white54)))
          : ListView.builder(
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          // Parse the ISO8601 string from DB back into a DateTime object
          final date = DateTime.parse(item['timestamp']);

          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              // 1. Thumbnail: Displays the image from the local path stored in DB
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(File(item['imagePath']), width: 50, height: 50, fit: BoxFit.cover),
              ),
              // 2. Title: Formatted date and time of the diagnosis
              title: Text(
                DateFormat('yyyy-MM-dd HH:mm').format(date),
                style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold),
              ),
              // 3. Subtitle: Brief summary of the AI analysis result (max 2 lines)
              subtitle: Text(
                item['result'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
              // Tap to open a detailed view of the specific record
              onTap: () => _showDetail(item),
              // Long press to trigger record deletion
              onLongPress: () async {
                await HistoryDatabase.instance.deleteHistory(item['id']);
                _refreshHistory();
              },
            ),
          );
        },
      ),
    );
  }

  /// Displays a modal bottom sheet containing the full image and the complete AI analysis.
  void _showDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to expand for long analysis texts
      backgroundColor: Colors.black,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the high-resolution image saved during diagnosis
              Image.file(File(item['imagePath'])),
              const SizedBox(height: 20),
              // Render the AI result using Markdown for proper formatting (headings, lists, etc.)
              MarkdownBody(
                data: item['result'],
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: Colors.white, fontSize: 16),
                  h1: const TextStyle(color: Colors.lightBlueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}