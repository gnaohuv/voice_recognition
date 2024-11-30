import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../components/already_have_an_account_acheck.dart';
import '../../../constants.dart';
import '../../Login/login_screen.dart';
import '../components/voice_record.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({Key? key}) : super(key: key);

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController(); // Thêm controller cho password
  String? email;
  String? password;
  String? confirmPassword;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'Email này đã được sử dụng bởi một tài khoản khác.';
      case 'invalid-email':
        return 'Email không hợp lệ. Vui lòng kiểm tra lại.';
      case 'operation-not-allowed':
        return 'Tài khoản không được phép đăng ký vào lúc này.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
      default:
        return 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.';
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Lỗi"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _trySignUp() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    _formKey.currentState!.save();
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email!,
        password: password!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thu âm giọng nói của bạn.')),
      );

      // Chuyển đến màn hình thu âm với userId của người dùng
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VoiceRecordingScreen(userId: userCredential.user!.uid),
        ),
      );
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getErrorMessage(e.code);
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog('Đã xảy ra lỗi không xác định. Vui lòng thử lại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            cursorColor: kPrimaryColor,
            onSaved: (newValue) => email = newValue,
            validator: (value) {
              if (value == null || value.isEmpty || !value.contains('@')) {
                return 'Vui lòng nhập email hợp lệ';
              }
              return null;
            },
            decoration: const InputDecoration(
              hintText: "Email",
              prefixIcon: Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(Icons.person),
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          TextFormField(
            controller: _passwordController,  // Gán controller cho trường mật khẩu
            textInputAction: TextInputAction.next,
            obscureText: !_isPasswordVisible,
            cursorColor: kPrimaryColor,
            onSaved: (newValue) => password = newValue,
            validator: (value) {
              if (value == null || value.isEmpty || value.length < 6) {
                return 'Mật khẩu phải chứa ít nhất 6 ký tự';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: "Mật khẩu",
              prefixIcon: const Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(Icons.lock),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          TextFormField(
            textInputAction: TextInputAction.done,
            obscureText: !_isConfirmPasswordVisible,
            cursorColor: kPrimaryColor,
            onSaved: (newValue) => confirmPassword = newValue,
            validator: (value) {
              if (value == null || value.isEmpty || value != _passwordController.text) {
                return 'Mật khẩu xác nhận không khớp';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: "Xác nhận mật khẩu",
              prefixIcon: const Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(Icons.lock),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          ElevatedButton(
            onPressed: _trySignUp,
            child: Text("Đăng ký".toUpperCase()),
          ),
          const SizedBox(height: defaultPadding),
          AlreadyHaveAnAccountCheck(
            login: false,
            press: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const LoginScreen();
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
