part of 'game_page.dart';

String get attributeKeyRoomGame => 'game_id';

class DemoGameController {
  final String userID;
  final String userName;
  DemoGameController({required this.userID, required this.userName});

  void init() {
    //
  }

  Future<void> uninit() async {
    await ZegoMiniGame().unloadGame();
    await ZegoMiniGame().uninitGameSDK();
    await ZegoMiniGame().uninitWebViewController();
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

  Future<void> loadGame({required String gameID, required String roomID}) async {
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
