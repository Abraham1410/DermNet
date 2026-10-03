import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/skin_article_service.dart';

class InformationDetailScreen extends StatefulWidget {
  final SkinArticle article;

  const InformationDetailScreen({super.key, required this.article});

  @override
  State<InformationDetailScreen> createState() =>
      _InformationDetailScreenState();
}

class _InformationDetailScreenState extends State<InformationDetailScreen> {
  final SkinArticleService _articleService = SkinArticleService();
  String _fullContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFullContent();
  }

  Future<void> _loadFullContent() async {
    final content =
        await _articleService.getFullArticle(widget.article.title);
    if (mounted) {
      setState(() {
        _fullContent =
            content.isNotEmpty ? content : widget.article.fullContent;
        _isLoading = false;
      });
    }
  }

  Color _getCategoryColor() {
    switch (widget.article.category) {
      case 'Inflammatory':
        return const Color(0xFFFF8F00);
      case 'Fungal':
        return const Color(0xFF7B1FA2);
      case 'Viral':
        return const Color(0xFFD32F2F);
      case 'Bacterial':
        return const Color(0xFF1976D2);
      case 'Acne':
        return const Color(0xFFE64A19);
      case 'Cancer':
        return const Color(0xFF455A64);
      default:
        return const Color(0xFF388E3C);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F4E20);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F3),
      body: CustomScrollView(
        slivers: [
          // Hero image with parallax
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: primaryGreen,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: Colors.white.withOpacity(0.9),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Color(0xFF1E3A2B),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.article.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.article.imageUrl.isNotEmpty)
                    Image.network(
                      widget.article.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: primaryGreen.withOpacity(0.3),
                        child: const Icon(
                          Icons.health_and_safety_rounded,
                          size: 64,
                          color: Colors.white54,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: primaryGreen.withOpacity(0.3),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        size: 64,
                        color: Colors.white54,
                      ),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Source row
                  Row(
                    children: [
                      _CategoryBadge(
                        category: widget.article.category,
                        color: _getCategoryColor(),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Source: ${widget.article.sourceUrl}',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Source',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Text(
                    widget.article.title,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E3A2B),
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Divider accent
                  Container(
                    height: 3,
                    width: 50,
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Content
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    _buildContentSections(_fullContent),

                  const SizedBox(height: 24),

                  // Disclaimer card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFE0B2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This information is for educational purposes only and is sourced from Wikipedia. Always consult a dermatologist for medical advice.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.orange.shade800,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSections(String content) {
    // Parse content into sections based on == headers ==
    final lines = content.split('\n');
    final widgets = <Widget>[];
    String currentSection = '';
    final buffer = StringBuffer();

    for (final line in lines) {
      if (line.trim().startsWith('==') && line.trim().endsWith('==')) {
        // Save previous section
        if (buffer.isNotEmpty) {
          widgets.add(_buildSection(currentSection, buffer.toString().trim()));
          buffer.clear();
        }
        currentSection = line.replaceAll('=', '').trim();
      } else {
        buffer.writeln(line);
      }
    }

    // Save last section
    if (buffer.isNotEmpty) {
      widgets.add(_buildSection(currentSection, buffer.toString().trim()));
    }

    if (widgets.isEmpty) {
      widgets.add(_buildSection('', content));
    }

    return Column(children: widgets);
  }

  Widget _buildSection(String title, String content) {
    if (content.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) ...[
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E3A2B),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.7,
                color: const Color(0xFF344B41),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  final Color color;

  const _CategoryBadge({required this.category, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
