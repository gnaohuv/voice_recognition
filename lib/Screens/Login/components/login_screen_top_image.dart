import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants.dart';

class LoginScreenTopImage extends StatelessWidget {
  const LoginScreenTopImage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "ĐĂNG NHẬP",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: defaultPadding * 2),
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 8,
              child: SizedBox(
                width: 150,  // Kích thước giới hạn của SizedBox
                height: 150,
                child: SvgPicture.asset("assets/images/robot-svgrepo-com.svg"),
              ),
            ),
            const Spacer(),
          ],

        ),
        const SizedBox(height: defaultPadding * 2),
      ],
    );
  }
}
