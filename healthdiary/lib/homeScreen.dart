import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthdiaryapp/screens/dailylogs.dart';
import 'package:healthdiaryapp/screens/healthtracker.dart';
import 'package:healthdiaryapp/screens/reminder.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  _HomescreenState createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Diary App'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(displayName),
              accountEmail: Text(user?.email ?? 'No email'),
              currentAccountPicture: CircleAvatar(
                child: Text(
                  displayName[0],
                  style: const TextStyle(fontSize: 40.0),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Daily Logs'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DailyLogsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety),
              title: const Text('Health Tracking'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HealthTrackingScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.alarm),
              title: const Text('Reminders'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RemindersScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<bool>(
        future: _isNewUser(user?.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == true) {
            return Container(
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Welcome to Health Diary App!'),
                    const SizedBox(height: 8),
                    Text(
                      'This app helps you track your daily health logs, health metrics, and set reminders.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click the menu bar to enter your information.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'After you enter your data refresh the screen to read your Data',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return _buildUserContent(user);
        },
      ),
    );
  }

  Future<bool> _isNewUser(String? uid) async {
    if (uid == null) return true;

    final healthTracking = await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('HealthTracking')
        .get();

    final dailyLogs = await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('DailyLogs')
        .get();

    final reminders = await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('Reminders')
        .get();

    return healthTracking.docs.isEmpty && dailyLogs.docs.isEmpty && reminders.docs.isEmpty;
  }

  Widget _buildUserContent(User? user) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(user?.uid)
                .collection('HealthTracking')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No health tracking data available.'));
              }
              final doc = snapshot.data!.docs.first;
              final data = doc.data();
              final content = "Blood Pressure: ${data['bloodPressure']}, "
                  "Heart Rate: ${data['heartRate']}, Blood Sugar: ${data['bloodSugar']}";
              return _buildInfoCard(
                context: context,
                title: 'Latest Health Tracking',
                content: content,
                color: Colors.green[50]!,
                docId: doc.id,
                collection: 'HealthTracking',
              );
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(user?.uid)
                .collection('DailyLogs')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No daily logs available.'));
              }
              final doc = snapshot.data!.docs.first;
              final data = doc.data();
              final content = "Mood: ${data['mood']}, Food: ${data['food']}, "
                  "Exercise: ${data['exercise']}, Sleep: ${data['sleep']}, "
                  "Symptoms: ${data['symptoms']}";
              return _buildInfoCard(
                context: context,
                title: 'Latest Daily Log',
                content: content,
                color: Colors.blue[50]!,
                docId: doc.id,
                collection: 'DailyLogs',
              );
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(user?.uid)
                .collection('Reminders')
                .orderBy('datetime')
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No upcoming reminders.'));
              }
              final doc = snapshot.data!.docs.first;
              final data = doc.data();
              final dateTime = data['datetime'].toDate();
              final formattedDate = "${dateTime.year}-${dateTime.month}-${dateTime.day}";
              final formattedTime = "${dateTime.hour}:${dateTime.minute}";
              final content = "${data['reminder']} on $formattedDate at $formattedTime";
              return _buildInfoCard(
                context: context,
                title: 'Next Reminder',
                content: content,
                color: Colors.yellow[50]!,
                docId: doc.id,
                collection: 'Reminders',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required String content,
    required Color color,
    required String docId,
    required String collection,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(content),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _editData(context, docId, collection, content),
                child: const Text('Edit'),
              ),
              TextButton(
                onPressed: () => _deleteData(docId, collection),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editData(BuildContext context, String docId, String collection, String currentContent) async {
    TextEditingController controller = TextEditingController(text: currentContent);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Data'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Update your data'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('Users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection(collection)
                  .doc(docId)
                  .update({'content': controller.text});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteData(String docId, String collection) async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection(collection)
        .doc(docId)
        .delete();
  }
}