class MimoTagGroup {
  const MimoTagGroup({
    required this.title,
    required this.description,
    required this.tags,
  });

  final String title;
  final String description;
  final List<String> tags;
}

class MimoAdvancedExample {
  const MimoAdvancedExample({
    required this.title,
    required this.scenario,
    required this.stylePrompt,
    required this.text,
    required this.notes,
    required this.voiceName,
    required this.audioPath,
    required this.durationMs,
    required this.sourceLabel,
  });

  final String title;
  final String scenario;
  final String stylePrompt;
  final String text;
  final String notes;
  final String voiceName;
  final String audioPath;
  final int durationMs;
  final String sourceLabel;
}

const List<MimoTagGroup> mimoStyleTagGroups = <MimoTagGroup>[
  MimoTagGroup(
    title: '方言',
    description: '文档推荐方言标签，适合放在文本最开头。',
    tags: <String>['东北话', '四川话', '河南话', '粤语'],
  ),
  MimoTagGroup(
    title: '基础情绪',
    description: '控制整段语音的基础情绪底色。',
    tags: <String>['开心', '悲伤', '愤怒', '恐惧', '惊讶', '兴奋', '委屈', '平静', '冷漠'],
  ),
  MimoTagGroup(
    title: '复合情绪',
    description: '适合故事、对话和角色化表达。',
    tags: <String>['怅然', '欣慰', '无奈', '愧疚', '释然', '嫉妒', '厌倦', '忐忑', '动情'],
  ),
  MimoTagGroup(
    title: '整体语调',
    description: '改变整段声音的说话方式。',
    tags: <String>['温柔', '高冷', '活泼', '严肃', '慵懒', '俏皮', '深沉', '干练', '凌厉'],
  ),
  MimoTagGroup(
    title: '音色定位',
    description: '补充声音的质感与年龄感。',
    tags: <String>['磁性', '醇厚', '清亮', '空灵', '稚嫩', '苍老', '甜美', '沙哑', '醇雅'],
  ),
  MimoTagGroup(
    title: '人设与角色',
    description: '用于更强的角色扮演或特殊模式。',
    tags: <String>['夹子音', '大姐姐音', '正太音', '大叔音', '台湾腔', '孙悟空', '林黛玉', '唱歌'],
  ),
];

const List<MimoTagGroup> mimoAudioTagGroups = <MimoTagGroup>[
  MimoTagGroup(
    title: '哭笑表达',
    description: '插入到具体句子前后，控制局部表情。',
    tags: <String>['笑', '轻笑', '大笑', '冷笑', '抽泣', '呜咽', '哽咽', '嚎啕大哭'],
  ),
  MimoTagGroup(
    title: '呼吸与停顿',
    description: '让句子有呼吸感和戏剧停顿。',
    tags: <String>['吸气', '深呼吸', '叹气', '长叹一口气', '喘息', '屏息', '停顿', '咳嗽'],
  ),
  MimoTagGroup(
    title: '状态与反应',
    description: '给一句话添加更明确的状态变化。',
    tags: <String>['紧张', '害怕', '激动', '疲惫', '撒娇', '心虚', '震惊', '不耐烦'],
  ),
  MimoTagGroup(
    title: '声音细节',
    description: '调节发声质感，可与情绪标签组合。',
    tags: <String>['颤抖', '声音颤抖', '变调', '破音', '鼻音', '气声', '低声', '呼喊'],
  ),
];

const List<MimoAdvancedExample> mimoAdvancedExamples = <MimoAdvancedExample>[
  MimoAdvancedExample(
    title: '沧桑老前辈叙事',
    scenario: '展示如何用低沉沙哑、娓娓道来的声音，讲出普通人的坚韧和岁月感。',
    stylePrompt: '声音低沉沙哑一点，像个历经沧桑的老前辈在讲述传奇人物。语气里带点由衷的敬佩，娓娓道来。',
    text:
        '街口那个老周啊，媳妇走得早，一个人拉扯俩娃，白天蹬三轮，晚上还去夜市摆摊修鞋。现在俩孩子都有出息喽，想接他去城里享福——他不去，就守着那间小铺子。哎，人哪，骨头硬，心里头就踏实。',
    notes: '适合故事旁白、人物小传和带有生活质感的短文朗读。表演指令负责控制叙述口吻，正文只保留实际要合成的内容。',
    voiceName: '冰糖',
    audioPath: 'assets/audio/examples/mimo-doc-case1-bingtang.wav',
    durationMs: 27840,
    sourceLabel: 'MiMo V2.5 TTS 发布文档 · Case1',
  ),
  MimoAdvancedExample(
    title: '灭世神祇导演模式',
    scenario: '展示如何用角色、场景和表演方向组织一段影视级角色台词。',
    stylePrompt:
        'CHARACTER\n曾是守护九天的神祇，见证了凡人的无药可救后，决定以灭世来完成最终的净化。他的心中装满悲悯，但手段是绝对的屠戮。\nSCENE\n悬浮于崩塌的祭坛之上，俯视下方在火海中哀嚎、曾奉他为信仰的信徒。他在降下最后的毁灭前，发出神圣却残忍的叹息。\nDIRECTION\n发声机制与共鸣：充分打开胸腔共鸣，制造一种神圣的回音感。声音位置靠后，音色如古钟般低沉且带有金属质感的磁性。\n声调与韵律：四声（去声）的下落要极其平缓，不要砸实，带有一种吟诵古籍般的从容与宏大。字句之间的停顿拉长，展现出视万物为刍狗的威压。\n气声与实声的较量：在说前两句时，实声饱满，高高在上；但在说出“闭上眼吧”时，声音突然混入大量疲惫的气息，神性开始出现裂痕，流露出勉强的残忍。\n咬字细节：古风词汇（如“垂怜”、“沉疴”、“剔骨刮毒”）咬字要深，声母起音圆润而不尖锐。结尾的最后半句，几乎全部转化为气声，像是在哄睡一个婴儿，将残酷包裹在极致的悲哀之中。',
    text: '你们求我垂怜，求我降下甘霖洗净这浊世。可这世间的沉疴，唯有烈火能剔骨刮毒。闭上眼吧。这业火烧起来的时候，一点也不疼。',
    notes: '适合角色配音、游戏 NPC 和影视旁白。表演指令先建立角色状态，再让正文承载实际台词。',
    voiceName: '白桦',
    audioPath: 'assets/audio/examples/mimo-doc-case2-baihua.wav',
    durationMs: 24160,
    sourceLabel: 'MiMo V2.5 TTS 发布文档 · Case2',
  ),
  MimoAdvancedExample(
    title: '星际航线标签编排',
    scenario: '展示如何在同一段文本里混合多种情绪、状态和节奏，让对白有明显转场。',
    stylePrompt: '',
    text:
        '(调侃) 老张你当时不是说这条航线稳得很吗……\n(模仿自信，提高音量) “系统全绿，放心走。”\n(突然停顿) ……现在呢？\n(爆发，愤怒压不住) 现在整艘船都在报警！你管这叫“放心”？！\n(声音变轻) 不过……你看那外面，裂开的星云像在呼吸一样。\n(急促｜呼喊) 别断通讯！喂！再撑十秒！十秒！！\n(低声｜情绪塌陷般平静) ……算了。\n(轻笑｜带点释然) 也挺好，至少是一起看的。',
    notes: '适合多人对白感、剧情转折和长台词。风格标签控制整体语气，音频标签控制局部笑声、停顿、呼喊等细节。',
    voiceName: '默认音色',
    audioPath: 'assets/audio/examples/mimo-doc-audio-tags.wav',
    durationMs: 27200,
    sourceLabel: 'MiMo V2.5 TTS 发布文档 · 音频标签',
  ),
  MimoAdvancedExample(
    title: '发射倒计时文本理解',
    scenario: '展示如何只靠标点、大小写和节奏安排，让模型理解紧张、爆发和兴奋。',
    stylePrompt: '',
    text:
        "Ten... nine... eight... seven... six... five... four... three... TWO... ONE... ZERO! LAUNCH! LAUNCH! WE HAVE LIFTOFF! GO GO GO! SHE'S CLIMBING! ALTITUDE 1,000... 5,000... 10,000 FEET AND CLIMBING! BEAUTIFUL! AB-SO-LUTE-LY BEAUTIFUL!",
    notes: '适合展示模型对纯文本节奏、情绪弧线和说话人状态的自动理解能力。',
    voiceName: 'Milo',
    audioPath: 'assets/audio/examples/mimo-doc-countdown.wav',
    durationMs: 28800,
    sourceLabel: 'MiMo V2.5 TTS 发布文档 · 文本理解',
  ),
  MimoAdvancedExample(
    title: '纪录片旁白音色设计',
    scenario: '展示如何把年龄、音色质感和职业角色写清楚，生成纪录片旁白感的音色。',
    stylePrompt: '一位中年男性，说标准普通话，嗓音低沉有磁性，带有轻微的沙哑质感，像纪录片旁白解说员，沉稳而有感染力。',
    text:
        '当最后一缕阳光消失在地平线之下，这片沉睡了亿万年的大地开始显露它真正的面貌。在这寂静的荒野中，每一块岩石都记录着时间的流逝，每一阵风都在诉说着古老的故事。',
    notes: '这是 voice design 模型生成的内置试听，适合作为“音色描述应该写多具体”的参考。',
    voiceName: 'Voice Design · 纪录片旁白',
    audioPath: 'assets/audio/examples/mimo-doc-voice-design-narrator.wav',
    durationMs: 24800,
    sourceLabel: 'MiMo V2.5 TTS 发布文档 · Voice Design Case1',
  ),
  MimoAdvancedExample(
    title: '北方老先生音色设计',
    scenario: '展示如何用年龄、口音、语速、质感和角色感共同塑造一个鲜明音色。',
    stylePrompt:
        '一位年迈的老先生，说带北方口音的普通话，语速缓慢而沉稳，嗓音略带沙哑和沧桑感，仿佛一位饱经风霜的老爷爷在讲故事，充满岁月的智慧。',
    text:
        '我这辈子啊，走南闯北六十多年。见过最热闹的集市，也见过最安静的戈壁。到头来才明白一个道理——这人哪，不在走了多远的路，在于记住了多少风景。年轻人，别光顾着赶路，偶尔也停下来看看天。',
    notes: '官方使用指南也推荐这种多维度写法：年龄、口音、语速、嗓音质感和叙事角色都写清楚。',
    voiceName: 'Voice Design · 北方老先生',
    audioPath: 'assets/audio/examples/mimo-doc-voice-design-elder.wav',
    durationMs: 42400,
    sourceLabel: 'MiMo V2.5 TTS 发布文档 · Voice Design Case2',
  ),
];

List<String> flattenMimoTags(List<MimoTagGroup> groups) {
  return List<String>.unmodifiable(
    groups.expand((group) => group.tags).toSet(),
  );
}
