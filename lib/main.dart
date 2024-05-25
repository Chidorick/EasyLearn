import 'package:flutter/material.dart';
import 'package:timelines/timelines.dart';
import 'package:table_calendar/table_calendar.dart';

void main() => runApp(MaterialApp(home: Roadmap()));

class Roadmap extends StatefulWidget {
  @override
  _RoadmapState createState() => _RoadmapState();
}

class _RoadmapState extends State<Roadmap> {
  final List<String> students = ['Student 1', 'Student 2', 'Student 3'];
  Map<String, List<String>> lessons = {
    'Student 1': ['Lesson 1', 'Lesson 2', 'Lesson 3'],
    'Student 2': ['Lesson 1', 'Lesson 2', 'Lesson 3'],
    'Student 3': ['Lesson 1', 'Lesson 2', 'Lesson 3']
  };
  Map<String, List<String>> lessonDescriptions = {
    'Student 1': ['Description 1', 'Description 2', 'Description 3'],
    'Student 2': ['Description 1', 'Description 2', 'Description 3'],
    'Student 3': ['Description 1', 'Description 2', 'Description 3']
  };
  Map<String, List<bool>> lessonCompletionStatus = {
    'Student 1': [false, false, false],
    'Student 2': [false, false, false],
    'Student 3': [false, false, false]
  };
  DateTime _selectedDay = DateTime.now();

  void _showEditDialog(BuildContext context, String student, int lessonIndex) {
    TextEditingController _textController =
        TextEditingController(text: lessons[student]![lessonIndex]);
    TextEditingController _descriptionController =
        TextEditingController(text: lessonDescriptions[student]![lessonIndex]);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Lesson'),
          content: Column(
            children: [
              TextField(
                controller: _textController,
                decoration: InputDecoration(hintText: "Enter new lesson info"),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(hintText: "Enter short description"),
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
                  lessonDescriptions[student]![lessonIndex] = _descriptionController.text;
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
                decoration: InputDecoration(hintText: "Enter short description"),
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
              child: Text('Add'),
              onPressed: () {
                setState(() {
                  lessons[student]!.add(_textController.text);
                  lessonDescriptions[student]!.add(_descriptionController.text);
                  lessonCompletionStatus[student]!.add(false);
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
                itemCount: students.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text(students[index]),
                          Expanded(
                            child: Row(
                              children: List.generate(
                                  lessons[students[index]]!.length * 2 - 1,
                                  (i) {
                                if (i.isEven) {
                                  return GestureDetector(
                                    onTap: () {
                                      _showEditDialog(
                                          context, students[index], i ~/ 2);
                                    },
                                    child: tick(lessonCompletionStatus[students[index]]![i ~/ 2]),
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
                              _addNewLesson(context, students[index]);
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
            ),
          ],
        ),
      ),
    );
  }
}