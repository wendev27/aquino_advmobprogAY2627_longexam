import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/custom_font.dart';
import '../widgets/custom_info.dart';
import '../widgets/post_card.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final PostService _postService = PostService();

  late Future<_ProfileData> _future;
  final Set<int> _liked = <int>{};
  final Set<int> _disliked = <int>{};

  bool get _isOwnProfile => widget.userId == null;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProfileData> _load() async {
    final User? me = await _userService.getUser();
    final int? targetId = widget.userId ?? me?.id;
    if (targetId == null) {
      return const _ProfileData(user: null, posts: <Post>[]);
    }
    final User? user = widget.userId == null
        ? me
        : await _userService.getUserById(targetId);
    final List<Post> posts = await _postService.getPostsByUser(targetId);
    return _ProfileData(user: user, posts: posts);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _logout() async {
    final bool confirmed = await CustomDialogs.confirm(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to see your newsfeed.',
      confirmLabel: 'Sign Out',
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (!confirmed || !mounted) return;
    await _userService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: _isOwnProfile
            ? <Widget>[
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: FutureBuilder<_ProfileData>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<_ProfileData> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final User? user = snapshot.data?.user;
          if (user == null) {
            return const Center(child: CustomFont('No profile data found.'));
          }
          final List<Post> posts = snapshot.data?.posts ?? const <Post>[];
          final ImageProvider avatar = user.image.isNotEmpty
              ? CachedNetworkImageProvider(user.image) as ImageProvider
              : const AssetImage(kAvatarPlaceholder) as ImageProvider;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(kDefaultPadding),
              children: <Widget>[
                Center(
                  child: CircleAvatar(radius: 52, backgroundImage: avatar),
                ),
                const SizedBox(height: kDefaultPadding),
                CustomFont(
                  user.fullName,
                  family: CustomFontFamily.primary,
                  fontSize: 22,
                  textAlign: TextAlign.center,
                ),
                Center(
                  child: CustomFont(
                    '@${user.username}',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: kDefaultPadding),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(kDefaultPadding),
                    child: Column(
                      children: <Widget>[
                        CustomInfo(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user.email,
                        ),
                        CustomInfo(
                          icon: Icons.wc_outlined,
                          label: 'Gender',
                          value: user.gender,
                        ),
                        CustomInfo(
                          icon: Icons.badge_outlined,
                          label: 'User ID',
                          value: '${user.id}',
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isOwnProfile) ...<Widget>[
                  const SizedBox(height: kDefaultPadding),
                  CustomButton(
                    label: 'Sign Out',
                    outlined: true,
                    color: Theme.of(context).colorScheme.error,
                    icon: Icons.logout,
                    onPressed: _logout,
                  ),
                ],
                const SizedBox(height: kDefaultPadding * 1.5),
                CustomFont(
                  _isOwnProfile ? 'Your Posts' : "${user.firstName}'s Posts",
                  family: CustomFontFamily.primary,
                  fontSize: 16,
                ),
                const SizedBox(height: kSmallPadding),
                if (posts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: kSpace16),
                    child: CustomFont(
                      'No posts yet.',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ...posts.map<Widget>((Post post) {
                    final bool liked = _liked.contains(post.id);
                    final bool disliked = _disliked.contains(post.id);
                    final Post displayPost = post.copyWith(
                      likes: post.likes + (liked ? 1 : 0),
                      dislikes: post.dislikes + (disliked ? 1 : 0),
                    );
                    return PostCard(
                      post: displayPost,
                      author: user,
                      liked: liked,
                      disliked: disliked,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DetailScreen(
                            post: post,
                            liked: liked,
                            disliked: disliked,
                            onToggleLike: () => _toggleLike(post.id),
                            onToggleDislike: () => _toggleDislike(post.id),
                          ),
                        ),
                      ),
                      onLike: () => _toggleLike(post.id),
                      onDislike: () => _toggleDislike(post.id),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileData {
  final User? user;
  final List<Post> posts;

  const _ProfileData({required this.user, required this.posts});
}
