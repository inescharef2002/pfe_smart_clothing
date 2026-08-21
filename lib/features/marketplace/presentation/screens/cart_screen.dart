import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pfe_smart_clothing/features/marketplace/domain/entities/cart_item_entity.dart';
import 'package:pfe_smart_clothing/features/marketplace/presentation/cubit/marketplace_cubit.dart';
import 'package:pfe_smart_clothing/features/marketplace/presentation/cubit/marketplace_state.dart';
import 'package:pfe_smart_clothing/features/profile/presentation/cubit/profile_cubit.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return BlocConsumer<MarketplaceCubit, MarketplaceState>(
      listener: (context, state) {
        if (state.checkoutSuccess) {
          _showSuccessDialog(context, state);
          context.read<MarketplaceCubit>().resetCheckout();
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.successMessage!),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
          context.read<MarketplaceCubit>().clearMessages();
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ));
          context.read<MarketplaceCubit>().clearMessages();
        }
      },
      builder: (context, state) => Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D0061), Color(0xFF5B21B6), Color(0xFF7C3AED)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isSmallScreen),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                            child: _buildCartItems(
                                context, state, isSmallScreen)),
                        if (state.cartItems.isNotEmpty)
                          _buildBottomBar(context, state),
                      ],
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

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isSmallScreen ? 16 : 20, 20, isSmallScreen ? 16 : 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3))),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mon Panier',
                  style: TextStyle(
                      fontSize: isSmallScreen ? 22 : 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text('Vos articles sélectionnés',
                  style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 13,
                      color: Colors.white.withValues(alpha: 0.75))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(BuildContext context, MarketplaceState state, bool isSmallScreen) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6D28D9)));
    }

    if (state.cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 70, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Votre panier est vide', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Text('Ajoutez des articles depuis le marketplace', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
            const SizedBox(height: 20),
            _buildGradientButton(label: 'Continuer vos achats', onTap: () => Navigator.pop(context)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20, vertical: 12),
      itemCount: state.cartItems.length,
      itemBuilder: (context, index) => _buildCartItem(context, state.cartItems[index], isSmallScreen),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItemEntity item, bool isSmallScreen) {
    final cubit = context.read<MarketplaceCubit>();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)),
            child: SizedBox(
              width: isSmallScreen ? 90 : 110,
              height: isSmallScreen ? 90 : 110,
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: const Color(0xFFF5F0FF), child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6D28D9)))),
                      errorWidget: (_, __, ___) => Container(color: const Color(0xFFF5F0FF), child: const Icon(Icons.checkroom, color: Color(0xFF6D28D9), size: 35)),
                    )
                  : Container(color: const Color(0xFFF5F0FF), child: const Icon(Icons.checkroom, size: 35, color: Color(0xFF6D28D9))),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.nom, style: TextStyle(fontSize: isSmallScreen ? 13 : 15, fontWeight: FontWeight.w600, color: const Color(0xFF333333)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item.taille.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF6D28D9).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text('T: ${item.taille}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF6D28D9))),
                        ),
                      if (item.taille.isNotEmpty && item.couleur.isNotEmpty) const SizedBox(width: 6),
                      if (item.couleur.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF6D28D9).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text('C: ${item.couleur}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF6D28D9))),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.prix} DT', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9))),
                      Row(
                        children: [
                          _buildQtyButton(icon: Icons.remove, onTap: () => cubit.updateQuantity(item.id, item.quantity - 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('${item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                          _buildQtyButton(icon: Icons.add, onTap: () => cubit.updateQuantity(item.id, item.quantity + 1)),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => cubit.removeFromCart(item.id),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: const Color(0xFF6D28D9).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, size: 15, color: const Color(0xFF6D28D9)),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, MarketplaceState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total (${state.cartItemsCount} article${state.cartItemsCount > 1 ? 's' : ''})', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              Text('${state.cartTotal.toStringAsFixed(2)} DT', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9))),
            ],
          ),
          const SizedBox(height: 14),
          state.isActionLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6D28D9)))
              : _buildGradientButton(label: 'Passer la commande', onTap: () => _showDeliveryForm(context, state)),
        ],
      ),
    );
  }

  Widget _buildGradientButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)], begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: const Color(0xFF6D28D9).withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
      ),
    );
  }

  void _showDeliveryForm(BuildContext context, MarketplaceState state) {
    final nomController = TextEditingController();
    final adresseController = TextEditingController();
    final telController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final cubit = context.read<MarketplaceCubit>();

    try {
      final profileState = context.read<ProfileCubit>().state;
      nomController.text = profileState.profile?.nom ?? '';
      emailController.text = profileState.profile?.email ?? '';
      telController.text = profileState.profile?.telephone ?? '';
    } catch (_) {}

    const methods = [
      {'id': 'especes', 'label': 'Espèces à la\nlivraison', 'icon': Icons.payments_outlined},
      {'id': 'carte',   'label': 'Carte\nbancaire',          'icon': Icons.credit_card_outlined},
      {'id': 'virement','label': 'Virement\nbancaire',        'icon': Icons.account_balance_outlined},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        String selectedMethod = 'especes';
        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    const Text('Informations de livraison', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9))),
                    const SizedBox(height: 4),
                    Text('Total : ${state.cartTotal.toStringAsFixed(2)} DT', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9))),
                    const SizedBox(height: 22),
                    TextFormField(controller: nomController, decoration: _inputDecoration('Nom complet', Icons.person_outline), validator: (v) => v!.isEmpty ? 'Nom requis' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: emailController, enabled: false, decoration: _inputDecoration('Email', Icons.email_outlined)),
                    const SizedBox(height: 12),
                    TextFormField(controller: adresseController, maxLines: 2, decoration: _inputDecoration('Adresse de livraison', Icons.location_on_outlined), validator: (v) => v!.isEmpty ? 'Adresse requise' : null),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: telController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Numéro de téléphone', Icons.phone_outlined),
                      validator: (v) {
                        if (v!.isEmpty) return 'Téléphone requis';
                        if (v.length < 8) return 'Numéro invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // ── Méthode de paiement ──────────────────────────────
                    const Text('Méthode de paiement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                    const SizedBox(height: 10),
                    Row(
                      children: methods.map((m) {
                        final selected = selectedMethod == m['id'];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedMethod = m['id'] as String),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFF6D28D9) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: selected ? const Color(0xFF6D28D9) : Colors.grey.shade200, width: selected ? 1.5 : 1),
                              ),
                              child: Column(
                                children: [
                                  Icon(m['icon'] as IconData, size: 22, color: selected ? Colors.white : const Color(0xFF6D28D9)),
                                  const SizedBox(height: 6),
                                  Text(m['label'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.grey.shade700)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    // ── Résumé commande ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFF5F0FF), borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Résumé de la commande', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF6D28D9))),
                          const SizedBox(height: 8),
                          ...state.cartItems.map((item) {
                            String details = '';
                            if (item.taille.isNotEmpty) details += ' T:${item.taille}';
                            if (item.couleur.isNotEmpty) details += ' C:${item.couleur}';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('${item.nom}$details × ${item.quantity}', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                  Text('${item.total.toStringAsFixed(2)} DT', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          }),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('${state.cartTotal.toStringAsFixed(2)} DT', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF6D28D9))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(ctx);
                        cubit.checkout(
                          nom: nomController.text.trim(),
                          adresse: adresseController.text.trim(),
                          telephone: telController.text.trim(),
                          methodePaiement: selectedMethod,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: const Color(0xFF6D28D9).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: const Center(child: Text('Confirmer la commande', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: double.infinity,
                        height: 46,
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
                        child: Center(child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500))),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'carte':    return 'Carte bancaire';
      case 'virement': return 'Virement bancaire';
      default:         return 'Espèces à la livraison';
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF6D28D9), size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF6D28D9), width: 1)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red, width: 1)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red, width: 1)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _showSuccessDialog(BuildContext context, MarketplaceState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 70),
            const SizedBox(height: 12),
            const Text('Commande confirmée !', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            if (state.lastOrderNumber != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF5F0FF), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Commande :', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        Text('#${state.lastOrderNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                      ],
                    ),
                    if (state.lastPaymentMethod != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Paiement :', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          Text(_paymentLabel(state.lastPaymentMethod!), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Continuer les achats', style: TextStyle(color: Color(0xFF6D28D9), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
