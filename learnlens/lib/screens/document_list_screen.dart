import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../bloc/document/document_bloc.dart';
import '../models/document.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_shimmer.dart';
import 'question_list_screen.dart';

/// Screen displaying list of user's documents
class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  @override
  void initState() {
    super.initState();
    // Load documents when screen is first displayed (user is authenticated at this point)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentBloc>().add(LoadDocuments());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DocumentBloc>().add(LoadDocuments());
            },
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: BlocConsumer<DocumentBloc, DocumentState>(
        listener: (context, state) {
          if (state is DocumentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is DocumentUploaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Document uploaded successfully!')),
            );
          }
        },
        builder: (context, state) {
          if (state is DocumentLoading || state is DocumentInitial) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) => const DocumentCardShimmer(),
            );
          } else if (state is DocumentUploading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Uploading... ${state.progress != null ? '${(state.progress! * 100).toInt()}%' : ''}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          } else if (state is DocumentLoaded) {
            if (state.documents.isEmpty) {
              return EmptyState(
                title: 'No Documents Yet',
                message: 'Upload your first document to start learning',
                icon: Icons.description_outlined,
                action: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _pickAndUploadDocument(context),
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: const Text(
                      'Upload Document',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.documents.length,
              itemBuilder: (context, index) {
                final document = state.documents[index];
                return _DocumentCard(document: document);
              },
            );
          } else if (state is DocumentError) {
            return EmptyState(
              title: 'Oops! Something went wrong',
              message: state.message,
              icon: Icons.error_outline,
              action: ElevatedButton(
                onPressed: () {
                  context.read<DocumentBloc>().add(LoadDocuments());
                },
                child: const Text('Retry'),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _pickAndUploadDocument(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadDocument(BuildContext context) async {
    // Show dialog to choose between file picker or camera
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Choose File'),
              onTap: () => Navigator.pop(context, 'file'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose Images (up to 5)'),
              onTap: () => Navigator.pop(context, 'images'),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'file') {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        context.read<DocumentBloc>().add(
              UploadDocument(result.files.single.path!),
            );
      }
    } else if (choice == 'camera' || choice == 'images') {
      context.read<DocumentBloc>().add(
            UploadImages(useCamera: choice == 'camera', maxImages: 5),
          );
    }
  }
}

class _DocumentCard extends StatelessWidget {
  final Document document;

  const _DocumentCard({required this.document});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processed':
        return AppTheme.successColor;
      case 'processing':
        return AppTheme.warningColor;
      case 'failed':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'processed':
        return Icons.check_circle;
      case 'processing':
        return Icons.hourglass_empty;
      case 'failed':
        return Icons.error;
      default:
        return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(document.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.description,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(document.status),
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          document.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                document.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(document.uploadedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.language,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    document.language.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (document.status == 'processed') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuestionListScreen(documentId: document.documentId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.quiz),
                        label: const Text('View Questions'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Document'),
                            content: const Text('Are you sure you want to delete this document?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.read<DocumentBloc>().add(DeleteDocument(document.documentId));
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.errorColor,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline),
                      color: AppTheme.errorColor,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

