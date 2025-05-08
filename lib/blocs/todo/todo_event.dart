import 'package:equatable/equatable.dart';
import 'package:alo_draft_app/models/todo_model.dart';

abstract class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object> get props => [];
}

class TodosLoaded extends TodoEvent {}

class TodoAdded extends TodoEvent {
  final String title;
  final String description;

  const TodoAdded({
    required this.title,
    required this.description,
  });

  @override
  List<Object> get props => [title, description];
}

class TodoUpdated extends TodoEvent {
  final Todo todo;

  const TodoUpdated(this.todo);

  @override
  List<Object> get props => [todo];
}

class TodoDeleted extends TodoEvent {
  final int id;

  const TodoDeleted(this.id);

  @override
  List<Object> get props => [id];
}
