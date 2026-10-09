import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/view/forgot_password.dart';

final _firebase = FirebaseAuth.instance;

class NewAccountPage extends StatefulWidget {
  const NewAccountPage({super.key});

  @override
  State<NewAccountPage> createState() => _NewAccountPageState();
}

class _NewAccountPageState extends State<NewAccountPage> {
  final _form = GlobalKey<FormState>();
  final _logger = Logger(printer: PrettyPrinter());

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _confirmFocus = FocusNode();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _confirmTouched = false;
  bool _submittedOnce = false;

  String get _password => _passwordController.text;
  String get _confirmation => _confirmController.text;
  bool get _passwordsMismatch =>
      _confirmation.isNotEmpty && _confirmation != _password;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_refreshPasswordFeedback);
    _confirmController.addListener(_refreshPasswordFeedback);
    _confirmFocus.addListener(() {
      if (!_confirmFocus.hasFocus && _confirmation.isNotEmpty && mounted) {
        setState(() => _confirmTouched = true);
      }
    });
  }

  void _refreshPasswordFeedback() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_refreshPasswordFeedback);
    _confirmController.removeListener(_refreshPasswordFeedback);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Inserisci la tua email';
    }
    if (!kRegexEmail.hasMatch(email)) {
      return 'Inserisci un indirizzo email valido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Inserisci una password';
    if (!kRegexPassword.hasMatch(password)) {
      return 'La password non soddisfa tutti i requisiti';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) return 'Conferma la password';
    if (value != _password) return 'Le password non coincidono';
    return null;
  }

  Future<void> _submitRegistration() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submittedOnce = true;
      _confirmTouched = true;
    });
    if (!(_form.currentState?.validate() ?? false) || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    User? createdUser;
    try {
      final credential = await _firebase.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _password,
      );
      final user = credential.user;
      if (user == null) throw StateError('Utente non disponibile');
      createdUser = user;

      final uid = user.uid;
      final codiceInvito = uid.substring(10, 16).toUpperCase();
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': _emailController.text.trim(),
        'uid': uid,
        'liste': [],
        'codiceInvito': codiceInvito,
        'isPro': false,
        'subscription': [],
      });
      await user.sendEmailVerification();
      await _firebase.signOut();

      _logger.i('Account creato; email di verifica inviata');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Verifica la tua email'),
              content: Text(
                'Abbiamo inviato un link di verifica a '
                '${_emailController.text.trim()}. Apri questa email e clicca '
                'sul link al suo interno per confermare l’indirizzo. Dopo la '
                'verifica potrai accedere all’app. Se non trovi il messaggio, '
                'controlla anche la cartella spam.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Torna al login'),
                ),
              ],
            ),
      );
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      if (createdUser != null) await _firebase.signOut();
      if (error.code == 'email-already-in-use') {
        await _showExistingEmailDialog();
        return;
      }
      final message =
          createdUser != null
              ? 'Account creato, ma non è stato possibile completare la '
                  'verifica email. Torna al login per richiedere un nuovo link.'
              : switch (error.code) {
                'invalid-email' => 'Indirizzo email non valido',
                'weak-password' => 'Password troppo debole',
                'network-request-failed' => 'Problema di connessione. Riprova.',
                'too-many-requests' =>
                  'Troppe richieste. Attendi qualche minuto e riprova.',
                _ => 'Impossibile creare l’account. Riprova.',
              };
      _showError(message);
      _logger.e('Registrazione Firebase fallita: ${error.code}');
    } catch (error) {
      if (createdUser != null) await _firebase.signOut();
      _showError(
        createdUser != null
            ? 'Account creato, ma non è stato possibile completare la '
                'verifica email. Torna al login per richiedere un nuovo link.'
            : 'Non è stato possibile completare la registrazione. '
                'Riprova tra poco.',
      );
      _logger.e('Errore durante la registrazione: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showExistingEmailDialog() async {
    if (!mounted) return;
    final resetPassword = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Email già registrata'),
            content: const Text(
              'Esiste già un account con questo indirizzo email. '
              'Accedi oppure, se hai dimenticato la password, puoi '
              'reimpostarla.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Torna al login'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Password dimenticata?'),
              ),
            ],
          ),
    );

    if (!mounted) return;
    if (resetPassword == true) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => ForgotPassword(
                initialEmail: _emailController.text.trim(),
              ),
        ),
      );
    } else if (resetPassword == false) {
      Navigator.of(context).pop();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
      );
  }

  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kBluScuro),
      floatingLabelStyle: const TextStyle(color: kPrimary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: kPrimary.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: kPrimary.withValues(alpha: 0.40)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kPrimary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
      ),
    );
  }

  Widget _passwordRequirement(String label, bool satisfied) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            satisfied ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: satisfied ? kGreen : kBluScuro.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: kBluScuro),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordRequirements() {
    final password = _password;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'La password deve contenere:',
          style: TextStyle(
            color: kBluScuro,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        _passwordRequirement('Almeno 8 caratteri', password.length >= 8),
        _passwordRequirement(
          'Una lettera maiuscola e una minuscola',
          RegExp(r'[A-Z]').hasMatch(password) &&
              RegExp(r'[a-z]').hasMatch(password),
        ),
        _passwordRequirement(
          'Almeno un numero',
          RegExp(r'\d').hasMatch(password),
        ),
        _passwordRequirement(
          'Almeno un carattere speciale',
          RegExp(r'[!@#$&*~^%+=?_-]').hasMatch(password),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCreateAccount =
        kRegexPassword.hasMatch(_password) &&
        _confirmation.isNotEmpty &&
        _confirmation == _password &&
        !_isSubmitting;
    final showMismatch =
        _confirmTouched && !_submittedOnce && _passwordsMismatch;
    final showMatch =
        _confirmTouched &&
        _confirmation.isNotEmpty &&
        _confirmation == _password;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: kBluScuro),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Form(
            key: _form,
            autovalidateMode:
                _submittedOnce
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Image.asset(kLogo, height: 58, width: 58),
                              const SizedBox(height: 5),
                              const Text(
                                kAppName,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Crea il tuo account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kBluScuro,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          decoration: _inputDecoration('Email'),
                          keyboardType: TextInputType.emailAddress,
                          textCapitalization: TextCapitalization.none,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          decoration: _inputDecoration(
                            'Password',
                            suffixIcon: IconButton(
                              tooltip:
                                  _obscurePassword
                                      ? 'Mostra password'
                                      : 'Nascondi password',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: kPrimary,
                              ),
                              onPressed:
                                  () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          enableSuggestions: false,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmController,
                          focusNode: _confirmFocus,
                          decoration: _inputDecoration(
                            'Conferma password',
                            suffixIcon: IconButton(
                              tooltip:
                                  _obscureConfirm
                                      ? 'Mostra conferma password'
                                      : 'Nascondi conferma password',
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: kPrimary,
                              ),
                              onPressed:
                                  () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                            ),
                          ),
                          obscureText: _obscureConfirm,
                          enableSuggestions: false,
                          autocorrect: false,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            _confirmFocus.unfocus();
                            setState(() => _confirmTouched = true);
                          },
                          // La validazione del form viene eseguita al submit;
                          // il feedback live compare solo dopo che il campo
                          // conferma ha perso il focus.
                          validator: _validateConfirmation,
                        ),
                        if (showMismatch) ...[
                          const SizedBox(height: 5),
                          const Text(
                            'Le password non coincidono',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ] else if (showMatch) ...[
                          const SizedBox(height: 5),
                          const Row(
                            children: [
                              Icon(Icons.check_circle, size: 15, color: kGreen),
                              SizedBox(width: 5),
                              Text(
                                'Le password coincidono',
                                style: TextStyle(color: kGreen, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        _passwordRequirements(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: canCreateAccount ? _submitRegistration : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      child:
                          _isSubmitting
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                'Crea account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
