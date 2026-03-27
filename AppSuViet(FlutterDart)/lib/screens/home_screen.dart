import 'package:flutter/material.dart';
import 'era_list_screen.dart';
import 'quiz_category_screen.dart';
import 'TimelineScreen.dart';
import 'map_screen.dart';
import 'festival_screen.dart';
import 'historical_figures_screen.dart';
import 'DocumentListScreen.dart';
import 'MapHistoryScreen.dart';
import '../services/saved_manager.dart';
import '../models/saved_item.dart';

// AI
import '../AI/ai_floating_button.dart';
import '../AI/ai_chat_popup.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<_MenuItem> menuItems = [
    _MenuItem('Triều đại phong kiến Việt Nam', Icons.account_balance, EraListScreen()),
    _MenuItem('Dòng thời gian Lịch Sử Việt Nam', Icons.timeline, TimelineScreen()),
    _MenuItem('Bản đồ Lịch Sử Việt Nam', Icons.map, MapScreen()),
    _MenuItem('Ngày lễ, kỷ niệm và lễ hội Việt Nam', Icons.celebration, FestivalScreen()),
    _MenuItem('Nhân vật lịch sử Việt Nam', Icons.people, HistoricalFiguresScreen()),
    _MenuItem('Văn kiện lịch sử', Icons.menu_book, DocumentListScreen()),
    _MenuItem('Trắc nghiệm', Icons.quiz, QuizCategoryScreen()),
    _MenuItem('Lãnh thổ Việt Nam qua các thời kì', Icons.flag, MapHistoryScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF7A0F10),
        title: const Text(
          'SỬ VIỆT',
          style: TextStyle(
            fontSize: 26,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontFamily: 'Serif',
            shadows: [
              Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(2, 2)),
            ],
          ),
        ),

        /// ⭐ ICON ĐÃ LƯU
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark, color: Colors.white),
            tooltip: 'Đã lưu',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const _SavedBottomSheet(),
              );
            },
          ),
        ],
      ),

      body: Stack(
        children: [
          /// 🌟 NỀN TRỐNG ĐỒNG
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/dongson_pattern.jpg'),
                fit: BoxFit.cover,
                opacity: 0.55,
              ),
            ),
          ),

          /// 🌟 LỚP GIẤY CỔ
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6C8).withOpacity(0.75),
            ),
          ),

          /// ⭐ GRID MENU
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: menuItems.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                // 🔹 Tính tỷ lệ động theo màn hình
                childAspectRatio: MediaQuery.of(context).size.width /
                    (MediaQuery.of(context).size.height / 2.5),
              ),
              itemBuilder: (_, index) {
                final item = menuItems[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => item.screen),
                    );
                  },
                  child: Card(
                    color: const Color(0xFFEEDCC2),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: Color(0xFFB28A47),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, size: 48, color: Colors.brown[900]),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Serif',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF4B2E1E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),


          /// 🤖 AI
          AIFloatingButton(
            onOpen: () {
              showDialog(
                context: context,
                builder: (_) => const AiChatPopup(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// =======================================================
/// MENU ITEM
/// =======================================================

class _MenuItem {
  final String title;
  final IconData icon;
  final Widget screen;

  _MenuItem(this.title, this.icon, this.screen);
}

/// =======================================================
/// 📌 BOTTOM SHEET – MỤC ĐÃ LƯU (THẬT)
/// =======================================================

class _SavedBottomSheet extends StatelessWidget {
  const _SavedBottomSheet();

  @override
  Widget build(BuildContext context) {
    final savedManager = SavedManager();

    return AnimatedBuilder(
      animation: savedManager,
      builder: (_, __) {
        final items = savedManager.items;

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            image: const DecorationImage(
              image: AssetImage('assets/images/dongson_pattern.jpg'),
              fit: BoxFit.cover,
              opacity: 0.25,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6C8).withOpacity(0.92),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: const Color(0xFFB28A47),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 14),

                /// 🔻 Thanh kéo
                Container(
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.brown[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

                const SizedBox(height: 12),

                /// 📌 TIÊU ĐỀ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.bookmark, color: Color(0xFF7A0F10)),
                    SizedBox(width: 8),
                    Text(
                      'MỤC ĐÃ LƯU',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Serif',
                        letterSpacing: 2,
                        color: Color(0xFF7A0F10),
                        shadows: [
                          Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(1, 1))
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Divider(color: Colors.brown[300]),

                Expanded(
                  child: items.isEmpty
                      ? const Center(
                    child: Text(
                      '📜 Chưa lưu tư liệu nào',
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 16,
                      ),
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (_, i) =>
                        _SavedItem(item: items[i]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}



/// =======================================================
/// 📍 ITEM ĐÃ LƯU
/// =======================================================

class _SavedItem extends StatelessWidget {
  final SavedItem item;
  const _SavedItem({required this.item});

  IconData get icon {
    switch (item.type) {
      case 'Triều đại':
        return Icons.account_balance;
      case 'Nhân vật':
        return Icons.person;
      case 'Sự kiện':
        return Icons.flag;
      case 'Bản đồ lịch sử':
        return Icons.map;
      default:
        return Icons.bookmark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF9F1D8),
            Color(0xFFE6CFA8),
          ],
        ),
        border: Border.all(
          color: Color(0xFFB28A47),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(2, 3),
          )
        ],
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

        /// 🏺 ICON
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF7A0F10),
          child: Icon(icon, color: Colors.white),
        ),

        /// 📜 NỘI DUNG
        title: Text(
          item.title,
          style: const TextStyle(
            fontFamily: 'Serif',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF4B2E1E),
          ),
        ),
        subtitle: Text(
          item.type,
          style: const TextStyle(
            fontFamily: 'Serif',
            fontStyle: FontStyle.italic,
            color: Colors.brown,
          ),
        ),

        /// ⭐ MỞ CHI TIẾT
        onTap: () {
          Navigator.pop(context);

          if (item.type == 'Bản đồ lịch sử') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MapHistoryScreen(
                  savedMapId: item.data as int,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => item.screen),
            );
          }
        },

        /// ❌ BỎ LƯU – DẠNG ẤN TRIỆN
        trailing: IconButton(
          icon: const Icon(
            Icons.bookmark_remove,
            color: Color(0xFF7A0F10),
          ),
          onPressed: () {
            SavedManager().toggle(item);
          },
        ),
      ),
    );
  }
}


