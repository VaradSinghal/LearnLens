import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../bloc/document/document_bloc.dart';
import '../models/document.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_shimmer.dart';
import 'question_list_screen.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  bool _showFloatingButtons = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DocumentBloc>().add(LoadDocuments());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      child: Stack(
        children: [
          // Background Gradient Blob
          Positioned(
            top: -100,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: BlocConsumer<DocumentBloc, DocumentState>(
              listener: (context, state) {
                if (state is DocumentError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                } else if (state is DocumentUploaded) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Document uploaded successfully!'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              builder: (context, state) {
                return Column(
                  children: [
                     // Custom Header
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Library',
                                style: Theme.of(context).textTheme.headlineLarge,
                              ),
                              Text(
                                'Manage your documents',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          // Optional: Search Icon or Profile Thumbnail
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: _buildBody(state),
                    ),
                  ],
                );
              },
            ),
          ),

          // Floating action buttons overlay
          if (_showFloatingButtons)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showFloatingButtons = false),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: const SizedBox(),
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 100, // Adjusted for new bottom nav
            right: 24,
            child: _buildFloatingActionButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(DocumentState state) {
    if (state is DocumentLoading || state is DocumentInitial) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: DocumentCardShimmer(),
        ),
      );
    } else if (state is DocumentUploading) {
       return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 24),
            Text(
              'Uploading... ${state.progress != null ? '${(state.progress! * 100).toInt()}%' : ''}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    } else if (state is DocumentLoaded) {
      if (state.documents.isEmpty) return _buildEmptyState();
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
        itemCount: state.documents.length,
        itemBuilder: (context, index) {
          final document = state.documents[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DocumentCard(document: document),
          );
        },
      );
    } else if (state is DocumentError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text('Error: ${state.message}', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<DocumentBloc>().add(LoadDocuments()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.description_outlined, size: 48, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text('No Documents Yet', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Upload your first document to start learning',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
               setState(() => _showFloatingButtons = true);
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Document'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_showFloatingButtons) ...[
          _buildFabOption(
            icon: Icons.camera_alt,
            label: 'Camera',
            onTap: _handleCameraUpload,
          ),
          const SizedBox(height: 16),
          _buildFabOption(
            icon: Icons.upload_file,
            label: 'Files',
            onTap: _handleFileUpload,
          ),
          const SizedBox(height: 24),
        ],
        
        FloatingActionButton(
          onPressed: () => setState(() => _showFloatingButtons = !_showFloatingButtons),
          backgroundColor: AppTheme.primaryColor,
          child: Icon(_showFloatingButtons ? Icons.close : Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildFabOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
              boxShadow: [
                 BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCameraUpload() async {
    setState(() => _showFloatingButtons = false);
    context.read<DocumentBloc>().add(
          UploadImages(useCamera: true, maxImages: 5),
        );
  }

  Future<void> _handleFileUpload() async {
    setState(() => _showFloatingButtons = false);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      context.read<DocumentBloc>().add(
            UploadDocument(result.files.single.path!),
          );
    }
  }
}

class _DocumentCard extends StatelessWidget {
  final Document document;

  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
     color: AppTheme.surfaceColor,
     opacity: 0.6,
      child: InkWell(
        onTap: () {
          if (document.status == 'processed') {
             Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuestionListScreen(documentId: document.documentId),
              ),
            );
          }
        },
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.insert_drive_file, color: AppTheme.primaryColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatDate(document.uploadedAt),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      if (document.status == 'processing')
                         const SizedBox(
                           width: 12, height: 12, 
                           child: CircularProgressIndicator(strokeWidth: 2)
                         )
                       else
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                           decoration: BoxDecoration(
                             color: AppTheme.successColor.withOpacity(0.1),
                             borderRadius: BorderRadius.circular(4),
                           ),
                           child: Text(
                             'Ready',
                             style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.successColor),
                           ),
                         ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
              onPressed: () => _showOptionsMenu(context),
            ),
          ],
        ),
      ),
    );
  }

   String _formatDate(DateTime date) {
    // Simple formatter, can use intl package if available
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              title: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
              onTap: () {
                Navigator.pop(context);
                context.read<DocumentBloc>().add(DeleteDocument(document.documentId));
              },
            ),
          ],
        ),
      ),
    );
  }
}
