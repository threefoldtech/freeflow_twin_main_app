import 'package:freeflow/screens/webview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../helpers/hex_color.dart';

class EnvironmentScreen extends StatefulWidget {
  _EnvironmentScreenState createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  final TextEditingController environmentController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();
  late String _environment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: HexColor('#dacfc7'), // <-- SEE HERE
            statusBarIconBrightness:
                Brightness.dark, //<-- For Android SEE HERE (dark icons)
            statusBarBrightness:
                Brightness.light, //<-- For iOS SEE HERE (dark icons)
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
                              fontSize: 18,
                              color: HexColor('#2c3e50'),
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Text(
                            "FREEFLOW EXPERIENCE",
                            style: TextStyle(
                                fontSize: 18,
                                color: HexColor('#2c3e50'),
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 15),
                          Text(
                              "Please enter your environment url in order to continue.",
                              style: TextStyle(
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
                                  controller: environmentController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true, // Added this
                                    contentPadding: EdgeInsets.all(12),
                                    filled: true,
                                    fillColor: Color.fromRGBO(227, 219, 213, 1),
                                  ),
                                  style: TextStyle(),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    _environment = environmentController.text;
                                    print(_environment);
                                    final replaced = _environment.replaceFirst(RegExp('(?:https?://)?'), '');
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => WebViewScreen(
                                                url: 'https://' + replaced)));
                                  },
                                  style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        HexColor('#66c9bf')),
                                    padding:
                                        MaterialStateProperty.all<EdgeInsets>(
                                            EdgeInsets.only(top: 5, bottom: 5)),
                                    minimumSize:
                                        MaterialStateProperty.all<Size>(
                                            Size(300, 34.0)),
                                  ),
                                  child: const Text('GO!',
                                      style: TextStyle(color: Colors.white)),
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
