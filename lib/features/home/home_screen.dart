import 'package:flutter/material.dart';
import '../../core/widgets/app_bar.dart';
import '../../core/widgets/search_bar.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/file_card.dart';
import '../../core/widgets/file_list_item.dart';
import '../../core/widgets/bottom_sheet.dart';
import '../../core/widgets/app_dialog.dart';
import '../../storage/document_storage.dart';
import '../../storage/local_document_storage.dart';
import '../../storage/models/writer_document.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DocumentStorage _storage = LocalDocumentStorage();
  late Future<List<WriterDocument>> _recentDocsFuture;

  @override
  void initState() {
    super.initState();
    _recentDocsFuture = _storage.recentDocuments();
  }

  void _refresh() {
    setState(() {
      _recentDocsFuture = _storage.recentDocuments();
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
        title: 'OpenWPS',
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CustomSearchBar(
                  hintText: 'Search files...',
                  onTap: () {},
                ),
              ),
              const SectionHeader(title: 'Recent'),
              SizedBox(
                height: 140,
                child: FutureBuilder<List<WriterDocument>>(
                  future: _recentDocsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No recent documents'));
                    }
                    final docs = snapshot.data!;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: SizedBox(
                            width: 140,
                            child: FileCard(
                              title: doc.isFavorite ? '★ ${doc.title}' : doc.title,
                              subtitle: 'Writer Document',
                              type: FileType.writer,
                              onTap: () async {
                                await Navigator.pushNamed(context, '/writer', arguments: doc.id);
                                _refresh();
                              },
                              onLongPress: () => _showFileOptions(context, doc),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const SectionHeader(title: 'Suggested'),
              // Placeholders for non-writer elements
              FileListItem(
                title: 'Design Assets',
                subtitle: 'Folder • 12 items',
                type: FileType.folder,
                onTap: () {},
                onLongPress: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
