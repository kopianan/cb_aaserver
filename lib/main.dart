import 'dart:developer';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:rust_mpc_ffi/lib.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  AwesomeNotifications().initialize('resource://drawable/notify', [
    NotificationChannel(
        channelKey: "basic_channel",
        channelName: "Basic Notification",
        importance: NotificationImportance.High,
        channelShowBadge: true,
        channelDescription: "Descriptions")
  ]);
  CBRustMpc().setup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<dynamic>? doDkg;
  @override
  void initState() {
    AwesomeNotifications().isNotificationAllowed().then(
      (value) {
        if (!value) {
          AwesomeNotifications()
              .requestPermissionToSendNotifications()
              .then((value) => Navigator.of(context).pop());
        }
      },
    );
    FirebaseMessaging.instance
        .getToken()
        .then((value) => log(value.toString()));
    FirebaseMessaging.instance
        .subscribeToTopic("dkg")
        .then((value) => print("SUBSCRIBE TO DKG TOPIC"));

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        createNotification();
        Future.delayed(Duration(seconds: 2)).then((e) {
          CBRustMpc().proccessDkgString(3).then((value) => print(value));
        });
        setState(() {});
        print('Message also contained a notification: ${message.notification}');
      }
    });
    super.initState();
  }

  void createNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(1),
          channelKey: 'basic_channel',
          body: "TEST"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("This apps as a server only. DKG Only",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
            const Text("INDEX : 3",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 30),
            FutureBuilder(
                future: doDkg,
                builder: (context, snapshot) {
                  return (snapshot.connectionState == ConnectionState.waiting)
                      ? ElevatedButton(
                          child: Transform.scale(
                            scale: 0.8,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () {},
                        )
                      : ElevatedButton(
                          child: const Text("DO DKG"),
                          onPressed: () {
                            doDkg = CBRustMpc().proccessDkgString(3);
                            setState(() {});
                          },
                        );
                }),
          ],
        ),
      ),
    );
  }
}



// cargo build --release --examples
// cargo ndk -t armeabi-v7a -t arm64-v8a -o /Users/anan/Documents/CoinBit/FlutterRustMpc/rust_mpc_ffi/example/android/app/src/main/jniLibs build --release 
// ln -s /Users/anan/Documents/CoinBit/coinbit_as_a_server/ios/target/universal/release/libgg20_mpc_ffi.a
// cat /Users/anan/Documents/CoinBit/coinbit_as_a_server/ios/target/binding.h >> Classes/RustMpcFfiPlugin.h