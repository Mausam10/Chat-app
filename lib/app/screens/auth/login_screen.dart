import 'package:chat_app/app/controllers/login_controller.dart';
import 'package:chat_app/app/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app/app/themes/theme_selector_sheet.dart';

class LoginScreen extends StatelessWidget {
  final controller = Get.put(LoginController());

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxBool isPasswordHidden = true.obs;

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.palette_outlined, color: colorScheme.primary),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => showThemeSelectorSheet(),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Icon with theme-aware styling
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.chat_bubble_rounded,
                  size: 64,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Welcome Text
            Text(
              "Welcome Back",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Sign in to your account",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),

            // Email Field with theme styling
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: "Email",
                hintText: "you@example.com",
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: colorScheme.primary,
                ),
                labelStyle: TextStyle(color: colorScheme.primary),
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outline, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.error, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Password Field with theme styling
            Obx(
              () => TextField(
                controller: passwordController,
                obscureText: isPasswordHidden.value,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: colorScheme.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordHidden.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed:
                        () => isPasswordHidden.value = !isPasswordHidden.value,
                  ),
                  labelStyle: TextStyle(color: colorScheme.primary),
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.error, width: 1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Handle forgot password
                },
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sign In Button with theme styling
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ).copyWith(
                  overlayColor: WidgetStateProperty.all(
                    colorScheme.onPrimary.withValues(alpha: 0.1),
                  ),
                ),
                onPressed: () {
                  Get.snackbar(
                    "Login",
                    "Sign in pressed!",
                    backgroundColor: colorScheme.primary,
                    colorText: colorScheme.onPrimary,
                    borderRadius: 12,
                    margin: const EdgeInsets.all(16),
                  );
                },
                child: Text(
                  "Sign In",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Divider with "OR"
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: colorScheme.outline.withValues(alpha: 0.5),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "OR",
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: colorScheme.outline.withValues(alpha: 0.5),
                    thickness: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Social Login Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Handle Google sign in
                    },
                    icon: Icon(
                      Icons.g_mobiledata,
                      color: colorScheme.onSurface,
                      size: 24,
                    ),
                    label: Text(
                      "Google",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Handle Apple sign in
                    },
                    icon: Icon(
                      Icons.apple,
                      color: colorScheme.onSurface,
                      size: 20,
                    ),
                    label: Text(
                      "Apple",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Create Account Text with theme styling
            Center(
              child: TextButton(
                onPressed: () {
                  Get.to(
                    () => RegisterScreen(),
                    arguments: "Data received from first screen",
                  );
                },
                child: Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(
                        text: "Create Account",

                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
