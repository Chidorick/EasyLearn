import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  static Student fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
    );
  }
}

class Lesson {
  int id;
  int studentId;
  String title;
  String description;
  bool completionStatus;
  DateTime date;

  Lesson({
    required this.id,
    required this.studentId,
    required this.title,
    required this.description,
    required this.completionStatus,
    required this.date,
  });

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
  bool _isDateWithLesson(DateTime date) {
    return lessonDates.values.any((lessonList) =>
        lessonList.any((lessonDate) => isSameDay(lessonDate, date)));
  }

  void _addNewStudent(BuildContext context) {
    TextEditingController _textController = TextEditingController();
    String? _selectedExam =
        'ЕГЭ по математике';
    List<String> _exams = ['ЕГЭ по математике', '-'];

    List<Lesson> defaultLessons = [
      Lesson(
        id: 1,
        studentId: 0,
        title: 'Основы ',
        description: 'Введение в ЕГЭ по математике',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 1)),
      ),
      Lesson(
        id: 2,
        studentId: 0,
        title: 'Линейные уравнения',
        description: 'Решение линейных уравнений и их систем',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 2)),
      ),
      Lesson(
        id: 3,
        studentId: 0,
        title: 'Логарифмы',
        description: 'Изучение логарифмических функций и их применений',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 20)),
      ),
      Lesson(
        id: 4,
        studentId: 0,
        title: 'Векторы',
        description: 'Основы векторной алгебры и их применения',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 4)),
      ),
      Lesson(
        id: 5,
        studentId: 0,
        title: 'Комплексные числа',
        description: 'Введение в комплексные числа и их свойства',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 5)),
      ),
      Lesson(
        id: 6,
        studentId: 0,
        title: 'Теорема Пифагора',
        description: 'Изучение теоремы Пифагора и её применений',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 6)),
      ),
      Lesson(
        id: 7,
        studentId: 0,
        title: 'Прогрессии',
        description: 'Арифметические и геометрические прогрессии',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 7)),
      ),
      Lesson(
        id: 8,
        studentId: 0,
        title: 'Геометрия',
        description: 'Изучение основных геометрических фигур и теорем',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 8)),
      ),
      Lesson(
        id: 9,
        studentId: 0,
        title: 'Тригонометрические функции',
        description:
            'Изучение синуса, косинуса и других тригонометрических функций',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 9)),
      ),
      Lesson(
        id: 10,
        studentId: 0,
        title: 'Площади фигур',
        description:
            'Изучение методов нахождения площадей геометрических фигур',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 10)),
      ),
      Lesson(
        id: 11,
        studentId: 0,
        title: 'Объемы тел',
        description: 'Расчет объемов пространственных геометрических тел',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 11)),
      ),
      Lesson(
        id: 12,
        studentId: 0,
        title: 'Неравенства',
        description: 'Решение различных типов неравенств',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 12)),
      ),
      Lesson(
        id: 13,
        studentId: 0,
        title: 'Планиметрия',
        description: 'Изучение свойств плоских фигур',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 13)),
      ),
      Lesson(
        id: 14,
        studentId: 0,
        title: 'Стереометрия',
        description: 'Изучение свойств пространственных фигур',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 14)),
      ),
      Lesson(
        id: 15,
        studentId: 0,
        title: 'Теория чисел',
        description: 'Основы теории чисел и делители',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 15)),
      ),
      Lesson(
        id: 16,
        studentId: 0,
        title: 'Математическая статистика',
        description:
            'Изучение методов математической статистики и их применения',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 16)),
      ),
      Lesson(
        id: 17,
        studentId: 0,
        title: 'Дифференциальные уравнения',
        description: 'Основы дифференциальных уравнений и методы их решения',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 17)),
      ),
      Lesson(
        id: 18,
        studentId: 0,
        title: 'Геометрическая оптика',
        description:
            'Понимание принципов геометрической оптики и их математическое описание',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 18)),
      ),
      Lesson(
        id: 19,
        studentId: 0,
        title: 'Элементы топологии',
        description:
            'Введение в элементы топологии и их математическое применение',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 19)),
      ),
      Lesson(
        id: 20,
        studentId: 0,
        title: 'Математическое моделирование',
        description:
            'Знакомство с основами математического моделирования и его использование в различных задачах',
        completionStatus: false,
        date: DateTime.now().add(Duration(days: 20)),
      ),
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Добавить нового студента'),
          content: Column(
            children: [
              TextField(
                controller: _textController,
                decoration: InputDecoration(hintText: "Введите имя студента"),
              ),
              DropdownButton<String>(
                value: _selectedExam,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedExam = newValue;
                  });
                },
                items: _exams.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
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
            TextButton(
              child: Text('Добавить'),
              onPressed: () async {
                int id = 0;
                String name = _textController.text;

                Student newStudent = Student(id: id, name: name);

                final Database db = await DatabaseHelper.instance.database;

                await db.insert(
                  'students',
                  newStudent.toMap(),
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );

                // Update the studentId for each default lesson
                for (var lesson in defaultLessons) {
                  lesson.studentId = id;
                  await db.insert(
                    'lessons',
                    lesson.toMap(),
                    conflictAlgorithm: ConflictAlgorithm.replace,
                  );
                }

                setState(() {
                  _students.add(newStudent);
                  lessons[newStudent.name] =
                      defaultLessons.map((lesson) => lesson.title).toList();
                  lessonDescriptions[newStudent.name] = defaultLessons
                      .map((lesson) => lesson.description)
                      .toList();
                  lessonCompletionStatus[newStudent.name] = defaultLessons
                      .map((lesson) => lesson.completionStatus)
                      .toList();
                  lessonDates[newStudent.name] =
                      defaultLessons.map((lesson) => lesson.date).toList();
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                      hintText: "Введите новую информацию об уроке"),
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
                        _lessonDate = picked;
                        lessonDates[student]![lessonIndex] = picked;
                      });
                    }
                  },
                )
              ],
            ),
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
                  _selectedDay = _lessonDate;
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
                decoration: InputDecoration(
                    hintText: "Введите новую информацию об уроке"),
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
                  _selectedDay = _lessonDate;
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
          title: Text('Вход'),
          content: Column(
            children: <Widget>[
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(hintText: 'Имя пользователя'),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(hintText: 'Пароль'),
                obscureText: true,
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
            TextButton(
              child: Text('Войти'),
              onPressed: () async {
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
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Регистрация'),
          content: Column(
            children: <Widget>[
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(hintText: 'Имя'),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(hintText: 'Пароль'),
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
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Ок'),
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDayStatus(BuildContext context, DateTime selectedDay) {
    final lessonsOnSelectedDay = lessonDates.entries
        .where((entry) =>
            entry.value.any((lessonDate) => isSameDay(lessonDate, selectedDay)))
        .map((entry) => entry.key)
        .toList();

    final studentNamesOnSelectedDay = _students
        .where((student) => lessonsOnSelectedDay.contains(student.name))
        .map((student) => student.name)
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Статус дня'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: studentNamesOnSelectedDay.isNotEmpty
                  ? studentNamesOnSelectedDay.map((name) {
                      int lessonIndex = lessonDates[name]!.indexWhere(
                          (lessonDate) => isSameDay(lessonDate, selectedDay));
                      return InkWell(
                        onTap: () {
                          if (lessonIndex != -1) {
                            _showEditDialog(context, name, lessonIndex);
                          }
                        },
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(name),
                              Text('Занято'),
                            ],
                          ),
                        ),
                      );
                    }).toList()
                  : [Text('День свободен')],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Oк'),
              onPressed: () {
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
        body: SingleChildScrollView(
          child: Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
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
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(
                                  lessons[studentName]!.length * 2,
                                  (i) {
                                    if (i.isEven) {
                                      return GestureDetector(
                                        onTap: () {
                                          _showEditDialog(
                                              context, studentName, i ~/ 2);
                                        },
                                        onLongPress: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text(
                                                    'Образовательные ресурсы'),
                                                content: SingleChildScrollView(
                                                  child: ListBody(
                                                    children: <Widget>[
                                                      InkWell(
                                                        child: Text(
                                                            'Материалы для подготовки по математике: лекции и решение задач'),
                                                        onTap: () => launch(
                                                            'https://ege-study.ru/ru/ege/materialy/matematika/'),
                                                      ),
                                                      SizedBox(height: 10),
                                                      InkWell(
                                                        child: Text(
                                                            'Материалы для подготовки к ЕГЭ по математике'),
                                                        onTap: () => launch(
                                                            'https://ege-study.ru/ru/ege/materialy/matematika/'),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                actions: <Widget>[
                                                  TextButton(
                                                    child: Text('Закрыть'),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: tick(lessonCompletionStatus[
                                            studentName]![i ~/ 2]),
                                      );
                                    } else {
                                      return Row(
                                        children: [spacer(), line(), spacer()],
                                      );
                                    }
                                  },
                                ),
                              ),
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
                        _showDayStatus(context, selectedDay);
                      },
                      calendarBuilders: CalendarBuilders(
                        selectedBuilder: (context, date, _) {
                          if (_lessonDay != null &&
                              isSameDay(_lessonDay, date)) {
                            return Container(
                              margin: const EdgeInsets.all(4.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
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
                        todayBuilder: (context, date, _) {
                          if (isSameDay(_selectedDay, date)) {
                            return Container(
                              margin: const EdgeInsets.all(4.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
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
                        markerBuilder: (context, date, events) {
                          if (_isDateWithLesson(date)) {
                            return Positioned(
                              right: 1,
                              bottom: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                                width: 7,
                                height: 7,
                              ),
                            );
                          }
                        },
                      )))
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: CircularNotchedRectangle(),
          notchMargin: 6.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: () {
                  setState(() {
                    _isCalendarVisible = !_isCalendarVisible;
                  });
                },
              ),
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
