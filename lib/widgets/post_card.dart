import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/post.dart';
import '../models/user.dart';
import 'custom_font.dart';
import 'custom_inkwell_button.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final User? author;
  final bool liked;
  final bool disliked;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback? onAuthorTap;

  const PostCard({
    super.key,
    required this.post,
    required this.author,
    required this.liked,
    required this.disliked,
    required this.onTap,
    required this.onLike,
    required this.onDislike,
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ImageProvider avatar = (author?.image.isNotEmpty ?? false)
        ? CachedNetworkImageProvider(author!.image) as ImageProvider
        : const AssetImage(kAvatarPlaceholder) as ImageProvider;

    return Card(
      margin: const EdgeInsets.only(bottom: kSpace12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(kSpace16, kSpace16, kSpace16, 0),
            child: InkWell(
              onTap: onAuthorTap,
              borderRadius: BorderRadius.circular(kBorderRadius),
              child: Row(
                children: <Widget>[
                  CircleAvatar(radius: kAvatarRadius, backgroundImage: avatar),
                  const SizedBox(width: kSpace12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        CustomFont(
                          (author?.fullName.isNotEmpty ?? false)
                              ? author!.fullName
                              : 'Unknown user',
                          family: CustomFontFamily.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        CustomFont(
                          '@${author?.username ?? '...'}',
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(kSpace16),
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (post.title.isNotEmpty) ...<Widget>[
                    CustomFont(
                      post.title,
                      family: CustomFontFamily.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: kSpace8),
                  ],
                  CustomFont(
                    post.body,
                    fontSize: 14,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (post.likes + post.dislikes > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpace16),
              child: Row(
                children: <Widget>[
                  Icon(Icons.thumb_up, size: 14, color: scheme.primary),
                  const SizedBox(width: kSpace4),
                  CustomFont(
                    '${post.likes}',
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                  const Spacer(),
                  CustomFont(
                    '${post.dislikes} dislikes',
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: kSpace16,
              vertical: kSpace8,
            ),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: kSpace4),
            child: Row(
              children: <Widget>[
                CustomInkwellButton(
                  icon: liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  label: 'Like',
                  color: liked ? scheme.primary : null,
                  onTap: onLike,
                ),
                CustomInkwellButton(
                  icon: disliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                  label: 'Dislike',
                  color: disliked ? scheme.onSurfaceVariant : null,
                  onTap: onDislike,
                ),
                CustomInkwellButton(
                  icon: Icons.mode_comment_outlined,
                  label: 'Comment',
                  onTap: onTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
