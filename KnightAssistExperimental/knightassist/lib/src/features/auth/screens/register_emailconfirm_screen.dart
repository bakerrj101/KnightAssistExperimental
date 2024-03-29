import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:knightassist/src/config/routing/app_router.dart';

import '../../../config/routing/routes.dart';
import '../../../global/widgets/responsive_scrollable_card.dart';

class ConfirmScreen extends ConsumerWidget {
  const ConfirmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Confirmation'),
      ),
      body: ResponsiveScrollableCard(
        child: SizedBox(
          width: 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Image(
                image: AssetImage('assets/KnightAssistCoA3.png'),
                height: 60,
                alignment: Alignment.center,
              ),
              const Text(
                'Thanks for signing up! Please enter a confirmation code from your email to verify your account.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.email,
                    color: Color.fromARGB(255, 91, 78, 119), size: 50.0),
              ),
              const Divider(
                height: 40,
                indent: 40,
                endIndent: 40,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    _buildTextField(labelText: 'Verification code'),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: BuildTextButton(),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

TextField _buildTextField({String labelText = '', bool obscureText = false}) {
  return TextField(
    cursorColor: Colors.black54,
    cursorWidth: 1,
    obscureText: obscureText,
    obscuringCharacter: '●',
    decoration: InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(
        color: Colors.black54,
        fontSize: 18,
      ),
      fillColor: Colors.red,
      border: const OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.black54,
        ),
        borderRadius: BorderRadius.all(
          Radius.circular(40),
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.black54,
          width: 1.5,
        ),
        borderRadius: BorderRadius.all(
          Radius.circular(40),
        ),
      ),
    ),
  );
}

class BuildTextButton extends StatelessWidget {
  const BuildTextButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                title: const Text('Email confirmed'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'Cancel'),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () =>
                        AppRouter.pushNamed(Routes.LoginScreenRoute),
                    child: const Text('OK'),
                  ),
                ],
              )),
      style: ButtonStyle(
        //padding: MaterialStateProperty.all(
        //const EdgeInsets.symmetric(vertical: 20),
        //),
        side:
            MaterialStateProperty.all(const BorderSide(color: Colors.black54)),
        backgroundColor:
            MaterialStateProperty.all(const Color.fromARGB(255, 91, 78, 119)),
      ),
      child: const Text(
        'Submit',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    );
  }
}
