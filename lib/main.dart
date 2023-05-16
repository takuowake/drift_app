import 'package:drift_app/src/drift/todos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final database = MyDatabase();
  final secureStorage = FlutterSecureStorage();
  runApp(MyApp(database: database, secureStorage: secureStorage));
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
    required this.database,
    required this.secureStorage,
  }) : super(key: key);

  final MyDatabase database;
  final FlutterSecureStorage secureStorage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DriftSample(database: database, secureStorage: secureStorage),
    );
  }
}

class DriftSample extends StatefulWidget {
  const DriftSample({
    Key? key,
    required this.database,
    required this.secureStorage,
  }) : super(key: key);

  final MyDatabase database;
  final FlutterSecureStorage secureStorage;

  @override
  _DriftSampleState createState() => _DriftSampleState();
}

class _DriftSampleState extends State<DriftSample> {
  late SharedPreferences? _prefs;
  late String? _secureValue;
  bool _isPrefsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences().then((_) {
      _getSecureValue().then((value) {
        setState(() {
          _secureValue = value;
          _isPrefsInitialized = true;
        });
      });
    });
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<String?> _getSecureValue() async {
    return widget.secureStorage.read(key: 'secureKey');
  }

  Future<void> _setSecureValue(String value) async {
    await widget.secureStorage.write(key: 'secureKey', value: value);
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
            if(_secureValue != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Secure Value: $_secureValue'),
              ),
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
                        final newValue = 'This is a secure value';
                        await _setSecureValue('This is a secure value');
                        await _incrementTodoCount();
                        setState(() {
                          _secureValue = newValue;
                        });
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