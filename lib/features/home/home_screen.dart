import 'package:flutter/material.dart';
import '../../core/widgets/app_bar.dart';
import '../../core/widgets/search_bar.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/file_card.dart';
import '../../core/widgets/file_list_item.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
      body: SingleChildScrollView(
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
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  SizedBox(
                    width: 140,
                    child: FileCard(
                      title: 'Q3 Report',
                      subtitle: 'Opened just now',
                      type: FileType.presentation,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: FileCard(
                      title: 'Budget FY24',
                      subtitle: 'Opened 2h ago',
                      type: FileType.spreadsheet,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: FileCard(
                      title: 'Project Proposal',
                      subtitle: 'Yesterday',
                      type: FileType.writer,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Suggested'),
            FileListItem(
              title: 'Marketing Plan',
              subtitle: 'Modified by Sarah • 2 days ago',
              type: FileType.writer,
              onTap: () {},
              onMoreTap: () {},
            ),
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
    );
  }
}
