import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/domain/remote_app_config.dart';
import 'package:shenghui_ai_voice_studio/src/services/local_json_store.dart';
import 'package:shenghui_ai_voice_studio/src/services/local_popup_notice_store.dart';

void main() {
  test('persists acknowledged popup notices by notice identity', () async {
    final jsonStore = MemoryJsonStore();
    final store = LocalPopupNoticeStore(jsonStore: jsonStore);
    const notice = RemotePopupNotice(
      id: 'notice-20260530',
      title: '维护提醒',
      message: '今晚 23:00 后可能短暂不可用',
      enabled: true,
    );
    const nextNotice = RemotePopupNotice(
      id: 'notice-20260531',
      title: '新提醒',
      message: '明天会有新的通知',
      enabled: true,
    );

    expect(await store.isAcknowledged(notice), isFalse);

    await store.acknowledge(notice);

    expect(await store.isAcknowledged(notice), isTrue);
    expect(await store.isAcknowledged(nextNotice), isFalse);
    expect(
      await LocalPopupNoticeStore(jsonStore: jsonStore).isAcknowledged(notice),
      isTrue,
    );
  });

  test(
    'content based popup identity changes when notice text changes',
    () async {
      final store = LocalPopupNoticeStore(jsonStore: MemoryJsonStore());
      const notice = RemotePopupNotice(
        title: '维护提醒',
        message: '今晚 23:00 后可能短暂不可用',
        enabled: true,
      );
      const changedNotice = RemotePopupNotice(
        title: '维护提醒',
        message: '明晚 23:00 后可能短暂不可用',
        enabled: true,
      );

      await store.acknowledge(notice);

      expect(await store.isAcknowledged(notice), isTrue);
      expect(await store.isAcknowledged(changedNotice), isFalse);
    },
  );

  test('ignores corrupted local acknowledgement data', () async {
    final jsonStore = MemoryJsonStore();
    await jsonStore.setString('shenghui_acknowledged_popup_notices', '{broken');
    final store = LocalPopupNoticeStore(jsonStore: jsonStore);

    expect(
      await store.isAcknowledged(
        const RemotePopupNotice(id: 'notice-20260530', enabled: true),
      ),
      isFalse,
    );
  });
}
