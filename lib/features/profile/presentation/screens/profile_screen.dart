import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart' show ImagePicker, ImageSource;
import 'package:pfe_smart_clothing/features/marketplace/presentation/cubit/marketplace_cubit.dart';
import 'package:pfe_smart_clothing/features/wardrobe/presentation/cubit/wardrobe_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nomController = TextEditingController();
  final _telController = TextEditingController();
  final _tailleController = TextEditingController();
  final _poidsController = TextEditingController();
  bool _isEditing = false;
  Uint8List? _pickedPhotoBytes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomController.dispose();
    _telController.dispose();
    _tailleController.dispose();
    _poidsController.dispose();
    super.dispose();
  }

  void _populateControllers(ProfileState state) {
    if (state.profile != null && !_isEditing) {
      _nomController.text = state.profile!.nom;
      _telController.text = state.profile!.telephone;
      _tailleController.text =
          state.profile!.taille == 0 ? '' : state.profile!.taille.toString();
      _poidsController.text =
          state.profile!.poids == 0 ? '' : state.profile!.poids.toString();
    }
  }

  Future<void> _pickPhoto() async {
    final xfile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    if (!mounted) return;
    setState(() => _pickedPhotoBytes = bytes);
    context.read<ProfileCubit>().uploadPhoto(xfile);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        _populateControllers(state);
        if (state.successMessage != null) {
          setState(() {
            _pickedPhotoBytes = null;
            _isEditing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.successMessage!),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
          context.read<ProfileCubit>().clearMessages();
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ));
          context.read<ProfileCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2D0061),
                  Color(0xFF5B21B6),
                  Color(0xFF7C3AED),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: state.isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF6D28D9)))
                  : Column(
                      children: [
                        _buildTopBar(context, state),
                        _buildProfileCard(state),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(28)),
                            ),
                            child: Column(
                              children: [
                                _buildTabBar(),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _buildInfoTab(context, state),
                                      _buildOrdersTab(state),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, ProfileState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Mon Profil',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.logout, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Déconnexion',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Avatar ───────────────────────────────────────────────────────────────────
  Widget _buildGeneratedAvatar(String initials, double size) {
    final colors = _avatarColors(initials);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -size * 0.18,
            right: -size * 0.18,
            child: Container(
              width: size * 0.55,
              height: size * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -size * 0.12,
            left: -size * 0.12,
            child: Container(
              width: size * 0.45,
              height: size * 0.45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Center(
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.35,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _avatarColors(String seed) {
    final palettes = [
      [const Color(0xFF6D28D9), const Color(0xFF7C3AED)],
      [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
      [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
      [const Color(0xFFC62828), const Color(0xFFEF9A9A)],
      [const Color(0xFFE65100), const Color(0xFFFFB74D)],
      [const Color(0xFF00695C), const Color(0xFF4DB6AC)],
      [const Color(0xFF4527A0), const Color(0xFF7986CB)],
      [const Color(0xFF558B2F), const Color(0xFFAED581)],
    ];
    final hash = seed.codeUnits.fold(0, (a, b) => a + b);
    return palettes[hash % palettes.length];
  }

  // ── Profile card ─────────────────────────────────────────────────────────────
  Widget _buildProfileCard(ProfileState state) {
    final nom = state.profile?.nom ?? '';
    final email = state.profile?.email ?? '';
    final tel = state.profile?.telephone ?? '';
    final taille = state.profile?.taille ?? 0;
    final poids = state.profile?.poids ?? 0;

    final parts = nom.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.length >= 2 && parts.first[0] != parts.last[0]
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : (nom.isNotEmpty
            ? nom[0].toUpperCase()
            : (email.isNotEmpty ? email[0].toUpperCase() : '?'));

    final photoUrl = state.profile?.photoUrl ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2D0061),
            Color(0xFF5B21B6),
            Color(0xFF7C3AED),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF6D28D9).withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6), width: 2.5),
                  ),
                  child: ClipOval(
                    child: () {
                      final Widget fallback =
                          _buildGeneratedAvatar(initials, 90);
                      if (_pickedPhotoBytes != null) {
                        return SizedBox(
                            width: 90,
                            height: 90,
                            child: Image.memory(_pickedPhotoBytes!,
                                fit: BoxFit.cover));
                      } else if (photoUrl.isNotEmpty) {
                        return SizedBox(
                          width: 90,
                          height: 90,
                          child: Image.network(photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => fallback),
                        );
                      } else {
                        return fallback;
                      }
                    }(),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt,
                        size: 14, color: Color(0xFF6D28D9)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            nom.isNotEmpty ? nom : 'Utilisateur',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 4),
          Text(email,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
          if (tel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_outlined,
                    color: Colors.white.withValues(alpha: 0.65), size: 13),
                const SizedBox(width: 4),
                Text(tel,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12)),
              ],
            ),
          ],
          if (taille > 0 || poids > 0) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (taille > 0)
                  _quickBadge('$taille cm', Icons.height_outlined),
                if (taille > 0 && poids > 0) const SizedBox(width: 10),
                if (poids > 0)
                  _quickBadge('$poids kg', Icons.monitor_weight_outlined),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _quickBadge(String label, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      );

  // ── TabBar ───────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF6D28D9),
        unselectedLabelColor: Colors.grey.shade500,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)]),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        labelPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.person_outline, size: 15),
            SizedBox(width: 6),
            Text('Mes infos'),
          ])),
          Tab(
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.receipt_long_outlined, size: 15),
            SizedBox(width: 6),
            Text('Commandes'),
          ])),
        ],
      ),
    );
  }

  // ── Tab 1 : Informations ─────────────────────────────────────────────────────
  Widget _buildInfoTab(BuildContext context, ProfileState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        children: [
          _sectionCard(
            title: 'Informations personnelles',
            icon: Icons.badge_outlined,
            trailing: GestureDetector(
              onTap: () {
                if (_isEditing) {
                  setState(() => _isEditing = false);
                  context.read<ProfileCubit>().updateProfile(
                        nom: _nomController.text.trim(),
                        telephone: _telController.text.trim(),
                        taille: int.tryParse(_tailleController.text) ?? 0,
                        poids: int.tryParse(_poidsController.text) ?? 0,
                      );
                } else {
                  setState(() => _isEditing = true);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6D28D9).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: state.isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF6D28D9)))
                    : Row(
                        children: [
                          Icon(_isEditing ? Icons.check : Icons.edit_outlined,
                              size: 14, color: const Color(0xFF6D28D9)),
                          const SizedBox(width: 4),
                          Text(_isEditing ? 'Sauvegarder' : 'Modifier',
                              style: const TextStyle(
                                  color: Color(0xFF6D28D9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ),
            child: Column(
              children: [
                _profileField(
                    controller: _nomController,
                    label: 'Nom complet',
                    icon: Icons.person_outline,
                    enabled: _isEditing),
                const SizedBox(height: 12),
                _profileField(
                    controller:
                        TextEditingController(text: state.profile?.email ?? ''),
                    label: 'Email',
                    icon: Icons.email_outlined,
                    enabled: false),
                const SizedBox(height: 12),
                _profileField(
                    controller: _telController,
                    label: 'Téléphone',
                    icon: Icons.phone_outlined,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildStatsCards(state),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Sécurité',
            icon: Icons.lock_outline,
            child: _settingsTile(
              icon: Icons.password_outlined,
              label: 'Changer le mot de passe',
              onTap: () => context.read<ProfileCubit>().sendPasswordReset(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(ProfileState state) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        _statCard('${state.wardrobeCount}', 'Garde-robe',
            Icons.checkroom_outlined, const Color(0xFF6D28D9)),
        _statCard('${state.ordersCount}', 'Commandes',
            Icons.receipt_long_outlined, const Color(0xFF26A69A)),
        _statCard('${state.cartCount}', 'Panier', Icons.shopping_bag_outlined,
            const Color(0xFF7C3AED)),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              maxLines: 2),
        ],
      ),
    );
  }

  // ── Tab 2 : Commandes ────────────────────────────────────────────────────────
  Widget _buildOrdersTab(ProfileState state) {
    if (state.orders.isEmpty && !state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                  color: Color(0xFFF5F0FF), shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_outlined,
                  size: 32, color: Color(0xFF6D28D9)),
            ),
            const SizedBox(height: 16),
            const Text('Aucune commande pour le moment',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text('Vos commandes apparaîtront ici',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: state.orders.length,
      itemBuilder: (context, index) => _buildOrderCard(state.orders[index]),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final statut = order['statut'] ?? 'En attente';
    final numero = order['numeroCommande'] ?? '-';
    final total = (order['total'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final articles = (order['articles'] as List?) ?? [];
    final createdAt = order['createdAt'] as Timestamp?;

    Color statutColor;
    IconData statutIcon;
    switch (statut) {
      case 'Livré':
        statutColor = Colors.green.shade600;
        statutIcon = Icons.check_circle_outline;
        break;
      case 'En cours':
        statutColor = Colors.orange.shade600;
        statutIcon = Icons.local_shipping_outlined;
        break;
      case 'Annulé':
        statutColor = Colors.red.shade400;
        statutIcon = Icons.cancel_outlined;
        break;
      default:
        statutColor = const Color(0xFF6D28D9);
        statutIcon = Icons.hourglass_empty_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(
                  bottom: BorderSide(color: Colors.grey.shade100, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#$numero',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333))),
                Row(children: [
                  Icon(statutIcon, size: 14, color: statutColor),
                  const SizedBox(width: 5),
                  Text(statut,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statutColor)),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...articles.take(2).map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${a['nom']} × ${a['quantity']}',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${((a['prix'] as num) * (a['quantity'] as int)).toStringAsFixed(2)} DT',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF333333)),
                          ),
                        ],
                      ),
                    )),
                if (articles.length > 2)
                  Text('+${articles.length - 2} autre(s) article(s)',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      createdAt != null ? _formatDate(createdAt.toDate()) : '',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                    Text('$total DT',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6D28D9))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF6D28D9)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333))),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _profileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: enabled ? const Color(0xFF6D28D9) : Colors.grey.shade500,
            fontSize: 12),
        prefixIcon: Icon(icon,
            color: enabled ? const Color(0xFF6D28D9) : Colors.grey.shade400,
            size: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6D28D9), width: 1)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6D28D9), width: 1.5)),
        filled: true,
        fillColor: enabled ? const Color(0xFFFAF5FF) : Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? const Color(0xFF6D28D9);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500, color: c))),
            Icon(Icons.arrow_forward_ios,
                size: 12, color: c.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  // ✅ Fix déconnexion : annuler les streams AVANT signOut
  void _showLogoutDialog(BuildContext context) {
    final marketplaceCubit = context.read<MarketplaceCubit>();
    final wardrobeCubit = context.read<WardrobeCubit>();
    final profileCubit = context.read<ProfileCubit>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // ✅ Annuler les streams AVANT la déconnexion
              marketplaceCubit.cancelStreams();
              wardrobeCubit.cancelStreams();
              // Délai pour laisser les streams se fermer
              await Future.delayed(const Duration(milliseconds: 150));
              profileCubit.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Déconnecter',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'jan',
      'fév',
      'mar',
      'avr',
      'mai',
      'jun',
      'jul',
      'aoû',
      'sep',
      'oct',
      'nov',
      'déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
