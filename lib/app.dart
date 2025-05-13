import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'blocs/auth/auth_cubit.dart';
import 'blocs/theme/theme_cubit.dart';
import 'blocs/transaction/transaction_cubit.dart';
import 'blocs/category/category_cubit.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/category_repository.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/auth_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/statistics_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'blocs/auth/auth_state.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userRepository = UserRepository();
    final transactionRepository = TransactionRepository();
    final categoryRepository = CategoryRepository();
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: userRepository),
        RepositoryProvider.value(value: transactionRepository),
        RepositoryProvider.value(value: categoryRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit(userRepository)),
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(create: (context) => TransactionCubit(
            RepositoryProvider.of<TransactionRepository>(context),
            0, // userId будет переинициализирован после авторизации
          )),
          BlocProvider(create: (context) => CategoryCubit(
            RepositoryProvider.of<CategoryRepository>(context),
          )),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: themeMode,
              locale: const Locale('ru', 'RU'),
              supportedLocales: const [
                Locale('ru', 'RU'),
                Locale('en', 'US'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              initialRoute: '/',
              onGenerateRoute: (settings) {
                Widget page;
                switch (settings.name) {
                  case '/':
                    page = const SplashScreen();
                    break;
                  case '/auth':
                    page = const AuthScreen();
                    break;
                  case '/home':
                    page = const HomeScreen();
                    break;
                  case '/statistics':
                    page = const StatisticsScreen();
                    break;
                  case '/settings':
                    page = const SettingsScreen();
                    break;
                  default:
                    page = const SplashScreen();
                }
                return PageRouteBuilder(
                  pageBuilder: (_, __, ___) => page,
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.ease;
                    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 350),
                  settings: settings,
                );
              },
            );
          },
        ),
      ),
    );
  }
}