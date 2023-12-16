import 'package:flutter/material.dart';
import 'package:flutter_rxdar_contact_list/bloc/auth/auth_errors.dart';
import 'package:flutter_rxdar_contact_list/dialogs/generic.dialog.dart';

Future<void> showAuthError({
  required AuthError authError,
  required BuildContext context,
}) =>
    showGenericDialog(
      context: context,
      title: authError.dialogTitle,
      content: authError.dialogText,
      optionsBuilder: () => {
        'OK': true,
      },
    );