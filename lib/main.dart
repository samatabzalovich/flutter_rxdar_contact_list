import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rxdar_contact_list/bloc/app_bloc.dart';
import 'package:flutter_rxdar_contact_list/bloc/auth/auth_errors.dart';
import 'package:flutter_rxdar_contact_list/bloc/views/current_view_enum.dart';
import 'package:flutter_rxdar_contact_list/dialogs/auth_error_dialog.dart';
import 'package:flutter_rxdar_contact_list/firebase_options.dart';
import 'package:flutter_rxdar_contact_list/loading/loading_screen.dart';
import 'package:flutter_rxdar_contact_list/views/contacts_list_view.dart';
import 'package:flutter_rxdar_contact_list/views/login_view.dart';
import 'package:flutter_rxdar_contact_list/views/newcontact_view.dart';
import 'package:flutter_rxdar_contact_list/views/register_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const App(),
  );
}

class App extends StatelessWidget {
  const App({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final AppBloc appBloc;
  StreamSubscription<AuthError?>? _authErrorSub;
  StreamSubscription<bool>? _isLoadingSub;

  @override
  void initState() {
    super.initState();
    appBloc = AppBloc();
  }

  @override
  void dispose() {
    appBloc.dispose();
    _authErrorSub?.cancel();
    _isLoadingSub?.cancel();
    super.dispose();
  }

  void handleAuthErrors(BuildContext context) async {
    await _authErrorSub?.cancel();
    _authErrorSub = appBloc.authError.listen((event) {
      final AuthError? authError = event;
      if (authError == null) {
        return;
      }
      showAuthError(
        authError: authError,
        context: context,
      );
    });
  }

  void setupLoadingScreen(BuildContext context) async {
    await _isLoadingSub?.cancel();
    _isLoadingSub = appBloc.isLoading.listen((isLoading) {
      if (isLoading) {
        LoadingScreen.instance().show(
          context: context,
          text: 'Loading...',
        );
      } else {
        LoadingScreen.instance().hide();
      }
    });
  }

  Widget getHomePage() {
    return StreamBuilder<CurrentView>(
      stream: appBloc.currentView,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return const Center(
              child: CircularProgressIndicator(),
            );
          case ConnectionState.active:
          case ConnectionState.done:
            final currentView = snapshot.requireData;
            switch (currentView) {
              case CurrentView.login:
                return LoginView(
                  login: appBloc.login,
                  goToRegisterView: appBloc.goToRegisterView,
                );
              case CurrentView.register:
                return RegisterView(
                  register: appBloc.register,
                  goToLoginView: appBloc.goToLoginView,
                );
              case CurrentView.contactList:
                return ContactsListView(
                  logout: appBloc.logout,
                  deleteAccount: appBloc.deleteAccount,
                  deleteContact: appBloc.deleteContact,
                  createNewContact: appBloc.goToCreateContactView,
                  contacts: appBloc.contacts,
                );
              case CurrentView.createContact:
                return NewContactView(
                  createContact: appBloc.createContact,
                  goBack: appBloc.goToContactListView,
                );
            }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    handleAuthErrors(context);
    setupLoadingScreen(context);
    return getHomePage();
  }
}