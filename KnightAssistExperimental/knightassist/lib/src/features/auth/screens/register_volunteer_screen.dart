import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:knightassist/src/config/routing/app_router.dart';
import 'package:knightassist/src/global/providers/all_providers.dart';
import 'package:knightassist/src/global/widgets/scrollable_column.dart';
import 'package:knightassist/src/helpers/form_validator.dart';

import '../../../global/states/auth_state.codegen.dart';
import '../../../global/widgets/custom_dialog.dart';
import '../../../global/widgets/custom_text_button.dart';
import '../../../global/widgets/custom_text_field.dart';
import '../../../helpers/constants/app_colors.dart';

class RegisterVolunteerScreen extends HookConsumerWidget {
  const RegisterVolunteerScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final emailController = useTextEditingController(text: '');
    final firstNameController = useTextEditingController(text: '');
    final lastNameController = useTextEditingController(text: '');
    final passwordController = useTextEditingController(text: '');
    final repeatPasswordController = useTextEditingController(text: '');

    void onAuthStateAuthenticated(String? currentUserEmail) {
      emailController.clear();
      firstNameController.clear();
      lastNameController.clear();
      passwordController.clear();
      repeatPasswordController.clear();
      AppRouter.popUntilRoot();
    }

    void onAuthStateFailed(String reason) async {
      await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return CustomDialog.alert(
            title: 'Register Failed',
            body: reason,
            buttonText: 'Retry',
          );
        },
      );
    }

    ref.listen<AuthState>(
      authProvider,
      (previous, authState) async => authState.maybeWhen(
        authenticated: onAuthStateAuthenticated,
        failed: onAuthStateFailed,
        orElse: () {},
      ),
    );

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ScrollableColumn(
          children: [
            Form(
              key: formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(25, 28, 25, 20),
                child: Column(
                  children: [
                    const Image(
                      image: AssetImage('assets/KnightAssistCoA3.png'),
                      height: 60,
                    ),

                    // Page Name
                    const Text(
                      'Register Volunteer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Email
                    CustomTextField(
                      controller: emailController,
                      floatingText: 'Email',
                      hintText: 'user@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: FormValidator.emailValidator,
                    ),

                    const SizedBox(height: 10),

                    // First Name
                    CustomTextField(
                      controller: firstNameController,
                      floatingText: 'First Name',
                      hintText: 'John',
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      validator: FormValidator.nameValidator,
                    ),

                    const SizedBox(height: 10),

                    // Last Name
                    CustomTextField(
                      controller: lastNameController,
                      floatingText: 'Last Name',
                      hintText: 'Doe',
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      validator: FormValidator.nameValidator,
                    ),

                    const SizedBox(height: 10),

                    // Password
                    CustomTextField(
                      controller: passwordController,
                      floatingText: 'Password',
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.next,
                      validator: FormValidator.passwordValidator,
                    ),

                    const SizedBox(height: 10),

                    // Repeat password
                    // TODO: Add logic to compare password fields
                    CustomTextField(
                      controller: repeatPasswordController,
                      floatingText: 'Repeat Password',
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      validator: FormValidator.passwordValidator,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 2),
              child: CustomTextButton(
                width: double.infinity,
                color: AppColors.primaryColor,
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    ref.read(authProvider.notifier).registerVolunteer(
                          email: emailController.text,
                          password: passwordController.text,
                          firstName: firstNameController.text,
                          lastName: lastNameController.text,
                        );
                  }
                },
                child: Consumer(
                  builder: (context, ref, child) {
                    final authState = ref.watch(authProvider);
                    if (authState is AUTHENTICATING) {
                      return const Center(
                        child: SpinKitRing(
                          color: Colors.white,
                          size: 30,
                          lineWidth: 4,
                          duration: Duration(milliseconds: 1100),
                        ),
                      );
                    }
                    return child!;
                  },
                  child: const Center(
                    child: Text(
                      'Confirm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        letterSpacing: 0.7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
