import 'package:flutter/material.dart';

import '../../internal/business/pip.dart';

/// pip
class ZegoPIPButton extends StatelessWidget {
  const ZegoPIPButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ZegoPIPController().enable(),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 51, 52, 56).withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            Icons.picture_in_picture_alt,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
