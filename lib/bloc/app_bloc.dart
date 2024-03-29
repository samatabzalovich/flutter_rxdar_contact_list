import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_rxdar_contact_list/bloc/auth/auth_bloc.dart';
import 'package:flutter_rxdar_contact_list/bloc/auth/auth_errors.dart';
import 'package:flutter_rxdar_contact_list/bloc/contact_bloc.dart';
import 'package:flutter_rxdar_contact_list/bloc/views/current_view_enum.dart';
import 'package:flutter_rxdar_contact_list/bloc/views/views_bloc.dart';
import 'package:flutter_rxdar_contact_list/models/contact.dart';
import 'package:rxdart/rxdart.dart';
@immutable
class AppBloc {
  final AuthBloc _authBloc;
  final ViewsBloc _viewsBloc;
  final ContactsBloc _contactsBloc;

  final Stream<CurrentView> currentView;
  final Stream<bool> isLoading;
  final Stream<AuthError?> authError;
  final StreamSubscription<String?> _userIdChanges;

  factory AppBloc() {
    final authBloc = AuthBloc();
    final viewsBloc = ViewsBloc();
    final contactsBloc = ContactsBloc();

    // pass userid from auth bloc into the contacts bloc

    final userIdChanges = authBloc.userId.listen((String? userId) {
      contactsBloc.userId.add(userId);
    });

    // calculate the current view
    final Stream<CurrentView> currentViewBasedOnAuthStatus =
        authBloc.authStatus.map<CurrentView>((authStatus) {
      if (authStatus is AuthStatusLoggedIn) {
        return CurrentView.contactList;
      } else {
        return CurrentView.login;
      }
    });

    // current view

    final Stream<CurrentView> currentView = Rx.merge([
      currentViewBasedOnAuthStatus,
      viewsBloc.currentView,
    ]);

    // isLoading

    final Stream<bool> isLoading = Rx.merge([
      authBloc.isLoading,
    ]);

    return AppBloc._(
      authBloc: authBloc,
      viewsBloc: viewsBloc,
      contactsBloc: contactsBloc,
      currentView: currentView,
      isLoading: isLoading.asBroadcastStream(),
      authError: authBloc.authError.asBroadcastStream(),
      userIdChanges: userIdChanges,
    );
  }

  void dispose() {
    _authBloc.dispose();
    _viewsBloc.dispose();
    _contactsBloc.dispose();
    _userIdChanges.cancel();
  }

  const AppBloc._({
    required AuthBloc authBloc,
    required ViewsBloc viewsBloc,
    required ContactsBloc contactsBloc,
    required this.currentView,
    required this.isLoading,
    required this.authError,
    required StreamSubscription<String?> userIdChanges,
  })  : _authBloc = authBloc,
        _viewsBloc = viewsBloc,
        _contactsBloc = contactsBloc,
        _userIdChanges = userIdChanges;

  void deleteContact(Contact contact) {
    _contactsBloc.deleteContact.add(
      contact,
    );
  }

  void createContact(
    String firstName,
    String lastName,
    String phoneNumber,
  ) {
    _contactsBloc.createContact.add(
      Contact.withoutId(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      ),
    );
  }

  void deleteAccount() {
    _contactsBloc.deleteAllContacts.add(null);
    _authBloc.deleteAccount.add(null);
  }

  void logout() {
    _authBloc.logout.add(
      null,
    );
  }

  Stream<Iterable<Contact>> get contacts => _contactsBloc.contacts;

  void register(
    String email,
    String password,
  ) {
    _authBloc.register.add(
      RegisterCommand(
        email: email,
        password: password,
      ),
    );
  }

  void login(
    String email,
    String password,
  ) {
    _authBloc.login.add(
      LoginCommand(
        email: email,
        password: password,
      ),
    );
  }

  void goToContactListView() => _viewsBloc.goToView.add(
        CurrentView.contactList,
      );

  void goToCreateContactView() => _viewsBloc.goToView.add(
        CurrentView.createContact,
      );

  void goToRegisterView() => _viewsBloc.goToView.add(
        CurrentView.register,
      );

  void goToLoginView() => _viewsBloc.goToView.add(
        CurrentView.login,
      );
}