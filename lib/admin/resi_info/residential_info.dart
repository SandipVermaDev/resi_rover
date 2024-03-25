import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resi_rover/admin/resi_info/add_residency.dart';
import 'package:resi_rover/admin/resi_info/edit_residency.dart';

class ResidentialInfoPage extends StatefulWidget {
  const ResidentialInfoPage({super.key});

  @override
  _ResidentialInfoPageState createState() => _ResidentialInfoPageState();
}

class _ResidentialInfoPageState extends State<ResidentialInfoPage> {
  Color gold = const Color(0xFFD7B504);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade400,
      appBar: AppBar(
        title: Text('Residential Information', style: TextStyle(color: gold)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance.collection('residencies').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<Widget> residencyWidgets = [];
            for (var doc in snapshot.data!.docs) {
              var residencyData = doc.data();
              String residencyName = residencyData['residencyName'];
              List<dynamic> images = residencyData['images'];
              Map<String, List<dynamic>> wingsAndFlats =
                  Map<String, List<dynamic>>.from(
                      residencyData['wingsAndFlats']);

              residencyWidgets.add(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: const Text('Residency Name',
                          style: TextStyle(color: Colors.black)),
                      subtitle: Text(residencyName,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 26)),
                    ),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          if (images[index] is String) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(images[index] as String),
                            );
                          } else {
                            return const SizedBox();
                          }
                        },
                      ),
                    ),
                    ...wingsAndFlats.entries.map((entry) {
                      String wing = entry.key;
                      List<String> flats = entry.value.cast<String>();
                      return Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20,top: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: gold
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Wing $wing',
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 15)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: flats
                                      .map((flat) => Text('Flat $flat',
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 15)))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 60),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: residencyWidgets,
              ),
            );
          }
        },
      ),
      floatingActionButton: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('residencies').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Loading state
            return FloatingActionButton(
              onPressed: () {},
              backgroundColor: Colors.black,
              child: Icon(Icons.add, color: gold),
            );
          } else if (snapshot.hasError) {
            // Error state
            return FloatingActionButton(
              onPressed: () {},
              backgroundColor: Colors.black,
              child: Icon(Icons.add, color: gold),
            );
          } else {
            final List<DocumentSnapshot> documents = snapshot.data!.docs;
            final bool residencyExists = documents.isNotEmpty;
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  onPressed: () {
                    if (residencyExists) {
                      // Navigate to edit page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditResidencyPage(residencyData: documents[0].data() as Map<String, dynamic>)),
                      );
                    } else {
                      // Navigate to add page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddResidencyPage()),
                      );
                    }
                  },
                  backgroundColor: Colors.black,
                  icon: Icon(residencyExists ? Icons.edit : Icons.add, color: gold),
                  label: Text(residencyExists ? 'Edit' : 'Add', style: TextStyle(color: gold)),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
