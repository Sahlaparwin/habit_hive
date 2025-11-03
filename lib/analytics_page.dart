import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  CollectionReference? _habitCollection;

  String _selectedView = 'Day'; // 'Day', 'Week', 'Month'
  final List<String> _views = ['Day', 'Week', 'Month'];

  final List<Color> _habitColors = [
    Colors.orange,
    Colors.yellow,
    Colors.brown,
    Colors.green,
    Colors.purple,
    Colors.blue,
    Colors.red,
  ];

  @override
  void initState() {
    super.initState();
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _habitCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('habits');
    }
  }

  Map<String, Map<String, int>> _processHabitData(
      List<QueryDocumentSnapshot> habits) {
    final Map<String, Map<String, int>> aggregated = {};

    for (var habit in habits) {
      final String title = habit['title'] ?? 'Unknown';
      final List completedDates = List.from(habit['completedDates'] ?? []);

      for (var dateStr in completedDates) {
        DateTime date = DateTime.tryParse(dateStr) ?? DateTime.now();
        String key;

        if (_selectedView == 'Day') {
          key = dateStr;
        } else if (_selectedView == 'Week') {
          final weekNumber = ((date.day - 1) ~/ 7) + 1;
          key = '${date.year}-${date.month.toString().padLeft(2, '0')}-W$weekNumber';
        } else {
          key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        }

        if (!aggregated.containsKey(key)) aggregated[key] = {};
        aggregated[key]![title] = (aggregated[key]![title] ?? 0) + 1;
      }
    }

    // Sort keys
    final sortedKeys = aggregated.keys.toList()..sort();
    return {for (var k in sortedKeys) k: aggregated[k]!};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.yellow, Colors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: const Text("Habit Analytics"),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      body: _habitCollection == null
          ? const Center(child: Text("User not logged in."))
          : StreamBuilder<QuerySnapshot>(
              stream: _habitCollection!.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No habits or completions yet."));
                }

                final aggregatedData = _processHabitData(snapshot.data!.docs);
                if (aggregatedData.isEmpty) {
                  return const Center(
                      child: Text("No completions yet. Mark habits as done!"));
                }

                final List<String> dates = aggregatedData.keys.toList();
                final List<String> habitTitles = aggregatedData.values
                    .expand((map) => map.keys)
                    .toSet()
                    .toList();

                final Map<String, Color> habitColorMap = {
                  for (int i = 0; i < habitTitles.length; i++)
                    habitTitles[i]: _habitColors[i % _habitColors.length]
                };

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _views.map((view) {
                          final isSelected = _selectedView == view;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isSelected ? Colors.orange : Colors.grey[300],
                                foregroundColor:
                                    isSelected ? Colors.white : Colors.black,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedView = view;
                                });
                              },
                              child: Text(view),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Habit Completions",
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 &&
                                        value.toInt() < dates.length) {
                                      String label = dates[value.toInt()];
                                      if (_selectedView == 'Day' &&
                                          label.length >= 5) {
                                        label = label.substring(label.length - 5);
                                      }
                                      return Text(label,
                                          style: const TextStyle(fontSize: 9));
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                            barGroups: List.generate(dates.length, (i) {
                              final date = dates[i];
                              final habitsOnDate = aggregatedData[date]!;
                              return BarChartGroupData(
                                x: i,
                                barRods: habitsOnDate.entries.map((entry) {
                                  return BarChartRodData(
                                    toY: entry.value.toDouble(),
                                    width: 12,
                                    color: habitColorMap[entry.key],
                                  );
                                }).toList(),
                                barsSpace: 4,
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: habitTitles.map((habit) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                  width: 12,
                                  height: 12,
                                  color: habitColorMap[habit]),
                              const SizedBox(width: 4),
                              Text(habit),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
