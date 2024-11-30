import 'package:flutter/material.dart';
import 'package:voice_recognize/pallete.dart';

class FeatureBox extends StatelessWidget {
  final Color color;
  final String headerText;
  final String descriptionText;

  const FeatureBox({
    super.key,
    required this.color,
    required this.headerText,
    required this.descriptionText,
  });

  @override
  Widget build(BuildContext context) {
    // Xác định kích thước của thẻ dựa trên chiều rộng màn hình
    final size = MediaQuery.of(context).size;
    final boxSize = size.width * 0.45; // 30% của chiều rộng màn hình

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      width: boxSize,
      height: boxSize*1.3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.all(
          Radius.circular(15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headerText,
              style: const TextStyle(
                fontFamily: "Cera Pro",
                color: Pallete.blackColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              descriptionText,
              style: TextStyle(
                fontFamily: "Cera Pro",
                color: Pallete.blackColor,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

