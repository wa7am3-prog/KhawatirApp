import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final _bioController = TextEditingController();
  bool _isEditingBio = false;

  // تحديث النبذة الشخصية في Firestore
  Future<void> _updateBio() async {
    if (_bioController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .update({'bio': _bioController.text.trim()});

    setState(() {
      _isEditingBio = false;
    });
  }

  // حذف خاطرة تخص المستخدم
  Future<void> _deletePost(String postId) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (ctx) => const AuthScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (ctx, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          final username = userData['username'] ?? 'مستخدم';
          final email = userData['email'] ?? currentUser?.email ?? '';
          final bio = userData['bio'] ?? 'أهلاً بك في عالم الخواطر!';

          if (!_isEditingBio) {
            _bioController.text = bio;
          }

          return Column(
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                username,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                email,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _isEditingBio
                          ? TextField(
                              controller: _bioController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'اكتب نبذة عنك...',
                              ),
                            )
                          : Text(
                              bio,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                            ),
                    ),
                    IconButton(
                      icon: Icon(_isEditingBio ? Icons.check : Icons.edit, color: Colors.deepPurple),
                      onPressed: () {
                        if (_isEditingBio) {
                          _updateBio();
                        } else {
                          setState(() {
                            _isEditingBio = true;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 30, thickness: 1),
              const Text(
                'خواطري المنشورة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where('userId', isEqualTo: currentUser!.uid)
                      .snapshots(),
                  builder: (ctx, postSnapshot) {
                    if (postSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final posts = postSnapshot.data?.docs ?? [];

                    if (posts.isEmpty) {
                      return const Center(child: Text('لم تقم بنشر أي خواطر بعد.'));
                    }

                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (ctx, index) {
                        final post = posts[index].data() as Map<String, dynamic>;
                        final postId = posts[index].id;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            title: Text(post['text'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePost(postId),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
