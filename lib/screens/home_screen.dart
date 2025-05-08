import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alo_draft_app/blocs/auth/auth_bloc.dart';
import 'package:alo_draft_app/blocs/auth/auth_event.dart';
import 'package:alo_draft_app/blocs/todo/todo_bloc.dart';
import 'package:alo_draft_app/blocs/todo/todo_event.dart';
import 'package:alo_draft_app/blocs/todo/todo_state.dart';
import 'package:alo_draft_app/widgets/todo_item.dart';
import 'package:alo_draft_app/screens/add_edit_todo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TodoBloc>().add(TodosLoaded());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              context.read<AuthBloc>().add(LoggedOut());
            },
          ),
        ],
      ),
      body: BlocBuilder<TodoBloc, TodoState>(
        builder: (context, state) {
          if (state is TodoLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state is TodoLoaded) {
            if (state.todos.isEmpty) {
              return const Center(
                child: Text('No todos yet. Add one to get started!'),
              );
            }
            return ListView.builder(
              itemCount: state.todos.length,
              itemBuilder: (context, index) {
                final todo = state.todos[index];
                return TodoItem(
                  todo: todo,
                  onEdit: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddEditTodoScreen(todo: todo),
                      ),
                    );
                  },
                  onDelete: () {
                    context.read<TodoBloc>().add(TodoDeleted(todo.id));
                  },
                  onToggle: (value) {
                    context.read<TodoBloc>().add(
                          TodoUpdated(
                            todo.copyWith(isCompleted: value),
                          ),
                        );
                  },
                );
              },
            );
          }
          if (state is TodoFailure) {
            return Center(
              child: Text('Error: ${state.error}'),
            );
          }
          return const Center(
            child: Text('No todos found'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditTodoScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
