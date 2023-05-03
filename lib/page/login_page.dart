import '../utils/local_db.dart';
import 'package:flutter/material.dart';

import '../utils/utils.dart';
import 'face_recognition/camera_page.dart';

class LoginPage extends StatefulWidget{
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{
  @override
  void initState() {
    printIfDebug(LocalDB.getUser().name);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Welcome to Quyet Tran Gym Management System",
      style: TextStyle(fontSize: 15)),
      centerTitle: true,
    ),
    body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/gym_background.gif'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildButton(
                  text: 'Register',
                  icon: Icons.app_registration_rounded,
                  onClicked: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FaceScanScreen()),
                    );
                  },
                ),
                const SizedBox(height: 24),
                buildButton(
                  text: 'Login',
                  icon: Icons.login,
                  onClicked: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FaceScanScreen(
                        user: LocalDB.getUser(),
                      )),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );



  //own widgets
  Widget buildButton({required String text, required IconData icon, required VoidCallback onClicked})=>
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
        ),
        icon: Icon(icon, size: 26),
        label: Text(
          text,
          style: const TextStyle(fontSize: 20),
        ),
        onPressed: onClicked,
      );
}