import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:fullstack/widgets/video_tile.dart';
import 'package:fullstack/widgets/video_tile_tap.dart';

final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    // 'https://www.googleapis.com/auth/contacts.readonly',
  ],
);

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isAuth = false;
  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;
  Widget playerWidget = Text("");
  Widget errorWidget = Center(
    child: CircularProgressIndicator(),
  );

  List<dynamic> videos = [];
  bool _isLoaded = false;
  int _nowPlayingIndex;
  bool isPlaying = true;
  Future<void> _initializePlay(String videoPath) async {
    // _chewieController.dispose();
    // _videoPlayerController.dispose();_chewieController?.dispose();
    _videoPlayerController = new VideoPlayerController.network(videoPath);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoInitialize: true,
      aspectRatio: 4 / 3,
      autoPlay: true,
      showControls: true,
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.red,
        bufferedColor: Colors.grey[200],
        handleColor: Colors.red,
        backgroundColor: Colors.grey[850],
      ),
      errorBuilder: (context, errorMessage) => Center(
        child: Text(errorMessage),
      ),
    );
    _chewieController.addListener(() {
      if (_chewieController.isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    });
    _videoPlayerController.addListener(checkIfVideoFinished);

    setState(() {
      playerWidget = Chewie(
        controller: _chewieController,
      );
    });
  }

  Future<void> _startPlay(String videoPath, int index) async {
    setState(() {
      _nowPlayingIndex = index;
    });
    _pausePrevious().then((_) {
      _initializePlay(videoPath);
    });
  }

  Future<bool> _pausePrevious() async {
    await _videoPlayerController?.pause();
    await _videoPlayerController?.seekTo(Duration(seconds: 0));

    return true;
  }

  void checkIfVideoFinished() {
    if (_videoPlayerController == null ||
        _videoPlayerController.value == null ||
        _videoPlayerController.value.position == null ||
        _videoPlayerController.value.duration == null) return;
    if (_videoPlayerController.value.position.inSeconds ==
        _videoPlayerController.value.duration.inSeconds) {
      _videoPlayerController.removeListener(checkIfVideoFinished);
      // _videoPlayerController.dispose();
      // Change _nowPlayingIndex
      _chewieController.exitFullScreen();

      setState(() {
        (_nowPlayingIndex < videos.length - 1)
            ? _nowPlayingIndex = _nowPlayingIndex + 1
            : _nowPlayingIndex = 0;
      });
      _initializePlay(videos[_nowPlayingIndex]["url"].toString().trim());
    }
  }

  void setErrorWidget() {
    setState(() {
      errorWidget = Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child:
                SvgPicture.asset('assets/images/no_content.svg', height: 260.0),
          ),
          Text(
            "No Content",
            style: TextStyle(
              fontSize: 60.0,
              color: Colors.white,
            ),
          )
        ],
      );
    });
  }

  Future<void> getVideoForUser(String id) async {
    http.Response response =
        await http.get("https://stark-castle-42998.herokuapp.com/id/$id");
    print(response.statusCode);
    if (response.statusCode == 200) {
      try {
        videos = jsonDecode(response.body);
        if (videos.length > 0) {
          setState(() {
            _isLoaded = true;
          });
          _initializePlay(videos[_nowPlayingIndex]["url"].toString().trim());
        } else {
          setErrorWidget();
        }
      } on Exception catch (_) {
        setErrorWidget();
      }
    } else {
      setErrorWidget();
    }
  }

  @override
  void initState() {
    super.initState();
    _nowPlayingIndex = 0;

    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {
      // print('Error signing in: $err');
    });

    // Reauthenticate user when app is opened
    googleSignIn
        .signInSilently(suppressErrors: false)
        .then((account) {})
        .catchError((err) {
      // print('Error signing in: $err');
    });
  }

  handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      print('User logged in as ${account.id}');
      setState(() {
        isAuth = true;
      });
      await getVideoForUser(account.id);
    } else {
      setState(() {
        _nowPlayingIndex = 0;
        _isLoaded = false;
        isAuth = false;
      });
    }
  }

  login() {
    googleSignIn.signIn();
  }

  logout() async {
    _chewieController?.pause();
    setState(() {
      errorWidget = Center(
        child: CircularProgressIndicator(),
      );
    });
    await googleSignIn.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: isAuth ? buildVideoList() : buildLoginScreen(),
    );
  }

  @override
  void dispose() {
    print('in      disponse');
    _videoPlayerController.dispose();
    _chewieController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  buildLoginScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'FullStack',
              style: TextStyle(
                fontFamily: "Signatra",
                fontSize: 90.0,
                color: Colors.red,
              ),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260.0,
                height: 60.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/google_signin_button.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  buildVideoList() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.exit_to_app,
          ),
          onPressed: () {
            logout();
          },
        ),
        title: Text('FullStack'),
      ),
      body: _isLoaded
          ? Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  child: playerWidget,
                ),
                Expanded(
                  child: Container(
                    child: ListView.builder(
                      itemExtent: 75,
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        return _isLoaded
                            ? VideoTileTap(
                                color: _nowPlayingIndex == index
                                    ? Colors.grey[700]
                                    : Colors.black,
                                onTap: () {
                                  _startPlay(
                                      videos[index]["url"].toString().trim(),
                                      index);
                                },
                                child: VideoTile(
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                    style: _nowPlayingIndex == index
                                        ? BorderStyle.solid
                                        : BorderStyle.none,
                                  ),
                                  title:
                                      '${videos[index]["title"].toString().trim()}',
                                  image:
                                      '${videos[index]["thumb"].toString().trim()}',
                                  playingNow: (_nowPlayingIndex == index)
                                      ? IconButton(
                                          focusColor: Colors.redAccent,
                                          icon: Icon(
                                            isPlaying
                                                ? Icons.pause_circle_filled
                                                : Icons.play_circle_filled,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                          onPressed: () async {
                                            _videoPlayerController
                                                    .value.isPlaying
                                                ? await _chewieController
                                                    .pause()
                                                : await _chewieController
                                                    .play();
                                            _videoPlayerController
                                                    .value.isPlaying
                                                ? setState(() {
                                                    isPlaying = true;
                                                  })
                                                : setState(() {
                                                    isPlaying = false;
                                                  });
                                          },
                                        )
                                      : Text(""),
                                ),
                              )
                            : Center(
                                child: CircularProgressIndicator(),
                              );
                      },
                    ),
                  ),
                ),
              ],
            )
          : errorWidget,
    );
  }
}
