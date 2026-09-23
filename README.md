## 语音

语音对象为凯尔希·思衡托 `char_1052_kalts2`，不是普通凯尔希。资料与台词见 [PRTS 思衡托语音记录](https://prts.wiki/w/%E5%87%AF%E5%B0%94%E5%B8%8C%C2%B7%E6%80%9D%E8%A1%A1%E6%89%98/%E8%AF%AD%E9%9F%B3%E8%AE%B0%E5%BD%95)。

* 技能 1/2 使用作战中 1/2，固定播放；技能 3 在作战中 3/4 间随机播放。
* `talk_LP` 使用任命队长、选中干员 1/2、作战中 2、3 星结束、进驻设施，共 6 条；日文“治疗准备已就绪”裁剪到约 1.49 秒，适配 `1.5 + math.random() * .5` 的说话时长限制，不使用标题语音“明日方舟”。
* 配音配置项为 `zh`、`jp`，默认 `jp`；配音语言与 UI 文本语言独立，随机说话事件直接由 `inst.talker_path_override` 触发，技能台词走 `SayAndVoice`。

FMOD 源文件位于 `soundSource/kaltsit_esperanta_voice_zh` 与 `soundSource/kaltsit_esperanta_voice_jp`，正式包位于 `sound/`。
