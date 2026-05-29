import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import 'app_panel.dart';

class MimoTaggedText extends StatelessWidget {
  const MimoTaggedText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.selectable = false,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final bool selectable;

  static final RegExp tagPattern = RegExp(
    r'[\(（][^\n\)）]{1,48}[\)）]|\[[^\n\]]{1,48}\]|【[^\n】]{1,48}】',
  );

  @override
  Widget build(BuildContext context) {
    final span = buildSpan(context, text, style: style);
    if (selectable) {
      return SelectableText.rich(span, maxLines: maxLines);
    }
    return Text.rich(span, maxLines: maxLines, overflow: overflow);
  }

  static TextSpan buildSpan(
    BuildContext context,
    String text, {
    TextStyle? style,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in tagPattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final token = match.group(0)!;
      final isAudioTag = token.startsWith('[') || token.startsWith('【');
      final color = isAudioTag ? scheme.tertiary : scheme.primary;
      final background = isAudioTag
          ? scheme.tertiaryContainer.withValues(alpha: 0.62)
          : scheme.primaryContainer.withValues(alpha: 0.72);
      spans.add(
        TextSpan(
          text: token,
          style: baseStyle.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            background: Paint()..color = background,
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return TextSpan(style: baseStyle, children: spans);
  }
}

class CopyableTaggedTextBlock extends StatefulWidget {
  const CopyableTaggedTextBlock({
    super.key,
    required this.title,
    required this.text,
    this.emptyText = '暂无内容',
    this.maxHeight,
    this.collapsible = false,
  });

  final String title;
  final String? text;
  final String emptyText;
  final double? maxHeight;
  final bool collapsible;

  @override
  State<CopyableTaggedTextBlock> createState() =>
      _CopyableTaggedTextBlockState();
}

class _CopyableTaggedTextBlockState extends State<CopyableTaggedTextBlock> {
  bool _expanded = false;

  void _copy(String displayText) {
    Clipboard.setData(ClipboardData(text: displayText));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${widget.title}已复制')));
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = widget.text?.trim();
    final displayText = value == null || value.isEmpty
        ? widget.emptyText
        : value;
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
          child: MimoTaggedText(
            displayText,
            selectable: true,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.72),
          ),
        ),
      ),
    );
    if (widget.collapsible && !_expanded) {
      return AppPanel(
        padding: const EdgeInsets.all(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _toggleExpanded,
          child: Row(
            children: <Widget>[
              AppHugeIcon(
                HugeIcons.strokeRoundedMagicWand02,
                size: 20,
                color: scheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MimoTaggedText(
                      displayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: value == null || value.isEmpty
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: '复制${widget.title}',
                onPressed: () => _copy(displayText),
                icon: const AppHugeIcon(HugeIcons.strokeRoundedCopy01),
              ),
              TextButton(onPressed: _toggleExpanded, child: const Text('展开')),
            ],
          ),
        ),
      );
    }
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: '复制${widget.title}',
                onPressed: () => _copy(displayText),
                icon: const AppHugeIcon(HugeIcons.strokeRoundedCopy01),
              ),
              if (widget.collapsible)
                TextButton(onPressed: _toggleExpanded, child: const Text('收起')),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.maxHeight == null)
            content
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: widget.maxHeight!),
              child: content,
            ),
        ],
      ),
    );
  }
}
