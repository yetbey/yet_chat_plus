import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:yet_chat_plus/controller/post_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/post_model.dart';
import 'package:yet_chat_plus/models/comment_model.dart';
import 'package:yet_chat_plus/main/components/post_card.dart';

class DetailedPostScreen extends StatefulWidget {
  final PostModel post;
  const DetailedPostScreen({super.key, required this.post});

  @override
  State<DetailedPostScreen> createState() => _DetailedPostScreenState();
}

class _DetailedPostScreenState extends State<DetailedPostScreen> {
  final PostController postController = Get.find();
  final TextEditingController _commentController = TextEditingController();
  late Future<List<CommentModel>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _commentsFuture = postController.getComments(widget.post.id);
  }

  void _postComment() {
    if (_commentController.text.trim().isEmpty) return;

    postController.addComment(widget.post.id, _commentController.text.trim()).then((_) {
      // Yorumu gönderdikten sonra alanı temizle ve listeyi yenile
      _commentController.clear();
      setState(() {
        _commentsFuture = postController.getComments(widget.post.id);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gönderi')),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Gönderinin kendisini gösteren bölüm
                SliverToBoxAdapter(
                  child: PostCard(postModel: widget.post, isDetailView: true,), // PostCard'ı burada yeniden kullanabiliriz
                ),
                // Yorumları listeleyen bölüm
                SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(8.0), child: Text('Yorumlar', style: Theme.of(context).textTheme.titleMedium))),
                FutureBuilder<List<CommentModel>>(
                  future: _commentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Henüz yorum yok.'))));
                    }
                    final comments = snapshot.data!;
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final comment = comments[index];
                          return ListTile(
                            leading: CircleAvatar(backgroundImage: NetworkImage(comment.userProfileImage ?? '')),
                            title: Text(comment.userName, style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(comment.content),
                          );
                        },
                        childCount: comments.length,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Yorum yazma alanı
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Yorum ekle...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _postComment,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
