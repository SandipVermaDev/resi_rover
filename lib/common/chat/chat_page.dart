import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final CollectionReference _chatCollection =
      FirebaseFirestore.instance.collection('chat');
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  Color gold = const Color(0xFFD7B504);

  late StreamController<QuerySnapshot> _streamController;
  late Stream<QuerySnapshot> _stream;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<QuerySnapshot>();
    _stream = _chatCollection
        .orderBy('timestamp', descending: true)
        .snapshots();
    _initStream();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  void _initStream() {
    _stream.listen((QuerySnapshot querySnapshot) {
      if (!_streamController.isClosed) {
        _streamController.add(querySnapshot);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat', style: TextStyle(color: gold)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.grey,
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _streamController.stream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      var messages = snapshot.data!.docs;

                      return ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          var message =
                              messages[index].data() as Map<String, dynamic>;
                          return _buildMessage(
                            message['user'],
                            message['email'],
                            message['content'],
                            message['type'],
                            messages[index].id,
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
          ),
          if (_uploadingImage)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(gold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage(String user, String email, dynamic content, String type,
      String messageId) {
    bool isCurrentUser = email ==
        FirebaseAuth
            .instance.currentUser?.email; // Check by email instead of 'admin'

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment:
                isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width *
                    0.6, // Set width to 60% of screen width
                child: Column(
                  crossAxisAlignment: isCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCurrentUser ? 'You' : user,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: isCurrentUser ? Colors.black : gold,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: _buildContent(
                          content, type, isCurrentUser, messageId),
                    ),
                  ],
                ),
              ),
              if (isCurrentUser)
                IconButton(
                  icon: const Icon(Icons.delete_rounded),
                  color: Colors.red,
                  onPressed: () {
                    _deleteMessage(messageId);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      dynamic content, String type, bool isCurrentUser, String messageId) {
    if (type == 'text') {
      // Text message
      return Column(
        children: [
          Text(
            content,
            style: TextStyle(
              color: isCurrentUser ? gold : Colors.black,
            ),
          ),
        ],
      );
    } else if (type == 'image') {
      // Image message
      return GestureDetector(
        onTap: () {
          _showImageDialog(content);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.network(
              content,
              width: 200,
              height: 150,
            ),
          ],
        ),
      );
    } else {
      return const Text(
        'Unsupported Content Type',
        style: TextStyle(color: Colors.red),
      );
    }
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: gold),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: const TextStyle(color: Colors.grey),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.black,
                prefixIcon: IconButton(
                  onPressed: () {
                    _pickImage();
                  },
                  icon: Icon(Icons.attach_file, color: gold),
                ),
              ),
              onSubmitted: (value) {
                _sendMessage();
              },
            ),
          ),
          const SizedBox(width: 8.0),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                _sendMessage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              child: Icon(Icons.send, color: gold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 150,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImageAndSend(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImageAndSend(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImageAndSend(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);

    if (pickedImage != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: gold,
            title: const Text('Preview Image'),
            content: SizedBox(
              height: 400,
              child: Column(
                children: [
                  Image.file(
                    File(pickedImage.path),
                    width: 200, // Adjust width as needed
                    height: 300, // Adjust height as needed
                  ),
                  const SizedBox(height: 50),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                      _sendImageAndClear(File(pickedImage.path));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    child: Text('Send', style: TextStyle(color: gold)),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _sendImageAndClear(File imageFile) async {
    setState(() {
      _uploadingImage = true;
    });

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      DocumentSnapshot userSnapshot =
          await _usersCollection.doc(currentUser.email).get();

      if (userSnapshot.exists) {
        String userType = userSnapshot['userType'];
        String userValue =
            (userType == 'admin') ? 'admin' : userSnapshot['name'];

        await _sendImage(userValue, currentUser.email!, imageFile);
      }
    }

    setState(() {
      _uploadingImage = false;
    });
  }

  Future<void> _sendImage(
      String userValue, String userEmail, File imageFile) async {
    File compressedImage = await _compressImage(imageFile);

    String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
    firebase_storage.Reference storageReference = firebase_storage
        .FirebaseStorage.instance
        .ref()
        .child("chat_images")
        .child(fileName);

    try {
      await storageReference.putFile(compressedImage);

      String downloadURL = await storageReference.getDownloadURL();

      await _chatCollection.add({
        'user': userValue,
        'email': userEmail,
        'content': downloadURL,
        'type': 'image',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      print("Error uploading image: $error");
    }
    }

  Future<File> _compressImage(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    img.Image image = img.decodeImage(Uint8List.fromList(imageBytes))!;

    File compressedImageFile = File(imageFile.path.replaceAll('.jpg', '_compressed.jpg'));
    await compressedImageFile.writeAsBytes(img.encodeJpg(image, quality: 40));

    return compressedImageFile;
  }

  void _sendMessage() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      DocumentSnapshot userSnapshot =
          await _usersCollection.doc(currentUser.email).get();

      if (userSnapshot.exists) {
        String userType = userSnapshot['userType'];
        String userValue =
            (userType == 'admin') ? 'admin' : userSnapshot['name'];

        String messageText = _messageController.text.trim();
        if (messageText.isNotEmpty) {
          await _chatCollection.add({
            'user': userValue,
            'email': currentUser.email,
            'content': messageText,
            'type': 'text',
            'timestamp': FieldValue.serverTimestamp(),
          });

          // Clear the message input
          _messageController.clear();
        }
      }
    }
  }

  void _deleteMessage(String messageId) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: gold,
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel delete
              },
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm delete
              },
              child: const Text('Delete',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
    if (confirmDelete == true) {
      DocumentSnapshot messageSnapshot =
          await _chatCollection.doc(messageId).get();
      if (messageSnapshot.exists) {
        String contentType = messageSnapshot['type'];

        if (contentType == 'image') {
          String imageURL = messageSnapshot['content'];
          try {
            await firebase_storage.FirebaseStorage.instance
                .refFromURL(imageURL)
                .delete();
          } catch (error) {
            print("Error deleting image from Firebase Storage: $error");
          }
        }
        await _chatCollection.doc(messageId).delete();
      }
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            width: 500,
            height: 700,
            child: PhotoViewGallery.builder(
              itemCount: 1,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(imageUrl),
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
              pageController: PageController(),
            ),
          ),
        );
      },
    );
  }

}
