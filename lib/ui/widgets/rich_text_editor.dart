import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

class RichTextEditorController {
  late final QuillController _controller;

  RichTextEditorController(String? initialText) {
    _controller = QuillController.basic();

    try {
      _controller.document = initialText != null
          ? Document.fromJson(jsonDecode(initialText))
          : Document();
    } catch (_) {
      _controller.document = Document.fromDelta(Delta()
        ..insert(initialText)
        ..insert('\n'));
    }
  }

  String? get text => _controller.document.isEmpty()
      ? null
      : jsonEncode(_controller.document.toDelta().toJson());

  void dispose() {
    _controller.dispose();
  }
}

RichTextEditorController useRichTextEditorController(String? initialText) {
  final controller = useMemoized(() => RichTextEditorController(initialText));

  useEffect(() => controller.dispose, const []);

  return controller;
}

class RichTextEditor extends StatelessWidget {
  final RichTextEditorController controller;
  final String title;

  const RichTextEditor({
    required this.controller,
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // title
        Text(
          title,
          style: textTheme.labelMedium!.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),

        // toolbar
        _CustomToolbar(controller._controller),
        const SizedBox(height: 8),

        // editor
        QuillEditor.basic(
          controller: controller._controller,
          configurations: QuillEditorConfigurations(
            minHeight: 150,
            customStyles: DefaultStyles(
              h1: DefaultTextBlockStyle(
                Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 24,
                      letterSpacing: -0.5,
                      height: 1.083,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                HorizontalSpacing.zero,
                const VerticalSpacing(8, 0),
                VerticalSpacing.zero,
                null,
              ),
              h2: DefaultTextBlockStyle(
                Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 20,
                      letterSpacing: -0.4,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                HorizontalSpacing.zero,
                const VerticalSpacing(6, 0),
                VerticalSpacing.zero,
                null,
              ),
              h3: DefaultTextBlockStyle(
                Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 18,
                      letterSpacing: -0.2,
                      height: 1.11,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                HorizontalSpacing.zero,
                const VerticalSpacing(6, 0),
                VerticalSpacing.zero,
                null,
              ),
            ),
          ),
        ),
        Divider(
          color: Theme.of(context).colorScheme.primary,
          thickness: 0,
        ),
      ],
    );
  }
}

class _CustomToolbar extends StatelessWidget {
  final QuillController controller;

  const _CustomToolbar(this.controller);

  @override
  Widget build(BuildContext context) {
    return QuillToolbar(
      child: Container(
        constraints: const BoxConstraints.tightFor(
          height: 48,
        ),
        child: _QuillToolbarArrowIndicatedButtonList(
          axis: Axis.horizontal,
          buttons: [
            QuillToolbarHistoryButton(
              isUndo: true,
              controller: controller,
            ),
            QuillToolbarHistoryButton(
              isUndo: false,
              controller: controller,
            ),
            QuillToolbarToggleStyleButton(
              controller: controller,
              attribute: Attribute.bold,
            ),
            QuillToolbarToggleStyleButton(
              controller: controller,
              attribute: Attribute.italic,
            ),
            QuillToolbarToggleStyleButton(
              controller: controller,
              attribute: Attribute.underline,
            ),
            QuillToolbarToggleStyleButton(
              controller: controller,
              attribute: Attribute.strikeThrough,
            ),
            QuillToolbarSelectHeaderStyleDropdownButton(
              controller: controller,
            ),
            QuillToolbarToggleStyleButton(
              controller: controller,
              attribute: Attribute.ul,
            ),
            QuillToolbarLinkStyleButton(
              controller: controller,
            )
          ],
        ),
      ),
    );
  }
}

/// Scrollable list with arrow indicators.
///
/// The arrow indicators are automatically hidden if the list is not
/// scrollable in the direction of the respective arrow.
class _QuillToolbarArrowIndicatedButtonList extends StatefulWidget {
  const _QuillToolbarArrowIndicatedButtonList({
    required this.axis,
    required this.buttons,
  });

  final Axis axis;
  final List<Widget> buttons;

  @override
  _QuillToolbarArrowIndicatedButtonListState createState() =>
      _QuillToolbarArrowIndicatedButtonListState();
}

class _QuillToolbarArrowIndicatedButtonListState
    extends State<_QuillToolbarArrowIndicatedButtonList>
    with WidgetsBindingObserver {
  final ScrollController _controller = ScrollController();
  bool _showBackwardArrow = false;
  bool _showForwardArrow = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);

    // Listening to the WidgetsBinding instance is necessary so that we can
    // hide the arrows when the window gets a new size and thus the toolbar
    // becomes scrollable/unscrollable.
    WidgetsBinding.instance.addObserver(this);

    // Workaround to allow the scroll controller attach to our ListView so that
    // we can detect if overflow arrows need to be shown on init.
    Timer.run(_handleScroll);
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _buildBackwardArrow(),
      _buildScrollableList(),
      _buildForwardArrow(),
    ];

    return widget.axis == Axis.horizontal
        ? Row(
            children: children,
          )
        : Column(
            children: children,
          );
  }

  @override
  void didChangeMetrics() => _handleScroll();

  @override
  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleScroll() {
    if (!mounted) return;

    setState(() {
      _showBackwardArrow =
          _controller.position.minScrollExtent != _controller.position.pixels;
      _showForwardArrow =
          _controller.position.maxScrollExtent != _controller.position.pixels;
    });
  }

  Widget _buildBackwardArrow() {
    IconData? icon;
    if (_showBackwardArrow) {
      if (widget.axis == Axis.horizontal) {
        icon = Icons.arrow_left;
      } else {
        icon = Icons.arrow_drop_up;
      }
    }

    return SizedBox(
      width: 8,
      child: Transform.translate(
        // Move the icon a few pixels to center it
        offset: const Offset(-5, 0),
        child: icon != null ? Icon(icon, size: 18) : null,
      ),
    );
  }

  Widget _buildScrollableList() {
    return Expanded(
      child: ScrollConfiguration(
        // Remove the glowing effect, as we already have the arrow indicators
        behavior: _NoGlowBehavior(),
        // The CustomScrollView is necessary so that the children are not
        // stretched to the height of the toolbar:
        // https://stackoverflow.com/a/65998731/7091839
        child: CustomScrollView(
          scrollDirection: widget.axis,
          controller: _controller,
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: widget.axis == Axis.horizontal
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: widget.buttons,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: widget.buttons,
                    ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildForwardArrow() {
    IconData? icon;
    if (_showForwardArrow) {
      if (widget.axis == Axis.horizontal) {
        icon = Icons.arrow_right;
      } else {
        icon = Icons.arrow_drop_down;
      }
    }

    return SizedBox(
      width: 8,
      child: Transform.translate(
        // Move the icon a few pixels to center it
        offset: const Offset(-5, 0),
        child: icon != null ? Icon(icon, size: 18) : null,
      ),
    );
  }
}

/// ScrollBehavior without the Material glow effect.
class _NoGlowBehavior extends ScrollBehavior {
  Widget buildViewportChrome(BuildContext _, Widget child, AxisDirection __) {
    return child;
  }
}
