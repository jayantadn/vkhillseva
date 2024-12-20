import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final String? image;

  const LoadingOverlay({super.key, this.image});

  @override
  Widget build(BuildContext context) {
    double size = 150.0;

    return Stack(
      children: [
        ModalBarrier(
          color: Colors.black.withOpacity(0.5),
          dismissible: false,
        ),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(
                width: size,
                height: size,
                child: ClipOval(
                  child: Image.asset(
                    image ?? 'assets/images/Logo/KrishnaLilaPark_circle.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
