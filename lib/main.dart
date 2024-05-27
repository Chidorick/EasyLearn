import 'package:flutter/material.dart';
import 'package:timelines/timelines.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:math';

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
  }
}

class Student {
  final int id;
  final String name;

  Student({required this.id, required this.name});

  // Convert a Student object into a Map. The keys must correspond to the names of the columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Convert a Map into a Student object
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

  // Convert a Lesson object into a Map. The keys must correspond to the names of the columns in the database.
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
  Map<String, List<Lesson>> _lessons = {};
  Map<String, List<bool>> lessonCompletionStatus = {};
  Map<String, List<String>> lessons = {};
  Map<String, List<String>> lessonDescriptions = {};
  Map<String, List<DateTime>> lessonDates = {};
  DateTime _selectedDay = DateTime.now();
  DateTime? _lessonDay;

  @override
  void initState() {
    super.initState();
    _lessonDay = _selectedDay;
    _loadData();
  }

  void _loadData() async {
    final db = await DatabaseHelper.instance.database;
    // Load students
    final studentMaps = await db.query('students');
    _students = studentMaps.map((map) => Student.fromMap(map)).toList();
    // Load lessons for each student
    for (var student in _students) {
      final lessonMaps = await db.query(
        'lessons',
        where: 'studentId = ?',
        whereArgs: [student.id],
      );
      _lessons[student.name] =
          lessonMaps.map((map) => Lesson.fromMap(map)).toList();
    }
    setState(() {});
  }

  void _addNewStudent(BuildContext context) {
    TextEditingController _textController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Student'),
          content: TextField(
            controller: _textController,
            decoration: InputDecoration(hintText: "Enter student's name"),
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
              onPressed: () async {
                int id = 0; // Generate this id as per your logic
                String name = _textController.text;
                // Create a Student object
                Student newStudent = Student(id: id, name: name);
                // Get a reference to the database
                final Database db = await DatabaseHelper.instance.database;
                // Insert the Student into the correct table
                await db.insert(
                  'students',
                  newStudent.toMap(),
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
                // Update the list of students and refresh the UI
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
          title: Text('Edit Lesson'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textController,
                decoration: InputDecoration(hintText: "Enter new lesson info"),
              ),
              TextField(
                controller: _descriptionController,
                decoration:
                    InputDecoration(hintText: "Enter short description"),
              ),
              ElevatedButton(
                child: Text("Select Date"),
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
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (lessonCompletionStatus[student]![lessonIndex])
              TextButton(
                child: Text('Uncomplete'),
                onPressed: () {
                  setState(() {
                    lessonCompletionStatus[student]![lessonIndex] = false;
                  });
                  Navigator.of(context).pop();
                },
              )
            else
              TextButton(
                child: Text('Complete'),
                onPressed: () {
                  setState(() {
                    lessonCompletionStatus[student]![lessonIndex] = true;
                  });
                  Navigator.of(context).pop();
                },
              ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                setState(() {
                  lessons[student]![lessonIndex] = _textController.text;
                  lessonDescriptions[student]![lessonIndex] =
                      _descriptionController.text;
                  lessonDates[student]![lessonIndex] = _lessonDate;
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

  void _addNewLesson(BuildContext context, String student) {
    TextEditingController _textController = TextEditingController();
    TextEditingController _descriptionController = TextEditingController();
    DateTime _lessonDate = DateTime.now();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Lesson'),
          content: Column(
            children: [
              TextField(
                controller: _textController,
                decoration: InputDecoration(hintText: "Enter new lesson info"),
              ),
              TextField(
                controller: _descriptionController,
                decoration:
                    InputDecoration(hintText: "Enter short description"),
              ),
              ElevatedButton(
                child: Text("Select Date"),
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Students Roadmap'),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _students.length, // Use _students here
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
            TableCalendar(
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
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _addNewStudent(context);
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }
}
