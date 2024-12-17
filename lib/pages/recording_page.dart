import 'dart:async';
import 'dart:io';

import 'package:al_fotiha/services/db_service.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/chat_bubble.dart';

class RecordingPage extends StatefulWidget {
  const RecordingPage({super.key});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  late final RecorderController recorderController;
  late PlayerController controller;

  final SqlService _sqlService = SqlService();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;

  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  String? _recordedFilePath;
  late Directory appDirectory;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _sqlService.init();
    controller = PlayerController();
  }

  Future<void> _initializeAudio() async {
    await Permission.microphone.request();

    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  Future<void> _startRecording() async {
    if (await Permission.microphone.isGranted) {
      Directory appDir = await getApplicationDocumentsDirectory();
      String filePath =
          '${appDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';
      appDirectory = appDir;

      await _recorder.startRecorder(toFile: filePath);

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero; // Reset the duration
        _recordedFilePath = null; // Reset previous recording
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration = _recordingDuration + const Duration(seconds: 1);
        });
      });
    } else {
      print("Microphone permission is not granted");
    }
  }

  Future<void> _stopRecording() async {
    String? filePath = await _recorder.stopRecorder();

    // Stop the timer
    _timer?.cancel();

    setState(() {
      _isRecording = false;
      _recordedFilePath = filePath; // Save the recording path
    });
  }

  // Future<void> _playRecording() async {
  //   if (_recordedFilePath != null && File(_recordedFilePath!).existsSync()) {
  //     await _player.startPlayer(
  //       fromURI: _recordedFilePath,
  //       whenFinished: () {
  //         setState(() {
  //           _isPlaying = false;
  //         });
  //       },
  //     );
  //     setState(() {
  //       _isPlaying = true;
  //     });
  //   }
  // }

  // Stop audio playback
  Future<void> _stopPlayback() async {
    await _player.stopPlayer();
    setState(() {
      _isPlaying = false;
    });
  }

  // Delete the recorded audio
  void _deleteRecording() {
    if (_recordedFilePath != null && File(_recordedFilePath!).existsSync()) {
      File(_recordedFilePath!).deleteSync();
    }
    setState(() {
      _recordedFilePath = null; // Clear the recorded file
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    super.dispose();
    _recorder.closeRecorder();
    _player.closePlayer();
    _timer?.cancel();
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
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                  ),
                  Text(
                    "Fotiha surasini qiroat qilish",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(width: 24),
                ],
              ),
            ),

            const SizedBox(height: 8),

            /// image
            Container(
              margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
              height: 463,
              child: Image.asset("assets/images/fotiha.png"),
            ),

            Expanded(
              // in here, record audio, send button etc.
              child: Column(
                children: [
                  if (_isRecording) ...[
                    const SizedBox(height: 22),
                    Text(
                      _formatDuration(_recordingDuration),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 38),
                  ],
                  if (!_isRecording && _recordedFilePath == null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 47),
                      child: Text(
                        "Qiroatni yozib yuborish uchun quyidagi tugmani 1 marta bosing",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 47),
                      child: Text(
                        "Qiroatni 10dan 120 sekundgacha yuboring",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color.fromRGBO(123, 126, 135, 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (_recordedFilePath != null) ...[
                    Column(
                      children: [
                        /// audio wave
                        Container(
                          height: 43,
                          width: double.infinity,
                          child: WaveBubble(
                            color: Colors.white,
                            path: _recordedFilePath,
                            appDirectory: appDirectory,
                          ),
                        ),
                        const SizedBox(height: 27),

                        Text(
                          _formatDuration(_recordingDuration),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w400),
                        ),

                        const SizedBox(height: 27),

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
                          child: Row(
                            children: [
                              // play and pause
                              GestureDetector(
                                onTap: () async {
                                  controller.playerState.isPlaying
                                      ? await controller.pausePlayer()
                                      : await controller.startPlayer();
                                  controller.setFinishMode(
                                      finishMode: FinishMode.pause);
                                },
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(64),
                                    color:
                                        const Color.fromRGBO(245, 245, 253, 1),
                                  ),
                                  child: Icon(
                                    controller.playerState.isPlaying
                                        ? Icons.stop
                                        : Icons.play_arrow,
                                    size: 30,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    _sqlService.saveAudio(_recordedFilePath!);
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      color:
                                          const Color.fromRGBO(48, 191, 119, 1),
                                      borderRadius: BorderRadius.circular(64),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "Yuborish",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // delete
                              GestureDetector(
                                onTap: _deleteRecording,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(64),
                                    color:
                                        const Color.fromRGBO(245, 245, 253, 1),
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Color.fromRGBO(121, 131, 169, 1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_recordedFilePath == null)
                    GestureDetector(
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(48, 191, 119, 1),
                          borderRadius: BorderRadius.circular(44),
                        ),
                        child: Center(
                          child: _isRecording
                              ? const Icon(
                                  Icons.pause,
                                  color: Colors.white,
                                )
                              : const Icon(
                                  Icons.mic,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
