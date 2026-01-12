import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/api_client.dart';
import '../../models/question.dart';

// Events
abstract class QuestionEvent extends Equatable {
  const QuestionEvent();

  @override
  List<Object> get props => [];
}

class LoadQuestions extends QuestionEvent {
  final String documentId;

  const LoadQuestions(this.documentId);

  @override
  List<Object> get props => [documentId];
}

class GenerateQuestions extends QuestionEvent {
  final String documentId;
  final String questionType;
  final String difficulty;
  final int numQuestions;

  const GenerateQuestions({
    required this.documentId,
    required this.questionType,
    required this.difficulty,
    this.numQuestions = 5,
  });

  @override
  List<Object> get props => [documentId, questionType, difficulty, numQuestions];
}

// States
abstract class QuestionState extends Equatable {
  const QuestionState();

  @override
  List<Object> get props => [];
}

class QuestionInitial extends QuestionState {}

class QuestionLoading extends QuestionState {}

class QuestionLoaded extends QuestionState {
  final List<Question> questions;

  const QuestionLoaded(this.questions);

  @override
  List<Object> get props => [questions];
}

class QuestionGenerating extends QuestionState {}

class QuestionGenerated extends QuestionState {
  final List<Question> questions;

  const QuestionGenerated(this.questions);

  @override
  List<Object> get props => [questions];
}

class QuestionError extends QuestionState {
  final String message;

  const QuestionError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class QuestionBloc extends Bloc<QuestionEvent, QuestionState> {
  final ApiClient _apiClient = ApiClient();

  QuestionBloc() : super(QuestionInitial()) {
    on<LoadQuestions>(_onLoadQuestions);
    on<GenerateQuestions>(_onGenerateQuestions);
  }

  Future<void> _onLoadQuestions(
    LoadQuestions event,
    Emitter<QuestionState> emit,
  ) async {
    emit(QuestionLoading());
    try {
      final response = await _apiClient.getQuestions(documentId: event.documentId);
      final questionsList = (response['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList();
      emit(QuestionLoaded(questionsList));
    } catch (e) {
      emit(QuestionError(e.toString()));
    }
  }

  Future<void> _onGenerateQuestions(
    GenerateQuestions event,
    Emitter<QuestionState> emit,
  ) async {
    emit(QuestionGenerating());
    try {
      final questionsList = await _apiClient.generateQuestions(
        documentId: event.documentId,
        questionType: event.questionType,
        difficulty: event.difficulty,
        numQuestions: event.numQuestions,
      );
      final questions = questionsList
          .map((q) => Question.fromJson(q))
          .toList();
      emit(QuestionGenerated(questions));
    } catch (e) {
      emit(QuestionError(e.toString()));
    }
  }
}

