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
  Map<String, List<String>> goals = {
    'Student 1': ['Goal 1', 'Goal 2', 'Goal 3'],
    'Student 2': ['Goal 1', 'Goal 2', 'Goal 3'],
    'Student 3': ['Goal 1', 'Goal 2', 'Goal 3']
  };
  DateTime _selectedDay = DateTime.now();

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
                      child: Column(
                        children: [
                          Text(
                            students[index],
                          ),
                          FixedTimeline.tileBuilder(
                            theme: TimelineThemeData(
                              nodePosition: 0,
                              color: Colors.blueAccent,
                              indicatorTheme: IndicatorThemeData(
                                position: 0,
                                size: 20.0,
                              ),
                              connectorTheme: ConnectorThemeData(
                                thickness: 2.5,
                              ),
                            ),
                            builder: TimelineTileBuilder.connectedFromStyle(
                              contentsAlign: ContentsAlign.basic,
                              oppositeContentsBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Day ${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              contentsBuilder: (context, index) => Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    lessons[students[index]]![index],
                                  ),
                                ),
                              ),
                              connectorStyleBuilder: (context, index) =>
                                  ConnectorStyle.solidLine,
                              indicatorStyleBuilder: (context, index) =>
                                  IndicatorStyle.dot,
                              itemCount: lessons[students[index]]!.length,
                            ),
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