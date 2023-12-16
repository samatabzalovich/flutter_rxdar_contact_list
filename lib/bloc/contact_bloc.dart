import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_rxdar_contact_list/models/contact.dart';
import 'package:rxdart/rxdart.dart';

typedef _Snapshots = QuerySnapshot<Map<String, dynamic>>;
typedef _Document = DocumentReference<Map<String, dynamic>>;

extension Unwrap<T> on Stream<T?> {
  Stream<T> unwrap() => switchMap(
        (optional) async* {
          if (optional != null) {
            yield optional;
          }
        },
      );
}

@immutable
class ContactsBloc {
  final Sink<String?> userId;
  final Sink<Contact> createContact;
  final Sink<Contact> deleteContact;
  final Sink<void> deleteAllContacts;
  final Stream<Iterable<Contact>> contacts;
  final StreamSubscription<void> _createContactSubscription;
  final StreamSubscription<void> _deleteContactSubscription;
  final StreamSubscription<void> _deleteAllContactsSubscription;

  void dispose() {
    userId.close();
    createContact.close();
    deleteContact.close();
    deleteAllContacts.close();
    _createContactSubscription.cancel();
    _deleteContactSubscription.cancel();
    _deleteAllContactsSubscription.cancel();
  }

  const ContactsBloc._({
    required this.userId,
    required this.createContact,
    required this.deleteContact,
    required this.contacts,
    required this.deleteAllContacts,
    required StreamSubscription<void> createContactSubscription,
    required StreamSubscription<void> deleteContactSubscription,
    required StreamSubscription<void> deleteAllContactsSubscription,
  })  : _createContactSubscription = createContactSubscription,
        _deleteContactSubscription = deleteContactSubscription,
        _deleteAllContactsSubscription = deleteAllContactsSubscription;
  factory ContactsBloc() {
    final backend = FirebaseFirestore.instance;
    final userId = BehaviorSubject<String?>();
    final Stream<Iterable<Contact>> contacts = userId.switchMap((userId) {
      if (userId == null) {
        return const Stream<_Snapshots>.empty();
      }
      return backend.collection(userId).snapshots();
    }).map<Iterable<Contact>>((snapshots) sync* {
      for (final snapshot in snapshots.docs) {
        yield Contact.fromJson(snapshot.data(), id: snapshot.id);
      }
    });
    // create contact
    final createContact = BehaviorSubject<Contact>();
    final StreamSubscription<void> createContactSubscription = createContact
        .switchMap(
          (Contact contactToCreate) => userId
              .take(
                1,
              )
              .unwrap()
              .asyncMap(
                (userId) => backend
                    .collection(
                      userId,
                    )
                    .add(
                      contactToCreate.data,
                    ),
              ),
        )
        .listen((event) {});
    // delete contact

    final deleteContact = BehaviorSubject<Contact>();

    final StreamSubscription<void> deleteContactSubscription = deleteContact
        .switchMap(
          (Contact contactToDelete) => userId
              .take(
                1,
              )
              .unwrap()
              .asyncMap(
                (userId) => backend
                    .collection(
                      userId,
                    )
                    .doc(
                      contactToDelete.id,
                    )
                    .delete(),
              ),
        )
        .listen((event) {});

    final deleteAllContacts = BehaviorSubject<void>();
    final deleteAllContactSubscription = deleteAllContacts
        .switchMap((_) => userId
            .take(
              1,
            )
            .unwrap()
            .asyncMap(
              (userId) => FirebaseFirestore.instance
                  .collection(
                    userId,
                  )
                  .get(),
            )
            .switchMap(
              (collection) => Stream.fromFutures(
                collection.docs.map(
                  (e) => e.reference.delete(),
                ),
              ),
            ))
        .listen((event) {});

    return ContactsBloc._(
        userId: userId,
        createContact: createContact,
        deleteContact: deleteContact,
        contacts: contacts,
        deleteAllContacts: deleteAllContacts,
        createContactSubscription: createContactSubscription,
        deleteContactSubscription: deleteContactSubscription,
        deleteAllContactsSubscription: deleteAllContactSubscription);
  }
}
