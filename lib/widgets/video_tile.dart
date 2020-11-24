import 'package:flutter/material.dart';

class VideoTile extends StatelessWidget {
  const VideoTile({
    Key key,
    @required this.title,
    this.image,
    this.border,
    this.playingNow,
  }) : super(key: key);

  final String title;

  final String image;
  final Border border;
  final Widget playingNow;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        margin: EdgeInsets.only(top: 5.0),
        decoration: BoxDecoration(
          border: border,
        ),
        child: Image.network(image),
      ),
      title: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          '$title',
          style: TextStyle(fontSize: 22.0),
        ),
      ),
      trailing: playingNow,
    );
  }
}
