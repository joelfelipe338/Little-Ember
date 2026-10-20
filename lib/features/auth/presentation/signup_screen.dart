import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/ember_button.dart';
import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';
import '../providers/auth_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _success = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nome: _nomeController.text.trim(),
      );
      if (mounted) {
        setState(() => _success = true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = _parseError(e);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('already registered') || msg.contains('user_already_exists')) {
      return 'Esse email já está cadastrado.';
    }
    if (msg.contains('weak password') || msg.contains('password')) {
      return 'Senha muito fraca. Use pelo menos 6 caracteres.';
    }
    if (msg.contains('network')) {
      return 'Sem conexão. Verifique sua internet.';
    }
    return 'Erro ao criar conta. Tente novamente.';
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RetroScaffold(
      top: RetroTopBar(
        left: 'CRIAR',
        right: 'CONTA',
        leading: _success
            ? null
            : RetroButton.icon(
                onPressed: _back,
                semanticLabel: 'Voltar',
                icon: const Icon(Icons.arrow_back_rounded),
              ),
      ),
      panelPadding: EdgeInsets.zero,
      body: _success ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: EmberColors.menta,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(BorderSide(color: EmberColors.tinta, width: EmberRetro.borda)),
                boxShadow: [BoxShadow(color: EmberColors.tinta, offset: Offset(0, 5))],
              ),
              child: const Icon(Icons.check_rounded, color: EmberColors.tinta, size: 44),
            ),
            const SizedBox(height: 24),
            Text('Conta criada!', style: EmberText.display(30), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Verifique seu email para confirmar a conta e depois faça login.',
              style: EmberText.body(15, color: EmberColors.textoSecundario),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            EmberButton(
              label: 'Ir para login',
              onPressed: () => context.go('/login'),
              icon: Icons.login_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 22),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Bem-vindo à roda', style: EmberText.display(32)),
            const SizedBox(height: 4),
            Text(
              'Leva 30 segundos. Depois é só chamar a galera.',
              style: EmberText.body(15, color: EmberColors.textoSecundario),
            ),
            const SizedBox(height: 22),
            const RetroFieldLabel('Nome'),
            TextFormField(
              controller: _nomeController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(hintText: 'Como a galera te chama?'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Digite seu nome';
                if (v.trim().length < 2) return 'Nome muito curto';
                return null;
              },
            ),
            const SizedBox(height: 14),
            const RetroFieldLabel('Email'),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(hintText: 'voce@email.com'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Digite seu email';
                if (!v.contains('@')) return 'Email inválido';
                return null;
              },
            ),
            const SizedBox(height: 14),
            const RetroFieldLabel('Senha'),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _handleSignup(),
              decoration: InputDecoration(
                helperText: 'Mínimo 6 caracteres',
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Mostrar senha' : 'Esconder senha',
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Digite uma senha';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              RetroErrorBox(_errorMessage!),
            ],
            const SizedBox(height: 22),
            EmberButton(
              label: 'CRIAR CONTA',
              onPressed: _handleSignup,
              isLoading: _isLoading,
              expand: true,
              icon: Icons.person_add_alt_1_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
