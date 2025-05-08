import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alo_draft_app/blocs/todo/todo_event.dart';
import 'package:alo_draft_app/blocs/todo/todo_state.dart';
import 'package:alo_draft_app/repositories/todo_repository.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository todoRepository;

  TodoBloc({required this.todoRepository}) : super(TodoInitial()) {
    on<TodosLoaded>(_onTodosLoaded);
    on<TodoAdded>(_onTodoAdded);
    on<TodoUpdated>(_onTodoUpdated);
    on<TodoDeleted>(_onTodoDeleted);
  }

  void _onTodosLoaded(TodosLoaded event, Emitter<TodoState> emit) async {
    emit(TodoLoading());
    try {
      final todos = await todoRepository.getTodos();
      emit(TodoLoaded(todos));
    } catch (e) {
      emit(TodoFailure(e.toString()));
    }
  }

  void _onTodoAdded(TodoAdded event, Emitter<TodoState> emit) async {
    final currentState = state;
    emit(TodoLoading());
    try {
      final newTodo = await todoRepository.createTodo(
        event.title,
        event.description,
      );

      if (currentState is TodoLoaded) {
        emit(TodoLoaded([...currentState.todos, newTodo]));
      } else {
        emit(TodoLoaded([newTodo]));
      }
    } catch (e) {
      emit(TodoFailure(e.toString()));
    }
  }

  void _onTodoUpdated(TodoUpdated event, Emitter<TodoState> emit) async {
    final currentState = state;
    if (currentState is TodoLoaded) {
      emit(TodoLoading());
      try {
        final updatedTodo = await todoRepository.updateTodo(event.todo);
        emit(TodoLoaded(
          currentState.todos.map((todo) {
            return todo.id == updatedTodo.id ? updatedTodo : todo;
          }).toList(),
        ));
      } catch (e) {
        emit(TodoFailure(e.toString()));
      }
    }
  }

  void _onTodoDeleted(TodoDeleted event, Emitter<TodoState> emit) async {
    final currentState = state;
    if (currentState is TodoLoaded) {
      emit(TodoLoading());
      try {
        await todoRepository.deleteTodo(event.id);
        emit(TodoLoaded(
          currentState.todos.where((todo) => todo.id != event.id).toList(),
        ));
      } catch (e) {
        emit(TodoFailure(e.toString()));
      }
    }
  }
}
