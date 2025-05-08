import 'package:equatable/equatable.dart';
import 'package:alo_draft_app/models/todo_model.dart';

abstract class TodoState extends Equatable {
  const TodoState();

  @override
  List<Object?> get props => [];
}

class TodoInitial extends TodoState {}

class TodoLoading extends TodoState {}

class TodoLoaded extends TodoState {
  final List<Todo> todos;

  const TodoLoaded(this.todos);

  @override
  List<Object?> get props => [todos];
}

class TodoFailure extends TodoState {
  final String error;

  const TodoFailure(this.error);

  @override
  List<Object?> get props => [error];
}
