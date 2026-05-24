import 'package:provider/single_child_widget.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/data_store.dart';
import '../services/notification_service.dart';

/// Aggregates top‑level providers for the app.
///
/// Example usage in `main.dart`:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///   runApp(const MyApp());
/// }
///
/// class MyApp extends StatelessWidget {
///   const MyApp({Key? key}) : super(key: key);
///
///   @override
///   Widget build(BuildContext context) {
///     return MultiProvider(
///       providers: AppProviders.providers,
///       child: const CupertinoApp(
///         title: 'YNAB',
///         home: HomeScreen(),
///       ),
///     );
///   }
/// }
/// ```
class AppProviders {
  static List<SingleChildWidget> get providers => [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProxyProvider<AuthService, DataStore>(
          create: (_) => DataStore(),
          update: (_, authService, dataStore) {
            if (authService.isAuthenticated) {
              dataStore!.startListening();
            } else {
              dataStore!.stopListening();
            }
            return dataStore;
          },
        ),
        Provider<NotificationService>(
          create: (_) => NotificationService(),
          dispose: (_, NotificationService service) => service.dispose(),
        ),
      ];
}
