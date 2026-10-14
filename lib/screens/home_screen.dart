import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _textController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;

  // اختيار صورة من المعرض
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // نشر الخاطرة مع الصورة في Firebase
  Future<void> _addPost() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() => _isUploading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      String imageUrl = '';

      // رفع الصورة إلى Firebase Storage إذا تم اختيارها
      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('post_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_selectedImage!);
        imageUrl = await ref.getDownloadURL();
      }

      // جلب اسم المستخدم الحالي
      final userData = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();

      // حفظ الخاطرة في Firestore
      await FirebaseFirestore.instance.collection('posts').add({
        'text': _textController.text.trim(),
        'imageUrl': imageUrl,
        'userId': user.uid,
        'username': userData.data()?['username'] ?? 'مستخدم',
        'createdAt': Timestamp.now(),
        'likes': [],
      });

      _textController.clear();
      setState(() {
        _selectedImage = null;
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل نشر الخاطرة: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // نافذة إضافة خاطرة
  void _showAddPostModal(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اكتب خاطرة جديدة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'عَبّر عما يدور في ذهنك...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_a_photo, color: Colors.deepPurple),
                  onPressed: _pickImage,
                ),
                if (_selectedImage != null)
                  const Text('تم اختيار صورة بنجاح', style: TextStyle(color: Colors.green))
                else
                  const Text('إضافة صورة (اختياري)'),
              ],
            ),
            const SizedBox(height: 15),
            if (_isUploading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: _addPost,
                child: const Text('نشر الخاطرة'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خواطر'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data?.docs ?? [];

          if (posts.isEmpty) {
            return const Center(child: Text('لا توجد خواطر بعد. كن أول من ينشر!'));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (ctx, index) {
              final post = posts[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            post['username'] ?? 'مستخدم',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        post['text'] ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (post['imageUrl'] != null && (post['imageUrl'] as String).isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            post['imageUrl'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            maxHeight: 250,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        onPressed: () => _showAddPostModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
