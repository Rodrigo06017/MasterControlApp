import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/xbox_theme.dart';
import 'viewmodels/controller_viewmodel.dart';
import 'views/screens/controller_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge styling with dark system bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: XboxTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MasterControlApp());
}

class MasterControlApp extends StatelessWidget {
  const MasterControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ControllerViewModel()),
      ],
      child: MaterialApp(
        title: 'MasterControlApp',
        debugShowCheckedModeBanner: false,
        theme: XboxTheme.themeData,
        home: const ControllerScreen(),
      ),
    );
  }
}
