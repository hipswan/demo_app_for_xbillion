import 'package:flutter/material.dart';

class VideoTileTap extends StatelessWidget {
  const VideoTileTap({
    Key key,
    @required this.onTap,
    this.child,
    this.color,
  }) : super(key: key);

  final Widget child;
  final Function onTap;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: child,
      ),
    );
  }
}
