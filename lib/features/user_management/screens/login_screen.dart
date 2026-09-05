import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  final VoidCallback onLoginSuccess;

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController =
  TextEditingController();

  final _passwordController =
  TextEditingController();

  final _formKey =
  GlobalKey<FormState>();

  bool _loading = false;
  bool _hidePassword = true;

  SupabaseClient get _supabase =>
      Supabase.instance.client;

  void _showError(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        behavior:
        SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(
              Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style:
                const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        behavior:
        SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style:
                const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_loading) return;

    final valid =
        _formKey.currentState
            ?.validate() ??
            false;

    if (!valid) return;

    setState(() {
      _loading = true;
    });

    try {
      final response =
      await _supabase.auth
          .signInWithPassword(
        email:
        _emailController.text
            .trim(),
        password:
        _passwordController.text,
      );

      if (response.user == null) {
        _showError(
          'Login failed. Please try again.',
        );
        return;
      }

      _showSuccess(
        'Login successful.',
      );

      widget.onLoginSuccess();
    } on AuthException catch (e) {
      _showError(
        e.message,
      );
    } catch (e) {
      _showError(
        'Unable to login. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const RegisterScreen(),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F5F5),

      appBar: AppBar(
        title:
        const Text(
          'Login',
        ),
        automaticallyImplyLeading:
        false,
      ),

      body: SafeArea(
        child: Center(
          child:
          SingleChildScrollView(
            padding:
            const EdgeInsets.all(
              24,
            ),
            child:
            ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 420,
              ),
              child: Card(
                elevation: 4,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets
                      .all(
                    24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 34,
                          backgroundColor:
                          Colors.black,
                          child: Icon(
                            Icons
                                .directions_transit,
                            color:
                            Color(
                              0xFFFCEB00,
                            ),
                            size: 38,
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        const Text(
                          'Welcome to Sentra1',
                          style:
                          TextStyle(
                            fontSize: 24,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        const Text(
                          'Login to access reports and personalised transit features.',
                          textAlign:
                          TextAlign
                              .center,
                          style:
                          TextStyle(
                            color:
                            Colors.grey,
                          ),
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        TextFormField(
                          controller:
                          _emailController,
                          keyboardType:
                          TextInputType
                              .emailAddress,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Email',
                            prefixIcon:
                            Icon(
                              Icons.email,
                            ),
                            border:
                            OutlineInputBorder(),
                          ),
                          validator:
                              (value) {
                            final email =
                                value
                                    ?.trim() ??
                                    '';

                            if (email
                                .isEmpty) {
                              return 'Please enter your email.';
                            }

                            if (!email
                                .contains(
                              '@',
                            )) {
                              return 'Please enter a valid email.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        TextFormField(
                          controller:
                          _passwordController,
                          obscureText:
                          _hidePassword,
                          decoration:
                          InputDecoration(
                            labelText:
                            'Password',
                            prefixIcon:
                            const Icon(
                              Icons.lock,
                            ),
                            suffixIcon:
                            IconButton(
                              onPressed:
                                  () {
                                setState(
                                      () {
                                    _hidePassword =
                                    !_hidePassword;
                                  },
                                );
                              },
                              icon: Icon(
                                _hidePassword
                                    ? Icons
                                    .visibility
                                    : Icons
                                    .visibility_off,
                              ),
                            ),
                            border:
                            const OutlineInputBorder(),
                          ),
                          validator:
                              (value) {
                            if (value ==
                                null ||
                                value
                                    .isEmpty) {
                              return 'Please enter your password.';
                            }

                            if (value.length <
                                6) {
                              return 'Password must contain at least 6 characters.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        SizedBox(
                          width:
                          double.infinity,
                          child:
                          ElevatedButton.icon(
                            style:
                            ElevatedButton
                                .styleFrom(
                              backgroundColor:
                              Colors.black,
                              foregroundColor:
                              const Color(
                                0xFFFCEB00,
                              ),
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                vertical:
                                14,
                              ),
                            ),
                            onPressed:
                            _loading
                                ? null
                                : _login,
                            icon:
                            _loading
                                ? const SizedBox(
                              width:
                              20,
                              height:
                              20,
                              child:
                              CircularProgressIndicator(
                                strokeWidth:
                                2,
                                color:
                                Color(
                                  0xFFFCEB00,
                                ),
                              ),
                            )
                                : const Icon(
                              Icons.login,
                            ),
                            label: Text(
                              _loading
                                  ? 'Logging in...'
                                  : 'Login',
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                          children: [
                            const Text(
                              'No account yet?',
                            ),
                            TextButton(
                              onPressed:
                              _openRegister,
                              child:
                              const Text(
                                'Register',
                                style:
                                TextStyle(
                                  color:
                                  Colors.black,
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }
}