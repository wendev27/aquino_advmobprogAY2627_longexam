import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_font.dart';
import 'detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final PostService _postService = PostService();
  final UserService _userService = UserService();
  late Future<List<Post>> _futureActivity;
  final Map<int, User> _authors = <int, User>{};

  @override
  void initState() {
    super.initState();
    _futureActivity = _load();
  }

  Future<List<Post>> _load() async {
    final List<Post> posts = await _postService.getPosts(
      limit: kFeedPageLimit * 2,
    );
    posts.sort(
      (Post a, Post b) =>
          (b.likes + b.dislikes).compareTo(a.likes + a.dislikes),
    );
    final List<Post> withActivity = posts
        .where((Post p) => p.likes + p.dislikes > 0)
        .take(15)
        .toList();
    for (final Post post in withActivity) {
      if (_authors.containsKey(post.userId)) continue;
      final User? user = await _userService.getUserById(post.userId);
      if (user != null) _authors[post.userId] = user;
    }
    return withActivity;
  }

  Future<void> _refresh() async {
    setState(() => _futureActivity = _load());
    await _futureActivity;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: _futureActivity,
      builder: (BuildContext context, AsyncSnapshot<List<Post>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 32,
                ),
                const SizedBox(height: kSpace12),
                const CustomFont('Failed to load activity.'),
                const SizedBox(height: kSpace8),
                ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            ),
          );
        }
        final List<Post> posts = snapshot.data ?? <Post>[];
        if (posts.isEmpty) {
          return Center(
            child: CustomFont(
              'No recent activity yet.',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        }
        final ColorScheme scheme = Theme.of(context).colorScheme;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(kSpace16),
            itemCount: posts.length,
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
            itemBuilder: (BuildContext context, int index) {
              final Post post = posts[index];
              final User? author = _authors[post.userId];
              final String name = (author?.fullName.isNotEmpty ?? false)
                  ? author!.fullName
                  : 'Someone';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.thumb_up, color: scheme.primary, size: 18),
                ),
                title: CustomFont(
                  "$name's post is getting attention",
                  family: CustomFontFamily.primary,
                  fontSize: 14,
                ),
                subtitle: CustomFont(
                  '${post.likes} likes · ${post.dislikes} dislikes',
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DetailScreen(
                      post: post,
                      liked: false,
                      disliked: false,
                      onToggleLike: () {},
                      onToggleDislike: () {},
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
