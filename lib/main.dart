import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:localink/firebase_options.dart';
import 'package:localink/models/lease.dart';
import 'package:localink/models/property.dart';
import 'package:localink/models/tenant.dart';
import 'package:localink/screens/auth/signup.dart';
import 'package:localink/screens/owner/AddPropertyScreen.dart';
import 'package:localink/screens/owner/PaymentManagementScreen.dart';
import 'package:localink/screens/owner/PropertyDetails.dart';
import 'package:localink/screens/owner/PropertyListScreen.dart';
import 'package:localink/screens/owner/ReceivedApplicationsScreen.dart';
import 'package:localink/screens/owner/edit_property_screen.dart';
import 'package:localink/screens/owner/owner_home_screen.dart';
import 'package:localink/screens/owner/AddTenantScreen.dart';
import 'package:localink/screens/owner/EditLeaseScreen.dart';
import 'package:localink/screens/owner/TenantHistoryScreen.dart';
import 'package:localink/screens/settings/AboutScreen.dart';
import 'package:localink/screens/settings/HelpScreen.dart';
import 'package:localink/screens/settings/ProfileScreen.dart';
import 'package:localink/screens/settings/SecurityScreen.dart';
import 'package:localink/screens/settings/SettingsScreen.dart';
import 'package:localink/screens/settings/contact_screen.dart';
import 'package:localink/screens/settings/privacy_screen.dart';
import 'package:localink/screens/settings/terms_screen.dart';
import 'package:localink/screens/tenant/ApplicationFormScreen.dart';
import 'package:localink/screens/tenant/PropertySearchFilters.dart';
import 'package:localink/screens/tenant/PropertySearchScreen.dart';
import 'package:localink/screens/tenant/TenantHomeScreen.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  
  testFirebaseConnection();
  runApp(const MyApp());
}

void testFirebaseConnection() async {
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Immobilier App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/owner/home': (context) => const OwnerHomeScreen(),
        '/tenant/home': (context) => const TenantHomeScreen(),
        '/add-property': (context) => const AddPropertyScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(), 
        '/about': (context) => const AboutScreen(),
        '/privacy': (context) => const PrivacyScreen(),
        '/terms': (context) => const TermsScreen(),
        '/contact': (context) => const ContactScreen(),
        '/help': (context) => const HelpScreen(),  
        '/security': (context) => const SecurityScreen(),
        '/property-detail': (context) {
          final String propertyId = ModalRoute.of(context)!.settings.arguments as String;
          return PropertyDetails(propertyId: propertyId);
        },
        '/edit-property': (context) {
          final String propertyId = ModalRoute.of(context)!.settings.arguments as String;
          return EditPropertyScreen(propertyId: propertyId);
        },
        // New routes for tenant management
       '/add-tenant': (context) => const AddTenantScreen(),
         
        '/edit-lease': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return EditLeaseScreen(leaseId: args['leaseId'] as String);
        },
        
        '/payment-management': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PaymentManagementScreen(
            tenant: args['tenant'] as Tenant,
            lease: args['lease'] as Lease,
          );
        },
       '/tenant-history': (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return const TenantHistoryScreen(); 
      },
      '/received-applications': (context) {
          final String ownerId = ModalRoute.of(context)!.settings.arguments as String;
          return ReceivedApplicationsScreen();
        },

        '/property-search': (context) => PropertySearchPage(),
        '/property-search-filters': (context) => const PropertySearchFiltersScreen(),
            /*
       // Nouvelles routes pour le locataire
        '/property-search': (context) => const PropertySearchScreen(),
        '/saved-searches': (context) => const SavedSearchesScreen(),
       
        '/lease-details': (context) => const LeaseDetailsScreen(),
        '/maintenance-requests': (context) => const MaintenanceRequestsScreen(),
        '/report-issue': (context) => const ReportIssueScreen(),
        '/documents': (context) => const DocumentsScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/contact-owner': (context) => const ContactOwnerScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        */
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData) {
          return LoginScreen();
        }

        return FutureBuilder(
          future: AuthService().getCurrentUserProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            final userProfile = profileSnapshot.data;
            
            // Redirection basée sur le type d'utilisateur
            if (userProfile?.userType == 'owner') {
              return const OwnerHomeScreen();
            } else if (userProfile?.userType == 'tenant') {
              return const TenantHomeScreen();
            } else {
              // Si le type d'utilisateur n'est pas reconnu, renvoyer vers la page de connexion
              return LoginScreen();
            }
          },
        );
      },
    );
  }
}
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}