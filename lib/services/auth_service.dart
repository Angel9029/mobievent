import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  UserModel? _user;
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? get currentUser => _user;
  bool get isLoggedIn => _user != null;

  Future<String?> register(String fullName, String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = credential.user!.uid;

      // Create user document in Firestore
      await _firestore.collection('users').doc(uid).set({
        'fullName': fullName,
        'email': email,
        'role': 'client',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _user = UserModel(
        id: uid,
        fullName: fullName,
        name: fullName.split(' ').first,
        email: email,
        passwordHash: 'firebase',
        isAdmin: false,
      );
      notifyListeners();
      return null;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      } else if (e.code == 'email-already-in-use') {
        return 'Este correo ya está registrado.';
      } else if (e.code == 'invalid-email') {
        return 'Correo inválido.';
      }
      return 'Error al registrar: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      final uid = credential.user!.uid;

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return 'Usuario no encontrado en la base de datos.';
      }

      final data = doc.data() as Map<String, dynamic>;
      _user = UserModel(
        id: uid,
        fullName: data['fullName'] ?? 'Usuario',
        name: (data['fullName'] ?? 'Usuario').split(' ').first,
        email: email,
        passwordHash: 'firebase',
        isAdmin: data['role'] == 'admin' || data['role'] == 'employee',
      );
      notifyListeners();
      return null;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Usuario no encontrado.';
      } else if (e.code == 'wrong-password') {
        return 'Contraseña incorrecta.';
      } else if (e.code == 'invalid-email') {
        return 'Correo inválido.';
      }
      return 'Error al iniciar sesión: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  // Require current password to perform sensitive profile updates
  Future<String?> updateProfile(String newFullName, String currentPassword) async {
    if (_user == null) return 'No hay usuario logueado.';
    try {
      final fb.User? user = _firebaseAuth.currentUser;
      if (user == null) return 'Usuario no autenticado.';

      final credential = fb.EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(credential);

      await _firestore.collection('users').doc(_user!.id).update({'fullName': newFullName});
      _user = UserModel(
        id: _user!.id,
        fullName: newFullName,
        name: newFullName.split(' ').first,
        email: _user!.email,
        passwordHash: 'firebase',
        isAdmin: _user!.isAdmin,
      );
      notifyListeners();
      return null;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return 'Contraseña actual incorrecta.';
      }
      return 'Error al actualizar perfil: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  Future<String?> changePassword(String currentPassword, String newPassword) async {
    if (_user == null) return 'No hay usuario logueado.';
    try {
      final fb.User? user = _firebaseAuth.currentUser;
      if (user == null) return 'Usuario no autenticado.';

      final credential = fb.EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);
      return null;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return 'Contraseña actual incorrecta.';
      }
      return 'Error al cambiar contraseña: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  Future<String?> updateEmail(String newEmail, String currentPassword) async {
    if (_user == null) return 'No hay usuario logueado.';
    try {
      final fb.User? user = _firebaseAuth.currentUser;
      if (user == null) return 'Usuario no autenticado.';

      // Reauthenticate with current password
      final credential = fb.EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(credential);

      // Check Firestore users collection for existing email used by another uid
      final q = await _firestore.collection('users').where('email', isEqualTo: newEmail).get();
      if (q.docs.isNotEmpty) {
        final doc = q.docs.first;
        if (doc.id != user.uid) {
          return 'El correo ya está en uso por otro usuario.';
        }
      }

      // Update in Firebase Auth
      await (user as dynamic).updateEmail(newEmail);

      // Update in Firestore
      await _firestore.collection('users').doc(user.uid).update({'email': newEmail});

      // Update local model
      _user = UserModel(
        id: _user!.id,
        fullName: _user!.fullName,
        name: _user!.name,
        email: newEmail,
        passwordHash: 'firebase',
        isAdmin: _user!.isAdmin,
      );
      notifyListeners();
      return null;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return 'Contraseña incorrecta.';
      } else if (e.code == 'email-already-in-use') {
        return 'El correo ya está en uso.';
      } else if (e.code == 'invalid-email') {
        return 'Correo inválido.';
      }
      return 'Error al actualizar correo: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  Future<String?> deleteAccount(String password) async {
    if (_user == null) return 'No hay usuario logueado.';
    try {
      final fb.User? user = _firebaseAuth.currentUser;
      if (user == null) return 'Usuario no autenticado.';

      final credential = fb.EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(credential);

      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();

      _user = null;
      notifyListeners();
      return null;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return 'Contraseña incorrecta.';
      }
      return 'Error al eliminar cuenta: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  void logout() {
    _firebaseAuth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> checkAuthState() async {
    final fb.User? user = _firebaseAuth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _user = UserModel(
          id: user.uid,
          fullName: data['fullName'] ?? 'Usuario',
          name: (data['fullName'] ?? 'Usuario').split(' ').first,
          email: user.email ?? '',
          passwordHash: 'firebase',
          isAdmin: data['role'] == 'admin' || data['role'] == 'employee',
        );
        notifyListeners();
      }
    }
  }
}
