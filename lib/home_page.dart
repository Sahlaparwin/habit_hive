import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'habit_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  CollectionReference? _habitCollection;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _habitCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('habits');
    } else {
      debugPrint("User not logged in!");
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ======================== Add Habit Dialog ========================
  void _addHabit() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Add Habit"),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 200,
            maxWidth: 300,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                TextField(
                  controller: _descController,
                  maxLines: null,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _gradientButton(
                label: "Cancel",
                onPressed: () {
                  _titleController.clear();
                  _descController.clear();
                  Navigator.pop(dialogContext);
                },
              ),
              _gradientButton(
                label: "Add",
                onPressed: () async {
                  if (_titleController.text.trim().isEmpty) return;

                  if (_habitCollection != null) {
                    try {
                      await _habitCollection!.add({
                        "title": _titleController.text.trim(),
                        "description": _descController.text.trim(),
                        "completedDates": [], // store completed dates
                        "timestamp": FieldValue.serverTimestamp(),
                      });
                    } catch (e) {
                      debugPrint("Error adding habit: $e");
                    }

                    _titleController.clear();
                    _descController.clear();

                    if (mounted) {
                      Navigator.of(dialogContext, rootNavigator: true).pop();
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gradientButton({required String label, required VoidCallback? onPressed}) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow, Colors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: onPressed == null ? Colors.grey[700] : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleCompletion(DocumentSnapshot habit) async {
    try {
      final String today = DateTime.now().toIso8601String().split('T')[0];
      List completedDates = List.from(habit['completedDates'] ?? []);

      if (completedDates.contains(today)) {
        // Uncheck for today
        completedDates.remove(today);
      } else {
        // Mark done for today
        completedDates.add(today);
      }

      await _habitCollection!.doc(habit.id).update({
        "completedDates": completedDates,
      });
    } catch (e) {
      debugPrint("Error updating habit: $e");
    }
  }

  void _deleteHabit(DocumentSnapshot habit) async {
    try {
      await _habitCollection!.doc(habit.id).delete();
    } catch (e) {
      debugPrint("Error deleting habit: $e");
    }
  }

  Widget _buildHabitCard(DocumentSnapshot habit) {
    final String today = DateTime.now().toIso8601String().split('T')[0];
    List completedDates = List.from(habit['completedDates'] ?? []);
    final bool completedToday = completedDates.contains(today);

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            decoration: completedToday ? TextDecoration.lineThrough : null,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          child: Text(habit['title']),
        ),
        subtitle: Text(habit['description']),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: completedToday,
              onChanged: (_) => _toggleCompletion(habit),
              activeColor: Colors.amber[700],
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteHabit(habit),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HabitDetailPage(
                habitId: habit.id,
                habitData: habit,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          title: const Text("Your Habits"),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      body: _habitCollection == null
          ? const Center(child: Text("User not logged in."))
          : StreamBuilder<QuerySnapshot>(
              stream: _habitCollection!
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No habits yet. Add one!"));
                }

                final habits = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
                    return _buildHabitCard(habits[index]);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}
