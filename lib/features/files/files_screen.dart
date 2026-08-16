import 'package:flutter/material.dart';
import '../../core/widgets/app_bar.dart';
import '../../core/widgets/file_list_item.dart';
import '../../core/widgets/file_card.dart';
import '../../core/widgets/bottom_sheet.dart';
import '../../core/widgets/app_dialog.dart';
import '../../storage/document_storage.dart';
import '../../storage/local_document_storage.dart';
import '../../storage/models/writer_document.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final DocumentStorage _storage = LocalDocumentStorage();
  late Future<List<WriterDocument>> _docsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _docsFuture = _storage.listDocuments();
    });
  }

  void _showFileOptions(BuildContext context, WriterDocument doc) {
    showAppBottomSheet(
      context: context,
      title: doc.title,
      child: Column(
        children: [
          ListTile(
            leading: Icon(doc.isFavorite ? Icons.star : Icons.star_border),
            title: Text(doc.isFavorite ? 'Remove Favorite' : 'Add to Favorites'),
            onTap: () async {
              Navigator.pop(context);
              await _storage.toggleFavorite(doc.id);
              _refresh();
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(context, doc);
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Duplicate'),
            onTap: () async {
              Navigator.pop(context);
              await _storage.duplicateDocument(doc.id);
              _refresh();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, doc);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WriterDocument doc) {
    showAppDialog(
      context: context,
      title: 'Delete Document?',
      content: Text('Are you sure you want to delete "${doc.title}"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            await _storage.deleteDocument(doc.id);
            if (!context.mounted) return;
            Navigator.pop(context);
            _refresh();
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  void _showRenameDialog(BuildContext context, WriterDocument doc) {
    final controller = TextEditingController(text: doc.title);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                await _storage.renameDocument(doc.id, newTitle);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                _refresh();
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Files',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {},
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Local'),
                Tab(text: 'Google Drive'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: () async => _refresh(),
                    child: FutureBuilder<List<WriterDocument>>(
                      future: _docsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return ListView(
                            children: const [
                               Center(
                                 child: Padding(
                                   padding: EdgeInsets.all(32),
                                   child: Text('No documents found.'),
                                 )
                               )
                            ],
                          );
                        }
                        final docs = snapshot.data!;
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            return FileListItem(
                              title: doc.isFavorite ? '★ ${doc.title}' : doc.title,
                              subtitle: 'Writer Document',
                              type: FileType.writer,
                              onTap: () async {
                                await Navigator.pushNamed(context, '/writer', arguments: doc.id);
                                _refresh();
                              },
                              onLongPress: () => _showFileOptions(context, doc),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const Center(
                    child: Text('Google Drive Integration Pending'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
