import 'package:flutter/material.dart';

class FavouriteTracksScreen extends StatelessWidget {
  const FavouriteTracksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Text("Favourite Tracks"),
    );
  }
}
