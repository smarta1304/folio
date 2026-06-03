import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../blocs/scanner/scanner_bloc.dart';
import '../../blocs/scanner/scanner_event.dart';
import '../../repositories/document_repository.dart';
import '../widgets/document_list_tile.dart';
import '../widgets/folder_list_tile.dart';
import 'scanner_screen.dart';
import 'document_detail_screen.dart';
import 'documents_by_folder_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Folio',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 26,
            letterSpacing: -1.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardInitial || state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => context.read<DashboardBloc>().add(LoadDashboard()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is DashboardLoaded) {
            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: TextField(
                      onChanged: (value) => context.read<DashboardBloc>().add(SearchDashboard(value)),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search documents or content...',
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                if (state.searchQuery != null && state.searchQuery!.isNotEmpty) ...[
                  _buildHeader('Search Results for "${state.searchQuery}"'),
                  _buildSearchResults(state),
                ] else ...[
                  _buildHeader('Folders (${state.folders.length})', onAdd: () => _showAddFolderDialog(context)),
                  _buildFolderList(state),
                  _buildHeader('Recent Documents'),
                  _buildRecentList(state),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          }
          return const Center(child: Text('Initializing...'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<ScannerBloc>().add(ResetScanner());
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        label: const Text('New Scan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.document_scanner_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(String title, {VoidCallback? onAdd}) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (onAdd != null)
              IconButton(
                onPressed: onAdd,
                icon: Icon(Icons.create_new_folder_outlined, color: Theme.of(context).colorScheme.onSurface),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderList(DashboardLoaded state) {
    if (state.folders.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'No folders yet.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final folder = state.folders[index];
            return FolderListTile(
              folder: folder,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DocumentsByFolderScreen(folder: folder)),
              ),
              onDelete: () => context.read<DashboardBloc>().add(DeleteFolder(folder.id!)),
            );
          },
          childCount: state.folders.length,
        ),
      ),
    );
  }

  Widget _buildSearchResults(DashboardLoaded state) {
    final results = state.searchResults ?? [];
    if (results.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text(
              'No matches found.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final doc = results[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: DocumentListTile(
                doc: doc,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DocumentDetailScreen(
                      document: doc,
                      repository: context.read<DocumentRepository>(),
                    ),
                  ),
                ),
                onDelete: () => context.read<DashboardBloc>().add(DeleteDocument(doc.id!)),
              ),
            );
          },
          childCount: results.length,
        ),
      ),
    );
  }

  Widget _buildRecentList(DashboardLoaded state) {
    if (state.recentDocuments.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'No scans yet. tap "New Scan" to start.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final doc = state.recentDocuments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Hero(
                tag: 'doc_${doc.id}',
                child: DocumentListTile(
                  doc: doc,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentDetailScreen(
                        document: doc,
                        repository: context.read<DocumentRepository>(),
                      ),
                    ),
                  ),
                  onDelete: () => context.read<DashboardBloc>().add(DeleteDocument(doc.id!)),
                ),
              ),
            );
          },
          childCount: state.recentDocuments.length,
        ),
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    int? selectedExpiry;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Folder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Folder Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                value: selectedExpiry,
                decoration: const InputDecoration(labelText: 'Auto-Delete After'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Never')),
                  DropdownMenuItem(value: 1, child: Text('1 Hour')),
                  DropdownMenuItem(value: 24, child: Text('24 Hours')),
                  DropdownMenuItem(value: 168, child: Text('7 Days')),
                ],
                onChanged: (val) => setDialogState(() => selectedExpiry = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  context.read<DashboardBloc>().add(AddFolder(
                        controller.text,
                        expiryHours: selectedExpiry,
                      ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
