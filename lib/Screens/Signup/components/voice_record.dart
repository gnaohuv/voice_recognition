import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter_sound/flutter_sound.dart' as fs;
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../Login/login_screen.dart';

class VoiceRecordingScreen extends StatefulWidget {
  final String userId;

  const VoiceRecordingScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _VoiceRecordingScreenState createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  late ap.AudioPlayer audioPlayer;
  fs.FlutterSoundRecorder? _recorder;
  String? recordedFilePath;
  bool isRecording = false;
  bool isRecorded = false;

  @override
  void initState() {
    super.initState();
    audioPlayer = ap.AudioPlayer();
    _recorder = fs.FlutterSoundRecorder();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    await _recorder!.openRecorder();
  }

  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không có quyền truy cập micro")),
      );
    }
  }

  Future<void> _startRecording() async {
    await _requestMicrophonePermission();
    Directory tempDir = await getTemporaryDirectory();
    recordedFilePath = '${tempDir.path}/recorded_audio.wav';

    setState(() {
      isRecording = true;
      isRecorded = false;
    });

    await _recorder!.startRecorder(
      toFile: recordedFilePath,
      codec: fs.Codec.pcm16WAV,
    );
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() {
      isRecording = false;
      isRecorded = true;
    });

    if (recordedFilePath != null) {
      await _uploadFileToFirebase(recordedFilePath!);
    }
  }

  Future<void> _playRecording() async {
    if (recordedFilePath != null) {
      await audioPlayer.play(ap.DeviceFileSource(recordedFilePath!));
    }
  }

  Future<void> _uploadFileToFirebase(String filePath) async {
    final file = File(filePath);
    final storageRef = FirebaseStorage.instance
        .ref()
        .child("voice_recordings/${widget.userId}/recorded_audio.wav");

    try {
      await storageRef.putFile(file);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã upload file lên Firebase")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể upload file: $e")),
      );
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thu âm giọng nói'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Vui lòng nói câu sau:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              '“Học viện Kỹ thuật Mật mã (KMA)”',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isRecording ? Colors.redAccent : Colors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  isRecording ? "Đang ghi âm..." : isRecorded ? "Ghi âm hoàn tất" : "Bấm để bắt đầu ghi âm",
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isRecording ? null : _startRecording,
              icon: const Icon(Icons.mic, color: Colors.white),
              label: const Text('Bắt đầu ghi âm', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                primary: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: isRecording ? _stopRecording : null,
              icon: const Icon(Icons.stop, color: Colors.white),
              label: const Text('Dừng ghi âm', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: isRecorded ? _playRecording : null,
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text('Nghe lại', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                primary: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (isRecorded)
              ElevatedButton.icon(
                onPressed: _navigateToLogin,
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Hoàn thành', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }
}
