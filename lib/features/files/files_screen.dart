import 'package:flutter/material.dart';
import '../../core/widgets/app_bar.dart';
import '../../core/widgets/file_list_item.dart';
import '../../core/widgets/file_card.dart';

class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

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
                  ListView(
                    children: [
                      FileListItem(
                        title: 'Documents',
                        subtitle: 'Folder',
                        type: FileType.folder,
                        onTap: () {},
                        onMoreTap: () {},
                      ),
                      FileListItem(
                        title: 'Downloads',
                        subtitle: 'Folder',
                        type: FileType.folder,
                        onTap: () {},
                        onMoreTap: () {},
                      ),
                      FileListItem(
                        title: 'Draft.docx',
                        subtitle: '12 KB • Today',
                        type: FileType.writer,
                        onTap: () {},
                        onMoreTap: () {},
                      ),
                    ],
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
