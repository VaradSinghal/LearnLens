import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../bloc/document/document_bloc.dart';
import '../models/document.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_shimmer.dart';
import 'question_list_screen.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DocumentBloc>().add(LoadDocuments());
      }
    });
  }

  void _showAddOptions(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Symbols.camera_alt, color: AppTheme.textPrimary),
              title: const Text('Scan with Camera'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(context); // Close sheet
                // Use parentContext to access the provider from the screen scope
                parentContext.read<DocumentBloc>().add(
                  UploadImages(useCamera: true, maxImages: 5),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Symbols.upload_file, color: AppTheme.textPrimary),
              title: const Text('Upload File'),
              contentPadding: EdgeInsets.zero,
              onTap: () async {
                Navigator.pop(context); // Close sheet
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'docx', 'txt', 'jpg', 'png', 'jpeg'],
                );

                if (result != null && result.files.single.path != null) {
                   parentContext.read<DocumentBloc>().add(
                     UploadDocument(result.files.single.path!),
                   );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DocumentBloc, DocumentState>(
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
            const SnackBar(
              content: Text('Document uploaded successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is DocumentUploading;
        
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Text(
              'Documents',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                onPressed: () => _showAddOptions(context),
                icon: const Icon(Symbols.add, size: 28),
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Stack(
            children: [
               _buildBody(state),
               if (isLoading)
                 Stack(
                   children: [
                     // Modal barrier
                     ModalBarrier(color: Colors.black.withOpacity(0.5), dismissible: false),
                     Center(
                       child: Container(
                         padding: const EdgeInsets.all(24),
                         decoration: BoxDecoration(
                           color: AppTheme.surfaceColor,
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             const CircularProgressIndicator(color: AppTheme.primaryColor),
                             const SizedBox(height: 16),
                             Text(
                               'Uploading...',
                               style: Theme.of(context).textTheme.bodyLarge,
                             ),
                             if (state.progress != null) ...[
                               const SizedBox(height: 8),
                               SizedBox(
                                 width: 200,
                                 child: LinearProgressIndicator(
                                   value: state.progress,
                                   backgroundColor: AppTheme.surfaceColor,
                                   color: AppTheme.primaryColor,
                                 ),
                               ),
                               const SizedBox(height: 4),
                               Text('${(state.progress! * 100).toInt()}%'),
                             ]
                           ],
                         ),
                       ),
                     ),
                   ],
                 ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(DocumentState state) {
     if (state is DocumentLoading || state is DocumentInitial) {
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: 3,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: DocumentCardShimmer(),
          ),
        );
      } else if (state is DocumentLoaded || state is DocumentUploading) {
         // Show existing list even while uploading
         final documents = (state is DocumentLoaded) 
             ? state.documents 
             : (state is DocumentUploading ? state.currentDocuments : []) ?? [];
             
        if (documents.isEmpty && state is! DocumentUploading) return _buildEmptyState();
        
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final document = documents[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
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
          Icon(Symbols.description, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No Documents Yet',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first document',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Document document;

  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Symbols.description, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
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
                             child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)
                           )
                         else if (document.status == 'processed')
                           const Icon(Symbols.check_circle, size: 14, color: AppTheme.successColor, fill: 1)
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Symbols.more_vert, color: AppTheme.textSecondary),
                onPressed: () => _showOptionsMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
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
              leading: const Icon(Symbols.delete, color: AppTheme.errorColor),
              title: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
              contentPadding: EdgeInsets.zero,
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
