import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/user_management/screens/login_screen.dart';


// Tab 1: Explore Map (Jia Cheng)
import 'features/stations_nearby/screens/map_home_screen.dart';

// Tab 2: Trip Planner (Tham)
import 'features/station_search/screens/journey_planner_screen.dart';

// Tab 3: Schedules & Cards (Clark)
import 'features/transit_card/screens/transit_dashboard_screen.dart';


const Color appYellow = Color(0xFFFCEB00);

// =============================================================
// SUPABASE CONFIGURATION
// Values come from --dart-define
// =============================================================

const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
);

const String supabaseKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

// =============================================================
// MAIN
// =============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    throw Exception(
      'Supabase configuration is missing. '
          'Please provide SUPABASE_URL and '
          'SUPABASE_PUBLISHABLE_KEY using --dart-define.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
  );

  runApp(
    const Sentra1App(),
  );
}

final supabase =
    Supabase.instance.client;

// =============================================================
// APP
// =============================================================

class Sentra1App extends StatelessWidget {
  const Sentra1App({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return MaterialApp(
      title:
      'Sentra1 Accessibility Transit',

      debugShowCheckedModeBanner:
      false,

      theme: ThemeData(
        useMaterial3: true,

        scaffoldBackgroundColor:
        const Color(0xFFF5F5F5),

        textTheme:
        GoogleFonts.dmSansTextTheme(
          ThemeData.light().textTheme,
        ),

        colorScheme:
        const ColorScheme.light(
          primary: appYellow,
          onPrimary: Colors.black,

          secondary:
          Colors.black,
          onSecondary:
          appYellow,

          surface:
          Colors.white,
          onSurface:
          Colors.black,
        ),

        // =====================================================
        // APP BAR
        // =====================================================

        appBarTheme:
        AppBarTheme(
          backgroundColor:
          Colors.black,

          foregroundColor:
          appYellow,

          elevation: 2,

          titleTextStyle:
          GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight:
            FontWeight.bold,
            color:
            appYellow,
          ),
        ),

        // =====================================================
        // BOTTOM NAVIGATION
        // =====================================================

        navigationBarTheme:
        NavigationBarThemeData(
          backgroundColor:
          Colors.black,

          indicatorColor:
          appYellow,

          labelTextStyle:
          WidgetStateProperty
              .resolveWith(
                (states) {
              if (states.contains(
                WidgetState.selected,
              )) {
                return GoogleFonts
                    .dmSans(
                  color:
                  appYellow,
                  fontSize: 12,
                  fontWeight:
                  FontWeight.bold,
                );
              }

              return GoogleFonts.dmSans(
                color:
                Colors.grey,
                fontSize: 12,
                fontWeight:
                FontWeight.w500,
              );
            },
          ),

          iconTheme:
          WidgetStateProperty
              .resolveWith(
                (states) {
              if (states.contains(
                WidgetState.selected,
              )) {
                return const IconThemeData(
                  color:
                  Colors.black,
                );
              }

              return const IconThemeData(
                color:
                Colors.grey,
              );
            },
          ),
        ),

        // =====================================================
        // SEGMENTED BUTTON
        // =====================================================

        segmentedButtonTheme:
        SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor:
            WidgetStateProperty
                .resolveWith<Color?>(
                  (states) {
                if (states.contains(
                  WidgetState.selected,
                )) {
                  return appYellow;
                }

                return Colors.grey
                    .shade200;
              },
            ),

            foregroundColor:
            WidgetStateProperty
                .resolveWith<Color?>(
                  (states) {
                if (states.contains(
                  WidgetState.selected,
                )) {
                  return Colors.black;
                }

                return Colors.black87;
              },
            ),

            textStyle:
            WidgetStateProperty.all(
              GoogleFonts.dmSans(
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
        ),
      ),

      // =======================================================
      // AUTH GATE
      // =======================================================

      home:
      const AuthGate(),
    );
  }
}

// =============================================================
// AUTH GATE
//
// Not logged in  -> LoginScreen
// Logged in      -> MainNavigationShell
// =============================================================

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
  });

  @override
  State<AuthGate> createState() =>
      _AuthGateState();
}

class _AuthGateState
    extends State<AuthGate> {
  @override
  Widget build(
      BuildContext context,
      ) {
    return StreamBuilder<AuthState>(
      stream: Supabase
          .instance
          .client
          .auth
          .onAuthStateChange,

      builder: (
          context,
          snapshot,
          ) {
        final Session? session =
            Supabase
                .instance
                .client
                .auth
                .currentSession;

        if (session != null) {
          return const MainNavigationShell();
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

// =============================================================
// MAIN NAVIGATION
// =============================================================

class MainNavigationShell
    extends StatefulWidget {
  const MainNavigationShell({
    super.key,
  });

  @override
  State<MainNavigationShell>
  createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState
    extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens =
  const [
    // Jia Cheng
    MapHomeScreen(),

    // Tham
    JourneyPlannerScreen(),

    // Clark
    TransitDashboardScreen(),
  ];

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      body:
      _screens[_currentIndex],

      bottomNavigationBar:
      NavigationBar(
        selectedIndex:
        _currentIndex,

        onDestinationSelected:
            (index) {
          setState(() {
            _currentIndex =
                index;
          });
        },

        destinations:
        const [
          NavigationDestination(
            icon: Icon(
              Icons.map_outlined,
            ),
            selectedIcon:
            Icon(
              Icons.map,
            ),
            label:
            'Explore Map',
          ),

          NavigationDestination(
            icon: Icon(
              Icons
                  .alt_route_outlined,
            ),
            selectedIcon:
            Icon(
              Icons.alt_route,
            ),
            label:
            'Trip Planner',
          ),

          NavigationDestination(
            icon: Icon(
              Icons
                  .departure_board_outlined,
            ),
            selectedIcon:
            Icon(
              Icons
                  .departure_board,
            ),
            label:
            'Schedules & Cards',
          ),
        ],
      ),
    );
  }
}