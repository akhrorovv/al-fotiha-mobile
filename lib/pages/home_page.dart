import 'dart:io';

import 'package:al_fotiha/pages/recording_page.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../services/db_service.dart';
import '../widgets/chat_bubble.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late YoutubePlayerController _controller;
  final SqlService _sqlService = SqlService();
  List<String> _audioPaths = [];
  bool isLoading = true;
  late Directory appDirectory;
  late PlayerController controller;

  late final RecorderController recorderController;


  void didPopNext() {
    // This is called when coming back to this page.
    _loadAudios();
  }


  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    _getDir();
    controller = PlayerController();
    _controller = YoutubePlayerController(
      initialVideoId:
          YoutubePlayer.convertUrlToId("https://youtu.be/PLHddf-1MHY")!,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
  }



  void _getDir() async {
    appDirectory = await getApplicationDocumentsDirectory();
    // path = "${appDirectory.path}/recording.m4a";
    isLoading = false;
    setState(() {});
  }

  String formatDate(String input) {
    // Parse the input string to a DateTime object
    DateTime dateTime = DateTime.parse(input);

    // Format the date and time as per the desired output
    String formattedDate =
        "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}, "
        "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year.toString().substring(2)}";

    return formattedDate;
  }

  void _initializeDatabase() async {
    await _sqlService.init();
    _loadAudios();
  }

  void _loadAudios() async {
    final audios = await _sqlService.loadAudios();
    setState(() {
      _audioPaths = audios;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromRGBO(245, 247, 249, 1),
      systemNavigationBarColor: Colors.white,
    ));
    return Scaffold(
      backgroundColor: const Color.fromRGBO(245, 247, 249, 1),
      body: SafeArea(
        child: Column(
          children: [
            /// app bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15.5),
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded, size: 15),
                  Text(
                    "Fotiha surasi",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(width: 24),
                ],
              ),
            ),

            Expanded  (
              child: Container(
                margin: const EdgeInsets.only(left: 8, right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    /// you tube video
                    Container(
                      margin: const EdgeInsets.only(right: 31),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color.fromRGBO(245, 247, 249, 1),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: YoutubePlayerBuilder(
                              player: YoutubePlayer(
                                controller: _controller,
                                bottomActions: const [
                                  ProgressBar(isExpanded: true),
                                  RemainingDuration(),
                                ],
                              ),
                              builder: (context, player) {
                                return player;
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Fotiha surasida yo‘l qo‘yilishi mumkin bo‘lgan xatolar ",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          )
                        ],
                      ),
                    ),

                    Expanded(
                      // stored audios show there
                      child: ListView.builder(
                        itemCount: _audioPaths.length,
                        itemBuilder: (context, index) {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 312,

                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.only(bottom: 8, top: 8, right: 8),
                              // height: 82,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: const Color.fromRGBO(245, 247, 249, 1),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    height: 50,
                                    child: WaveBubble(
                                      color: const Color.fromRGBO(245, 247, 249, 1),
                                      path: _audioPaths[index],
                                      // isSender: true,
                                      appDirectory: appDirectory,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text("Audio ${index + 1}"),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),

            /// Button
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(4),
              height: 72,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(33.0),
                  topRight: Radius.circular(33.0),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.only(left: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(64),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Qiroatni tekshirish...",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(147, 158, 197, 1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecordingPage(),
                          ),
                        ).then((_) {
                          // This is called when returning to the current page
                          _loadAudios();
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(
                            top: 12, bottom: 12, right: 12),
                        padding: const EdgeInsets.only(left: 16, right: 20),
                        width: 148,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(48),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Qiroat qilish",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
