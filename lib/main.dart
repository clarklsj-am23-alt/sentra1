import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/user_management/screens/login_screen.dart';
import 'features/stations_nearby/screens/map_home_screen.dart';
import 'features/station_search/screens/journey_planner_screen.dart';
import 'features/transit_card/screens/transit_dashboard_screen.dart';
import 'features/user_management/screens/user_profile_screen.dart';

const Color appYellow = Color(0xFFFCEB00);

// SUPABASE CONFIGURATION
const String supabaseUrl = 'https://jquemzsrgjyvmvfqwsrp.supabase.co';
const String supabaseKey = 'sb_publishable_0zf3Cv3XpEurtW_n9OvcZg_OKx1OTPu';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(const Sentra1App());
}

final supabase = Supabase.instance.client;

class Sentra1App extends StatelessWidget {
  const Sentra1App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentra1 Accessibility Transit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        textTheme: GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme),
        colorScheme: const ColorScheme.light(
          primary: appYellow,
          onPrimary: Colors.black,
          secondary: Colors.black,
          onSecondary: appYellow,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: appYellow,
          elevation: 2,
          titleTextStyle: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: appYellow,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.black,
          indicatorColor: appYellow,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.dmSans(
                color: appYellow,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              );
            }
            return GoogleFonts.dmSans(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.black);
            }
            return const IconThemeData(color: Colors.grey);
          }),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return appYellow;
              }
              return Colors.grey.shade200;
            }),
            foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.black;
              }
              return Colors.black87;
            }),
            textStyle: WidgetStateProperty.all(
              GoogleFonts.dmSans(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final Session? session = Supabase.instance.client.auth.currentSession;

        if (session != null) {
          return MainNavigationShell(user: session.user);
        }

        return LoginScreen(
          onLoginSuccess: () {
            setState(() {});
          },
        );
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key, required this.user});

  final User user;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      MapHomeScreen(user: widget.user),
      const JourneyPlannerScreen(),
      const TransitDashboardScreen(),
      UserProfileScreen(user: widget.user, onPreferenceChanged: (_) {}),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Sentra1 Accessibility Map'
              : _currentIndex == 3
              ? 'Profile'
              : 'Sentra1',
        ),
        actions: _currentIndex == 3
            ? const []
            : [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Explore Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.alt_route_outlined),
            selectedIcon: Icon(Icons.alt_route),
            label: 'Trip Planner',
          ),
          NavigationDestination(
            icon: Icon(Icons.departure_board_outlined),
            selectedIcon: Icon(Icons.departure_board),
            label: 'Schedules & Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}