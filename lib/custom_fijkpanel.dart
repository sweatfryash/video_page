import 'dart:async';
import 'dart:math';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomFijkPanel extends StatefulWidget {
  const CustomFijkPanel(
      {Key key,
        this.player,
        this.buildContext,
        this.viewSize,
        this.texturePos,
        this.onPlayingChanged,
        this.onHideAppBarChanged})
      : super(key: key);

  final FijkPlayer player;
  final BuildContext buildContext;
  final Size viewSize;
  final Rect texturePos;
  final ValueChanged<bool> onPlayingChanged;
  final ValueChanged<bool> onHideAppBarChanged;
  @override
  _CustomFijkPanelState createState() => _CustomFijkPanelState();
}

class _CustomFijkPanelState extends State<CustomFijkPanel> {

  FijkPlayer get player => widget.player;
  bool _playing = false;
  Timer _statelessTimer;
  double _seekPos = -1.0;
  Duration _duration = Duration(); //时长
  Duration _currentPos = Duration(); //当前位置
  Duration _bufferPos = Duration(); //缓存位置
  double _volume; //音量
  double _brightness; //亮度
  bool _dragLeft;

  StreamSubscription _currentPosSubs; //当前播放位置数据流
  StreamSubscription _bufferPosSubs; //缓存位置数据流
  StreamController<double> _valController;
  FijkData data; //存储了音量亮度等信息
  bool _hideAppbarActions = false; //控制appbar上的按钮的显示
  bool _hideBottomActions = false; //控制底部播放按钮，进度条以及全屏按钮的显示
  bool _hideStatusBar = false;

  @override
  void initState() {
    super.initState();
    _valController = StreamController.broadcast();
    _currentPos = player.currentPos;
    _bufferPos = player.bufferPos;
    _currentPosSubs = player.onCurrentPosUpdate.listen((v) {
      setState(() {
        _currentPos = v;
      });
    });
    _bufferPosSubs = player.onBufferPosUpdate.listen((v) {
      if (_hideBottomActions == false) {
        setState(() {
          _bufferPos = v;
        });
      } else {
        _bufferPos = v;
      }
    });
    widget.player.addListener(_playerValueChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _currentPosSubs.cancel();
    _bufferPosSubs.cancel();
    player.release();
  }

  void _playerValueChanged() {
    FijkValue value = player.value;
    bool playing = (value.state == FijkState.started);
    if (playing != _playing) {
      _playing = playing;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _duration = player.value.duration; //执行多余的次数了
    Rect rect = Rect.fromLTRB(
        max(0.0, widget.texturePos.left),
        max(0.0, widget.texturePos.top),
        min(widget.viewSize.width, widget.texturePos.right),
        min(widget.viewSize.height, widget.texturePos.bottom));

    return Positioned.fromRect(
      rect: rect,
      child: GestureDetector(
        child: Container(
          color: Colors.transparent,
          child: Column(
            children: <Widget>[
              Spacer(),
              bottomActions(),
            ],
          ),
        ),
        onTap: onPlayViewTap,
        onDoubleTap: onPlayViewDoubleTap,
        onVerticalDragUpdate: onVerticalDragUpdateFun,
        onVerticalDragStart: onVerticalDragStartFun,
        onVerticalDragEnd: onVerticalDragEndFun,
      ),
    );
  }

  Widget bottomActions() {
    return Stack(
      children: <Widget>[
        Offstage(
          offstage: _hideBottomActions,
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: <Color>[Colors.black38, Colors.black12,Colors.transparent])),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    _playing ? Icons.pause : Icons.play_arrow,
                    size: 33,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    _playOrPause();
                  },
                ),
                Expanded(
                  child: buildSlider(context),
                ),
                SizedBox(width: 10),
                buildTimeText(context, 15),
                IconButton(
                    icon: Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () {
                      player.enterFullScreen();
                    }),
              ],
            ),
          ),
        ),
        _bottomProgressLine(),
      ],
    );
  }
  void onPlayViewTap() {
    if (_playing) {
      _hideAppbarActions = !_hideAppbarActions;
    }
    _hideBottomActions = !_hideBottomActions;
    _hideStatusBar = !_hideStatusBar;
    if (_hideStatusBar) {
      SystemChrome.setEnabledSystemUIOverlays([]);
    } else {
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    }
    setState(() {});
  }

  void onPlayViewDoubleTap() {
    if (_playing) {
      _hideAppbarActions = false;
    } else {
      _hideAppbarActions = true;
      if(!_hideBottomActions){
        _hideBottomActions = true;
      }
    }
    _playOrPause();
  }
  //播放或者暂停的操作
  void _playOrPause() {
    if (player.isPlayable() || player.state == FijkState.asyncPreparing) {
      if (player.state == FijkState.started) {
        player.pause();
      } else {
        player.start();
      }
    } else {
      FijkLog.w("Invalid state ${player.state} ,can't perform play or pause");
    }
  }
  void onVerticalDragStartFun(DragStartDetails d) {
    if (d.localPosition.dx > MediaQuery.of(context).size.width / 2) {
      // right, volume
      _dragLeft = false;
      FijkVolume.getVol().then((v) {
        if (data != null && !data.contains("__fijkview_panel_init_volume")) {
          data.setValue("__fijkview_panel_init_volume", v);
        }
        setState(() {
          _volume = v;
          _valController.add(v);
        });
      });
    } else {
      // left, brightness
      _dragLeft = true;
      FijkPlugin.screenBrightness().then((v) {
        if (data != null &&
            !data.contains("__fijkview_panel_init_brightness")) {
          data.setValue("__fijkview_panel_init_brightness", v);
        }
        setState(() {
          _brightness = v;
          _valController.add(v);
        });
      });
    }
    _statelessTimer?.cancel();
    _statelessTimer = Timer(const Duration(milliseconds: 2000), () {
      setState(() {});
    });
  }

  void onVerticalDragUpdateFun(DragUpdateDetails d) {
    double delta = d.primaryDelta / widget.viewSize.height;
    delta = -delta.clamp(-1.0, 1.0);
    if (_dragLeft != null && _dragLeft == false) {
      if (_volume != null) {
        _volume += delta;
        _volume = _volume.clamp(0.0, 1.0);
        FijkVolume.setVol(_volume);
        setState(() {
          _valController.add(_volume);
        });
      }
    } else if (_dragLeft != null && _dragLeft == true) {
      if (_brightness != null) {
        _brightness += delta;
        _brightness = _brightness.clamp(0.0, 1.0);
        FijkPlugin.setScreenBrightness(_brightness);
        setState(() {
          _valController.add(_brightness);
        });
      }
    }
  }

  void onVerticalDragEndFun(DragEndDetails e) {
    _volume = null;
    _brightness = null;
  }

  double duration2double(Duration d) {
    return d != null ? d.inMilliseconds.toDouble() : 0.0;
  }

  String duration2String(Duration duration) {
    if (duration.inMilliseconds < 0) return "-: negtive";

    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    int inHours = duration.inHours;
    return inHours > 0
        ? "$inHours:$twoDigitMinutes:$twoDigitSeconds"
        : "$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget buildTimeText(BuildContext context, double height) {
    String text =
        "${duration2String(_currentPos)}" + "/${duration2String(_duration)}";
    return Text(text, style: TextStyle(fontSize: 10, color: Color(0xFFFFFFFF)));
  }

  Widget buildSlider(BuildContext context) {
    double duration = duration2double(_duration);

    double currentValue = _seekPos > 0 ? _seekPos : duration2double(_currentPos);
    currentValue = currentValue.clamp(0.0, duration);

    double bufferPos = duration2double(_bufferPos);
    bufferPos = bufferPos.clamp(0.0, duration);

    return Container(
      height: 20,
      child: FijkSlider(
        colors: FijkSliderColors(
            cursorColor: Theme.of(context).primaryColorDark,
            playedColor: Theme.of(context).primaryColor,
            baselineColor: Colors.white38,
            bufferedColor: Colors.black12),
        value: currentValue,
        cacheValue: bufferPos,
        min: 0.0,
        max: duration,
        onChanged: (v) {
          //_restartHideTimer();
          setState(() {
            _seekPos = v;
          });
        },
        onChangeEnd: (v) {
          setState(() {
            player.seekTo(v.toInt());
            _currentPos = Duration(milliseconds: _seekPos.toInt());
            _seekPos = -1.0;
          });
        },
      ),
    );
  }

  Widget _bottomProgressLine() {
    double duration = duration2double(_duration);
    double currentValue = _seekPos > 0 ? _seekPos : duration2double(_currentPos);
    currentValue = currentValue.clamp(0.0, duration);
    double progress = currentValue / duration;
    return Container(
      height: 2,
      child: Offstage(
        offstage: !_hideBottomActions,
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }

}

