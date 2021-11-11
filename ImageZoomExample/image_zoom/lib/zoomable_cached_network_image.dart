import 'package:flutter/material.dart';

import 'allow_multiple_horizontal_drag_recognizer.dart';
import 'allow_multiple_scale_recognizer.dart';
import 'allow_multiple_vertical_drag_recognizer.dart';

class ZoomableCachedNetworkImage extends StatelessWidget {
  final String url;

  Offset offset = Offset.zero;
  double scale = 1.0;

  ZoomableCachedNetworkImage(
      {Key? key,
      required this.url,
      this.offset = Offset.zero,
      this.scale = 1.0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ZoomablePhotoViewer(
      url: url,
      offset: offset,
      scale: scale,
    );
  }
}

class ZoomablePhotoViewer extends StatefulWidget {
  final String url;
  Offset offset = Offset.zero;
  double scale = 1.0;

  ZoomablePhotoViewer(
      {Key? key,
      required this.url,
      this.offset = Offset.zero,
      this.scale = 1.0})
      : super(key: key);

  @override
  _ZoomablePhotoViewerState createState() => _ZoomablePhotoViewerState();
}

class _ZoomablePhotoViewerState extends State<ZoomablePhotoViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _flingAnimation;
  late Offset _normalizedOffset;
  late double _previousScale;
  late HitTestBehavior behavior;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // The maximum offset value is 0,0. If the size of this renderer's box is w,h
  // then the minimum offset value is w - _scale * w, h - _scale * h.
  Offset _clampOffset(Offset offset) {
    final Size size = context.size!;
    final Offset minOffset =
        Offset(size.width, size.height) * (1.0 - widget.scale);
    return Offset(
        offset.dx.clamp(minOffset.dx, 0.0), offset.dy.clamp(minOffset.dy, 0.0));
  }

  void _handleFlingAnimation() {
    setState(() {
      widget.offset = _flingAnimation.value;
    });
  }

  void _handleOnScaleStart(ScaleStartDetails details) {
    setState(() {
      _previousScale = widget.scale;
      _normalizedOffset = (details.focalPoint - widget.offset) / widget.scale;
      // The fling animation stops if an input gesture starts.
      _controller.stop();
    });
  }

  void _handleOnScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      widget.scale = (_previousScale * details.scale).clamp(1.0, 4.0);
      // Ensure that image location under the focal point stays in the same place despite scaling.
      widget.offset =
          _clampOffset(details.focalPoint - _normalizedOffset * widget.scale);
    });
  }

  void _handleOnScaleEnd(ScaleEndDetails details) {
    const double _kMinFlingVelocity = 800.0;
    final double magnitude = details.velocity.pixelsPerSecond.distance;
    print('magnitude: ' + magnitude.toString());
    if (magnitude < _kMinFlingVelocity) return;
    final Offset direction = details.velocity.pixelsPerSecond / magnitude;
    final double distance = (Offset.zero & context.size!).shortestSide;
    _flingAnimation = Tween<Offset>(
            begin: widget.offset,
            end: _clampOffset(widget.offset + direction * distance))
        .animate(_controller);
    _controller
      ..value = 0.0
      ..fling(velocity: magnitude / 1000.0);
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        AllowMultipleScaleRecognizer:
            GestureRecognizerFactoryWithHandlers<AllowMultipleScaleRecognizer>(
          () => AllowMultipleScaleRecognizer(), //constructor
          (AllowMultipleScaleRecognizer instance) {
            //initializer
            instance.onStart = (details) => _handleOnScaleStart(details);
            instance.onEnd = (details) => _handleOnScaleEnd(details);
            instance.onUpdate = (details) => _handleOnScaleUpdate(details);
          },
        ),
        AllowMultipleHorizontalDragRecognizer:
            GestureRecognizerFactoryWithHandlers<
                AllowMultipleHorizontalDragRecognizer>(
          () => AllowMultipleHorizontalDragRecognizer(),
          (AllowMultipleHorizontalDragRecognizer instance) {
            instance.onStart =
                (details) => _handleHorizontalDragAcceptPolicy(instance);
            instance.onUpdate =
                (details) => _handleHorizontalDragAcceptPolicy(instance);
          },
        ),
        AllowMultipleVerticalDragRecognizer:
            GestureRecognizerFactoryWithHandlers<
                AllowMultipleVerticalDragRecognizer>(
          () => AllowMultipleVerticalDragRecognizer(),
          (AllowMultipleVerticalDragRecognizer instance) {
            instance.onStart =
                (details) => _handleVerticalDragAcceptPolicy(instance);
            instance.onUpdate =
                (details) => _handleVerticalDragAcceptPolicy(instance);
          },
        ),
      },
      //Creates the nested container within the first.
      behavior: HitTestBehavior.opaque,
      child: ClipRect(
        child: Transform(
          transform: Matrix4.identity()
            ..translate(widget.offset.dx, widget.offset.dy)
            ..scale(widget.scale),
          child: Image.network(
            widget.url,
          ),
        ),
      ),
    );
  }

  void _handleHorizontalDragAcceptPolicy(
      AllowMultipleHorizontalDragRecognizer instance) {
    widget.scale > 1.0
        ? instance.alwaysAccept = true
        : instance.alwaysAccept = false;
  }

  void _handleVerticalDragAcceptPolicy(
      AllowMultipleVerticalDragRecognizer instance) {
    widget.scale > 1.0
        ? instance.alwaysAccept = true
        : instance.alwaysAccept = false;
  }
}
