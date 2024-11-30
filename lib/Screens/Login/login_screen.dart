import 'package:flutter/material.dart';
import 'package:voice_recognize/responsive.dart';
import 'package:voice_recognize/screens/Login/components/login_form.dart';
import 'package:voice_recognize/screens/Login/components/login_screen_top_image.dart';
import '../../components/background.dart';
import 'components/voice_login.dart';
import 'package:voice_recognize/constants.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Background(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        physics: const BouncingScrollPhysics(),
        child: const Responsive(
          mobile: MobileLoginScreen(),
          desktop: Row(
            children: [
              Expanded(
                child: LoginScreenTopImage(),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 450,
                      child: LoginForm(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MobileLoginScreen extends StatelessWidget {
  const MobileLoginScreen({Key? key}) : super(key: key);

  void _voiceLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceLoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const LoginScreenTopImage(),
        Row(
          children: const [
            Spacer(),
            Expanded(
              flex: 8,
              child: LoginForm(),
            ),
            Spacer(),
          ],
        ),
        const SizedBox(height: 20), // Tạo khoảng cách giữa form và văn bản
        VoiceLoginText(
          press: () {
            _voiceLogin(context); // Chuyển đến màn hình VoiceLoginScreen khi nhấn
          },
        ),
      ],
    );
  }
}

class VoiceLoginText extends StatelessWidget {
  final Function? press;
  const VoiceLoginText({
    Key? key,
    required this.press,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          "Hoặc ",
          style: const TextStyle(color: kPrimaryColor),
        ),
        GestureDetector(
          onTap: press as void Function()?,
          child: Text(
            "Đăng nhập bằng giọng nói",
            style: const TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }
}
