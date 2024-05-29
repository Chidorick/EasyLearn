import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final _databaseName = "RoadmapDatabase.db";
  static final _databaseVersion = 1;
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

Future _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE students (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL
            group TEXTs
    )
  ''');
  await db.execute('''
    CREATE TABLE lessons (
      id INTEGER PRIMARY KEY,
      studentId INTEGER,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      completionStatus BOOLEAN NOT NULL,
      date TEXT NOT NULL,
      FOREIGN KEY (studentId) REFERENCES students (id)
    )
  ''');
  await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      password TEXT NOT NULL,
      email TEXT NOT NULL
    )
  ''');
}
}

class Student {
  final int id;
  final String name;

  Student({required this.id, required this.name});

  // Преобразовать объект Student в Map. Ключи должны соответствовать именам столбцов в базе данных.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Преобразовать Map в объект Student
  static Student fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
    );
  }
}

class Lesson {
  final int id;
  final int studentId;
  final String title;
  final String description;
  final bool completionStatus;
  final DateTime date;

  Lesson({
    required this.id,
    required this.studentId,
    required this.title,
    required this.description,
    required this.completionStatus,
    required this.date,
  });

  // Преобразовать объект Lesson в Map. Ключи должны соответствовать именам столбцов в базе данных.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'title': title,
      'description': description,
      'completionStatus': completionStatus ? 1 : 0,
      'date': date.toIso8601String(),
    };
  }

  static Lesson fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'],
      studentId: map['studentId'],
      title: map['title'],
      description: map['description'],
      completionStatus: map['completionStatus'] == 1,
      date: DateTime.parse(map['date']),
    );
  }
}

Future<List<Lesson>> getLessonsForStudent(int studentId) async {
  final db = await DatabaseHelper.instance.database;
  final List<Map<String, dynamic>> maps = await db.query(
    'lessons',
    where: 'studentId = ?',
    whereArgs: [studentId],
  );

  return List.generate(maps.length, (i) {
    return Lesson(
      id: maps[i]['id'],
      studentId: maps[i]['studentId'],
      title: maps[i]['title'],
      description: maps[i]['description'],
      completionStatus: maps[i]['completionStatus'] == 1,
      date: DateTime.parse(maps[i]['date']),
    );
  });
}

void main() => runApp(MaterialApp(home: Roadmap()));

class Roadmap extends StatefulWidget {
  @override
  _RoadmapState createState() => _RoadmapState();
}

class _RoadmapState extends State<Roadmap> {
  List<Student> _students = [];
  Map<String, List<bool>> lessonCompletionStatus = {};
  bool _isCalendarVisible = false;
  Map<String, List<String>> lessons = {};
  Map<String, List<String>> lessonDescriptions = {};
  Map<String, List<DateTime>> lessonDates = {};
  DateTime _selectedDay = DateTime.now();
  DateTime? _lessonDay;

  void _addNewStudent(BuildContext context) {
    TextEditingController _textController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Добавить нового студента'),
          content: TextField(
            controller: _textController,
            decoration: InputDecoration(hintText: "Введите имя студента"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Добавить'),
              onPressed: () async {
                int id = 0; // Сгенерируйте этот идентификатор в соответствии с вашей логикой
                String name = _textController.text;
                // Создать объект Student
                Student newStudent = Student(id: id, name: name);
                // Получить ссылку на базу данных
                final Database db = await DatabaseHelper.instance.database;
                // Вставить Student в правильную таблицу
                await db.insert(
                  'students',
                  newStudent.toMap(),
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
                // Обновить список студентов и обновить UI
                setState(() {
                  _students.add(newStudent);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, String student, int lessonIndex) {
    TextEditingController _textController =
        TextEditingController(text: lessons[student]![lessonIndex]);
    TextEditingController _descriptionController =
        TextEditingController(text: lessonDescriptions[student]![lessonIndex]);
    DateTime _lessonDate = lessonDates[student]![lessonIndex];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Редактировать урок'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textController,
                decoration: InputDecoration(hintText: "Введите новую информацию об уроке"),
              ),
              TextField(
                controller: _descriptionController,
                decoration:
                    InputDecoration(hintText: "Введите краткое описание"),
              ),
              ElevatedButton(
                child: Text("Выбрать дату"),
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _lessonDate,
                    firstDate: DateTime(2021),
                    lastDate: DateTime(2025),
                  );
                  if (picked != null && picked != _lessonDate) {
                    setState(() {
                      _lessonDay = picked;
                    });
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (lessonCompletionStatus[student]![lessonIndex])
              TextButton(
                child: Text('Не завершено'),
                onPressed: () {
                  setState(() {
                    lessonCompletionStatus[student]![lessonIndex] = false;
                  });
                  Navigator.of(context).pop();
                },
              )
            else
              TextButton(
                child: Text('Завершено'),
                onPressed: () {
                  setState(() {
                    lessonCompletionStatus[student]![lessonIndex] = true;
                  });
                  Navigator.of(context).pop();
                },
              ),
            TextButton(
              child: Text('Сохранить'),
              onPressed: () {
                setState(() {
                  lessons[student]![lessonIndex] = _textController.text;
                  lessonDescriptions[student]![lessonIndex] =
                      _descriptionController.text;
                  lessonDates[student]![lessonIndex] = _lessonDate;
                  _selectedDay = _lessonDate; // Обновить выбранный день
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addNewLesson(BuildContext context, String student) {
    TextEditingController _textController = TextEditingController();
    TextEditingController _descriptionController = TextEditingController();
    DateTime _lessonDate = DateTime.now();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Новый урок'),
          content: Column(
            children: [
              TextField(
                controller: _textController,
                decoration: InputDecoration(hintText: "Введите новую информацию об уроке"),
              ),
              TextField(
                controller: _descriptionController,
                decoration:
                    InputDecoration(hintText: "Введите краткое описание"),
              ),
              ElevatedButton(
                child: Text("Выбрать дату"),
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _lessonDate,
                    firstDate: DateTime(2021),
                    lastDate: DateTime(2025),
                  );
                  if (picked != null && picked != _lessonDate) {
                    setState(() {
                      _lessonDate = picked;
                    });
                  }
                },
              )
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                setState(() {
                  lessons[student]!.add(_textController.text);
                  lessonDescriptions[student]!.add(_descriptionController.text);
                  lessonCompletionStatus[student]!.add(false);
                  lessonDates[student]!.add(_lessonDate);
                  _selectedDay = _lessonDate; // Update the selected day
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget tick(bool isChecked) {
    return isChecked
        ? Icon(Icons.check_circle, color: Colors.blue)
        : Icon(Icons.radio_button_unchecked, color: Colors.blue);
  }

  Widget spacer() {
    return Container(width: 5.0);
  }

  Widget line() {
    return Container(color: Colors.blue, height: 5.0, width: 50.0);
  }

  Future<void> _showLoginDialog(BuildContext context) async {
    final TextEditingController _usernameController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login'),
          content: Column(
            children: <Widget>[
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(hintText: 'Username'),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(hintText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Login'),
              onPressed: () async {
                // Add your login logic here
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

Future<void> _showRegisterDialog(BuildContext context) async {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _selectedGroup;
  List<String> _groups = ['Group A', 'Group B', 'Group C']; // Пример групп

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Register'),
        content: Column(
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(hintText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(hintText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(hintText: 'Email'),
            ), 
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Register'),
            onPressed: () async {
              // Добавьте здесь логику регистрации
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('EasyLearn'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.login),
              onPressed: () => _showLoginDialog(context),
            ),
            IconButton(
              icon: Icon(Icons.app_registration),
              onPressed: () => _showRegisterDialog(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  String studentName = _students[index].name;
                  if (!lessons.containsKey(studentName)) {
                    lessons[studentName] = [];
                    lessonDescriptions[studentName] = [];
                    lessonCompletionStatus[studentName] = [];
                    lessonDates[studentName] = [];
                  }
                  return Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text(studentName),
                          Expanded(
                            child: Row(
                              children: List.generate(
                                  lessons[studentName]!.length * 2, (i) {
                                if (i.isEven) {
                                  return GestureDetector(
                                    onTap: () {
                                      _showEditDialog(
                                          context, studentName, i ~/ 2);
                                    },
                                    child: tick(lessonCompletionStatus[
                                        studentName]![i ~/ 2]),
                                  );
                                } else {
                                  return Row(
                                    children: [spacer(), line(), spacer()],
                                  );
                                }
                              }),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              _addNewLesson(context, studentName);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Visibility(
              visible: _isCalendarVisible,
              child: TableCalendar(
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _selectedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  selectedBuilder: (context, date, _) {
                    if (_lessonDay != null && isSameDay(_lessonDay, date)) {
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          date.day.toString(),
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    } else {
                      return null;
                    }
                  },
                ),
              ),
            )
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: CircularNotchedRectangle(),
          notchMargin: 6.0, // Add a margin for the notch
          child: Row(
            mainAxisAlignment: MainAxisAlignment
                .spaceAround, // This will space out the items evenly
            children: <Widget>[
              IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () {
                    setState(() {
                      _isCalendarVisible = !_isCalendarVisible;
                    });
                  }),

              // Spacer to center the FloatingActionButton
              SizedBox(width: 48),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  _addNewStudent(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
