import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ad_state.dart';
import '../services/grid-properties.dart';
import '../services/tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

enum SwipeDirection { up, down, left, right }

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {

  AnimationController? controller;

  List<List<Tile>> grid = List.generate(4, (y) => List.generate(4, (x) => Tile(x, y, 0)));

  /// List<GameState> gameStates = []; /// for "undo"
  List<Tile> toAdd = [];

  Iterable<Tile> get gridTiles => grid.expand((e) => e);
  Iterable<Tile> get allTiles => [gridTiles, toAdd].expand((e) => e);
  List<List<Tile>> get gridCols => List.generate(4, (x) => List.generate(4, (y) => grid[y][x]));

  Timer? aiTimer;

  bool isGameOver = false;
  bool isGameWon = false;
  List<int> gameSituation = [];

  /// List for get tiles value
  int score = 0;
  int highScore = 0;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    controller?.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          for (var e in toAdd) {
            grid[e.y][e.x].value = e.value;
          }
          for (var t in gridTiles) {
            t.resetAnimations();
          }
          toAdd.clear();
        });
        getTilesInfo();
      }
    });

    setupSavedGame();
    createRewardedAd();
    createInterstitialAd();
    loadHighScore();

    createBannerAdWidget();

  }

  @override
  Widget build(BuildContext context) {
    double contentPadding = 16;
    double borderSize = 4;
    double gridSize = MediaQuery.of(context).size.width - contentPadding * 2;
    double tileSize = (gridSize - borderSize * 2) / 4;
    List<Widget> stackItems = [];

    /// Empty tiles
    stackItems.addAll(gridTiles.map((t) => TileWidget(
      x: tileSize * t.x,
      y: tileSize * t.y,
      containerSize: tileSize,
      size: tileSize - borderSize * 2,
      color: Colors.deepOrange.shade100,
    )));

    /// NotEmpty tiles
    stackItems.addAll(
      allTiles.map((tile) {
          return AnimatedBuilder(
            animation: controller!,
            builder: (context, child) => (tile.animatedValue!.value == 0)
                ? const SizedBox()
                : TileWidget(
                    x: tileSize * tile.animatedX!.value,
                    y: tileSize * tile.animatedY!.value,
                    containerSize: tileSize,
                    size: (tileSize - borderSize * 2) * tile.size!.value,
                    color: numTileColor[tile.animatedValue!.value]!,
                    child: GestureDetector(
                      onTap: () {
                        print(tileSize * tile.animatedX!.value);
                      },
                      child: Center(
                          child: Stack(
                        children: [
                          TileNumber(tile.animatedValue!.value),
                          Stack(
                            children: [
                              Container(
                                // padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(cornerRadius),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: numTileColor[tile.animatedValue!.value]!,
                                    // color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(cornerRadius),
                                  ),
                                  alignment: Alignment.center,
                                  child: ClipRRect(

                                    child: Image(
                                      height: tileSize,
                                      width: tileSize,
                                      image: AssetImage("assets/images/clashofclanstroops/${tile.animatedValue!.value}.png",),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                          bottomRight: Radius.circular(5),
                                          topLeft: Radius.circular(5)),
                                      color: Color.fromRGBO(255, 192, 22, .9),
                                    ),
                                  child: Text(
                                      tile.animatedValue!.value.toString(),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 10),
                                    ),
                                ),
                              ),
                            ],
                          ),
                          /// #image
                        ],
                      )),
                    ),
                  ),
          );
        },
      ),
    );

    return Scaffold(
      backgroundColor: Colors.deepOrange.shade50,
      body: SafeArea(
        child: Stack(
          children: [
            /// main game table
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(
                    height: 80,
                  ),
                  Swiper(
                    up: () {
                      merge(SwipeDirection.up);
                    },
                    down: () async {
                      merge(SwipeDirection.down);
                    },
                    left: () {
                      merge(SwipeDirection.left);
                    },
                    right: () {
                      merge(SwipeDirection.right);
                    },
                    child: Container(
                      height: gridSize,
                      width: gridSize,
                      padding: EdgeInsets.all(borderSize),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.deepOrange.shade200,
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(5, 5),),
                        ],
                      ),
                      child: Stack(
                        children: stackItems,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    // child: Text("AD AD AD AD AD"),
                    child: bannerAdMainWidget,
                  ),
                ],
              ),
            ),

            /// control panel
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 10, left: 10, right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// score, high score
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5,),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.deepOrangeAccent,
                                  Color.fromRGBO(255, 192, 22, 1),
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(5, 5),),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "Score",
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                                Text(
                                  score.toString(),
                                  style: const TextStyle(fontSize: 18, color: Colors.white,),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10,),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5,),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.deepOrangeAccent,
                                  Color.fromRGBO(255, 192, 22, 1),
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(5, 5),),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "High score",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                                Text(
                                  highScore.toString(),
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      /// pause button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isPause = true;
                            isMainMenuOpen = true;
                            createBannerAdWidget();
                          });
                          // setupNewGame();
                        },
                        child: Container(
                          height: 40,
                          width: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.deepOrangeAccent,
                                Color.fromRGBO(255, 192, 22, 1),
                              ],
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(5, 5),),
                            ],
                          ),
                          child: Icon(
                            Icons.pause,
                            color: Colors.white,
                            size: iconSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            /// Front panels
            gameOverWidget(),

            gameWonWidget(),

            mainMenuWidget(),
          ],
        ),
      ),
    );
  }

  /// Functions

  bool isMainMenuOpen = true;
  bool isPause = false;
  double iconSize = 28;
  double textSize = 16;

  late final AnimationController animatedController = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  );
  late final Animation<double> fadeAnimation = CurvedAnimation(
    parent: animatedController,
    curve: Curves.easeIn,
  );

  /// Widgets =================== Widgets ======================= Widgets =================== Widgets ============== Widgets =============== Widgets ================= Widgets =============== Widgets ================== Widgets ========

  double buttonsHeight = 50;
  double sizedBoxHeight = 25;
  Widget mainMenuWidget() {
    if ((isMainMenuOpen)) {
      return Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: Colors.white.withOpacity(.9),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 50, left: 50, right: 50),
                  child: const Image(
                    image: AssetImage("assets/images/logo.png"),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      (isPause) ?
                      Container(
                        height: buttonsHeight,
                        width: 250,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.deepOrangeAccent,
                              Color.fromRGBO(255, 192, 22, 1),
                            ],
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(10, 10),),
                          ],
                        ),
                        child: MaterialButton(
                          onPressed: () async {
                            SharedPreferences possibility = await SharedPreferences.getInstance();
                            continueCount = (await possibility.getInt("possibility")) ?? 3;
                            setState(() {
                              isMainMenuOpen = false;
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow, color: Colors.white, size: iconSize,),
                              const SizedBox(width: 10,),
                              Center(child: Text("Continue", style: TextStyle(color: Colors.white, fontSize: textSize,),textAlign: TextAlign.center,)),
                            ],
                          ),
                        ),
                      ):
                      Container(
                        height: buttonsHeight,
                        width: 250,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.deepOrangeAccent,
                              Color.fromRGBO(255, 192, 22, 1),
                            ],
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(10, 10),),
                          ],
                        ),
                        child: TextButton.icon(
                          onPressed: setupNewGame,
                          icon: Icon(Icons.play_arrow, color: Colors.white, size: iconSize,),
                          label: Text("Play", style: TextStyle(color: Colors.white, fontSize: textSize,),),
                        ),
                      ),


                      (isPause) ?
                      Column(
                        children: [
                          SizedBox(height: sizedBoxHeight,),
                          Container(
                            height: buttonsHeight,
                            width: 250,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.deepOrangeAccent,
                                  Color.fromRGBO(255, 192, 22, 1),
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(10, 10),),
                              ],
                            ),
                            child: MaterialButton(
                              onPressed: (){
                                showInterstitialAd();
                                setupNewGame();
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.replay, color: Colors.white, size: iconSize,),
                                  const SizedBox(width: 10,),
                                  Text(" Restart", style: TextStyle(color: Colors.white, fontSize: textSize,),),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ) : SizedBox(),

                      SizedBox(height: sizedBoxHeight,),
                      Container(
                        height: buttonsHeight,
                        width: 250,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.deepOrangeAccent,
                              Color.fromRGBO(255, 192, 22, 1),
                            ],
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(10, 10),),
                          ],
                        ),
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.share, color: Colors.white, size: iconSize,),
                          label: Text("Share", style: TextStyle(color: Colors.white, fontSize: textSize,),),
                        ),
                      ),
                      SizedBox(height: sizedBoxHeight,),
                      Container(
                        height: buttonsHeight,
                        width: 250,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.deepOrangeAccent,
                              Color.fromRGBO(255, 192, 22, 1),
                            ],
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(10, 10),),
                          ],
                        ),
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.star_rate, color: Colors.white, size: iconSize,),
                          label: Text("Rate", style: TextStyle(color: Colors.white, fontSize: textSize,),
                          ),
                        ),
                      ),

                    ],
                  ),
                  /*Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 60,
                        width: 250,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.deepOrangeAccent,
                              Color.fromRGBO(255, 192, 22, 1),
                            ],
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(10, 10),),
                          ],
                        ),
                        child: MaterialButton(
                          onPressed: () {
                            setState(() {
                              isMainMenuOpen = false;
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow, color: Colors.white, size: iconSize,),
                              const SizedBox(width: 10,),
                              Center(child: Text("Continue", style: TextStyle(color: Colors.white, fontSize: textSize,),textAlign: TextAlign.center,)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30,),
                      Container(
                        height: 60,
                        width: 250,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.deepOrangeAccent,
                              Color.fromRGBO(255, 192, 22, 1),
                            ],
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(10, 10),),
                          ],
                        ),
                        child: MaterialButton(
                          onPressed: (){
                            showInterstitialAd();
                            setupNewGame();
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.replay, color: Colors.white, size: iconSize,),
                              const SizedBox(width: 10,),
                              Text(" Restart", style: TextStyle(color: Colors.white, fontSize: textSize,),),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30,),
                      Container(
                        height: 60,
                        width: 250,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.deepOrangeAccent,
                              Color.fromRGBO(255, 192, 22, 1),
                            ],
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(10, 10),),
                          ],
                        ),
                        child: MaterialButton(
                          onPressed: () => SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close, color: Colors.white, size: iconSize,),
                              const SizedBox(width: 10,),
                              Text("Exit game", style: TextStyle(color: Colors.white, fontSize: textSize),),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),*/
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              height: 55,
              width: 55,
              margin: const EdgeInsets.only(left: 10, top: 200),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: (){
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => CollectionPage()));
                    },
                    child: Container(
                      height: 50,
                      width: 50,
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.deepOrangeAccent,
                            Color.fromRGBO(255, 192, 22, 1),
                          ],
                        ),
                        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(5, 5),),],
                        image: DecorationImage(
                          image: AssetImage("assets/images/clashofclanstroops/2.png"),
                          fit: BoxFit.cover,
                        )
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(Icons.change_circle, color: Colors.yellow.shade700, size: 28,),
                  ),
                  const Center(
                    child: Text("Coming soon!", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                  )
                ],
              ),
            ),
          ),

          /// ads
          // (isPause) ?
          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: bannerAdPauseWidget,
          // ) :
          // const SizedBox(),
        ],
      );
    } else {
      return const SizedBox();
    }
  }

  Widget gameWonWidget() {
    animatedController.forward(from: .5);
    if ((isGameWon)) {
      return FadeTransition(
        opacity: animatedController,
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.white.withOpacity(.8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "You Won!",
                style: TextStyle(
                  fontSize: 48.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 50,),
              Container(
                width: 200,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.deepOrangeAccent,
                      Color.fromRGBO(255, 192, 22, 1),
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black54,
                        blurRadius: 10,
                        offset: Offset(10, 10)),
                  ],
                ),
                child: MaterialButton(
                  onPressed: setupNewGame,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.replay, color: Colors.white,),
                        SizedBox(width: 5,),
                        Text(" Play again ", style: TextStyle(fontSize: 16, color: Colors.white),),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15,),
              TextButton(
                onPressed: () {
                  setState(() {
                    isGameWon = false;
                    isPause = false;
                    isMainMenuOpen = true;
                  });
                },
                child: const Text(
                  "No, thanks",
                  style: TextStyle(
                      color: Color.fromRGBO(227, 88, 23, 1),
                      fontSize: 16,
                      decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  Widget gameOverWidget() {
    animatedController.forward(from: 0);
    if ((isGameOver)) {
      return FadeTransition(
        opacity: fadeAnimation,
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.white.withOpacity(.9),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Game Over!",
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 50,),
                  Container(
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient:
                      (continueCount != 0) ?
                      const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.deepOrangeAccent,
                          Color.fromRGBO(255, 192, 22, 1),
                        ],
                      ) :
                      LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.grey,
                          Colors.grey.shade200
                        ],
                      ) ,
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black54,
                            blurRadius: 10,
                            offset: Offset(10, 10)),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: MaterialButton(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.ondemand_video, color: Colors.white),
                            const SizedBox(width: 10,),
                            Column(
                              children: [
                                const Text("Continue", style: TextStyle(color: Colors.white, fontSize: 16),),
                                Text("Have: $continueCount", style: const TextStyle(color: Colors.white, fontSize: 8),),
                              ],
                            ),
                          ],
                        ),
                      ),
                      onPressed: (continueCount != 0) ? showRewardedAd : null,
                    ),
                  ),
                  const SizedBox(height: 20,),
                  Container(
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.deepOrangeAccent,
                          Color.fromRGBO(255, 192, 22, 1),
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(10, 10)),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: MaterialButton(
                      onPressed: (){
                        showInterstitialAd();
                        setupNewGame();
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.replay, color: Colors.white,),
                            SizedBox(width: 10,),
                            Text("Restart", style: TextStyle(color: Colors.white, fontSize: 16),),
                          ],
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        showInterstitialAd();
                        isGameOver = false;
                        isPause = false;
                        isMainMenuOpen = true;
                      });
                    },
                    child: const Text(
                      "No, thanks",
                      style: TextStyle(color: Color.fromRGBO(227, 88, 23, 1), fontSize: 16, decoration: TextDecoration.underline,),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  /// Widgets ====================== Widgets =================== Widgets =============== Widgets ================== Widgets ====================== Widgets ================= Widgets ========================= Widgets ==========


  /// ADS

  Widget bannerAdMainWidget = Text("Reklama");

  void createBannerAdWidget() {
    BannerAd mainBanner = BannerAd(
      adUnitId: AdState.mainBannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    )..load();
    bannerAdMainWidget = StatefulBuilder(
      builder: (context, setState) => SizedBox(
        height: 80,
        child: AdWidget(ad: mainBanner),
      ),
    );
  }

  InterstitialAd? interstitialAd;
  int showsCount = 0;
  void createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdState.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          interstitialAd?.dispose();
          createInterstitialAd();
          print('InterstitialAd failed to load: $error');
        },
      ),
    );
  }
  void showInterstitialAd() {
    createInterstitialAd();
    interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print("ad Dismiss");
        },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print("$ad OnAdFailed $error");
        ad.dispose();
        createInterstitialAd();
      },
    );
    if (showsCount == 2) {
      interstitialAd?.show();
      showsCount = 0;
    } else {
      showsCount++;
    }
  }

  RewardedAd? rewardedAd;
  void createRewardedAd() {
    RewardedAd.load(
      adUnitId: AdState.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          print('$ad loaded.');
          rewardedAd = ad;
          },
        onAdFailedToLoad: (LoadAdError error) {
          print('RewardedAd failed to load: $error');
          },
      ),
    );
  }
  void showRewardedAd() async {
    createRewardedAd();

    rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        createRewardedAd();
      },
    );
    await rewardedAd?.show(onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
      continueGame();
    });
  }

  /// ADS

  int continueCount = 3;
  void continueGame() async {
    if (continueCount == 0) return;

    List<int> values = [];
    setState(() {
      isGameOver = false;

      /// Get value
      values.addAll(allTiles.map((tile) {
        return tile.animatedValue!.value;
      }));

      /// Remove values
      values.sort();
      values.removeRange(0, continueCount+2);

      /// limit
      continueCount--;

      /// Clear table
      for (var t in gridTiles) {
        t.value = 0;
        t.resetAnimations();
      }
    });

    SharedPreferences possibility = await SharedPreferences.getInstance();
    await possibility.setInt("possibility", continueCount);

    addNewTiles(values, true);
    controller?.forward(from: 0);

  }

  /*void undoMove() {
    GameState previousState = gameStates.removeLast();
    bool Function() mergeFn;
    switch (previousState.swipe) {
      case SwipeDirection.up:
        mergeFn = mergeUp;
        break;
      case SwipeDirection.down:
        mergeFn = mergeDown;
        break;
      case SwipeDirection.left:
        mergeFn = mergeLeft;
        break;
      case SwipeDirection.right:
        mergeFn = mergeRight;
        break;
    }
    setState(() {
      grid = previousState.previousGrid;
      mergeFn();
      controller?.reverse(from: .99).then((_) {
        setState(() {
          grid = previousState.previousGrid;
          for (var t in gridTiles) {
            t.resetAnimations();
          }
        });
      });
    });
  }*/

  Future<void> merge(SwipeDirection direction) async {
    bool Function() mergeFn;
    switch (direction) {
      case SwipeDirection.up:
        {
          calcScoreVertical();
          mergeFn = mergeUp;
        }
        break;
      case SwipeDirection.down:
        {
          calcScoreVertical();
          mergeFn = mergeDown;
        }
        break;
      case SwipeDirection.left:
        {
          calcScoreHorizontal();
          mergeFn = mergeLeft;
        }
        break;
      case SwipeDirection.right:
        {
          calcScoreHorizontal();
          mergeFn = mergeRight;
        }
        break;
    }

    /// This comment related to "Undo"
    /// List<List<Tile>> gridBeforeSwipe = grid.map((row) => row.map((tile) => tile.copy()).toList()).toList();
    setState(() {
      if (mergeFn()) {
        /// This comment related to "Undo"
        /// gameStates.add(GameState(gridBeforeSwipe, direction));
        addNewTiles([2], true);
        controller?.forward(from: 0);
      }
    });
  }

  bool mergeLeft() => grid.map((e) => mergeTiles(e)).toList().any((e) => e);

  bool mergeRight() =>
      grid.map((e) => mergeTiles(e.reversed.toList())).toList().any((e) => e);

  bool mergeUp() => gridCols.map((e) => mergeTiles(e)).toList().any((e) => e);

  bool mergeDown() => gridCols
      .map((e) => mergeTiles(e.reversed.toList()))
      .toList()
      .any((e) => e);

  bool mergeTiles(List<Tile> tiles) {
    bool didChange = false;
    for (int i = 0; i < tiles.length; i++) {
      for (int j = i; j < tiles.length; j++) {
        if (tiles[j].value != 0) {
          Tile? mergeTile = tiles
              .skip(j + 1)
              .firstWhere((t) => t.value != 0, orElse: () => Tile(0, 0, 0));
          if (mergeTile.value != tiles[j].value) {
            mergeTile = null;
          }
          if (i != j || mergeTile != null) {
            didChange = true;
            int resultValue = tiles[j].value;
            tiles[j].moveTo(controller!, tiles[i].x, tiles[i].y);
            if (mergeTile != null) {
              resultValue += mergeTile.value;
              mergeTile.moveTo(controller!, tiles[i].x, tiles[i].y);
              mergeTile.bounce(controller!);
              mergeTile.changeNumber(controller!, resultValue);
              mergeTile.value = 0;
              tiles[j].changeNumber(controller!, 0);
            }
            tiles[j].value = 0;
            tiles[i].value = resultValue;
          }
          break;
        }
      }
    }
    return didChange;
  }

  List<List<int>> tileValueList = [
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0]
  ];

  void addNewTiles(List<int> values, bool isNewGame) {
    List<Tile> empty = gridTiles.where((t) => t.value == 0).toList();

    if (isNewGame) empty.shuffle();
    for (int i = 0; i < values.length; i++) {
      // print("X: ${empty[i].animatedX!.value.toInt()}");
      // print("Y: ${empty[i].animatedY!.value.toInt()}");
      toAdd.add(Tile(empty[i].x, empty[i].y, values[i])..appear(controller!));

      // setState(() {
      //   tileValueList[empty[i].animatedX!.value.toInt()][empty[i].animatedY!.value.toInt()] = 2;
      // });

      // if (direction != null) {
      //   if ((direction == SwipeDirection.up) || (direction == SwipeDirection.down)) {
      //     gridCols[empty[i].animatedX!.value.toInt()][empty[i].animatedY!.value.toInt()].value = values[i];
      //   } else {
      //     grid[empty[i].animatedX!.value.toInt()][empty[i].animatedY!.value.toInt()].value = values[i];
      //   }
      // }

    }
  }

  void setupNewGame() async {
    setState(() {
      // gameStates.clear();
      isMainMenuOpen = false;
      isGameOver = false;
      isGameWon = false;
      continueCount = 3;
      for (var t in gridTiles) {
        t.value = 0;
        t.resetAnimations();
      }
      score = 2048;
      toAdd.clear();
      addNewTiles([2, 2], true);
      // addNewTiles([2, 4, 8, 16, 32, 64, 128, 256, 512, 1024], false);

      controller?.forward(from: 0);
    });
  }

  void getTilesInfo() {
    setState(() {
      gameSituation.clear();

      gameSituation.addAll(allTiles.map((tile) {
        return tile.animatedValue!.value;

        /// add value
      }));

      print(gameSituation);

      /// print value

      for (int i = 0; i <= 3; i++) {
        tileValueList[0] = [gameSituation[0], gameSituation[1], gameSituation[2], gameSituation[3]];
        tileValueList[1] = [gameSituation[4], gameSituation[5], gameSituation[6], gameSituation[7]];
        tileValueList[2] = [gameSituation[8], gameSituation[9], gameSituation[10], gameSituation[11]];
        tileValueList[3] = [gameSituation[12], gameSituation[13], gameSituation[14], gameSituation[15]];
      }
      print(tileValueList);

      saveGameProcess();

      isGameWon = gameWon(tileValueList);

      /// isGameWon
      isGameOver = gameOver(tileValueList);

      /// isGameOver
    });
  }



  void saveGameProcess() async {
    if (score != 0) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("gameProcess", gameSituation.toString());
      await prefs.setInt("score", score);
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove("gameProcess");
      prefs.remove("score");
    }
  }

  void setupSavedGame() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? loadGameSituation = prefs.getString("gameProcess");
    int? loadScore = prefs.getInt("score");

    if (loadGameSituation == null) return;



    loadGameSituation = loadGameSituation.replaceAll(RegExp('[^0-9-,]'), '');
    List<int> getGameSituation =  loadGameSituation.split(",").map(int.parse).toList();
    print("GGGGGGGGGGGGGGGGGGGg: $getGameSituation");

    setState(() {
      isPause = true;
      score = loadScore!;
      for (var t in gridTiles) {
        t.value = 0;
        t.resetAnimations();
      }
      toAdd.clear();
      addNewTiles(getGameSituation, false);
      controller?.forward(from: 0);
    });
  }



  void calcScoreHorizontal() {
    for (int i = 0; i <= 3; i++) {
      List<int> row = [];
      row.addAll(tileValueList[i]);

      print("RRRRR1 : $row");
      row.removeWhere((element) => element == 0);
      print("RRRRR2 : $row");

      for (int j = 0; j <= row.length - 2; j++) {
        if (row[j] == row[j + 1]) {
          setState(() {
            score += row[j] * 2;
            if (score > highScore) {
              highScore = score;
              storeHighScore();
            }
            j++;
          });
        }
      }
    }
  }

  void calcScoreVertical() {
    for (int i = 0; i <= 3; i++) {
      List<int> column = [];
      for (int f = 0; f <= 3; f++) {
        column.add(tileValueList[f][i]);
      }

      print("RRRRR1 : $column");
      column.removeWhere((element) => element == 0);
      print("RRRRR2 : $column");

      for (int j = 0; j <= column.length - 2; j++) {
        if (column[j] == column[j + 1]) {
          setState(() {
            score += column[j] * 2;
            if (score > highScore) {
              highScore = score;
              storeHighScore();
            }
            j++;
          });
        }
      }
    }
  }

  Future<void> storeHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("highScore", highScore);
  }

  Future<void> loadHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt("highScore")!;
  }

  bool gameOver(List<List<int>> tileValueList) {
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (tileValueList[i][j] == 0) {
          return false;
        }
        if (i != 3 && tileValueList[i][j] == tileValueList[i + 1][j]) {
          return false;
        }
        if (j != 3 && tileValueList[i][j] == tileValueList[i][j + 1]) {
          return false;
        }
      }
    }
    return true;
  }

  bool gameWon(List<List<int>> tileValueList) {
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (tileValueList[i][j] == 2048) {
          return true;
        }
      }
    }
    return false;
  }
}
