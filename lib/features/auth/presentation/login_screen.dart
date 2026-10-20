import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/ember_button.dart';
import '../../../shared/widgets/ember_flame.dart';
import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
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
    if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
      return 'Email ou senha incorretos.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Confirme seu email antes de entrar.';
    }
    if (msg.contains('network')) {
      return 'Sem conexão. Verifique sua internet.';
    }
    return 'Erro ao entrar. Tente novamente.';
  }

  void _soon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login com $provider em breve!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RetroScaffold(
      top: const RetroTopBar(left: 'LITTLE', right: 'EMBER'),
      ticker: 'CONVIDADOS VOTAM PELO LINK  •  O APP DECIDE POR VOCÊS  •  ${AppConstants.sloganCurto.toUpperCase()}  •',
      panelPadding: EdgeInsets.zero,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mascote + saudação
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Brasinha(size: 84),
                const SizedBox(width: 12),
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 30),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: EmberColors.branco,
                      border: EmberRetro.contorno,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                    child: Text('E aí! Bora acender um rolê?', style: EmberText.mono(13).copyWith(height: 1.4, letterSpacing: 0)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Entrar', style: EmberText.display(34)),
            const SizedBox(height: 4),
            Text(
              AppConstants.slogan,
              style: EmberText.body(15, color: EmberColors.textoSecundario),
            ),
            const SizedBox(height: 22),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword ? 'Mostrar senha' : 'Esconder senha',
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Digite sua senha';
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
                    label: 'ENTRAR',
                    icon: Icons.play_arrow_rounded,
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                    expand: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OU', style: EmberText.mono(11, color: EmberColors.textoSecundario)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: RetroButton(
                    onPressed: () => _soon('Google'),
                    color: EmberColors.branco,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        SizedBox(width: 8),
                        Text('Google'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RetroButton(
                    onPressed: () => _soon('Apple'),
                    color: EmberColors.tinta,
                    foregroundColor: EmberColors.creme,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.apple, size: 22),
                        SizedBox(width: 6),
                        Text('Apple'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Não tem conta? ', style: EmberText.body(14, color: EmberColors.textoSecundario)),
                TextButton(
                  onPressed: () => context.push('/signup'),
                  style: TextButton.styleFrom(
                    foregroundColor: EmberColors.brasaTexto,
                    minimumSize: const Size(44, 44),
                  ),
                  child: const Text('Criar conta'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
