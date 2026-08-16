import 'package:flutter/material.dart';
import '../../core/widgets/app_bar.dart';
import '../../core/widgets/search_bar.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/file_card.dart';
import '../../core/widgets/file_list_item.dart';
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
                onMoreTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
