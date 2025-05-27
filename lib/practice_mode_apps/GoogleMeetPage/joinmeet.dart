import 'package:flutter/material.dart';
import 'package:device_frame/device_frame.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'joinmeet2.dart';

class JoinMeet1 extends StatelessWidget {
  const JoinMeet1({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat UI',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: DeviceFrame(
        device: Devices.ios.iPhone13ProMax,
        isFrameVisible: true,
        orientation: Orientation.portrait,
        screen: const ChatScreen(),
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Base UI layer
          Column(
            children: [
              // Top bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side with back button, avatar and name
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_back,
                            color: Colors.blue.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(
                              'https://picsum.photos/200', // Placeholder since we can't use the original URL
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Juan Dela Cruz',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      // Info button
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.info,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Chat area
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    children: [
                      // Message bubble
                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Link text
                                  InkWell(
                                    onTap: () {
                                      // Navigate to JoinMeet2 screen
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (context) => const JoinMeet2(),
                                        ),
                                      );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        12,
                                        8,
                                        12,
                                        0,
                                      ),
                                      child: Text(
                                        'https://meet.google.com/\nabc-defg-hij',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Link preview
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'meet.google.com',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Sent status
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Text(
                                'Sent',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom input bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Add button
                      IconButton(
                        icon: Icon(
                          Icons.add,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                        onPressed: () {},
                      ),
                      // Camera button
                      IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                        onPressed: () {},
                      ),
                      // Gallery button
                      IconButton(
                        icon: Icon(
                          Icons.image_outlined,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                        onPressed: () {},
                      ),
                      // Microphone button
                      IconButton(
                        icon: Icon(
                          Icons.mic,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                        onPressed: () {},
                      ),
                      // Message input field
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Message',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                    ),
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                              // Emoji button
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.emoji_emotions_outlined,
                                  color: Colors.blue.shade600,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Like button
                      IconButton(
                        icon: Icon(
                          Icons.thumb_up,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Image overlay in the middle
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                'assets/images/joinmeet1.jpg',
                width: MediaQuery.of(context).size.width * 0.8,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
