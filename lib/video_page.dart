import 'dart:async';

import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart' hide NestedScrollView;
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:videopage/custom_fijkpanel.dart';

class VideoPage extends StatefulWidget {
  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> with TickerProviderStateMixin {
  bool _hideTitle = true; //控制appbar的title的显示

  bool _playing = false;
  bool sendDanmu = true; //控制发送弹幕小部件的状态
  TabController primaryTC;
  double pinnedHeaderHeight;
  final ScrollController _sc = ScrollController();
  final double extraHeight = 175; //视频框的高度
  final FijkPlayer _player = FijkPlayer();

  bool _hideAppbarActions = false; //控制appbar上的按钮的显示

  bool downLock = true;
  bool upLock = false;


  @override
  void initState() {
    super.initState();
    _player.setDataSource('https://app.hnsi.cn/yicr-test/images/test_video.mp4',
        autoPlay: true);

    primaryTC = TabController(length: 2, vsync: this);
    _sc.addListener(onListScrolled);
    _player.addListener(playerValueChanged);
  }

  @override
  void dispose() {
    primaryTC.dispose();
    _sc.dispose();
    _player.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    pinnedHeaderHeight = statusBarHeight + kToolbarHeight;
    return Scaffold(
      body: _buildScaffoldBody(),
    );
  }

  Widget _buildScaffoldBody() {
    return NestedScrollView(
        controller: _sc,
        headerSliverBuilder: (c, f) {
          return <Widget>[
            SliverAppBar(
              elevation: 0,
              pinned: true,
              expandedHeight: extraHeight,
              leading:
              Offstage(offstage: _hideAppbarActions, child: BackButton()),
              title: Offstage(
                offstage: _hideTitle,
                child: GestureDetector(
                  onTap: () {
                    _player.start();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.play_circle_outline),
                      SizedBox(width: 5),
                      TextField(),
                      Text('立即播放',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.normal)),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                offstageIcon(
                    _hideAppbarActions, Icons.picture_in_picture_alt, () {}),
                offstageIcon(_hideAppbarActions, Icons.airplay, () {}),
                offstageIcon(_hideAppbarActions, Icons.more_vert, () {}),
              ],
              flexibleSpace: playerView(),
            )
          ];
        },
        pinnedHeaderSliverHeightBuilder: () {
          return pinnedHeaderHeight + (_playing ? extraHeight : 0);
        },
        innerScrollPositionKeyBuilder: () {
          var index = "Tab";
          index += primaryTC.index.toString();
          return Key(index);
        },
        body: Column(
          children: <Widget>[
            tabBar(),
            Expanded(
              child: TabBarView(
                controller: primaryTC,
                children: <Widget>[
                  NestedScrollViewInnerScrollPositionKeyWidget(
                    Key("Tab0"),
                    GlowNotificationWidget(
                      ListView.builder(
                        //store Page state
                        key: PageStorageKey("Tab0"),
                        physics: ClampingScrollPhysics(),
                        itemBuilder: (c, i) {
                          return Container(
                            alignment: Alignment.center,
                            height: 60.0,
                            child:
                            Text(Key("Tab0").toString() + ": ListView$i"),
                          );
                        },
                        itemCount: 50,
                      ),
                      showGlowLeading: false,
                    ),
                  ),
                  NestedScrollViewInnerScrollPositionKeyWidget(
                    Key("Tab1"),
                    GlowNotificationWidget(
                      ListView.builder(
                        //store Page state
                        key: PageStorageKey("Tab1"),
                        physics: ClampingScrollPhysics(),
                        itemBuilder: (c, i) {
                          return Container(
                            alignment: Alignment.center,
                            height: 60.0,
                            child:
                            Text(Key("Tab1").toString() + ": ListView$i"),
                          );
                        },
                        itemCount: 50,
                      ),
                      showGlowLeading: false,
                    ),
                  )
                ],
              ),
            )
          ],
        ));
  }



  //tabbar
  Widget tabBar() {
    return GestureDetector(
      onVerticalDragEnd: (DragEndDetails details) {},
      child: Container(
        height: 40,
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          //BoxShadow中Offset (1,1)右下，(-1,-1)左上,(1,-1)右上,(-1,1)左下
          BoxShadow(
            color: Colors.grey[200],
            offset: Offset(1, 1),
            blurRadius: 5,
          ),
          BoxShadow(
              color: Colors.grey[200], offset: Offset(-1, 1), blurRadius: 5)
        ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              width: 210,
              child: TabBar(
                controller: primaryTC,
                labelColor: Colors.blue,
                indicatorColor: Colors.blue,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 2.0,
                isScrollable: false,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: '简介'),
                  Tab(text: '评论'),
                ],
              ),
            ),
            Container(
              width: 130,
              height: 30,
              margin: EdgeInsets.only(right: 15),
              child: _danMu(),
            ),
          ],
        ),
      ),
    );
  }

  Stack _danMu() {
    return Stack(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Spacer(flex: 1),
                    AnimatedContainer(
                      alignment: Alignment.centerRight,
                      duration: const Duration(milliseconds: 200),
                      width: sendDanmu ? 130 : 41,
                      decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border:
                          Border.all(color: Colors.grey[300], width: 0.5),
                          borderRadius: BorderRadius.circular(20)),
                      child: GestureDetector(
                        onTap: () {
                          sendDanmu = !sendDanmu;
                          setState(() {});
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 30,
                          decoration: BoxDecoration(
                              color:
                              sendDanmu ? Colors.white : Colors.grey[200],
                              borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(sendDanmu ? 0 : 20),
                                  right: Radius.circular(20))),
                          child: Icon(
                            sendDanmu
                                ? Icons.chat_bubble_outline
                                : Icons.remove_circle_outline,
                            size: 23,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.only(left: 10),
                  alignment: Alignment.centerLeft,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: sendDanmu ? 1 : 0,
                    child: Text(
                      '点我发弹幕',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            );
  }

  ///视频区域，返回[FlexibleSpaceBar],在其[background]中放入[Stack],
  ///其中上层是一个透明的区域[GestureDetector]用来检测手势操作，下层是[FijkView]
  Widget playerView() {
    return FlexibleSpaceBar(
      collapseMode: CollapseMode.pin,
      background: FijkView(
          player: _player,
          color: Colors.black,
          panelBuilder: (FijkPlayer player, FijkData data, BuildContext context, Size viewSize,
              Rect texturePos) {
            return CustomFijkPanel(
              player: player,
              buildContext: context,
              texturePos: texturePos,
              viewSize: viewSize,
            );
          }
      ),
    );
  }
  
  void playerValueChanged() {
    FijkValue value = _player.value;
    bool playing = (value.state == FijkState.started);
    if (playing != _playing) {
      _playing = playing; //修改_playing变量，setstate后更新页面显示
      final before = pinnedHeaderHeight;
      //处理固定头部高度的改变引起的列表未知的变化
      if (_playing) {
        //SystemChrome.setEnabledSystemUIOverlays([]);
        _sc.position.applyContentDimensions(_sc.position.minScrollExtent,
            _sc.position.maxScrollExtent + before);
      } else {
        //
        _sc.position.applyContentDimensions(_sc.position.minScrollExtent,
            _sc.position.maxScrollExtent - before);
      }
      setState(() {});
    }
  }

  void onListScrolled() {
    if (_sc.position.pixels > 70 && downLock) {
      _hideTitle = false;
      setState(() {});
      upLock = true;
      downLock = false;
    }
    if (_sc.position.pixels < 70 && upLock) {
      _hideTitle = true;
      setState(() {});
      upLock = false;
      downLock = true;
    }
  }
  //组合被offstage包裹的icon
  Widget offstageIcon(bool hideIcon, IconData iconData, VoidCallback onPressed) {
    return Offstage(
      offstage: hideIcon,
      child: IconButton(
        icon: Icon(
          iconData,
          size: 23,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
  
 
