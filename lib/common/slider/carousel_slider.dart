import 'dart:async';

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';


class ResidencyCarousel extends StatefulWidget {
  const ResidencyCarousel({super.key});

  @override
  _ResidencyCarouselState createState() => _ResidencyCarouselState();
}

class _ResidencyCarouselState extends State<ResidencyCarousel> {
  late String _residencyName = '';
  late List<String> _residencyImages = [];
  int _currentIndex = 0;
  late Timer _timer;

  Color gold = const Color(0xFFD7B504);

  @override
  void initState() {
    super.initState();
    _fetchResidencyDetails();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _fetchResidencyDetails() async {
    final QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('residencies').get();
    final Map<String, dynamic> firstResidencyData =
        querySnapshot.docs.first.data() as Map<String, dynamic>;
    setState(() {
      _residencyName = firstResidencyData['residencyName'] as String;
      _residencyImages = List<String>.from(firstResidencyData['images']);
    });
    _startImageSlider();
  }

  void _startImageSlider() {
    if (_residencyImages.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _residencyImages.length;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            _residencyName,
            style: const TextStyle(
                color: Colors.purple, fontSize: 28, fontWeight: FontWeight.bold
            ),
          ),
        ),
        const SizedBox(height: 20),
        Stack(
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                viewportFraction: 1.0,
                enlargeCenterPage: true,
                autoPlay: true,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
              items: _residencyImages.map((String url) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple, width: 3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                        /*child: Image.network(
                          url,
                          fit: BoxFit.cover,
                        ),*/
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _residencyImages.asMap().entries.map((entry) {
                  int index = entry.key;
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentIndex == index ? gold : gold.withOpacity(0.4),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
