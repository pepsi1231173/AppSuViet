import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/era.dart';
import '../services/api_service.dart';
import 'era_detail_screen.dart';

class EraListScreen extends StatefulWidget {
  const EraListScreen({super.key});

  @override
  State<EraListScreen> createState() => _EraListScreenState();
}

class _EraListScreenState extends State<EraListScreen> {
  final ApiService _api = ApiService();
  late Future<List<Era>> _future;
  final PageController _pageController = PageController(viewportFraction: 1.0);

  @override
  void initState() {
    super.initState();
    _future = _api.fetchEras();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ AppBar với nút quay lại
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5E3C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Các Triều Đại Việt Nam',
          style: GoogleFonts.notoSerif(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,

        // ✅ NÚT BA CHẤM
        actions: [
          FutureBuilder<List<Era>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final eras = snapshot.data!;

              return PopupMenuButton<int>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },

                itemBuilder: (context) {
                  return List.generate(eras.length, (index) {
                    final era = eras[index];

                    return PopupMenuItem<int>(
                      value: index,
                      padding: EdgeInsets.zero,
                      child: Container(
                        width: 260,
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            // 🖼 Ảnh triều đại
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                era.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // 📜 Tên + năm
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    era.name,
                                    style: GoogleFonts.notoSerifDisplay(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF4B2E05),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${era.startYear} – ${era.endYear}',
                                    style: GoogleFonts.notoSerif(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.brown,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              );
            },
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/paper_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<List<Era>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B4513)),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Lỗi tải dữ liệu: ${snapshot.error}',
                  style: GoogleFonts.notoSerif(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            final eras = snapshot.data ?? [];
            if (eras.isEmpty) {
              return Center(
                child: Text(
                  'Không có dữ liệu triều đại.',
                  style: GoogleFonts.notoSerif(
                    color: Colors.black54,
                    fontSize: 18,
                  ),
                ),
              );
            }
            return Column(
              children: [
                // 🏯 Tiêu đề
                Container(
                  padding: const EdgeInsets.only(top: 60, bottom: 16),
                  child: Text(
                    '📜 Các Triều Đại Việt Nam 📜',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSerifDisplay(
                      color: const Color(0xFF4B2E05),
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                      shadows: const [
                        Shadow(
                          color: Colors.brown,
                          blurRadius: 4,
                          offset: Offset(1, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                // 🖼 Danh sách triều đại
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: eras.length,
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double value = 1.0;
                          if (_pageController.position.haveDimensions) {
                            value = (_pageController.page! - index).abs();
                            value = (1 - (value * 0.2)).clamp(0.8, 1.0);
                          }
                          return Center(
                            child: Transform.scale(
                              scale: value,
                              child: child,
                            ),
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EraDetailScreen(
                                  eraName: eras[index].name.replaceAll(' ', '_'),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 10,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                // Ảnh triều đại
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Image.asset(
                                    eras[index].imageUrl,
                                    fit: BoxFit.cover,
                                    height: double.infinity,
                                    width: double.infinity,
                                  ),
                                ),

                                // Lớp phủ tối
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.75),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),

                                // 🏯 Tên + năm triều đại
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 28, left: 12, right: 12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        eras[index].name,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.notoSerifDisplay(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                          shadows: const [
                                            Shadow(
                                              blurRadius: 8,
                                              color: Colors.black87,
                                              offset: Offset(1, 2),
                                            )
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${eras[index].startYear} – ${eras[index].endYear}',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.notoSerif(
                                          color: const Color(0xFFFFE082),
                                          fontSize: 18,
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w600,
                                          shadows: const [
                                            Shadow(
                                              blurRadius: 6,
                                              color: Colors.black54,
                                              offset: Offset(1, 1),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
