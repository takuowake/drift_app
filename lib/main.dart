import 'package:drift_app/src/drift/todos.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final database = MyDatabase();
  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
    required this.database,
  }) : super(key: key);

  final MyDatabase database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DriftSample(database: database),
    );
  }
}

class DriftSample extends StatefulWidget {
  const DriftSample({
    Key? key,
    required this.database,
  }) : super(key: key);

  final MyDatabase database;

  @override
  _DriftSampleState createState() => _DriftSampleState();
}

class _DriftSampleState extends State<DriftSample> {
  late SharedPreferences? _prefs;
  bool _isPrefsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences().then((_) {
      setState(() {
        _isPrefsInitialized = true;
      });
    });
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  int get _todoCount => _prefs?.getInt('todoCount') ?? 0;

  Future<void> _incrementTodoCount() async {
    await _prefs?.setInt('todoCount', _todoCount + 1);
  }

  Future<void> _decrementTodoCount() async {
    await _prefs?.setInt('todoCount', _todoCount - 1);
  }

  @override
  Widget build(BuildContext context) {
    if(!_isPrefsInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: Text('Todo Count: ${_todoCount ?? 0}')),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: StreamBuilder(
                stream: widget.database.watchEntries(),
                builder:
                    (BuildContext context, AsyncSnapshot<List<Todo>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) => TextButton(
                      child: Text(snapshot.data![index].content),
                      onPressed: () async {
                        await widget.database.updateTodo(
                          snapshot.data![index],
                          'updated',
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      child: const Text('Add'),
                      onPressed: () async {
                        await widget.database.addTodo(
                          'test test test',
                        );
                        await _incrementTodoCount();
                        setState(() {});
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      child: const Text('remove'),
                      onPressed: () async {
                        //15
                        //以下追加
                        final list = await widget.database.allTodoEntries;
                        if (list.isNotEmpty) {
                          await widget.database.deleteTodo(list[list.length - 1]);
                          await _decrementTodoCount();
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}