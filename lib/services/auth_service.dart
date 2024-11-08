
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localink/models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream pour écouter les changements d'état de l'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Inscription avec email et mot de passe
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String userType,
    String? displayName,
  }) async {
    try {
      // Créer l'utilisateur dans Firebase Auth
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) throw Exception('La création du compte a échoué');

      // Créer le profil utilisateur dans Firestore
      final UserProfile userProfile = UserProfile(
        id: user.uid,
        email: email,
        displayName: displayName,
        userType: userType,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userProfile.toMap());

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      return userProfile;
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  // Connexion avec email et mot de passe
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) throw Exception('La connexion a échoué');

      // Mettre à jour la dernière connexion
      await _firestore.collection('users').doc(user.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Récupérer le profil utilisateur
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return UserProfile.fromMap(user.uid, doc.data()!);
    } catch (e) {
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Erreur lors de la réinitialisation du mot de passe: $e');
    }
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Aucun utilisateur connecté');

      Map<String, dynamic> updates = {};
      
      if (displayName != null) {
        await user.updateDisplayName(displayName);
        updates['displayName'] = displayName;
      }

      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
        updates['photoUrl'] = photoUrl;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  // Obtenir le profil utilisateur
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return UserProfile.fromMap(user.uid, doc.data()!);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

Future<Map<String, dynamic>> validateUserSession() async {
    try {
      // 1. Vérifier l'état d'authentification actuel
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'isValid': false,
          'error': 'No authenticated user found',
          'userId': null
        };
      }

      // 2. Récupérer d'abord le document de l'utilisateur
      final userDoc = await _firestore
          .collection('users')
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        return {
          'isValid': false,
          'error': 'User document not found in Firestore',
          'userId': currentUser.uid
        };
      }

      String tenantId = userDoc.docs.first.id;

      // 3. Vérifier le bail avec l'ID du tenant
      final leaseQuery = await _firestore
          .collection('leases')
          .where('tenantId', isEqualTo: tenantId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      // 4. Retourner les informations complètes
      return {
        'isValid': true,
        'userId': currentUser.uid,
        'tenantId': tenantId,
        'hasActiveLease': leaseQuery.docs.isNotEmpty,
        'leaseId': leaseQuery.docs.isNotEmpty ? leaseQuery.docs.first.id : null
      };
    } catch (e) {
      print('Validation error: $e');
      return {
        'isValid': false,
        'error': 'Validation error: $e',
        'userId': null
      };
    }
  }

  Future<void> debugAuthState() async {
    try {
      final User? currentUser = _auth.currentUser;
      print('=== Auth Debug Information ===');
      print('Current User: ${currentUser?.uid}');
      
      if (currentUser != null) {
        // Rechercher l'utilisateur par userId
        final userQuery = await _firestore
            .collection('users')
            .where('userId', isEqualTo: currentUser.uid)
            .get();
            
        print('User documents found: ${userQuery.docs.length}');
        
        if (userQuery.docs.isNotEmpty) {
          String tenantId = userQuery.docs.first.id;
          print('TenantId: $tenantId');
          
          // Rechercher les baux actifs
          final leases = await _firestore
              .collection('leases')
              .where('tenantId', isEqualTo: tenantId)
              .where('status', isEqualTo: 'active')
              .get();
              
          print('Found ${leases.docs.length} active lease(s)');
          for (var lease in leases.docs) {
            print('Lease ${lease.id}: ${lease.data()}');
          }
        }
      }
    } catch (e) {
      print('Debug error: $e');
    }
  }


  // Changer le mot de passe
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Aucun utilisateur connecté');

      // Récupérer les informations d'identification de l'utilisateur
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      // Réauthentifier l'utilisateur
      await user.reauthenticateWithCredential(credential);

      // Changer le mot de passe
      await user.updatePassword(newPassword);

      // Mettre à jour la dernière modification du mot de passe dans Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'passwordLastChanged': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          throw Exception('Le mot de passe actuel est incorrect');
        case 'requires-recent-login':
          throw Exception('Cette opération nécessite une connexion récente. Veuillez vous reconnecter.');
        case 'weak-password':
          throw Exception('Le nouveau mot de passe est trop faible');
        default:
          throw Exception('Erreur lors du changement de mot de passe: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erreur inattendue lors du changement de mot de passe: $e');
    }
  }

}