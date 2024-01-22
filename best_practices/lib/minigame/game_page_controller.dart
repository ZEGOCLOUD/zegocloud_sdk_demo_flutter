part of 'game_page.dart';

String get attributeKeyRoomGame => 'game_id';

class DemoGameController {
  final String userID;
  final String userName;
  final String roomID;
  DemoGameController({
    required this.userID,
    required this.userName,
    required this.roomID,
  });

  void init() {
    ZegoMiniGame().loadedStateNotifier.addListener(onloadedStateUpdated);
  }

  Future<void> uninit() async {
    ZegoMiniGame().loadedStateNotifier.removeListener(onloadedStateUpdated);
    await ZegoMiniGame().unloadGame();
    await ZegoMiniGame().uninitGameSDK();
    await ZegoMiniGame().uninitWebViewController();
  }

  void onloadedStateUpdated() {
    debugPrint('onloadedStateUpdated: ${ZegoMiniGame().loadedStateNotifier.value}');
  }

  String? currentGameID;

  Widget gameView() {
    return ValueListenableBuilder(
      valueListenable: ZegoMiniGame().loadedStateNotifier,
      builder: (context, bool loaded, child) => Offstage(offstage: !loaded, child: child),
      child: InAppWebView(
        initialFile: 'assets/minigame/index.html',
        onWebViewCreated: (InAppWebViewController controller) async {
          ZegoMiniGame().initWebViewController(controller);
        },
        onLoadStop: (controller, url) async {
          final token = await YourGameServer().getToken(
            serverSecret: SDKKeyCenter.serverSecret,
          );

          await ZegoMiniGame().initGameSDK(
            appID: SDKKeyCenter.appID,
            token: token,
            userID: userID,
            userName: userName,
            avatarUrl: 'https://robohash.org/$userID.png?set=set4',
            language: GameLanguage.english,
          );
        },
        onConsoleMessage: (controller, ConsoleMessage msg) async {
          debugPrint('[InAppWebView][${msg.messageLevel}]${msg.message}');
        },
      ),
    );
  }

  Widget gameButton() {
    return ValueListenableBuilder(
      valueListenable: ZegoMiniGame().loadedStateNotifier,
      builder: (context, bool loaded, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (loaded) ...[startGameButton(), const SizedBox(width: 10)],
            if (!loaded) loadGameButton(context) else quitGameButton(context),
          ],
        );
      },
    );
  }

  Widget startGameButton() {
    return ValueListenableBuilder(
      valueListenable: ZegoMiniGame().gameStateNotifier,
      builder: (context, ZegoGameState gameState, _) {
        if (gameState != ZegoGameState.playing) {
          return ElevatedButton(
            onPressed: () async {
              startGame([userID]);
            },
            child: const Text('Start'),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget loadGameButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        showGameListView(context).then((ZegoGameInfo? gameInfo) async {
          if (gameInfo != null) {
            final gameID = gameInfo.miniGameId!;
            debugPrint('loadGame: $gameID');
            final gameList = ZegoMiniGame().getAllGameList();
            // If the gameList has not been loaded successfully at this time,
            // wait here for the game list to be loaded and then proceed to load the game.
            if (gameList.value.where((e) => e.miniGameId == gameID).isEmpty) {
              void onGameListUpdate() {
                if (gameList.value.where((e) => e.miniGameId == gameID).isNotEmpty) {
                  gameList.removeListener(onGameListUpdate);
                  loadGame(gameID);
                }
              }

              gameList.addListener(onGameListUpdate);
            } else {
              loadGame(gameID);
            }
          }
        });
      },
      child: const Text('Game List'),
    );
  }

  Future<void> loadGame(String gameID) async {
    try {
      await ZegoMiniGame().loadGame(
        gameID: gameID,
        gameMode: ZegoGameMode.inroom,
        loadGameConfig: ZegoLoadGameConfig(
          minGameCoin: 0,
          roomID: roomID,
          useRobot: true,
        ),
      );
      debugPrint('[APP]loadGame: $gameID');
      currentGameID = gameID;
    } catch (e) {
      showSnackBar('loadGame:$e');
    }
    try {
      final exchangeUserCurrencyResult = await YourGameServer().exchangeUserCurrency(
        gameID: gameID,
        exchangeValue: 100,
        outOrderId: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      debugPrint('[APP]exchangeUserCurrencyResult: $exchangeUserCurrencyResult');
    } catch (e) {
      showSnackBar('exchangeUserCurrency:$e');
    }
    try {
      final getUserCurrencyResult = await YourGameServer().getUserCurrency(
        userID: userID,
        gameID: gameID,
      );
      debugPrint('[APP]getUserCurrencyResult: $getUserCurrencyResult');
    } catch (e) {
      showSnackBar('getUserCurrency:$e');
    }
  }

  Widget quitGameButton(BuildContext context) {
    return ElevatedButton(
      onPressed: unloadGame,
      child: const Text('Quit'),
    );
  }

  Future<void> unloadGame() async {
    await ZegoMiniGame().unloadGame();
  }

  Future<void> startGame(List<String> playWithUserID) async {
    final gameInfo = ZegoMiniGame().getAllGameList().value.firstWhere((e) => e.miniGameId == currentGameID!);
    final gameMaxPlayer = gameInfo.detail!.player?.reduce(max) ?? 1;
    await ZegoMiniGame().startGame(
      playerList: [
        ...playWithUserID.asMap().entries.map((e) => ZegoPlayer(seatIndex: e.key, userID: e.value)),
      ],
      robotList: playWithUserID.length < gameMaxPlayer
          ? List.generate(
              gameMaxPlayer - playWithUserID.length,
              (index) => ZegoGameRobot(
                robotAvatar: 'https://robohash.org/${Random().nextInt(1000000)}.png',
                seatIndex: playWithUserID.length + index,
                robotName: faker.person.name(),
                robotCoin: 1000,
              ),
            )
          : [],
      gameConfig: ZegoStartGameConfig(
        taxRate: 0,
        minGameCoin: 0,
        timeout: 60,
        taxType: ZegoTaxType.winnerDeduction,
      ),
    );
  }
}
