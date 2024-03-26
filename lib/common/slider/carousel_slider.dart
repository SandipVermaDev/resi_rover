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
  late Stream<QuerySnapshot> _residencyStream;
  int _currentIndex = 0;

  Color gold = const Color(0xFFD7B504);

  @override
  void initState() {
    super.initState();
    _residencyStream = FirebaseFirestore.instance.collection('residencies').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _residencyStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(
                color: gold,
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No residency data available.');
            }

            final residencyData = snapshot.data!.docs.first.data() as Map<String, dynamic>?;

            if (residencyData == null) {
              return const Center(child: Text('Residency data is null.'));
            }

            final residencyName = residencyData['residencyName'] as String;
            final residencyImages = List<String>.from(residencyData['images'] ?? []);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    residencyName,
                    style: const TextStyle(
                        color: Colors.purple, fontSize: 30, fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                const SizedBox(height: 15),
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
                      items: residencyImages.map((String url) {
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
                        children: residencyImages.asMap().entries.map((entry) {
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
        ),
      ],
    );
  }
}
