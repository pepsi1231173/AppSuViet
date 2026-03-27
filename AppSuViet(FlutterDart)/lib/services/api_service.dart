  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import 'package:flutter/foundation.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import '../models/era.dart';
  import '../models/event.dart';
  import '../models/quiz_question.dart';
  import '../models/king.dart';
  import '../models/TimelineItem.dart';
  import '../models/provinces.dart';
  import '../models/historical_figure.dart';
  import '../models/festival.dart';
  import '../models/HistoricalDocument .dart';
  import '../models/map_history.dart';

  class ApiService {
    final String wikiBase = 'https://vi.wikipedia.org/w/api.php';
    final String baseUrl = 'https://entrappingly-humanlike-letha.ngrok-free.dev';



    /// 🔹 Danh sách triều đại Việt Nam (bỏ Nhà Lê sơ & Lê trung hưng)
    final List<String> vietnamEras = [
      'Nhà_Ngô',
      'Nhà_Đinh',
      'Nhà_Tiền_Lê',
      'Nhà_Lý',
      'Nhà_Trần',
      'Nhà_Hồ',
      'Nhà_Hậu_Lê',
      'Nhà_Mạc',
      'Nhà_Tây_Sơn',
      'Nhà_Nguyễn',
    ];

    /// 🗓 Dữ liệu năm tương ứng từng triều đại
    static const Map<String, List<int>> eraYears = {
      'Nhà_Ngô': [939, 965],
      'Nhà_Đinh': [968, 980],
      'Nhà_Tiền_Lê': [980, 1009],
      'Nhà_Lý': [1009, 1225],
      'Nhà_Trần': [1226, 1400],
      'Nhà_Hồ': [1400, 1407],
      'Nhà_Hậu_Lê': [1428, 1789],
      'Nhà_Mạc': [1527, 1677],
      'Nhà_Tây_Sơn': [1778, 1802],
      'Nhà_Nguyễn': [1802, 1945],
    };

    /// ✅ Lấy danh sách triều đại (cache + Wikipedia)
    Future<List<Era>> fetchEras() async {
      final futures = vietnamEras.map((e) => fetchEraDetailByName(e)).toList();
      return await Future.wait(futures);
    }

    /// ✅ Lấy chi tiết triều đại theo tên (có cache + Wikipedia)
    Future<Era> fetchEraDetailByName(String eraName) async {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'era_$eraName';

      // 🔹 Cache
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        try {
          final json = jsonDecode(cached);
          return Era.fromJson(json);
        } catch (_) {}
      }

      final uri = Uri.parse(
        '$wikiBase?action=query&titles=$eraName'
            '&prop=extracts&format=json&exintro&explaintext',
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      String extract = '';
      if (res.statusCode == 200) {
        try {
          final data = await compute(jsonDecode, res.body);
          final pages = data['query']['pages'] as Map<String, dynamic>;
          extract = pages.values.first['extract'] ?? '';
        } catch (_) {}
      }

      final readableName = eraName.replaceAll('_', ' ');
      final years = eraYears[eraName] ?? [0, 0];
      final startYear = years[0];
      final endYear = years[1];

      final era = Era(
        id: readableName.hashCode,
        name: readableName,
        description: extract.isNotEmpty
            ? extract
            : 'Không có mô tả chi tiết cho triều đại này.',
        imageUrl:
        'assets/images/${eraName.toLowerCase().replaceAll("nhà_", "nha_")}.jpg',
        startYear: startYear,
        endYear: endYear,
      );

      prefs.setString(cacheKey, jsonEncode(era.toJson()));
      return era;
    }

    /// 🗓 Lấy các sự kiện tiêu biểu theo triều đại
    Future<List<EventModel>> fetchEventsByEra(String eraName) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = 'events_$eraName';

        // 🔹 Cache nhanh
        final cached = prefs.getString(cacheKey);
        if (cached != null) {
          try {
            final List list = jsonDecode(cached);
            return list.map((e) => EventModel.fromJson(e)).toList();
          } catch (_) {}
        }

        final readableName = eraName.replaceAll('_', ' ');
        final searchTerm = "$readableName sự kiện tiêu biểu";
        final url = Uri.parse(
          '$wikiBase?action=query&list=search&format=json'
              '&srsearch=${Uri.encodeComponent(searchTerm)}',
        );

        final res = await http.get(url).timeout(const Duration(seconds: 6));
        if (res.statusCode != 200) throw Exception('Không thể tải từ Wikipedia');

        final data = jsonDecode(res.body);
        final results = (data['query']['search'] as List?) ?? [];

        final filtered = results.where((item) {
          final title = (item['title'] as String).toLowerCase();
          return title.contains(readableName.toLowerCase());
        }).toList();

        final finalResults = filtered.isNotEmpty ? filtered : results.take(3);

        final events = finalResults.map((item) {
          final title = item['title'];
          final snippet =
          (item['snippet'] as String).replaceAll(RegExp(r'<[^>]*>'), '');
          return EventModel(
            id: title.hashCode,
            eraId: readableName.hashCode,
            title: title,
            year: 0,
            description: snippet,
            imageUrl: '',
          );
        }).toList();

        prefs.setString(
            cacheKey, jsonEncode(events.map((e) => e.toJson()).toList()));
        return events;
      } catch (e) {
        debugPrint('⚠️ Lỗi fetchEventsByEra: $e');
        return [
          EventModel(
            id: 0,
            eraId: 0,
            title: 'Không tìm thấy sự kiện tiêu biểu',
            year: 0,
            description:
            'Không thể tải sự kiện tiêu biểu của ${eraName.replaceAll("_", " ")}.',
            imageUrl: '',
          ),
        ];
      }
    }

    /// 🔍 Chi tiết sự kiện (demo)
    Future<EventModel> fetchEventDetail(int id) async {
      return EventModel(
        id: id,
        eraId: 0,
        title: 'Sự kiện $id',
        year: 1000 + id,
        description: 'Mô tả chi tiết của sự kiện $id (dữ liệu mô phỏng).',
        imageUrl: '',
      );
    }



    /// 🔹 Lấy danh sách nhân vật theo triều đại Nhà Đinh
    Future<List<HistoricalFigure>> fetchHistoricalFigures() async {
      const String apiUrl = 'https://entrappingly-humanlike-letha.ngrok-free.dev/api/HistoricalFigures/all';
      const String cacheKey = 'historical_figures_all';

      final prefs = await SharedPreferences.getInstance();

      // 🔥 XÓA CACHE CŨ (tránh bị dữ liệu cũ / trùng triều)
      await prefs.remove(cacheKey);

      try {
        // 🔹 Gọi API
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final List<dynamic> list =
          jsonDecode(utf8.decode(response.bodyBytes));

          // 🔹 Lưu cache mới
          await prefs.setString(cacheKey, jsonEncode(list));

          // 🔹 Parse JSON → Model
          return list
              .map((e) => HistoricalFigure.fromJson(e))
              .toList();
        } else {
          throw Exception('Failed to load historical figures from API');
        }
      } catch (e) {
        // 🔻 Nếu lỗi → thử lấy cache (nếu có)
        final cached = prefs.getString(cacheKey);
        if (cached != null) {
          final List<dynamic> list = jsonDecode(cached);
          return list
              .map((e) => HistoricalFigure.fromJson(e))
              .toList();
        }

        return [];
      }
    }



    /// 🔐 Đăng nhập (giả lập)
    Future<Map<String, dynamic>> login(String username, String password) async {
      await Future.delayed(const Duration(milliseconds: 400));
      return {'token': 'fake_${username.hashCode}', 'displayName': username};
    }



    /// 🕰️ Lấy dữ liệu timeline từ API ASP.NET
    Future<List<TimelineItem>> fetchTimeline() async {
      // 🔹 Dùng HTTP khi test trên emulator để tránh lỗi chứng chỉ
      const String apiUrl = 'https://entrappingly-humanlike-letha.ngrok-free.dev/api/Timeline';

      try {
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((e) => TimelineItem.fromJson(e)).toList();
        } else {
          throw Exception('Lỗi tải dữ liệu: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('❌ Lỗi fetchTimeline: $e');
        throw Exception('Không thể kết nối tới API: $e');
      }
    }
    /// 🗺️ Lấy danh sách tỉnh/thành từ API ASP.NET hoặc file JSON cục bộ
    Future<List<Province>> fetchProvinces() async {
      const String apiUrl = 'https://entrappingly-humanlike-letha.ngrok-free.dev/api/Provinces';

      try {
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((e) => Province.fromJson(e)).toList();
        } else {
          throw Exception('Lỗi tải dữ liệu: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('❌ Lỗi fetchProvinces: $e');
        throw Exception('Không thể kết nối tới API: $e');
      }
    }
    /// 🎉 Lấy danh sách lễ hội – ngày lễ văn hóa Việt Nam từ API ASP.NET
    Future<List<Festival>> fetchFestivals() async {
      const String apiUrl = 'https://entrappingly-humanlike-letha.ngrok-free.dev/api/Holidays'; // 🔹 endpoint bên ASP.NET

      try {
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((e) => Festival.fromJson(e)).toList();
        } else {
          throw Exception('Lỗi tải lễ hội: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('❌ Lỗi fetchFestivals: $e');
        throw Exception('Không thể kết nối tới API lễ hội: $e');
      }
    }
    Future<List<TimelineItem>> fetchEventsByPeriod(String eraName) async {
      final response = await http.get(

        Uri.parse('$baseUrl/api/timeline/events-by-era/$eraName'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((e) => TimelineItem.fromJson(e)).toList();
      } else {
        throw Exception("Không load được sự kiện triều đại");
      }
    }
    Future<List<HistoricalDocument>> fetchDocuments() async {
      final res = await http.get(Uri.parse("$baseUrl/api/documents"));

      if (res.statusCode != 200) return [];

      final List data = jsonDecode(res.body);

      return data.map((e) => HistoricalDocument.fromJson(e)).toList();
    }

    Future<HistoricalDocument?> fetchDocumentById(int id) async {
      final res = await http.get(Uri.parse("$baseUrl/api/documents/$id"));

      if (res.statusCode != 200) return null;

      return HistoricalDocument.fromJson(jsonDecode(res.body));
    }
    Future<List<QuizQuestion>> fetchQuizByEra(String era) async {
      final response = await http.get(Uri.parse("$baseUrl/api/Quiz/$era"));

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((e) => QuizQuestion.fromJson(e)).toList();
      } else {
        return [];
      }
    }
    Future<String> askAi(String question, {bool useHybrid = true}) async {
      final url = Uri.parse('$baseUrl/api/ai/chat');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "query": question,
          "useHybrid": useHybrid,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json["answer"] ?? "Không có câu trả lời.";
      } else {
        return "Lỗi server: ${response.statusCode}";
      }
    }
    Future<String> getWelcomeMessage() async {
      final url = Uri.parse('$baseUrl/api/ai/welcome');

      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json["message"] ?? "Xin chào! Bạn muốn hỏi gì về lịch sử Việt Nam?";
      } else {
        return "Xin chào!";
      }
    }

    Future<List<MapHistory>> fetchMapHistories() async {
      final response =
      await http.get(Uri.parse("$baseUrl/api/MapHistory"));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => MapHistory.fromJson(e)).toList();
      } else {
        throw Exception("Không thể tải danh sách bản đồ lịch sử");
      }
    }

  }




