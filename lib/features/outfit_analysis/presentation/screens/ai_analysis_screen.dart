import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pfe_smart_clothing/features/marketplace/domain/entities/product_entity.dart';
import 'package:pfe_smart_clothing/features/marketplace/presentation/cubit/marketplace_cubit.dart';
import 'package:pfe_smart_clothing/features/marketplace/presentation/cubit/marketplace_state.dart';
import 'package:pfe_smart_clothing/features/wardrobe/domain/entities/wardrobe_item_entity.dart';
import 'package:pfe_smart_clothing/features/wardrobe/presentation/cubit/wardrobe_cubit.dart';
import 'package:pfe_smart_clothing/features/wardrobe/presentation/cubit/wardrobe_state.dart';
import '../cubit/outfit_analysis_cubit.dart';
import '../cubit/outfit_analysis_state.dart';

class _K {
  static const primary = Color(0xFF6D28D9);
  static const primaryLight = Color(0xFF7C3AED);
  static const primarySurface = Color(0xFFF5F0FF);
  static const border = Color(0xFFE9D5FF);
  static const textMain = Color(0xFF1A1A2E);
  static const textMuted = Color(0xFF9CA3AF);
}

class AiAnalysisScreen extends StatefulWidget {
  const AiAnalysisScreen({super.key});

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen> {
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  final _nomCtrl = TextEditingController();
  final _marqueCtrl = TextEditingController();
  final _couleurCtrl = TextEditingController();
  String _categorie = 'Robes';
  String _taille = '';
  bool _formFilled = false;
  String? _historyId;

  final List<String> _categories = [
    'Robes', 'Pantalons', 'Chemises', 'Chaussures',
    'Accessoires', 'Vestes', 'T-shirts', 'Pulls', 'Jupes', 'Autres',
  ];
  final List<String> _tailles = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL',
    '34', '36', '38', '40', '42', '44',
  ];

  @override
  void dispose() {
    _nomCtrl.dispose();
    _marqueCtrl.dispose();
    _couleurCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final cubit = context.read<OutfitAnalysisCubit>();
    final xfile = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1024);
    if (xfile == null) return;
    if (!mounted) return;
    final bytes = await xfile.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedImage = xfile;
      _selectedImageBytes = bytes;
      _formFilled = false;
      _nomCtrl.clear();
      _marqueCtrl.clear();
      _couleurCtrl.clear();
      _categorie = 'Robes';
      _taille = '';
    });
    cubit.resetAnalysis();
  }

  void _fillFormFromState(OutfitAnalysisState state) {
    if (state.analysisResult != null && !_formFilled) {
      final r = state.analysisResult!;
      _nomCtrl.text = r.nom;
      _marqueCtrl.text = r.marque;
      _couleurCtrl.text = r.couleur;
      if (_categories.contains(r.categorie)) _categorie = r.categorie;
      if (_tailles.contains(r.taille)) _taille = r.taille;
      _formFilled = true;
      // Log l'analyse dans Firestore (fire & forget — on garde l'id pour mark saved)
      context.read<WardrobeCubit>().logAnalysis(
        categorie: r.categorie,
        couleur: r.couleur,
        description: r.description,
        confidence: r.confidence,
      ).then((id) { if (mounted) setState(() => _historyId = id); });
    }
  }

  void _saveToWardrobe() {
    if (_nomCtrl.text.trim().isEmpty) return;
    // Marquer l'analyse comme sauvegardée dans l'historique
    if (_historyId != null) {
      context.read<WardrobeCubit>().markHistoryAsSaved(_historyId!);
    }
    context.read<WardrobeCubit>().addItem(
      WardrobeItemEntity(
        id: '',
        nom: _nomCtrl.text.trim(),
        categorie: _categorie,
        imageUrl: '',
        marque: _marqueCtrl.text.trim(),
        taille: _taille,
        couleur: _couleurCtrl.text.trim(),
        source: 'ai_analysis',
      ),
      imageFile: _selectedImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WardrobeCubit, WardrobeState>(
      listenWhen: (prev, curr) =>
          (prev.isActionLoading && !curr.isActionLoading) ||
          (prev.errorMessage == null && curr.errorMessage != null),
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Vêtement ajouté à la garde-robe !'),
            ]),
            backgroundColor: Colors.green.shade500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
          Navigator.pop(context);
        }
      },
      child: BlocConsumer<OutfitAnalysisCubit, OutfitAnalysisState>(
        listener: (context, state) {
          if (state.analysisResult != null) {
            setState(() => _fillFormFromState(state));
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ));
            context.read<OutfitAnalysisCubit>().clearMessages();
          }
        },
        builder: (context, state) => Scaffold(
          body: Container(
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
                  _buildHeader(),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(32)),
                      ),
                      child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImageSection(state),
                          const SizedBox(height: 20),
                          if (state.isAnalyzing) _buildAnalyzingState(),
                          if (state.analysisResult != null) ...[
                            _buildAnalysisResult(state),
                            const SizedBox(height: 20),
                            _buildEditableForm(),
                            const SizedBox(height: 20),
                            _buildSaveButton(state),
                            const SizedBox(height: 28),
                            _buildMarketplaceSection(state),
                          ],
                        ],
                      ),
                    ),
                  ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 11),
                      SizedBox(width: 4),
                      Text('IA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  const Text('Analyse de vêtement',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              Text('Photo → détection automatique',
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(OutfitAnalysisState state) {
    return Column(
      children: [
        GestureDetector(
          onTap: _showPickerOptions,
          child: Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedImage != null ? _K.primary : _K.border,
                width: _selectedImage != null ? 1.5 : 1,
              ),
            ),
            child: _selectedImageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Image.memory(
                      _selectedImageBytes!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: const BoxDecoration(color: _K.primarySurface, shape: BoxShape.circle),
                        child: const Icon(Icons.add_a_photo_outlined, size: 28, color: _K.primary),
                      ),
                      const SizedBox(height: 14),
                      const Text('Prenez ou importez une photo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _K.textMain)),
                      const SizedBox(height: 4),
                      Text('L\'IA détectera automatiquement les détails', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _actionButton(icon: Icons.photo_library_outlined, label: 'Galerie', onTap: () => _pickImage(ImageSource.gallery), filled: false)),
            const SizedBox(width: 10),
            Expanded(child: _actionButton(icon: Icons.camera_alt_outlined, label: 'Caméra', onTap: () => _pickImage(ImageSource.camera), filled: false)),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _actionButton(
                icon: Icons.auto_awesome,
                label: 'Analyser avec IA',
                onTap: _selectedImage != null && !state.isAnalyzing
                    ? () => context.read<OutfitAnalysisCubit>().analyzeClothing(_selectedImage!)
                    : null,
                filled: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton({required IconData icon, required String label, VoidCallback? onTap, required bool filled}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: filled ? _K.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: onTap != null ? _K.primary : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: filled ? Colors.white : onTap != null ? _K.primary : Colors.grey.shade400),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: filled ? Colors.white : onTap != null ? _K.primary : Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _K.border)),
      child: const Column(
        children: [
          SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(strokeWidth: 3, color: _K.primary, backgroundColor: _K.primarySurface),
          ),
          SizedBox(height: 16),
          Text('Analyse en cours...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _K.textMain)),
          SizedBox(height: 6),
          Text('L\'IA détecte la couleur, la catégorie et les détails', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _K.textMuted)),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult(OutfitAnalysisState state) {
    final r = state.analysisResult!;
    final confidence = r.confidence * 100;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_K.primary.withValues(alpha: 0.08), _K.primaryLight.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _K.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: _K.primary, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14)),
              const SizedBox(width: 10),
              const Text('Résultat de l\'analyse IA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _K.primary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: confidence >= 70 ? Colors.green.shade100 : Colors.orange.shade100, borderRadius: BorderRadius.circular(20)),
                child: Text('${confidence.round()}% confiance', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: confidence >= 70 ? Colors.green.shade700 : Colors.orange.shade700)),
              ),
            ],
          ),
          if (r.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(r.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              _resultChip(Icons.category_outlined, r.categorie),
              _resultChip(Icons.palette_outlined, r.couleur),
              if (r.marque.isNotEmpty) _resultChip(Icons.store_outlined, r.marque),
              if (r.taille.isNotEmpty) _resultChip(Icons.straighten_outlined, r.taille),
            ],
          ),
          const SizedBox(height: 10),
          Text('Les champs ci-dessous ont été pré-remplis. Vous pouvez les modifier.', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _resultChip(IconData icon, String label) {
    if (label.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _K.border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _K.primary),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _K.textMain)),
        ],
      ),
    );
  }

  Widget _buildEditableForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.edit_outlined, size: 15, color: _K.primary),
            SizedBox(width: 8),
            Text('Vérifiez et complétez', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _K.textMain)),
          ]),
          const SizedBox(height: 14),
          _formField(_nomCtrl, 'Nom du vêtement *', Icons.checkroom_outlined),
          const SizedBox(height: 10),
          _formField(_couleurCtrl, 'Couleur', Icons.palette_outlined),
          const SizedBox(height: 14),
          Text('Catégorie', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7, runSpacing: 7,
            children: _categories.map((c) {
              final sel = _categorie == c;
              return GestureDetector(
                onTap: () => setState(() => _categorie = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? _K.primary : const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? _K.primary : _K.border),
                  ),
                  child: Text(c, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : _K.primary)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _formField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: _K.primary, size: 18),
        filled: true,
        fillColor: const Color(0xFFFAF5FF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _K.primary, width: 1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );
  }

  Widget _buildSaveButton(OutfitAnalysisState state) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _nomCtrl,
      builder: (context, nomValue, _) {
        return BlocBuilder<WardrobeCubit, WardrobeState>(
          builder: (context, wardrobeState) {
            final canSave = nomValue.text.trim().isNotEmpty && !wardrobeState.isActionLoading;
            return GestureDetector(
              onTap: canSave ? _saveToWardrobe : null,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: canSave ? const [_K.primary, _K.primaryLight] : [Colors.grey.shade300, Colors.grey.shade300],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: canSave ? [BoxShadow(color: _K.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
                ),
                child: Center(
                  child: wardrobeState.isActionLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Ajouter à ma garde-robe', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Marketplace recommendations (spec: "recommend similar items for purchase") ──
  Widget _buildMarketplaceSection(OutfitAnalysisState state) {
    final detected = state.analysisResult!.categorie;
    return BlocBuilder<MarketplaceCubit, MarketplaceState>(
      builder: (context, mpState) {
        final similar = mpState.products
            .where((p) => p.categorie == detected && p.disponible)
            .take(4)
            .toList();
        if (similar.isEmpty) return const SizedBox();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: _K.primarySurface, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.store_outlined, size: 16, color: _K.primary),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Articles similaires', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _K.textMain)),
                      Text('Trouvés dans le Marketplace', style: TextStyle(fontSize: 11, color: _K.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: similar.length,
                itemBuilder: (_, i) => _buildProductCard(similar[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(ProductEntity product) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _K.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: product.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: _K.primarySurface, child: const Center(child: Icon(Icons.checkroom, color: _K.primary))),
                      errorWidget: (_, __, ___) => Container(color: _K.primarySurface, child: const Center(child: Icon(Icons.checkroom, color: _K.primary))),
                    )
                  : Container(color: _K.primarySurface, child: const Center(child: Icon(Icons.checkroom, color: _K.primary))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.nom, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _K.textMain)),
                const SizedBox(height: 4),
                Text('${product.prixActuel} DT',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: product.promo ? Colors.red : _K.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: _K.primarySurface, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.camera_alt_outlined, color: _K.primary, size: 20)),
                title: const Text('Prendre une photo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              ListTile(
                leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: _K.primarySurface, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.photo_library_outlined, color: _K.primary, size: 20)),
                title: const Text('Choisir depuis la galerie', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
