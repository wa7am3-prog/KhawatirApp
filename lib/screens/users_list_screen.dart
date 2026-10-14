import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المستخدمون المتواجدون'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final usersDocs = snapshot.data?.docs ?? [];

          // تصفية القائمة بحيث لا يظهر المستخدم الحالي لنفسه
          final otherUsers = usersDocs.where((doc) => doc.id != currentUserId).toList();

          if (otherUsers.isEmpty) {
            return const Center(
              child: Text(
                'لا يوجد مستخدمون آخرون مسجلون حالياً.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: otherUsers.length,
            itemBuilder: (ctx, index) {
              final userData = otherUsers[index].data() as Map<String, dynamic>;
              final peerId = otherUsers[index].id;
              final peerUsername = userData['username'] ?? 'مستخدم';
              final peerBio = userData['bio'] ?? 'أهلاً بك في عالم الخواطر!';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    peerUsername,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    peerBio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chat_bubble_outline, color: Colors.deepPurple),
                  onTap: () {
                    // الانتقال إلى شاشة الدردشة عند الضغط على المستخدم
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => ChatScreen(
                          peerId: peerId,
                          peerUsername: peerUsername,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
