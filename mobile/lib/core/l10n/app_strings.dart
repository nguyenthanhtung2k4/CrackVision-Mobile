class AppStrings {
  final String langCode;
  const AppStrings._(this.langCode);

  static AppStrings of(String code) {
    switch (code) {
      case 'en': return const AppStrings._('en');
      default:   return const AppStrings._('vi');
    }
  }

  // ── Navigation ──────────────────────────────────────────────
  String get navHome     => _s(vi: 'Trang chủ', en: 'Home');
  String get navHistory  => _s(vi: 'Lịch sử',   en: 'History');
  String get navSettings => _s(vi: 'Cài đặt',   en: 'Settings');

  // ── Home ────────────────────────────────────────────────────
  String get homeTagline      => _s(vi: 'Phát hiện vết nứt bằng AI',     en: 'AI-Powered Crack Detection');
  String get homeGreeting     => _s(vi: 'Xin chào',                       en: 'Hello');
  String get statsToday       => _s(vi: 'Hôm nay',                        en: 'Today');
  String get statsAccuracy    => _s(vi: 'Độ chính xác',                   en: 'Accuracy');
  String get statsMaterials   => _s(vi: 'Vật liệu',                       en: 'Materials');
  String get startScanning    => _s(vi: 'BẮT ĐẦU QUÉT',                  en: 'START SCANNING');
  String get scanCamera       => _s(vi: 'Chụp ảnh',                       en: 'Take Photo');
  String get scanCameraDesc   => _s(vi: 'Dùng camera',                    en: 'Use camera');
  String get scanGallery      => _s(vi: 'Thư viện',                       en: 'Gallery');
  String get scanGalleryDesc  => _s(vi: 'Chọn từ ảnh',                   en: 'Pick from photos');
  String get quickTips        => _s(vi: 'MẸO CHỤP ẢNH',                  en: 'PHOTO TIPS');
  String get bestAccuracy     => _s(vi: 'Chính xác nhất',                 en: 'Best Accuracy');
  String get tipLightTitle    => _s(vi: 'Ánh sáng tốt',                   en: 'Good Lighting');
  String get tipLightDesc     => _s(vi: 'Chụp nơi đủ sáng, tránh bóng tối', en: 'Shoot in bright light, avoid shadows');
  String get tipDistTitle     => _s(vi: 'Khoảng cách',                    en: 'Distance');
  String get tipDistDesc      => _s(vi: 'Giữ cách 30-50cm so với bề mặt', en: 'Keep 30-50cm from the surface');
  String get tipSteadyTitle   => _s(vi: 'Giữ vững',                       en: 'Stay Steady');
  String get tipSteadyDesc    => _s(vi: 'Không rung tay khi chụp',        en: 'Keep hands still when shooting');
  String get tipLensTitle     => _s(vi: 'Ống kính sạch',                  en: 'Clean Lens');
  String get tipLensDesc      => _s(vi: 'Lau ống kính trước khi chụp',    en: 'Wipe lens before shooting');
  String get offlineTitle     => _s(vi: 'Hoạt động không cần mạng',       en: 'Works Without Internet');
  String get offlineDesc      => _s(vi: 'AI chạy trực tiếp trên thiết bị', en: 'AI runs directly on device');
  String get offlineTag       => _s(vi: 'OFFLINE',                        en: 'OFFLINE');
  String get recentActivity   => _s(vi: 'HOẠT ĐỘNG GẦN ĐÂY',             en: 'RECENT ACTIVITY');
  String get seeAll           => _s(vi: 'Xem tất cả',                     en: 'See All');
  String get minutesAgo      => _s(vi: '2 phút trước',                    en: '2 min ago');
  String get hourAgo         => _s(vi: '1 giờ trước',                     en: '1 hr ago');

  // ── History ─────────────────────────────────────────────────
  String get historyTitle     => _s(vi: 'Lịch sử quét',                   en: 'Scan History');
  String get historyTotalLabel => _s(vi: 'Tổng cộng',                     en: 'Total');
  String get historyCrackLabel => _s(vi: 'Có vết nứt',                    en: 'Cracks');
  String get historyCleanLabel => _s(vi: 'An toàn',                       en: 'Clean');
  String get searchHint       => _s(vi: 'Tìm kiếm...',                    en: 'Search...');
  String get filterAll        => _s(vi: 'Tất cả',                         en: 'All');
  String get filterLarge      => _s(vi: 'Vết nứt lớn',                    en: 'Large Crack');
  String get filterSmall      => _s(vi: 'Vết nứt nhỏ',                    en: 'Small Crack');
  String get filterSafe       => _s(vi: 'An toàn',                        en: 'Safe');
  String get noResults        => _s(vi: 'Không tìm thấy kết quả',         en: 'No results found');
  String get noHistory        => _s(vi: 'Không thể tải lịch sử',          en: 'Could not load history');
  String get retry            => _s(vi: 'Thử lại',                        en: 'Retry');
  String get filterTitle      => _s(vi: 'Lọc kết quả',                    en: 'Filter Results');
  String get filterByDate     => _s(vi: 'Lọc theo ngày',                  en: 'Filter by Date');
  String get filterByConf     => _s(vi: 'Lọc theo độ tin cậy',            en: 'Filter by Confidence');
  String get dateAll          => _s(vi: 'Tất cả',                         en: 'All');
  String get dateToday        => _s(vi: 'Hôm nay',                        en: 'Today');
  String get dateWeek         => _s(vi: '7 ngày',                         en: '7 days');
  String get dateMonth        => _s(vi: '30 ngày',                        en: '30 days');
  String get confAll          => _s(vi: 'Tất cả',                         en: 'All');
  String get confHigh         => _s(vi: 'Cao >90%',                       en: 'High >90%');
  String get confMed          => _s(vi: 'TB 70-90%',                      en: 'Med 70-90%');
  String get confLow          => _s(vi: 'Thấp <70%',                      en: 'Low <70%');
  String get clearFilter      => _s(vi: 'Xóa bộ lọc',                     en: 'Clear Filter');
  String get apply            => _s(vi: 'Áp dụng',                        en: 'Apply');
  String get deleteAllTitle   => _s(vi: 'Xóa toàn bộ lịch sử?',          en: 'Delete all history?');
  String get deleteAllDesc    => _s(vi: 'Tất cả kết quả scan sẽ bị xóa vĩnh viễn.', en: 'All scan results will be permanently deleted.');
  String get cancel           => _s(vi: 'Hủy',                            en: 'Cancel');
  String get deleteAll        => _s(vi: 'Xóa tất cả',                     en: 'Delete All');

  // ── Settings ────────────────────────────────────────────────
  String get settingsTitle    => _s(vi: 'Cài đặt',                        en: 'Settings');
  String get settingsSubtitle => _s(vi: 'Tùy chỉnh ứng dụng của bạn',    en: 'Customize your app');
  String get sectionDetection => _s(vi: 'CÀI ĐẶT PHÁT HIỆN',             en: 'DETECTION');
  String get sectionConnect   => _s(vi: 'KẾT NỐI',                        en: 'CONNECTIVITY');
  String get sectionUI        => _s(vi: 'GIAO DIỆN',                      en: 'APPEARANCE');
  String get sectionGeneral   => _s(vi: 'CHUNG',                          en: 'GENERAL');
  String get sectionLanguage  => _s(vi: 'NGÔN NGỮ',                       en: 'LANGUAGE');
  String get highAccLabel     => _s(vi: 'Độ chính xác cao',               en: 'High Accuracy');
  String get highAccDesc      => _s(vi: 'Dùng model AI đầy đủ, chậm hơn', en: 'Full AI model, slower');
  String get autoSaveLabel    => _s(vi: 'Tự động lưu',                    en: 'Auto-Save');
  String get autoSaveDesc     => _s(vi: 'Lưu kết quả scan vào lịch sử',  en: 'Save scan results to history');
  String get offlineModeLabel => _s(vi: 'Chế độ offline',                 en: 'Offline Mode');
  String get offlineModeDesc  => _s(vi: 'Dùng AI trên thiết bị khi mất mạng', en: 'Use on-device AI when offline');
  String get notifLabel       => _s(vi: 'Thông báo',                      en: 'Notifications');
  String get notifDesc        => _s(vi: 'Nhận thông báo khi scan xong',   en: 'Get notified when scan completes');
  String get darkModeLabel    => _s(vi: 'Chế độ tối',                     en: 'Dark Mode');
  String get darkModeDesc     => _s(vi: 'Giao diện tối cho ban đêm',      en: 'Dark interface for night use');
  String get languageLabel    => _s(vi: 'Ngôn ngữ',                       en: 'Language');
  String get languageDesc     => _s(vi: 'Chọn ngôn ngữ hiển thị',        en: 'Choose display language');
  String get updateModel      => _s(vi: 'Cập nhật model AI',              en: 'Update AI Model');
  String get updateModelDesc  => _s(vi: 'MobileNetV2 v2.4.1 — mới nhất', en: 'MobileNetV2 v2.4.1 — latest');
  String get clearHistory     => _s(vi: 'Xóa toàn bộ lịch sử',           en: 'Clear All History');
  String get clearHistoryDesc => _s(vi: 'Xóa tất cả kết quả đã lưu',     en: 'Delete all saved results');
  String get rateApp          => _s(vi: 'Đánh giá ứng dụng',             en: 'Rate the App');
  String get rateAppDesc      => _s(vi: 'Giúp chúng tôi cải thiện',      en: 'Help us improve');
  String get helpSupport      => _s(vi: 'Hỗ trợ & trợ giúp',             en: 'Help & Support');
  String get helpSupportDesc  => _s(vi: 'Liên hệ nhóm phát triển',       en: 'Contact the dev team');
  String get aboutApp         => _s(vi: 'Về ứng dụng',                   en: 'About App');
  String get aboutAppDesc     => _s(vi: 'CrackVision v2.4.1 — Đại Nam University', en: 'CrackVision v2.4.1 — Dai Nam University');
  String get logout           => _s(vi: 'Đăng xuất',                      en: 'Log Out');
  String get statsTotal       => _s(vi: 'Tổng scan',                      en: 'Total Scans');
  String get statsAccSet      => _s(vi: 'Chính xác',                      en: 'Accuracy');
  String get statsStorage     => _s(vi: 'Bộ nhớ',                         en: 'Storage');
  String get chooseLanguage   => _s(vi: 'Chọn ngôn ngữ',                  en: 'Choose Language');
  String get offlineBannerTitle => _s(vi: 'Hoạt động 100% offline',       en: '100% Offline');
  String get offlineBannerDesc  => _s(vi: 'AI chạy trực tiếp trên thiết bị, không cần internet', en: 'AI runs locally on device, no internet needed');
  String get clearHistoryConfirm => _s(vi: 'Xóa toàn bộ lịch sử?',       en: 'Clear all history?');
  String get clearHistoryConfirmDesc => _s(vi: 'Tất cả kết quả scan sẽ bị xóa vĩnh viễn.', en: 'All scan results will be permanently deleted.');
  String get cleared          => _s(vi: 'Đã xóa toàn bộ lịch sử',        en: 'History cleared');

  String _s({required String vi, required String en}) =>
      langCode == 'en' ? en : vi;
}
