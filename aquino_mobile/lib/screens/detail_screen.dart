import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/comment_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/custom_font.dart';
import '../widgets/custom_inkwell_button.dart';
import '../widgets/custom_text_formfield.dart';

class DetailScreen extends StatefulWidget {
  final Post post;
  final bool liked;
  final bool disliked;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleDislike;

  const DetailScreen({
    super.key,
    required this.post,
    required this.liked,
    required this.disliked,
    required this.onToggleLike,
    required this.onToggleDislike,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final CommentService _commentService = CommentService();
  final UserService _userService = UserService();
  final TextEditingController _commentController = TextEditingController();

  late bool _liked;
  late bool _disliked;
  late Future<List<Comment>> _futureComments;
  List<Comment> _comments = <Comment>[];
  final Map<int, User> _commentAuthors = <int, User>{};
  final Set<int> _likedComments = <int>{};
  User? _author;
  User? _me;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.liked;
    _disliked = widget.disliked;
    _futureComments = _loadComments();
    _userService.getUserById(widget.post.userId).then((User? user) {
      if (mounted) setState(() => _author = user);
    });
    _userService.getUser().then((User? user) {
      if (mounted) setState(() => _me = user);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<List<Comment>> _loadComments() async {
    final List<Comment> comments = await _commentService.getCommentsByPost(
      widget.post.id,
    );
    _comments = comments;
    unawaited(_hydrateCommentAuthors(comments));
    return comments;
  }

  Future<void> _hydrateCommentAuthors(List<Comment> comments) async {
    for (final Comment comment in comments) {
      if (comment.userId == 0 || _commentAuthors.containsKey(comment.userId)) {
        continue;
      }
      final User? user = await _userService.getUserById(comment.userId);
      if (user != null && mounted) {
        setState(() => _commentAuthors[comment.userId] = user);
      }
    }
  }

  void _toggleLike() {
    setState(() {
      if (_liked) {
        _liked = false;
      } else {
        _liked = true;
        _disliked = false;
      }
    });
    widget.onToggleLike();
  }

  void _toggleDislike() {
    setState(() {
      if (_disliked) {
        _disliked = false;
      } else {
        _disliked = true;
        _liked = false;
      }
    });
    widget.onToggleDislike();
  }

  void _toggleCommentLike(Comment comment) {
    setState(() {
      if (_likedComments.contains(comment.id)) {
        _likedComments.remove(comment.id);
      } else {
        _likedComments.add(comment.id);
      }
    });
  }

  Future<void> _submitComment() async {
    final String text = _commentController.text.trim();
    if (text.isEmpty || _me == null) return;
    setState(() => _sending = true);
    try {
      final Comment created = await _commentService.addComment(
        postId: widget.post.id,
        userId: _me!.id,
        body: text,
      );
      final Comment display = created.username.isEmpty
          ? Comment(
              id: created.id,
              postId: widget.post.id,
              body: text,
              likes: 0,
              userId: _me!.id,
              username: _me!.username,
              fullName: _me!.fullName,
            )
          : created;
      setState(() {
        _comments.insert(0, display);
        _commentAuthors[_me!.id] = _me!;
        _commentController.clear();
      });
    } catch (error) {
      if (mounted) CustomDialogs.showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _buildPostHeader(Post post) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ImageProvider avatar = (_author?.image.isNotEmpty ?? false)
        ? CachedNetworkImageProvider(_author!.image) as ImageProvider
        : const AssetImage(kAvatarPlaceholder) as ImageProvider;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            CircleAvatar(radius: kAvatarRadius, backgroundImage: avatar),
            const SizedBox(width: kSmallPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CustomFont(
                    (_author?.fullName.isNotEmpty ?? false)
                        ? _author!.fullName
                        : 'Unknown user',
                    family: CustomFontFamily.primary,
                    fontSize: 15,
                  ),
                  CustomFont(
                    '@${_author?.username ?? '...'}',
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: kDefaultPadding),
        if (post.title.isNotEmpty) ...<Widget>[
          CustomFont(
            post.title,
            family: CustomFontFamily.primary,
            fontSize: 18,
          ),
          const SizedBox(height: 6),
        ],
        CustomFont(post.body, fontSize: 15),
        const SizedBox(height: kSmallPadding),
        Row(
          children: <Widget>[
            Icon(Icons.thumb_up, size: 14, color: scheme.primary),
            const SizedBox(width: 4),
            CustomFont(
              '${post.likes} likes',
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: kSpace16),
            CustomFont(
              '${post.dislikes} dislikes',
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
        const Divider(),
        Row(
          children: <Widget>[
            CustomInkwellButton(
              icon: _liked ? Icons.thumb_up : Icons.thumb_up_outlined,
              label: 'Like',
              color: _liked ? scheme.primary : null,
              onTap: _toggleLike,
            ),
            CustomInkwellButton(
              icon: _disliked ? Icons.thumb_down : Icons.thumb_down_outlined,
              label: 'Dislike',
              color: _disliked ? scheme.onSurfaceVariant : null,
              onTap: _toggleDislike,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComment(Comment comment) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final User? author = _commentAuthors[comment.userId];
    final bool liked = _likedComments.contains(comment.id);
    final int displayLikes = comment.likes + (liked ? 1 : 0);
    final ImageProvider avatar = (author?.image.isNotEmpty ?? false)
        ? CachedNetworkImageProvider(author!.image) as ImageProvider
        : const AssetImage(kAvatarPlaceholder) as ImageProvider;
    final String name = (author?.fullName.isNotEmpty ?? false)
        ? author!.fullName
        : (comment.fullName.isNotEmpty ? comment.fullName : comment.username);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpace8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(radius: 16, backgroundImage: avatar),
          const SizedBox(width: kSpace8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kSpace12,
                    vertical: kSpace8,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(kBorderRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      CustomFont(
                        name.isEmpty ? 'Anonymous' : name,
                        family: CustomFontFamily.primary,
                        fontSize: 13,
                      ),
                      const SizedBox(height: kSpace4),
                      CustomFont(comment.body, fontSize: 14),
                    ],
                  ),
                ),
                const SizedBox(height: kSpace4),
                Row(
                  children: <Widget>[
                    GestureDetector(
                      onTap: () => _toggleCommentLike(comment),
                      child: CustomFont(
                        liked ? 'Liked' : 'Like',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: liked ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: kSpace16),
                    CustomFont(
                      '$displayLikes',
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentComposer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(kSmallPadding),
        child: Row(
          children: <Widget>[
            Expanded(
              child: CustomTextFormField(
                controller: _commentController,
                label: 'Write a comment…',
              ),
            ),
            const SizedBox(width: kSmallPadding),
            _sending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _me == null ? null : _submitComment,
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Post displayPost = widget.post.copyWith(
      likes: widget.post.likes + (_liked ? 1 : 0),
      dislikes: widget.post.dislikes + (_disliked ? 1 : 0),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: FutureBuilder<List<Comment>>(
              future: _futureComments,
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<Comment>> snapshot,
                  ) {
                    final bool loading =
                        snapshot.connectionState == ConnectionState.waiting;
                    return ListView(
                      padding: const EdgeInsets.all(kDefaultPadding),
                      children: <Widget>[
                        _buildPostHeader(displayPost),
                        const Divider(height: kDefaultPadding * 2),
                        const CustomFont(
                          'Comments',
                          family: CustomFontFamily.primary,
                          fontSize: 16,
                        ),
                        const SizedBox(height: kSmallPadding),
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: kDefaultPadding,
                            ),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (snapshot.hasError)
                          CustomFont(
                            'Failed to load comments.',
                            color: Theme.of(context).colorScheme.error,
                          )
                        else if (_comments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: kSpace16,
                            ),
                            child: CustomFont(
                              'No comments yet. Be the first to comment!',
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          )
                        else
                          ..._comments.map<Widget>(_buildComment),
                      ],
                    );
                  },
            ),
          ),
          _buildCommentComposer(),
        ],
      ),
    );
  }
}
