import 'package:flutter/material.dart';
import '../../data/datasources/disease_local_data.dart';
import '../../data/models/disease_model.dart';
import 'detail_disease_page.dart';

class ListDiseasePage extends StatefulWidget {
  const ListDiseasePage({super.key});

  @override
  State<ListDiseasePage> createState() => _ListDiseasePageState();
}

class _ListDiseasePageState extends State<ListDiseasePage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Disease> _filtered(List<Disease> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((d) {
      return d.name.toLowerCase().contains(q) ||
          d.symptom.toLowerCase().contains(q) ||
          d.reason.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final diseases = _filtered(DiseaseLocalData.diseases);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    'Explore Causes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E3A2B),
                    ),
                  ),
                  const Spacer(),
                  // biar title benar2 center
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 14),

              // Search
              _SearchBar(
                controller: _searchCtrl,
                hint: 'Search Skin Disease',
                onChanged: (v) => setState(() => _query = v),
                onClear: () => setState(() {
                  _searchCtrl.clear();
                  _query = '';
                }),
              ),
              const SizedBox(height: 14),

              // Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.25, // mirip layout di contoh
                  ),
                  itemCount: diseases.length,
                  itemBuilder: (context, index) {
                    final disease = diseases[index];
                    return _DiseaseGridCard(
                      disease: disease,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailDiseasePage(disease: disease),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiseaseGridCard extends StatelessWidget {
  final Disease disease;
  final VoidCallback onTap;

  const _DiseaseGridCard({
    required this.disease,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Expanded(
                child: Text(
                  disease.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A2B),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Image (thumbnail / icon)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 52,
                  height: 52,
                  color: const Color(0xFFF2F6F3),
                  child: Image.asset(
                    disease.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.healing_rounded,
                      color: Color(0xFF1E3A2B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF8AA39A)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF9BB2AA)),
                border: InputBorder.none,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded, color: Color(0xFF8AA39A)),
            ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
        ),
      ),
    );
  }
}
