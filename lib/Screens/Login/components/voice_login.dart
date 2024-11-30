import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:voice_recognize/home_page.dart';

const defaultPadding = 16.0;

class VoiceLoginScreen extends StatefulWidget {
  const VoiceLoginScreen({Key? key}) : super(key: key);

  @override
  _VoiceLoginScreenState createState() => _VoiceLoginScreenState();
}

class _VoiceLoginScreenState extends State<VoiceLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  String? recordedFilePath;
  bool isRecording = false;
  bool isPlaying = false;
  String? _similarityResult;
  String? _userId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    await _recorder!.openRecorder();
    await _player!.openPlayer();
    await _requestMicrophonePermission();
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
    Directory tempDir = await getTemporaryDirectory();
    recordedFilePath = '${tempDir.path}/voice_login.wav';

    setState(() {
      isRecording = true;
    });

    await _recorder!.startRecorder(
      toFile: recordedFilePath,
      codec: Codec.pcm16WAV,
    );
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() {
      isRecording = false;
    });
  }

  Future<void> _playRecording() async {
    if (recordedFilePath != null && !isPlaying) {
      setState(() {
        isPlaying = true;
      });

      await _player!.startPlayer(
        fromURI: recordedFilePath,
        codec: Codec.pcm16WAV,
        whenFinished: () {
          setState(() {
            isPlaying = false;
          });
        },
      );
    }
  }

  Future<void> _stopPlaying() async {
    await _player!.stopPlayer();
    setState(() {
      isPlaying = false;
    });
  }

  Future<void> _authenticateAndRetrieveUid() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      setState(() {
        _userId = userCredential.user?.uid;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Xác thực thành công"),
            content: const Text("Vui lòng ghi âm mẫu giọng nói..."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi xác thực: $e")),
      );
    }
  }

  Future<void> _compareVoice() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng xác thực trước khi so sánh giọng nói")),
      );
      return;
    }

    // Hiển thị hộp thoại tải ngay lập tức
    setState(() {
      isLoading = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Đang so sánh giọng nói..."),
            ],
          ),
        );
      },
    );

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("voice_recordings/$_userId/recorded_audio.wav");

      final refFile = await storageRef.getDownloadURL();
      final directory = await getTemporaryDirectory();
      final refPath = '${directory.path}/reference_audio.wav';

      final refFileData = await http.get(Uri.parse(refFile));
      File(refPath).writeAsBytesSync(refFileData.bodyBytes);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://voice-api-uvym.onrender.com/compare/'),
      );
      request.files.add(await http.MultipartFile.fromPath('file1', refPath));
      request.files.add(await http.MultipartFile.fromPath('file2', recordedFilePath!));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      setState(() {
        _similarityResult = responseData;
      });

      final similarityString = responseData.replaceAll(RegExp(r'[^0-9.]'), '');
      final similarity = double.parse(similarityString);

      Navigator.of(context).pop(); // Đóng hộp thoại tải
      setState(() {
        isLoading = false;
      });

      // Kiểm tra và hiển thị kết quả
      if (similarity > 0.6) {
        _showResultDialog("Đăng nhập thành công", "Giọng nói khớp với tài khoản.");
      } else {
        _showResultDialog("Đăng nhập thất bại", "Giọng nói không khớp.");
      }
    } catch (e) {
      Navigator.of(context).pop(); // Đóng loading nếu có lỗi xảy ra
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi so sánh giọng nói: $e")),
      );
    }
  }

  // Tạo hàm hiển thị dialog kết quả để tái sử dụng
  void _showResultDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (title == "Đăng nhập thành công") {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập bằng giọng nói'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: defaultPadding),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Mật khẩu",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: defaultPadding),
                ElevatedButton(
                  onPressed: _authenticateAndRetrieveUid,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text("Xác thực", style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: defaultPadding),
                ElevatedButton(
                  onPressed: isRecording ? _stopRecording : _startRecording,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: isRecording ? Colors.red : Colors.orange,
                  ),
                  child: Text(
                    isRecording ? 'Dừng ghi âm' : 'Bắt đầu ghi âm',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: defaultPadding),
                if (recordedFilePath != null)
                  ElevatedButton(
                    onPressed: isPlaying ? _stopPlaying : _playRecording,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(
                      isPlaying ? 'Dừng phát' : 'Phát lại bản ghi',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                const SizedBox(height: defaultPadding),
                ElevatedButton(
                  onPressed: _compareVoice,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text("Đăng nhập", style: TextStyle(fontSize: 16)),
                ),
                if (_similarityResult != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: defaultPadding),
                    child: Text(
                      'Kết quả so sánh: $_similarityResult',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _recorder?.closeRecorder();
    _player?.closePlayer();
    super.dispose();
  }
}
