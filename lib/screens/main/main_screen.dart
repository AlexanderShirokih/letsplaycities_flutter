import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/game/game_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Describes the main screen
class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        createBackground("bg_geo"),
        Column(
          children: [
            _createAppLogo(),
            _createNavigationButtonsGroup(context),
          ],
        ),
        Positioned.fill(
          child: Container(
            alignment: Alignment.topRight,
            padding: EdgeInsets.only(top: 26.0, right: 16.0),
            child: SizedBox(
              width: 54.0,
              height: 54.0,
              child: RaisedButton(
                onPressed: () {},
                color: Theme.of(context).accentColor,
                child: Icon(Icons.settings),
              ),
            ),
          ),
        )
      ],
    );
  }
}

_createAppLogo() => Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 64.0, 20.0, 20.0),
      child: Image.asset("assets/images/logo.png"),
    );

_createNavigationButtonsGroup(BuildContext context) => Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 240.0,
              maxWidth: 260.0,
              minHeight: 230.0,
              maxHeight: 260.0,
            ),
            child: AnimatedMainButtons(),
          ),
        ),
      ),
    );

class AnimatedMainButtons extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AnimatedMainButtonsState();
}

class _AnimatedMainButtonsState extends State<AnimatedMainButtons>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<Offset> _primaryButtonsOffset;
  Animation<Offset> _secondaryButtonsOffset;
  AnimationStatus _lastDirection = AnimationStatus.forward;

  setPrimaryButtonsVisibility(bool isVisible) {
    setState(() {
      if (!isVisible)
        _controller.forward();
      else
        _controller.reverse();
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.forward ||
            status == AnimationStatus.reverse) {
          _lastDirection = status;
        }
      });
    _primaryButtonsOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.5, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _secondaryButtonsOffset = Tween<Offset>(
      begin: const Offset(1.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        var shouldCloseApp = !_controller.isAnimating &&
            _lastDirection != AnimationStatus.forward;
        if (!shouldCloseApp) setPrimaryButtonsVisibility(true);
        return shouldCloseApp;
      },
      child: Stack(
        children: [
          SlideTransition(
              position: _primaryButtonsOffset,
              child: _createPrimaryButtons(context)),
          SlideTransition(
            position: _secondaryButtonsOffset,
            child: _createSecondaryButtons(context),
          ),
        ],
      ),
    );
  }

  _createPrimaryButtons(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomMaterialButton("Играть", Icon(Icons.play_arrow), () {
            setPrimaryButtonsVisibility(false);
          }),
          CustomMaterialButton(
              "Достижения", FaIcon(FontAwesomeIcons.medal), () {}),
          CustomMaterialButton("Рейтинги", Icon(Icons.trending_up), () {}),
          CustomMaterialButton("Города", Icon(Icons.apartment), () {}),
        ],
      );

  _createSecondaryButtons(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomMaterialButton("Игрок против андроида", Icon(Icons.android),
              () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => GameScreen()));
          }),
          CustomMaterialButton(
              "Игрок против игрока", Icon(Icons.person), () {}),
          CustomMaterialButton("Онлайн", Icon(Icons.language), () {}),
          CustomMaterialButton("Мультиплеер", Icon(Icons.wifi), () {}),
        ],
      );
}