import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group('Mock Authentications', () {
    final provider = MockProvider();
    test("It should not be initialized to begin with", () {
      expect(provider._isInitialized, false);
    });
    test('Can not log out without initialization', () {
      expect(
        provider.logOut(),
        throwsA(const TypeMatcher<NotInitializedException>()),
      );
    });

    test('Should be able to initialize', () async {
      await provider.initialize();
      expect(provider.isInitialized, true);
    });

    test('User should be null after initialization', () {
      expect(provider.currentUser, null);
    });

    test('should be able to initialize in less than 2 second', () async {
      await provider.initialize();
      expect(provider.isInitialized, true);
    }, timeout: const Timeout(Duration(seconds: 3)));

    test(
      "Create user function should delegate to login function",
      () async{
        final badUser = await provider.createUser(
          email: 'foo@bar.com',
          password: "Any password",
        );
        expect(
            badUser, throwsA(const TypeMatcher<UserNotLoggedAuthException>()));
        final badPassword =
            provider.createUser(email: 'someone@gmail.com', password: "foobar");

        expect(badPassword,
            throwsA(const TypeMatcher<WrongPasswordAuthException>()));

        final user =
            provider.createUser(email: "ionthefirst", password: "Nyamavindi");
        expect(provider.currentUser, user);
        expect(const AuthUser(isEmailVerified: false), false);
      },
    );

    test("Logged in user should be able to get verified", () {
      provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user?.isEmailVerified, true);
    });

    test("Shoud be able to log out and log in again", () async {
      await provider.logOut();
      await provider.logIn(email: 'email', password: 'password');
      final user=provider.currentUser;
      expect(user, isNotNull);
    });
  });
}

class NotInitializedException implements Exception {}

class MockProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitialized = false;

  bool get isInitialized => _isInitialized;
  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    if (!isInitialized) throw NotInitializedException();
    await Future.delayed(const Duration(seconds: 2));
    return logIn(
      email: email,
      password: password,
    );
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 2));
    _isInitialized = true;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) {
    if (!isInitialized) throw NotInitializedException();
    if (email == 'foo@bar.com') throw UserNotLoggedAuthException();
    if (password == 'foobar') throw WrongPasswordAuthException();
    const user = AuthUser(isEmailVerified: false);
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> logOut() async {
    if (!isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotLoggedAuthException();

    await Future.delayed(const Duration(seconds: 2));
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!isInitialized) throw NotInitializedException();
    final user = _user;

    if (user == null) throw UserNotLoggedAuthException();
    const newUser = AuthUser(isEmailVerified: true);
    _user = newUser;
  }
}