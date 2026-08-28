import 'package:flutter/material.dart';

class CustomLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const CustomLinkButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: color ?? scheme.primary),
      ),
    );
  }
}
