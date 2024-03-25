import 'package:flutter/material.dart';

class LikedByPage extends StatefulWidget {
  final List<String> likes;

  const LikedByPage({super.key, required this.likes});

  @override
  State<LikedByPage> createState() => _LikedByPageState();
}

class _LikedByPageState extends State<LikedByPage> {
  Color gold = const Color(0xFFD7B504);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Liked By',style: TextStyle(color: gold)),
        iconTheme: IconThemeData(color: gold),
      ),
      body: Container(
        color: Colors.grey,
        child: ListView(
          children: widget.likes.map((userEmail) {
            return Padding(
              padding: const EdgeInsets.only(left: 16,right: 16,top: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  title: Text(userEmail,style: TextStyle(color: gold)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
