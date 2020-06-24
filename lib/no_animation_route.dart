import 'package:flutter/cupertino.dart';

class NoAnimationRoute extends PageRouteBuilder {
  final Widget widget;

  NoAnimationRoute(this.widget)
    : super(
    transitionDuration: Duration(milliseconds: 100),
    pageBuilder: (
        BuildContext context,
        Animation<double> animation1,
        Animation<double> animation2){
      return widget;
    },
  );
}