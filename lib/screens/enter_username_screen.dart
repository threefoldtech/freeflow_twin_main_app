import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:freeflow/app_config.dart';
import 'package:freeflow/helpers/shared_preference_data.dart';
import 'package:freeflow/screens/webview_screen.dart';
import 'package:flutter/material.dart';

import 'package:freeflow/models/user.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../helpers/hex_color.dart';

class EnterUsernameScreen extends StatefulWidget {
  _EnterUsernameScreenState createState() => _EnterUsernameScreenState();
}

class _EnterUsernameScreenState extends State<EnterUsernameScreen> with WidgetsBindingObserver {
  final TextEditingController usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  User user = new User(username: '');

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: HexColor('#dacfc7'), // <-- SEE HERE
            statusBarIconBrightness: Brightness.dark, //<-- For Android SEE HERE (dark icons)
            statusBarBrightness: Brightness.light, //<-- For iOS SEE HERE (dark icons)
          ),
          centerTitle: true,
          iconTheme: IconThemeData(
            color: HexColor('#2c3e50'), //change your color here
          ),
          backgroundColor: HexColor('#dacfc7'),
          elevation: 0.0,
          title: SvgPicture.asset(
            'assets/logo.svg',
            height: 40,
          ),
        ),
        body: Container(
            color: HexColor('#dacfc7'),
            height: double.infinity,
            alignment: Alignment.center,
            child: CustomScrollView(scrollDirection: Axis.vertical, slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Image.asset(
                      'assets/freeflow_spawner.png',
                      height: 300,
                    ),
                    Container(
                      child: Column(
                        children: [
                          Text(
                            "WELCOME TO YOUR",
                            style: TextStyle(
                              fontSize: 14,
                              color: HexColor('#2c3e50'),
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Text(
                            "FREEFLOW EXPERIENCE",
                            style: TextStyle(fontSize: 22, color: HexColor('#2c3e50'), fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 30),
                          Text("Please enter your ThreeFold Connect username in order to continue.",
                              style: TextStyle(
                                fontWeight: FontWeight.w300,
                                color: HexColor('#2c3e50'),
                              ),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    Container(
                      width: 300,
                      child: Column(
                        children: [
                          Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                TextFormField(
                                  style: TextStyle(color: HexColor('#2c3e50')),
                                  controller: usernameController,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your username',
                                    hintStyle: TextStyle(fontWeight: FontWeight.w200),
                                    border: InputBorder.none,
                                    isDense: true,
                                    // Added this
                                    contentPadding: EdgeInsets.all(12),
                                    filled: true,
                                    fillColor: Color.fromRGBO(227, 219, 213, 1),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    if (usernameController.text.length == 0) {
                                      return;
                                    }

                                    user.username = usernameController.text.trim();

                                    await setNameInStorage(user.username);

                                    print('https://' + user.username + AppConfig().freeFlowUrl());

                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => WebViewScreen(
                                                url: 'https://' + user.username + AppConfig().freeFlowUrl())));
                                  },
                                  style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(HexColor('#66c9bf')),
                                    padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.only(top: 5, bottom: 5)),
                                    minimumSize: MaterialStateProperty.all<Size>(Size(300, 34.0)),
                                  ),
                                  child: const Text('GO!', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ])));
  }
}
