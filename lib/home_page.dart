import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:voice_recognize/feature_box.dart';
import 'package:voice_recognize/openai_sevice.dart';
import 'package:voice_recognize/pallete.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Screens/Login/login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final speechToText = SpeechToText();
  final flutterTts = FlutterTts();
  String lastWords = "";
  final OpenAIService openAIService = OpenAIService();
  String? generatedContent;
  String? generatedImageUrl;
  int start = 200;
  int delay = 200;
  TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initSpeechToText();
    initTextToSpeech();
  }

  Future<void> initTextToSpeech() async {
    await flutterTts.setSharedInstance(true);
    await flutterTts.setLanguage("vi-VN");
    setState(() {});
  }

  Future<void> initSpeechToText() async {
    await speechToText.initialize();
    setState(() {});
  }

  Future<void> startListening() async {
    await speechToText.listen(onResult: onSpeechResult);
    setState(() {});
  }

  Future<void> stopListening() async {
    await speechToText.stop();
    setState(() {});
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords;
      _textController.text = lastWords;
    });
  }

  Future<void> systemSpeak(String content) async {
    await flutterTts.speak(content);
  }

  @override
  void dispose() {
    super.dispose();
    speechToText.stop();
    flutterTts.stop();
    _textController.dispose();
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      // Hiển thị thông báo lỗi nếu có vấn đề khi đăng xuất
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng xuất thất bại: $e")),
      );
    }
  }


  void _showUserInfo() {
    // Implement chức năng hiển thị thông tin cá nhân
  }

  void _showSearchHistory() {
    // Implement chức năng hiển thị lịch sử tìm kiếm
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BounceInDown(child: const Text("Mae")),
        centerTitle: true,
        backgroundColor: Pallete.assistantCircleColor,
      ),
      drawer: Drawer(
        backgroundColor: Pallete.assistantCircleColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Pallete.assistantCircleColor,
              ),
              child: Text(
                'Tùy chọn',
                style: TextStyle(
                  color: Pallete.blackColor,
                  fontSize: 24,
                  fontFamily: 'Cera Pro',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person, color: Pallete.mainFontColor),
              title: Text(
                'Thông tin cá nhân',
                style: TextStyle(
                  color: Pallete.mainFontColor,
                  fontSize: 16,
                  fontFamily: 'Cera Pro',
                ),
              ),
              onTap: _showUserInfo,
            ),
            ListTile(
              leading: Icon(Icons.history, color: Pallete.mainFontColor),
              title: Text(
                'Lịch sử tìm kiếm',
                style: TextStyle(
                  color: Pallete.mainFontColor,
                  fontSize: 16,
                  fontFamily: 'Cera Pro',
                ),
              ),
              onTap: _showSearchHistory,
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Pallete.mainFontColor),
              title: Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Pallete.mainFontColor,
                  fontSize: 16,
                  fontFamily: 'Cera Pro',
                ),
              ),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Ảnh trợ lý ảo
            ZoomIn(
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      height: 100,
                      width: 100,
                      margin: EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: Pallete.assistantCircleColor,
                        shape: BoxShape.circle
                      ),
                    ),
                  ),
                  Container(
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(image: AssetImage('assets/images/virtualAssistant.png'))
                    ),
                  )
                ],
              ),
            ),
            // Khung chat
            FadeInRight(
              child: Visibility(
                visible: generatedImageUrl == null,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 40).copyWith(
                      top: 3,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Pallete.borderColor,
                    ),
                    borderRadius: BorderRadius.circular(20).copyWith(
                      topLeft: Radius.zero,
                    )
                  ),
                  child:  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child:  Text(
                      generatedContent == null ? "Chào buổi sáng, tôi có thể giúp gì cho bạn ?" : generatedContent!,
                    style: TextStyle(
                      color: Pallete.mainFontColor,
                      fontSize: generatedContent == null ? 20 : 15,
                      fontFamily: 'Cera Pro',
                    ),),
                  ),
                ),
              ),
            ),
            if(generatedImageUrl != null)
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: ClipRRect(borderRadius:BorderRadius.circular(20),
                  child: Image.network(generatedImageUrl!)),
            ),
            SlideInLeft(
              child: Visibility(
                visible: generatedContent == null  && generatedImageUrl == null,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(
                    top:10,
                    left: 22,
                  ),
                  child: const Text("Một số tính năng chính",
                    style: TextStyle(
                      fontFamily: "Cera Pro",
                      color: Pallete.mainFontColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Gợi ý
            Visibility(
              visible: generatedContent == null,
              child:  SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SlideInDown(
                      delay: Duration(milliseconds: start),
                      child: const FeatureBox(
                      color: Pallete.firstSuggestionBoxColor,
                      headerText: "ChatGPT",
                        descriptionText: "Hỗ trợ bạn mọi lúc, hiểu bạn từng câu, đáp ứng nhanh chóng và thông minh với ChatGPT",
                      ),
                    ),
                    SlideInDown(
                      delay: Duration(milliseconds: start + delay),
                      child: const FeatureBox(
                        color: Pallete.secondSuggestionBoxColor,
                        headerText: "Dall-E",
                        descriptionText: "DALL-E là công cụ sáng tạo hình ảnh bằng AI, biến mọi ý tưởng thành tác phẩm nghệ thuật độc đáo",
                      ),
                    ),
                    SlideInDown(
                      delay: Duration(milliseconds: start + 2 * delay),
                      child: const FeatureBox(
                        color: Pallete.thirdSuggestionBoxColor,
                        headerText: "Smart Voice Assistant",
                        descriptionText: "Kết nối bạn với thế giới thông qua lời nói, hỗ trợ mọi yêu cầu nhanh chóng và tiện lợi",
                      ),
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            // Container(
            //   padding: const EdgeInsets.all(10),
            //   alignment: Alignment.centerLeft,
            //   margin: const EdgeInsets.only(
            //     top: 10,
            //     left: 22,
            //   ),
            //   child: Text(
            //     "You said: $lastWords",
            //     style: const TextStyle(
            //       fontFamily: "Cera Pro",
            //       color: Pallete.mainFontColor,
            //       fontSize: 15,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // ),
            // Khung nhập dữ liệu
            Padding(
              padding: const EdgeInsets.only(right: 5, left: 10,top: 5,bottom: 50),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(5),
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: "Nhập tin nhắn hoặc nói...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            lastWords = value;
                          });
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    color:Pallete.secondSuggestionBoxColor,
                    icon: Icon(Icons.send),
                    onPressed: () async {
                      if (_textController.text.isNotEmpty) {
                        final response = await openAIService.chatGPTAPI(_textController.text);
                        setState(() {
                          generatedContent = response;
                        });
                        await systemSpeak(response);
                        _textController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Pallete.firstSuggestionBoxColor,
        onPressed:() async{
          if(await speechToText.hasPermission && speechToText.isNotListening){
            await startListening();
          }
          else if(speechToText.isListening){
            final speech = await  openAIService.isArtPromptAPI(lastWords);
            if(speech.contains('https')){
              generatedImageUrl = speech;
              generatedContent = null;
              setState(() {
              });
            }else{
              generatedImageUrl = null;
              generatedContent = speech;
              setState(() {
              });
              await systemSpeak(speech);
            }
            await systemSpeak(speech);
            await stopListening();

          }
          else{
            initSpeechToText();
          }
        },
        child: Icon(speechToText.isListening ? Icons.stop: Icons.mic),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
