import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

class WaveBubble extends StatefulWidget {
  final int? index;
  final String? path;
  final double? width;
  final Directory appDirectory;
  final Color color;

  const WaveBubble({
    super.key,
    required this.appDirectory,
    this.width,
    this.index,
    this.path,
    required this.color,
  });

  @override
  State<WaveBubble> createState() => _WaveBubbleState();
}

class _WaveBubbleState extends State<WaveBubble> {
  File? file;

  late PlayerController controller;
  late StreamSubscription<PlayerState> playerStateSubscription;

  final playerWaveStyle = const PlayerWaveStyle(
    fixedWaveColor: Color.fromRGBO(186, 194, 226, 1),
    liveWaveColor: Color.fromRGBO(70, 131, 250, 1),
    spacing: 6,
    showSeekLine: false,
  );

  @override
  void initState() {
    super.initState();
    controller = PlayerController();
    _preparePlayer();
    playerStateSubscription = controller.onPlayerStateChanged.listen((_) {
      setState(() {});
    });
  }

  void _preparePlayer() async {
    if (widget.index == null && widget.path == null && file?.path == null) {
      return;
    }
    // Prepare player with extracting waveform if index is even.
    controller.preparePlayer(
      path: widget.path ?? file!.path,
      shouldExtractWaveform: widget.index?.isEven ?? true,
    );
    // Extracting waveform separately if index is odd.
    if (widget.index?.isOdd ?? false) {
      controller
          .extractWaveformData(
            path: widget.path ?? file!.path,
            noOfSamples:
                playerWaveStyle.getSamplesForWidth(widget.width ?? 200),
          )
          .then((waveformData) => debugPrint(waveformData.toString()));
    }
  }

  @override
  void dispose() {
    playerStateSubscription.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.path != null || file?.path != null
        ? Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: widget.color,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 8),
                if (!controller.playerState.isStopped)
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(70, 131, 250, 1),
                      borderRadius: BorderRadius.circular(44),
                    ),
                    child: Center(
                      child: IconButton(
                        onPressed: () async {
                          controller.playerState.isPlaying
                              ? await controller.pausePlayer()
                              : await controller.startPlayer();
                          controller.setFinishMode(
                              finishMode: FinishMode.pause);
                        },
                        icon: Icon(
                          controller.playerState.isPlaying
                              ? Icons.stop
                              : Icons.play_arrow,
                          size: 25,
                        ),
                        color: Colors.white,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                AudioFileWaveforms(
                  size: Size(MediaQuery.of(context).size.width / 2 + 35, 100),
                  playerController: controller,
                  waveformType: WaveformType.long,
                  enableSeekGesture: true,
                  playerWaveStyle: playerWaveStyle,
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
  }
}
