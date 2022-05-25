import 'package:flutter/material.dart';

// import 'dashed_line_view.dart';

class VerticalSplitView extends StatefulWidget {
  final Widget left;
  final Widget right;
  final double ratio;
  final int leftMinWidth;
  final int rightMinWidth;
  final double dividerWidth;

  const VerticalSplitView(this.left, this.right,
      {this.ratio = 0.5, this.leftMinWidth = 0, this.rightMinWidth = 0, this.dividerWidth = 16});

  @override
  _VerticalSplitViewState createState() => _VerticalSplitViewState();
}

class _VerticalSplitViewState extends State<VerticalSplitView> {
  // from 0-1
  double _ratio = 0.0;
  double _minRatio = 0.0;
  double _maxRatio = 0.0;
  double _maxWidth = -1;

  get _width1 => _ratio * _maxWidth;
  get _width2 => (1 - _ratio) * _maxWidth;

  @override
  void initState() {
    super.initState();
    _ratio = widget.ratio;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, BoxConstraints constraints) {
      assert(_ratio <= 1);
      assert(_ratio >= 0);
      if (_maxWidth == -1) _maxWidth = constraints.maxWidth - widget.dividerWidth;
      if (_maxWidth != constraints.maxWidth) {
        _maxWidth = constraints.maxWidth - widget.dividerWidth;
      }
      _minRatio = widget.leftMinWidth / _maxWidth;
      _maxRatio = 1 - widget.rightMinWidth / _maxWidth;

      return SizedBox(
        width: constraints.maxWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: _width1,
              child: widget.left,
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              child: SizedBox(
                width: widget.dividerWidth,
                height: constraints.maxHeight,
                // child: Align(
                //   alignment: Alignment.bottomCenter,
                child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: VerticalDivider(
                      color: Colors.grey,
                      thickness: 1,
                    )
                    // TODO: Custom painter is disapearing
                    //   CustomPaint(painter: DashedLineVerticalPainter(startX: widget.dividerWidth / 2),
                    ),
                // ),
              ),
              onPanUpdate: (DragUpdateDetails details) {
                setState(() {
                  _ratio += details.delta.dx / _maxWidth;
                  if (_ratio > 1)
                    _ratio = 1;
                  else if (_ratio < 0.0) _ratio = 0.0;

                  if (_ratio < _minRatio) {
                    _ratio = _minRatio;
                  } else if (_ratio > _maxRatio) {
                    _ratio = _maxRatio;
                  }
                });
              },
            ),
            SizedBox(
              width: _width2,
              child: widget.right,
            ),
          ],
        ),
      );
    });
  }
}
