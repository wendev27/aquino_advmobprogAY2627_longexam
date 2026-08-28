import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/custom_font.dart';
import '../widgets/post_card.dart';
import 'detail_screen.dart';
import 'profile_screen.dart';

class NewsfeedScreen extends StatefulWidget {
  const NewsfeedScreen({super.key});

  @override
  State<NewsfeedScreen> createState() => _NewsfeedScreenState();
}

class _NewsfeedScreenState extends State<NewsfeedScreen> {
  final PostService _postService = PostService();
  final UserService _userService = UserService();

  late Future<List<Post>> _futurePosts;
  List<Post> _posts = <Post>[];
  final Map<int, User> _authors = <int, User>{};
  final Set<int> _liked = <int>{};
  final Set<int> _disliked = <int>{};
  User? _me;
  bool _posting = false;
  final TextEditingController _composer = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futurePosts = _loadPosts();
    _userService.getUser().then((User? user) {
      if (mounted) setState(() => _me = user);
    });
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<List<Post>> _loadPosts() async {
    final List<Post> posts = await _postService.getPosts(
      limit: kFeedPageLimit * 3,
    );
    _posts = posts;
    unawaited(_hydrateAuthors(posts));
    return posts;
  }

  Future<void> _hydrateAuthors(List<Post> posts) async {
    final Set<int> ids = posts.map((Post p) => p.userId).toSet();
    for (final int id in ids) {
      if (_authors.containsKey(id)) continue;
      final User? user = await _userService.getUserById(id);
      if (user != null && mounted) setState(() => _authors[id] = user);
    }
  }

  Future<void> _refresh() async {
    setState(() => _futurePosts = _loadPosts());
    await _futurePosts;
  }

  void _toggleLike(int postId) {
    setState(() {
      if (_liked.contains(postId)) {
        _liked.remove(postId);
      } else {
        _liked.add(postId);
        _disliked.remove(postId);
      }
    });
  }

  void _toggleDislike(int postId) {
    setState(() {
      if (_disliked.contains(postId)) {
        _disliked.remove(postId);
      } else {
        _disliked.add(postId);
        _liked.remove(postId);
      }
    });
  }

  Future<void> _openComposer() async {
    if (_me == null) return;
    _composer.clear();
    final bool? shouldPost = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(kBorderRadius),
        ),
      ),
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: kSpace16,
          right: kSpace16,
          top: kSpace16,
          bottom: MediaQuery.of(context).viewInsets.bottom + kSpace16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const CustomFont(
              'Create post',
              family: CustomFontFamily.primary,
              fontSize: 18,
            ),
            const SizedBox(height: kSpace16),
            TextField(
              controller: _composer,
              autofocus: true,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "What's on your mind, ${_me!.firstName}?",
              ),
            ),
            const SizedBox(height: kSpace16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Post'),
            ),
            const SizedBox(height: kSpace8),
          ],
        ),
      ),
    );
    if (shouldPost == true && _composer.text.trim().isNotEmpty && mounted) {
      await _submitPost(_composer.text.trim());
    }
  }

  Future<void> _submitPost(String body) async {
    setState(() => _posting = true);
    try {
      final Post created = await _postService.addPost(
        title: body.length > 40 ? '${body.substring(0, 40)}…' : body,
        body: body,
        userId: _me!.id,
      );
      setState(() {
        _posts.insert(0, created);
        _authors[_me!.id] = _me!;
      });
    } catch (error) {
      if (mounted) CustomDialogs.showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  void _openPost(Post post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailScreen(
          post: post,
          liked: _liked.contains(post.id),
          disliked: _disliked.contains(post.id),
          onToggleLike: () => _toggleLike(post.id),
          onToggleDislike: () => _toggleDislike(post.id),
        ),
      ),
    );
  }

  void _openAuthor(int userId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ProfileScreen(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: _futurePosts,
      builder: (BuildContext context, AsyncSnapshot<List<Post>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final ColorScheme scheme = Theme.of(context).colorScheme;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(kSpace16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.error_outline, color: scheme.error, size: 32),
                  const SizedBox(height: kSpace12),
                  const CustomFont('Failed to load the newsfeed.'),
                  const SizedBox(height: kSpace8),
                  CustomFont(
                    snapshot.error.toString(),
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: kSpace16),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(kSpace16),
            children: <Widget>[
              if (_me != null)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: _me!.image.isNotEmpty
                          ? CachedNetworkImageProvider(_me!.image)
                                as ImageProvider
                          : const AssetImage(kAvatarPlaceholder)
                                as ImageProvider,
                    ),
                    title: Text("What's on your mind, ${_me!.firstName}?"),
                    trailing: _posting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.edit_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    onTap: _posting ? null : _openComposer,
                  ),
                ),
              const SizedBox(height: kSpace16),
              if (_posts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: kSpace32),
                  child: Center(
                    child: CustomFont(
                      'No posts yet.',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ..._posts.map<Widget>((Post post) {
                  final bool liked = _liked.contains(post.id);
                  final bool disliked = _disliked.contains(post.id);
                  final Post displayPost = post.copyWith(
                    likes: post.likes + (liked ? 1 : 0),
                    dislikes: post.dislikes + (disliked ? 1 : 0),
                  );
                  return PostCard(
                    post: displayPost,
                    author: _authors[post.userId],
                    liked: liked,
                    disliked: disliked,
                    onTap: () => _openPost(post),
                    onLike: () => _toggleLike(post.id),
                    onDislike: () => _toggleDislike(post.id),
                    onAuthorTap: () => _openAuthor(post.userId),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
