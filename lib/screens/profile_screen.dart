import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          Text(
            '我的學習',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 20),
          const Card(
            child: ListTile(
              contentPadding: EdgeInsets.all(18),
              leading: CircleAvatar(
                radius: 28,
                child: Icon(Icons.person),
              ),
              title: Text(
                'Language Learner',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('English · Tagalog / Taglish'),
            ),
          ),
          const SizedBox(height: 18),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.local_fire_department_outlined),
                  title: Text('連續學習'),
                  trailing: Text('3 天'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.book_outlined),
                  title: Text('已收藏句子'),
                  trailing: Text('28'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('已掌握'),
                  trailing: Text('11'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
