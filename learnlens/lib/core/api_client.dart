import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'config.dart';

/// API client for communicating with the backend
class ApiClient {
  late Dio _dio;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Add interceptor for authentication
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get Firebase ID token
          final user = _auth.currentUser;
          if (user != null) {
            try {
              final token = await user.getIdToken();
              options.headers['Authorization'] = 'Bearer $token';
              print('Auth token added to request: ${options.uri}');
            } catch (e) {
              print('Error getting ID token: $e');
              // Continue without token - will get 401 which is handled
            }
          } else {
            print('Warning: No current user, request will fail with 401');
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // Handle errors
          if (error.response?.statusCode == 401) {
            // Check if user is logged in
            final user = _auth.currentUser;
            if (user == null) {
              // User not logged in - provide helpful error
              error.response?.data = {
                'error': 'Please log in to access this feature'
              };
            } else {
              // User logged in but token invalid - might need refresh
              error.response?.data = {
                'error': 'Authentication failed. Please try logging in again.'
              };
            }
          }
          
          // Extract error message from response
          String errorMessage = 'An error occurred';
          
          // Handle connection errors
          if (error.type == DioExceptionType.connectionError || 
              error.type == DioExceptionType.connectionTimeout) {
            errorMessage = 'Cannot connect to server. Please check if the backend is running.';
          } else if (error.response != null) {
            final data = error.response?.data;
            if (data is Map && data['detail'] != null) {
              errorMessage = data['detail'].toString();
            } else if (data is String) {
              errorMessage = data;
            }
          } else if (error.message != null) {
            // Clean up error message
            String msg = error.message!;
            if (msg.contains('Connection refused')) {
              errorMessage = 'Cannot connect to server. Please check if the backend is running on port 8000.';
            } else if (msg.contains('Failed host lookup')) {
              errorMessage = 'Cannot reach server. Please check your network connection.';
            } else {
              errorMessage = msg.split('\n').first;
            }
          }
          
          error.response?.data = {'error': errorMessage};
          handler.next(error);
        },
      ),
    );
  }

  /// Upload a document
  Future<Map<String, dynamic>> uploadDocument(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await _dio.post('/documents/upload', data: formData);
    // Backend returns UploadResponse with document_id, status, message
    // We need to fetch the full document after upload
    if (response.data['document_id'] != null) {
      // Wait a bit for processing, then fetch the document
      await Future.delayed(const Duration(seconds: 2));
      return await getDocument(response.data['document_id'].toString());
    }
    return response.data;
  }

  /// Get list of documents
  Future<Map<String, dynamic>> getDocuments({int skip = 0, int limit = 20}) async {
    final response = await _dio.get(
      '/documents',
      queryParameters: {'skip': skip, 'limit': limit},
    );
    return response.data;
  }

  /// Get a specific document
  Future<Map<String, dynamic>> getDocument(String documentId) async {
    final response = await _dio.get('/documents/$documentId');
    return response.data;
  }

  /// Delete a document
  Future<void> deleteDocument(String documentId) async {
    await _dio.delete('/documents/$documentId');
  }

  /// Generate questions for a document
  Future<List<dynamic>> generateQuestions({
    required String documentId,
    required String questionType,
    required String difficulty,
    int numQuestions = 5,
  }) async {
    final response = await _dio.post(
      '/documents/$documentId/questions/generate',
      queryParameters: {
        'question_type': questionType,
        'difficulty': difficulty,
        'num_questions': numQuestions,
      },
    );
    // Backend returns a list directly, not wrapped in an object
    if (response.data is List) {
      return response.data;
    }
    return [];
  }

  /// Get questions for a document
  Future<Map<String, dynamic>> getQuestions({
    required String documentId,
    int skip = 0,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/documents/$documentId/questions',
      queryParameters: {'skip': skip, 'limit': limit},
    );
    return response.data;
  }

  /// Get a specific question
  Future<Map<String, dynamic>> getQuestion(String questionId) async {
    final response = await _dio.get('/questions/$questionId');
    return response.data;
  }

  /// Submit an attempt
  Future<Map<String, dynamic>> submitAttempt({
    required String questionId,
    required String userAnswer,
    double? timeTaken,
  }) async {
    final response = await _dio.post(
      '/attempts',
      data: {
        'question_id': questionId,
        'user_answer': userAnswer,
        'time_taken': timeTaken,
      },
    );
    return response.data;
  }

  /// Get user's attempts
  Future<List<dynamic>> getAttempts({
    String? questionId,
    int skip = 0,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/attempts',
      queryParameters: {
        if (questionId != null) 'question_id': questionId,
        'skip': skip,
        'limit': limit,
      },
    );
    // Backend returns a list directly
    if (response.data is List) {
      return response.data;
    }
    return [];
  }

  /// Get performance analytics
  Future<Map<String, dynamic>> getPerformanceAnalytics({String? documentId}) async {
    final response = await _dio.get(
      '/analytics/performance',
      queryParameters: documentId != null ? {'document_id': documentId} : null,
    );
    return response.data;
  }

  /// Get document summary analytics
  Future<Map<String, dynamic>> getDocumentSummary(String documentId) async {
    final response = await _dio.get('/analytics/document/$documentId/summary');
    return response.data;
  }
}

