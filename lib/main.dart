import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/app_providers.dart';
import 'views/root_view.dart';

import 'services/data_store.dart';
import 'models/models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const YNABApp());
}

class YNABApp extends StatelessWidget {
  const YNABApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.providers,
      child: Consumer<DataStore>(
        builder: (context, dataStore, _) {
          final colorTheme = dataStore.userSettings.colorTheme;
          Brightness? brightness;
          if (colorTheme == ColorTheme.light) {
            brightness = Brightness.light;
          } else if (colorTheme == ColorTheme.dark) {
            brightness = Brightness.dark;
          }

          return CupertinoApp(
            title: 'YNAB',
            debugShowCheckedModeBanner: false,
            theme: CupertinoThemeData(
              brightness: brightness,
              primaryColor: const Color(0xFF5B6CF6),
              textTheme: const CupertinoTextThemeData(
                primaryColor: Color(0xFF5B6CF6),
              ),
            ),
            home: const RootView(),
          );
        },
      ),
    );
  }
}
