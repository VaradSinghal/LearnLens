import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/api_client.dart';
import '../../models/document.dart';

// Events
abstract class DocumentEvent extends Equatable {
  const DocumentEvent();

  @override
  List<Object> get props => [];
}

class LoadDocuments extends DocumentEvent {}

class UploadDocument extends DocumentEvent {
  final String filePath;

  const UploadDocument(this.filePath);

  @override
  List<Object> get props => [filePath];
}

class UploadImages extends DocumentEvent {
  final bool useCamera;
  final int maxImages;

  const UploadImages({required this.useCamera, this.maxImages = 5});

  @override
  List<Object> get props => [useCamera, maxImages];
}

class DeleteDocument extends DocumentEvent {
  final String documentId;

  const DeleteDocument(this.documentId);

  @override
  List<Object> get props => [documentId];
}

// States
abstract class DocumentState extends Equatable {
  const DocumentState();

  @override
  List<Object> get props => [];
}

class DocumentInitial extends DocumentState {}

class DocumentLoading extends DocumentState {}

class DocumentLoaded extends DocumentState {
  final List<Document> documents;

  const DocumentLoaded(this.documents);

  @override
  List<Object> get props => [documents];
}

class DocumentUploading extends DocumentState {
  final double? progress;
  final List<Document> currentDocuments;

  const DocumentUploading({
    this.progress, 
    this.currentDocuments = const [],
  });

  @override
  List<Object> get props => [progress ?? 0.0, currentDocuments];
}

class DocumentUploaded extends DocumentState {
  final Document document;

  const DocumentUploaded(this.document);

  @override
  List<Object> get props => [document];
}

class DocumentError extends DocumentState {
  final String message;

  const DocumentError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final ApiClient _apiClient = ApiClient();

  final ImagePicker _imagePicker = ImagePicker();

  DocumentBloc() : super(DocumentInitial()) {
    on<LoadDocuments>(_onLoadDocuments);
    on<UploadDocument>(_onUploadDocument);
    on<UploadImages>(_onUploadImages);
    on<DeleteDocument>(_onDeleteDocument);
  }

  Future<void> _onLoadDocuments(
    LoadDocuments event,
    Emitter<DocumentState> emit,
  ) async {
    emit(DocumentLoading());
    try {
      final response = await _apiClient.getDocuments();
      final documentsList = (response['documents'] as List)
          .map((doc) => Document.fromJson(doc))
          .toList();
      emit(DocumentLoaded(documentsList));
    } catch (e) {
      emit(DocumentError(e.toString()));
    }
  }

  Future<void> _onUploadDocument(
    UploadDocument event,
    Emitter<DocumentState> emit,
  ) async {
    // Preserve current documents
    final currentDocs = state is DocumentLoaded ? (state as DocumentLoaded).documents : <Document>[];
    emit(DocumentUploading(currentDocuments: currentDocs));
    
    try {
      // Upload document - API client will fetch full document after upload
      final response = await _apiClient.uploadDocument(event.filePath);
      
      // Check if we got a full document or just upload response
      if (response.containsKey('document_id') && !response.containsKey('title')) {
        // This is UploadResponse, wait a bit more and fetch document
        await Future.delayed(const Duration(seconds: 3));
        final document = await _apiClient.getDocument(response['document_id'].toString());
        emit(DocumentUploaded(Document.fromJson(document)));
      } else {
        // Full document response
        emit(DocumentUploaded(Document.fromJson(response)));
      }
      
      // Reload documents list
      add(LoadDocuments());
    } catch (e) {
      emit(DocumentError(e.toString()));
    }
  }

  Future<void> _onUploadImages(
    UploadImages event,
    Emitter<DocumentState> emit,
  ) async {
    final currentDocs = state is DocumentLoaded ? (state as DocumentLoaded).documents : <Document>[];
    emit(DocumentUploading(currentDocuments: currentDocs));
    try {
      List<XFile> pickedImages = [];
      
      if (event.useCamera) {
        // Take a single photo
        final image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (image != null) {
          pickedImages.add(image);
        }
      } else {
        // Pick multiple images from gallery
        pickedImages = await _imagePicker.pickMultiImage(
          imageQuality: 85,
        );
      }

      if (pickedImages.isEmpty) {
        emit(DocumentError('No images selected'));
        return;
      }

      // Limit to maxImages
      if (pickedImages.length > event.maxImages) {
        pickedImages = pickedImages.take(event.maxImages).toList();
      }

      // Upload each image
      int successCount = 0;
      for (final image in pickedImages) {
        try {
          final response = await _apiClient.uploadDocument(image.path);
          if (response.containsKey('document_id')) {
            successCount++;
          }
        } catch (e) {
          // Continue with other images even if one fails
          print('Error uploading ${image.name}: $e');
        }
      }

      if (successCount > 0) {
        emit(DocumentUploaded(Document(
          documentId: '',
          userId: '',
          title: '$successCount image(s) uploaded',
          extractedText: '',
          language: 'en',
          uploadedAt: DateTime.now(),
          status: 'processed',
        )));
        // Reload documents list
        add(LoadDocuments());
      } else {
        emit(DocumentError('Failed to upload images'));
      }
    } catch (e) {
      emit(DocumentError('Error uploading images: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteDocument(
    DeleteDocument event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await _apiClient.deleteDocument(event.documentId);
      // Reload documents list
      add(LoadDocuments());
    } catch (e) {
      emit(DocumentError(e.toString()));
    }
  }
}

