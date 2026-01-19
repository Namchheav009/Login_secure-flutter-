import 'dart:ui';
import 'package:flutter/material.dart';

import 'database/app_db.dart';
import 'welcome.dart';

class HomeScreen extends StatefulWidget {
  final String? currentEmail;

  const HomeScreen({Key? key, this.currentEmail}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, Object?>>> _usersFuture;
  Future<Map<String, Object?>?>? _meFuture;

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();

    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    _usersFuture = AppDB.instance.getAllUsers();
    if (widget.currentEmail != null && widget.currentEmail!.isNotEmpty) {
      _meFuture = AppDB.instance.getUserByEmail(widget.currentEmail!);
    } else {
      _meFuture = null;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B2D5B), // deep professional blue
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_meFuture != null) _buildMeCard(),
                    const SizedBox(height: 14),
                    _sectionTitle('Group 4'),
                    const SizedBox(height: 10),
                    Expanded(child: _buildUsersList()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TOP BAR =================
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          _roundIconButton(
            icon: Icons.logout_rounded,
            tooltip: 'Logout',
            onTap: _showLogoutConfirmation,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Home',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _roundIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onTap: _reload,
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  // ================= ME CARD =================
  Widget _buildMeCard() {
    return FutureBuilder<Map<String, Object?>?>(
      future: _meFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _glassContainer(
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  _SkeletonCircle(size: 44),
                  SizedBox(width: 12),
                  Expanded(child: _SkeletonLines()),
                ],
              ),
            ),
          );
        }

        if (!snap.hasData || snap.data == null) return const SizedBox.shrink();

        final me = snap.data!;
        final name = (me['name'] ?? 'User').toString();
        final email = (me['email'] ?? '').toString();

        return _glassContainer(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withOpacity(0.16),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= SECTION TITLE =================
  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ================= USERS LIST =================
  Widget _buildUsersList() {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: _usersFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return _stateBox(
            icon: Icons.error_outline_rounded,
            title: 'Database Error',
            subtitle: snap.error.toString(),
            actionText: 'Retry',
            onAction: _reload,
          );
        }

        final users = (snap.data ?? []);

        final filtered = users.where((u) {
          if (_query.isEmpty) return true;
          final name = (u['name'] ?? '').toString().toLowerCase();
          final email = (u['email'] ?? '').toString().toLowerCase();
          return name.contains(_query) || email.contains(_query);
        }).toList();

        if (filtered.isEmpty) {
          return _stateBox(
            icon: Icons.person_search_rounded,
            title: 'No users found',
            subtitle: _query.isEmpty ? 'Your database is empty.' : 'Try a different keyword.',
            actionText: 'Refresh',
            onAction: _reload,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _usersFuture;
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final user = filtered[index];
              final name = (user['name'] ?? '').toString();
              final email = (user['email'] ?? '').toString();

              return _userCard(
                name: name.isEmpty ? 'No name' : name,
                email: email,
                onEdit: () => _showUpdateDialog(user),
                onDelete: () => _showDeleteConfirmation(email),
              );
            },
          ),
        );
      },
    );
  }

  Widget _userCard({
    required String name,
    required String email,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _glassContainer(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.14),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 13),
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: Colors.white.withOpacity(0.85)),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      ),
    );
  }

  // ================= GLASS CONTAINER =================
  Widget _glassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ================= STATES (EMPTY/ERROR) =================
  Widget _stateBox({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _glassContainer(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.9), size: 42),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0B2D5B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(actionText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= LOGOUT =================
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // ================= DELETE =================
  void _showDeleteConfirmation(String email) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete $email ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await AppDB.instance.deleteUser(email);
              Navigator.pop(context);
              _reload();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color.fromARGB(217, 244, 67, 54)),
            ),
          ),
        ],
      ),
    );
  }

  // ================= UPDATE =================
  void _showUpdateDialog(Map<String, Object?> user) {
    final nameCtrl = TextEditingController(text: (user['name'] ?? '').toString());
    final emailCtrl = TextEditingController(text: (user['email'] ?? '').toString());
    final oldEmail = (user['email'] ?? '').toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await AppDB.instance.updateUser(
                oldEmail,
                nameCtrl.text.trim(),
                emailCtrl.text.trim(),
              );
              Navigator.pop(context);
              _reload();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

// ====== small skeleton widgets for loading ======
class _SkeletonCircle extends StatelessWidget {
  final double size;
  const _SkeletonCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SkeletonLines extends StatelessWidget {
  const _SkeletonLines();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 10,
          width: 180,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}
