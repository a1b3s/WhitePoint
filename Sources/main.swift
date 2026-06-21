import Cocoa
import CoreGraphics
import Carbon.HIToolbox
import ServiceManagement

// MARK: - システム輝度読み取り（起動時にポインタをキャッシュ）

private typealias GetBrightnessFn = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
private let _brightnessHandle: UnsafeMutableRawPointer? = dlopen(
    "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY)
private let _brightnessFn: GetBrightnessFn? = {
    guard let h = _brightnessHandle, let sym = dlsym(h, "DisplayServicesGetBrightness") else { return nil }
    return unsafeBitCast(sym, to: GetBrightnessFn.self)
}()

func readSystemBrightness() -> Double {
    guard let fn = _brightnessFn else { return 0.8 }
    var v: Float = 0.8; _ = fn(CGMainDisplayID(), &v)
    return Double(max(0.01, min(1.0, v)))
}

// MARK: - ローカライズ文字列

struct Loc {
    let brightness: String; let warmth: String
    let presets: [String]         // [昼, 夕方, 夜, 就寝前]
    let autoOff: String;   let autoOn: String
    let strengths: [String]       // [弱, 中, 強]
    let schedOff: String;  let schedOn: String
    let schedEdit: String
    let statsPrefix: String; let statsEmpty: String
    let zoneNames: [String]       // [昼, 夕方, 夜, 就寝前] — 統計表示用
    let launchLogin: String
    let langMenu: String
    let quit: String
    // スケジュールウィンドウ
    let schedWinTitle: String; let schedWinHeader: String; let schedWinSave: String
    let schedRuleNames: [String]  // [朝, 夕方, 夜, 就寝前]
}

private let locTable: [String: Loc] = [
    "ja": Loc(
        brightness: "ホワイトポイント", warmth: "暖かさ",
        presets: ["昼（標準）","夕方","夜","就寝前"],
        autoOff: "自動モード OFF", autoOn: "✓ 自動モード ON",
        strengths: ["　弱","　中","　強"],
        schedOff: "スケジュール OFF", schedOn: "✓ スケジュール ON",
        schedEdit: "　スケジュールを設定...",
        statsPrefix: "今日: ", statsEmpty: "今日: まだデータなし",
        zoneNames: ["昼","夕方","夜","就寝前"],
        launchLogin: "ログイン時に自動起動",
        langMenu: "言語 / Language",
        quit: "終了",
        schedWinTitle: "スケジュール設定",
        schedWinHeader: "各時刻になると自動で設定が切り替わります",
        schedWinSave: "保存して閉じる",
        schedRuleNames: ["朝","夕方","夜","就寝前"]
    ),
    "en": Loc(
        brightness: "White Point", warmth: "Warmth (Blue Light)",
        presets: ["Day (Normal)","Evening","Night","Bedtime"],
        autoOff: "Auto Mode OFF", autoOn: "✓ Auto Mode ON",
        strengths: ["　Low","　Med","　High"],
        schedOff: "Schedule OFF", schedOn: "✓ Schedule ON",
        schedEdit: "　Edit Schedule...",
        statsPrefix: "Today: ", statsEmpty: "Today: No data yet",
        zoneNames: ["Day","Evening","Night","Bedtime"],
        launchLogin: "Launch at Login",
        langMenu: "Language / 言語",
        quit: "Quit",
        schedWinTitle: "Schedule Settings",
        schedWinHeader: "Settings switch automatically at each time",
        schedWinSave: "Save & Close",
        schedRuleNames: ["Morning","Evening","Night","Bedtime"]
    ),
    "zh": Loc(
        brightness: "白点", warmth: "暖色（蓝光过滤）",
        presets: ["白天（标准）","傍晚","夜间","睡前"],
        autoOff: "自动模式 关", autoOn: "✓ 自动模式 开",
        strengths: ["　弱","　中","　强"],
        schedOff: "计划 关", schedOn: "✓ 计划 开",
        schedEdit: "　设置计划...",
        statsPrefix: "今日：", statsEmpty: "今日：暂无数据",
        zoneNames: ["白天","傍晚","夜间","睡前"],
        launchLogin: "登录时自动启动",
        langMenu: "语言 / Language",
        quit: "退出",
        schedWinTitle: "计划设置",
        schedWinHeader: "到达设定时间时自动切换",
        schedWinSave: "保存并关闭",
        schedRuleNames: ["早晨","傍晚","夜间","睡前"]
    ),
    "ko": Loc(
        brightness: "화이트 포인트", warmth: "따뜻함（블루라이트 차단）",
        presets: ["낮（기본）","저녁","밤","취침 전"],
        autoOff: "자동 모드 OFF", autoOn: "✓ 자동 모드 ON",
        strengths: ["　약","　중","　강"],
        schedOff: "스케줄 OFF", schedOn: "✓ 스케줄 ON",
        schedEdit: "　스케줄 설정...",
        statsPrefix: "오늘: ", statsEmpty: "오늘: 아직 데이터 없음",
        zoneNames: ["낮","저녁","밤","취침 전"],
        launchLogin: "로그인 시 자동 실행",
        langMenu: "언어 / Language",
        quit: "종료",
        schedWinTitle: "스케줄 설정",
        schedWinHeader: "설정한 시간에 자동으로 전환됩니다",
        schedWinSave: "저장 후 닫기",
        schedRuleNames: ["아침","저녁","밤","취침 전"]
    ),
    "es": Loc(
        brightness: "Punto Blanco", warmth: "Calidez (Luz Azul)",
        presets: ["Día (Normal)","Tarde","Noche","Antes de dormir"],
        autoOff: "Modo Auto OFF", autoOn: "✓ Modo Auto ON",
        strengths: ["　Suave","　Medio","　Fuerte"],
        schedOff: "Horario OFF", schedOn: "✓ Horario ON",
        schedEdit: "　Editar Horario...",
        statsPrefix: "Hoy: ", statsEmpty: "Hoy: Sin datos aún",
        zoneNames: ["Día","Tarde","Noche","Antes de dormir"],
        launchLogin: "Iniciar al Arrancar",
        langMenu: "Idioma / Language",
        quit: "Salir",
        schedWinTitle: "Configurar Horario",
        schedWinHeader: "La configuración cambia automáticamente",
        schedWinSave: "Guardar y Cerrar",
        schedRuleNames: ["Mañana","Tarde","Noche","Antes de dormir"]
    ),
]

private let langNames = ["ja":"🇯🇵 日本語","en":"🇺🇸 English","zh":"🇨🇳 中文","ko":"🇰🇷 한국어","es":"🇪🇸 Español"]
private let langOrder = ["ja","en","zh","ko","es"]

func detectLang() -> String {
    for pref in Locale.preferredLanguages {
        let code = String(pref.prefix(2))
        if locTable[code] != nil { return code }
    }
    return "en"
}

// 現在の言語（起動時に確定、変更時に更新）
var currentLang: String = UserDefaults.standard.string(forKey:"lang") ?? detectLang()
var s: Loc { locTable[currentLang] ?? locTable["en"]! }

// MARK: - 今日の日付文字列

func todayString() -> String {
    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date())
}

// MARK: - 今日の使用統計

struct DailyStats: Codable {
    var date: String
    var 昼: Double   = 0   // 秒数
    var 夕方: Double = 0
    var 夜: Double   = 0
    var 就寝前: Double = 0
}

// MARK: - Schedule Rule

struct ScheduleRule: Codable {
    var name: String; var hour: Int; var minute: Int
    var brightness: Double; var warmth: Double; var enabled: Bool
}

let defaultRules: [ScheduleRule] = [
    .init(name:"朝",     hour:7,  minute:0, brightness:1.0,  warmth:0.0,  enabled:false),
    .init(name:"夕方",   hour:17, minute:0, brightness:0.9,  warmth:0.2,  enabled:false),
    .init(name:"夜",     hour:20, minute:0, brightness:0.75, warmth:0.45, enabled:false),
    .init(name:"就寝前", hour:22, minute:0, brightness:0.6,  warmth:0.65, enabled:false),
]

// MARK: - Schedule Window

final class ScheduleWindowController: NSWindowController, NSWindowDelegate {
    private var rules: [ScheduleRule]; private let onSave: ([ScheduleRule]) -> Void
    private var checkboxes: [NSButton] = []; private var timePickers: [NSDatePicker] = []
    init(rules: [ScheduleRule], onSave: @escaping ([ScheduleRule]) -> Void) {
        self.rules = rules; self.onSave = onSave
        let w = NSPanel(contentRect:NSRect(x:0,y:0,width:360,height:260),
                        styleMask:[.titled,.closable], backing:.buffered, defer:false)
        w.title=s.schedWinTitle; w.isReleasedWhenClosed=false
        super.init(window:w); w.delegate=self; w.center(); buildUI()
    }
    required init?(coder:NSCoder) { fatalError() }
    private func buildUI() {
        guard let cv=window?.contentView else { return }
        let hdr=NSTextField(labelWithString:s.schedWinHeader)
        hdr.frame=NSRect(x:16,y:226,width:330,height:18)
        hdr.font = .systemFont(ofSize:11); hdr.textColor = .secondaryLabelColor; cv.addSubview(hdr)
        for (i,rule) in rules.enumerated() {
            let y=175-i*44
            let displayName = i < s.schedRuleNames.count ? s.schedRuleNames[i] : rule.name
            let cb=NSButton(checkboxWithTitle:displayName,target:nil,action:nil)
            cb.frame=NSRect(x:16,y:y+10,width:80,height:22); cb.state=rule.enabled ? .on:.off
            cv.addSubview(cb); checkboxes.append(cb)
            let desc=NSTextField(labelWithString:"明るさ \(Int(rule.brightness*100))%  暖かさ \(Int(rule.warmth*100))%")
            desc.frame=NSRect(x:100,y:y+12,width:160,height:16)
            desc.font = .systemFont(ofSize:11); desc.textColor = .secondaryLabelColor; cv.addSubview(desc)
            let dp=NSDatePicker()
            dp.datePickerStyle = .textFieldAndStepper; dp.datePickerElements=[.hourMinute]
            dp.frame=NSRect(x:260,y:y+8,width:84,height:24)
            var c=Calendar.current.dateComponents([.year,.month,.day],from:Date())
            c.hour=rule.hour; c.minute=rule.minute
            dp.dateValue=Calendar.current.date(from:c) ?? Date()
            cv.addSubview(dp); timePickers.append(dp)
            if i<rules.count-1 {
                let sep=NSBox(); sep.boxType = .separator
                sep.frame=NSRect(x:16,y:y+2,width:330,height:1); cv.addSubview(sep)
            }
        }
        let btn=NSButton(title:s.schedWinSave,target:self,action:#selector(save))
        btn.frame=NSRect(x:110,y:12,width:160,height:32); btn.bezelStyle = .rounded
        btn.keyEquivalent="\r"; cv.addSubview(btn)
    }
    @objc private func save() {
        var updated=rules
        for (i,(cb,dp)) in zip(checkboxes,timePickers).enumerated() {
            updated[i].enabled=cb.state == .on
            let c=Calendar.current.dateComponents([.hour,.minute],from:dp.dateValue)
            updated[i].hour=c.hour ?? updated[i].hour; updated[i].minute=c.minute ?? updated[i].minute
        }
        onSave(updated); window?.close()
    }
    func windowWillClose(_ n:Notification) {}
}

// MARK: - AppController

final class AppController: NSObject, NSApplicationDelegate {

    // 状態
    private var brightness: Double = 1.0
    private var warmth: Double     = 0.0

    // スケジュール
    private var scheduleEnabled = false
    private var rules: [ScheduleRule] = defaultRules
    private var scheduleTimer: Timer?
    private var scheduleWindowCtrl: ScheduleWindowController?

    // 自動モード
    private var autoEnabled  = false
    private var autoStrength = 1
    private var autoTimer: Timer?
    private var brightnessPollTimer: Timer?
    private var lastSysBrightness: Double = -1

    // アニメーション
    private var animTimer: Timer?
    private var animStartB: Double=1.0, animStartW: Double=0.0
    private var animTargetB: Double=1.0, animTargetW: Double=0.0
    private var animStep=0; private let animSteps=30

    // 統計
    private var stats = DailyStats(date: todayString())
    private var statsTimer: Timer?
    private var lastStatTick = Date()

    // ホットキー
    private var hotKeyHandler: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef?] = []

    // UI refs
    private var statusItem: NSStatusItem!
    private var brightnessSlider: NSSlider!
    private var warmthSlider: NSSlider!
    private var brightnessLabel: NSTextField!
    private var warmthLabel: NSTextField!
    private var scheduleToggleItem: NSMenuItem!
    private var autoToggleItem: NSMenuItem!
    private var autoStrengthItems: [NSMenuItem] = []
    private var statsItem: NSMenuItem!
    private var launchAtLoginItem: NSMenuItem!

    // MARK: 起動

    func applicationDidFinishLaunching(_ n: Notification) {
        let ud = UserDefaults.standard
        brightness      = ud.object(forKey:"brightness")   != nil ? clamp(ud.double(forKey:"brightness"),   0.25,1.0) : 1.0
        warmth          = ud.object(forKey:"warmth")       != nil ? clamp(ud.double(forKey:"warmth"),       0.0, 1.0) : 0.0
        scheduleEnabled = ud.bool(forKey:"scheduleEnabled")
        autoEnabled     = ud.bool(forKey:"autoEnabled")
        autoStrength    = ud.object(forKey:"autoStrength") != nil ? ud.integer(forKey:"autoStrength") : 1
        if let d=ud.data(forKey:"scheduleRules"),
           let r=try? JSONDecoder().decode([ScheduleRule].self, from:d) { rules=r }
        loadStats()

        setupStatusItem()
        applyGamma()
        updateStatusIcon()
        registerForReapply()
        setupGlobalHotKeys()
        startStatsTimer()

        if scheduleEnabled { startScheduleTimer(); checkSchedule() }
        if autoEnabled     { startAutoTimers();    applyAuto(animated:false) }
    }

    func applicationWillTerminate(_ n: Notification) {
        saveStats()
        CGDisplayRestoreColorSyncSettings()
    }

    // MARK: - メニュー

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.toolTip = "明るさ・ブルーライト調整"
        statusItem.menu = buildMenu()
        updateStatusIcon()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu(); menu.autoenablesItems = false

        let bi=NSMenuItem(); bi.view=sliderRow(label:brightnessText(), labelRef:&brightnessLabel,
            value:brightness, min:0.25, max:1.0, action:#selector(brightnessChanged(_:)), sliderRef:&brightnessSlider)
        menu.addItem(bi)
        let wi=NSMenuItem(); wi.view=sliderRow(label:warmthText(), labelRef:&warmthLabel,
            value:warmth, min:0.0, max:1.0, action:#selector(warmthChanged(_:)), sliderRef:&warmthSlider)
        menu.addItem(wi)

        menu.addItem(.separator())

        let presetValues: [(Double,Double)] = [(1.0,0.0),(0.9,0.2),(0.75,0.45),(0.6,0.65)]
        for (i,(b,w)) in presetValues.enumerated() {
            let name = i < s.presets.count ? s.presets[i] : ""
            let item=NSMenuItem(title:name, action:#selector(presetSelected(_:)), keyEquivalent:"")
            item.target=self; item.representedObject=[b,w]; item.isEnabled=true; menu.addItem(item)
        }

        menu.addItem(.separator())

        // 自動モード
        let at=NSMenuItem(title:autoTitle(), action:#selector(toggleAuto), keyEquivalent:"")
        at.target=self; at.isEnabled=true; menu.addItem(at); autoToggleItem=at
        autoStrengthItems.removeAll()
        for (i,label) in s.strengths.enumerated() {
            let item=NSMenuItem(title:label, action:#selector(setAutoStrength(_:)), keyEquivalent:"")
            item.target=self; item.tag=i; item.state=(i==autoStrength) ? .on:.off
            item.isEnabled=autoEnabled; menu.addItem(item); autoStrengthItems.append(item)
        }

        menu.addItem(.separator())

        // スケジュール
        let st=NSMenuItem(title:scheduleTitle(), action:#selector(toggleSchedule), keyEquivalent:"")
        st.target=self; st.isEnabled=true; menu.addItem(st); scheduleToggleItem=st
        let se=NSMenuItem(title:s.schedEdit, action:#selector(openScheduleWindow), keyEquivalent:"")
        se.target=self; se.isEnabled=true; menu.addItem(se)

        menu.addItem(.separator())

        // 今日の統計
        let si=NSMenuItem(title:statsText(), action:nil, keyEquivalent:"")
        si.isEnabled=false; menu.addItem(si); statsItem=si

        menu.addItem(.separator())

        // ログイン時に自動起動
        let li=NSMenuItem(title:launchAtLoginTitle(), action:#selector(toggleLaunchAtLogin), keyEquivalent:"")
        li.target=self; li.isEnabled=true; menu.addItem(li); launchAtLoginItem=li

        // 言語サブメニュー
        let langItem=NSMenuItem(title:s.langMenu, action:nil, keyEquivalent:"")
        let langSub=NSMenu(); langSub.autoenablesItems=false
        for code in langOrder {
            let name=langNames[code] ?? code
            let item=NSMenuItem(title:name, action:#selector(selectLanguage(_:)), keyEquivalent:"")
            item.target=self; item.representedObject=code
            item.state=(code==currentLang) ? .on:.off; item.isEnabled=true
            langSub.addItem(item)
        }
        langItem.submenu=langSub; langItem.isEnabled=true; menu.addItem(langItem)

        menu.addItem(.separator())
        let q=NSMenuItem(title:s.quit, action:#selector(quitApp), keyEquivalent:"q")
        q.target=self; q.isEnabled=true; menu.addItem(q)
        return menu
    }

    private func sliderRow(label:String, labelRef: inout NSTextField!,
                           value:Double, min:Double, max:Double,
                           action:Selector, sliderRef: inout NSSlider!) -> NSView {
        let v=NSView(frame:NSRect(x:0,y:0,width:240,height:52))
        let l=NSTextField(labelWithString:label)
        l.frame=NSRect(x:14,y:30,width:210,height:16); l.font = .systemFont(ofSize:12, weight:.medium)
        v.addSubview(l); labelRef=l
        let s=NSSlider(value:value, minValue:min, maxValue:max, target:self, action:action)
        s.frame=NSRect(x:14,y:8,width:212,height:20); s.isContinuous=true
        v.addSubview(s); sliderRef=s; return v
    }

    // MARK: - アイコン更新

    func updateStatusIcon() {
        // Icon history:
        // v1: "circle.lefthalf.filled"  ◑ 固定1種類
        // v2: "sun.max" / "sun.haze" / "moon"  状態で3種類
        // v3: "sun.max" / "sun.haze" / "moon" / "moon.zzz" / "wand.and.stars" 5種類
        // v4: moonphase 5段階（現在）- 調整量に応じて満月→新月
        let level = (1.0 - brightness) * 0.6 + warmth * 0.4
        let iconName: String
        switch level {
        case ..<0.12: iconName = "moonphase.full.moon"
        case ..<0.30: iconName = "moonphase.waxing.gibbous"
        case ..<0.50: iconName = "moonphase.first.quarter"
        case ..<0.70: iconName = "moonphase.waxing.crescent"
        default:      iconName = "moonphase.new.moon"
        }
        if let img = NSImage(systemSymbolName:iconName, accessibilityDescription:nil) {
            img.isTemplate = true
            statusItem.button?.image = img
        }
    }

    // MARK: - スライダー・プリセット

    @objc private func brightnessChanged(_ s:NSSlider) {
        cancelAnimation(); disableAutoMode()
        brightness=s.doubleValue; brightnessLabel.stringValue=brightnessText()
        applyGamma(); updateStatusIcon(); save()
    }
    @objc private func warmthChanged(_ s:NSSlider) {
        cancelAnimation(); disableAutoMode()
        warmth=s.doubleValue; warmthLabel.stringValue=warmthText()
        applyGamma(); updateStatusIcon(); save()
    }
    @objc private func presetSelected(_ sender:NSMenuItem) {
        guard let v=sender.representedObject as? [Double], v.count==2 else { return }
        cancelAnimation(); disableAutoMode()
        applyInstant(brightness:v[0], warmth:v[1])
    }

    func applyInstant(brightness b:Double, warmth w:Double) {
        brightness=b; warmth=w
        brightnessSlider?.doubleValue=b; warmthSlider?.doubleValue=w
        brightnessLabel?.stringValue=brightnessText(); warmthLabel?.stringValue=warmthText()
        applyGamma(); updateStatusIcon(); save()
    }

    private func animateTo(brightness targetB:Double, warmth targetW:Double) {
        guard abs(targetB-brightness)>0.005 || abs(targetW-warmth)>0.005 else { return }
        cancelAnimation()
        animStartB=brightness; animStartW=warmth; animTargetB=targetB; animTargetW=targetW; animStep=0
        animTimer=Timer.scheduledTimer(withTimeInterval:0.8/Double(animSteps), repeats:true) { [weak self] _ in
            self?.animationTick()
        }
        RunLoop.main.add(animTimer!, forMode:.common)
    }

    @objc private func animationTick() {
        animStep+=1
        let t=Double(animStep)/Double(animSteps)
        let ease=t<0.5 ? 2*t*t : -1+(4-2*t)*t
        brightness=animStartB+(animTargetB-animStartB)*ease
        warmth=animStartW+(animTargetW-animStartW)*ease
        brightnessSlider?.doubleValue=brightness; warmthSlider?.doubleValue=warmth
        brightnessLabel?.stringValue=brightnessText(); warmthLabel?.stringValue=warmthText()
        applyGamma()
        if animStep>=animSteps { animTimer?.invalidate(); animTimer=nil; updateStatusIcon(); save() }
    }

    private func cancelAnimation() { animTimer?.invalidate(); animTimer=nil }

    @objc private func quitApp() { saveStats(); CGDisplayRestoreColorSyncSettings(); NSApp.terminate(nil) }
    private func brightnessText() -> String { "\(s.brightness): \(Int((brightness*100).rounded()))%" }
    private func warmthText()     -> String { "\(s.warmth): \(Int((warmth*100).rounded()))%" }
    private func save() { UserDefaults.standard.set(brightness,forKey:"brightness"); UserDefaults.standard.set(warmth,forKey:"warmth") }
    private func clamp(_ v:Double,_ lo:Double,_ hi:Double) -> Double { max(lo,min(hi,v)) }

    // MARK: - グローバルホットキー（Carbon）
    // ⌥⌘↑: 明るさ+10%  ⌥⌘↓: 明るさ-10%
    // ⌥⌘→: 暖かさ+10%  ⌥⌘←: 暖かさ-10%

    private func setupGlobalHotKeys() {
        var types=[EventTypeSpec(eventClass:OSType(kEventClassKeyboard),
                                 eventKind:OSType(kEventHotKeyPressed))]
        let selfPtr=UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        InstallEventHandler(GetApplicationEventTarget(), hotKeyEventCallback, 1, &types, selfPtr, &hotKeyHandler)

        let sig: FourCharCode = 0x57485054  // 'WHPT'
        let mods = UInt32(optionKey|cmdKey)
        let keys: [(UInt32,UInt32)] = [
            (UInt32(kVK_UpArrow),1), (UInt32(kVK_DownArrow),2),
            (UInt32(kVK_RightArrow),3), (UInt32(kVK_LeftArrow),4),
        ]
        for (key,id) in keys {
            var hkID=EventHotKeyID(signature:sig, id:id); var ref: EventHotKeyRef?
            RegisterEventHotKey(key, mods, hkID, GetApplicationEventTarget(), 0, &ref)
            hotKeyRefs.append(ref)
        }
    }

    func handleHotKey(id: UInt32) {
        cancelAnimation(); disableAutoMode()
        switch id {
        case 1: adjustBrightness(+0.1)
        case 2: adjustBrightness(-0.1)
        case 3: adjustWarmth(+0.1)
        case 4: adjustWarmth(-0.1)
        default: break
        }
    }

    private func adjustBrightness(_ delta:Double) {
        brightness=clamp(brightness+delta, 0.25, 1.0)
        brightnessSlider?.doubleValue=brightness; brightnessLabel?.stringValue=brightnessText()
        applyGamma(); updateStatusIcon(); save()
    }
    private func adjustWarmth(_ delta:Double) {
        warmth=clamp(warmth+delta, 0.0, 1.0)
        warmthSlider?.doubleValue=warmth; warmthLabel?.stringValue=warmthText()
        applyGamma(); updateStatusIcon(); save()
    }

    // MARK: - ログイン時に自動起動

    private func launchAtLoginTitle() -> String {
        if #available(macOS 13.0, *) {
            let on = SMAppService.mainApp.status == .enabled
            return on ? "✓ \(s.launchLogin)" : s.launchLogin
        }
        return s.launchLogin
    }

    // MARK: - 言語切り替え

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String else { return }
        currentLang = code
        UserDefaults.standard.set(code, forKey:"lang")
        // メニューを再構築して即反映
        statusItem.menu = buildMenu()
        // スライダーラベルも更新
        brightnessLabel?.stringValue = brightnessText()
        warmthLabel?.stringValue     = warmthText()
        statsItem?.title             = statsText()
    }

    @objc private func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            let svc = SMAppService.mainApp
            do {
                if svc.status == .enabled { try svc.unregister() }
                else                      { try svc.register()   }
            } catch {
                NSWorkspace.shared.open(URL(string:"x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!)
            }
            launchAtLoginItem?.title = launchAtLoginTitle()
        } else {
            NSWorkspace.shared.open(URL(string:"x-apple.systempreferences:com.apple.preferences.users")!)
        }
    }

    // MARK: - 今日の統計

    private func currentZone() -> String {
        if brightness < 0.65 || warmth > 0.55 { return "就寝前" }
        if brightness < 0.80 || warmth > 0.30 { return "夜" }
        if brightness < 0.93 || warmth > 0.12 { return "夕方" }
        return "昼"
    }

    private func startStatsTimer() {
        lastStatTick=Date()
        statsTimer=Timer.scheduledTimer(withTimeInterval:60, repeats:true) { [weak self] _ in self?.tickStats() }
        RunLoop.main.add(statsTimer!, forMode:.common)
    }

    @objc private func tickStats() {
        // 日付が変わったらリセット
        if stats.date != todayString() { saveStats(); stats=DailyStats(date:todayString()) }
        let elapsed=Date().timeIntervalSince(lastStatTick); lastStatTick=Date()
        switch currentZone() {
        case "夕方":   stats.夕方   += elapsed
        case "夜":     stats.夜     += elapsed
        case "就寝前": stats.就寝前 += elapsed
        default:       stats.昼     += elapsed
        }
        statsItem?.title=statsText()
        saveStats()
    }

    private func statsText() -> String {
        let secs = [stats.就寝前, stats.夜, stats.夕方, stats.昼]
        let names = s.zoneNames.reversed()  // [就寝前, 夜, 夕方, 昼] 順に
        let allNames = Array(names)
        let parts = zip(allNames, secs).filter { $0.1 >= 60 }.map { (name, sec) -> String in
            let h = Int(sec) / 3600; let m = (Int(sec) % 3600) / 60
            return h > 0 ? "\(name) \(h)h\(m)m" : "\(name) \(m)m"
        }
        return parts.isEmpty ? s.statsEmpty : s.statsPrefix + parts.joined(separator: " / ")
    }

    private func loadStats() {
        if let d=UserDefaults.standard.data(forKey:"dailyStats"),
           let s=try? JSONDecoder().decode(DailyStats.self, from:d),
           s.date==todayString() { stats=s }
    }

    private func saveStats() {
        if let d=try? JSONEncoder().encode(stats) { UserDefaults.standard.set(d, forKey:"dailyStats") }
    }

    // MARK: - 自動モード

    private func autoTitle()     -> String { autoEnabled     ? s.autoOn   : s.autoOff }
    private func scheduleTitle() -> String { scheduleEnabled ? s.schedOn  : s.schedOff }

    @objc private func toggleAuto() {
        autoEnabled.toggle(); UserDefaults.standard.set(autoEnabled, forKey:"autoEnabled")
        autoToggleItem.title=autoTitle(); autoStrengthItems.forEach { $0.isEnabled=autoEnabled }
        if autoEnabled { lastSysBrightness = -1; startAutoTimers(); applyAuto(animated:true) }
        else           { stopAutoTimers(); updateStatusIcon() }
    }

    @objc private func setAutoStrength(_ sender:NSMenuItem) {
        autoStrength=sender.tag; UserDefaults.standard.set(autoStrength, forKey:"autoStrength")
        autoStrengthItems.forEach { $0.state=($0.tag==autoStrength) ? .on:.off }
        if autoEnabled { applyAuto(animated:true) }
    }

    private func disableAutoMode() {
        guard autoEnabled else { return }
        autoEnabled=false; stopAutoTimers()
        autoToggleItem?.title=autoTitle(); autoStrengthItems.forEach { $0.isEnabled=false }
        UserDefaults.standard.set(false, forKey:"autoEnabled")
        updateStatusIcon()
    }

    private func startAutoTimers() {
        autoTimer?.invalidate()
        autoTimer=Timer.scheduledTimer(withTimeInterval:300, repeats:true) { [weak self] _ in self?.applyAuto(animated:true) }
        RunLoop.main.add(autoTimer!, forMode:.common)
        brightnessPollTimer?.invalidate()
        brightnessPollTimer=Timer.scheduledTimer(withTimeInterval:1, repeats:true) { [weak self] _ in self?.pollBrightness() }
        RunLoop.main.add(brightnessPollTimer!, forMode:.common)
    }

    private func stopAutoTimers() { autoTimer?.invalidate(); autoTimer=nil; brightnessPollTimer?.invalidate(); brightnessPollTimer=nil }

    @objc private func pollBrightness() {
        guard autoEnabled else { return }
        let cur=readSystemBrightness()
        if abs(cur-lastSysBrightness) >= 0.04 { lastSysBrightness=cur; applyAuto(animated:true) }
    }

    func applyAuto(animated:Bool) {
        guard autoEnabled else { return }
        let cal=Calendar.current; let now=Date()
        let t=Double(cal.component(.hour,from:now))+Double(cal.component(.minute,from:now))/60.0
        let timeW: Double
        switch t {
        case 6..<17:  timeW=0.0
        case 17..<20: timeW=lerp(0.0,0.5,(t-17)/3)
        case 20..<22: timeW=lerp(0.5,0.7,(t-20)/2)
        default:      timeW=0.7
        }
        let timeB: Double
        switch t {
        case 6..<17:  timeB=1.0
        case 17..<20: timeB=lerp(1.0,0.82,(t-17)/3)
        case 20..<22: timeB=lerp(0.82,0.68,(t-20)/2)
        default:      timeB=0.68
        }
        let sys=readSystemBrightness(); lastSysBrightness=sys
        let weber=0.5+0.5*sys
        let scale=[0.45,0.70,1.0][max(0,min(2,autoStrength))]
        let finalW=clamp(timeW*weber*scale, 0.0, 1.0)
        let finalB=clamp(1.0-(1.0-timeB)*scale, 0.35, 1.0)
        if animated { animateTo(brightness:finalB, warmth:finalW) }
        else        { applyInstant(brightness:finalB, warmth:finalW) }
    }

    private func lerp(_ a:Double,_ b:Double,_ t:Double) -> Double { a+(b-a)*max(0,min(1,t)) }

    // MARK: - スケジュール

    @objc private func toggleSchedule() {
        scheduleEnabled.toggle(); UserDefaults.standard.set(scheduleEnabled, forKey:"scheduleEnabled")
        scheduleToggleItem.title=scheduleTitle()
        if scheduleEnabled { startScheduleTimer(); checkSchedule() } else { stopScheduleTimer() }
    }

    @objc private func openScheduleWindow() {
        scheduleWindowCtrl=ScheduleWindowController(rules:rules) { [weak self] updated in
            guard let self=self else { return }
            self.rules=updated
            if let d=try? JSONEncoder().encode(updated) { UserDefaults.standard.set(d, forKey:"scheduleRules") }
            if self.scheduleEnabled { self.checkSchedule() }
        }
        scheduleWindowCtrl?.showWindow(nil); NSApp.activate(ignoringOtherApps:true)
    }

    private func startScheduleTimer() {
        scheduleTimer?.invalidate()
        var c=Calendar.current.dateComponents([.year,.month,.day,.hour,.minute],from:Date())
        c.minute=(c.minute ?? 0)+1; c.second=0
        let next=Calendar.current.date(from:c) ?? Date().addingTimeInterval(60)
        let t=Timer(fireAt:next, interval:60, target:self, selector:#selector(checkSchedule), userInfo:nil, repeats:true)
        RunLoop.main.add(t, forMode:.common); scheduleTimer=t
    }
    private func stopScheduleTimer() { scheduleTimer?.invalidate(); scheduleTimer=nil }

    @objc func checkSchedule() {
        guard scheduleEnabled else { return }
        let cal=Calendar.current; let now=Date()
        let nm=cal.component(.hour,from:now)*60+cal.component(.minute,from:now)
        if let r=rules.filter({$0.enabled && $0.hour*60+$0.minute<=nm}).max(by:{$0.hour*60+$0.minute < $1.hour*60+$1.minute}) {
            applyInstant(brightness:r.brightness, warmth:r.warmth)
        }
    }

    // MARK: - ガンマ適用

    func applyGamma() {
        var count:UInt32=0; CGGetActiveDisplayList(0,nil,&count)
        guard count>0 else { return }
        var displays=[CGDirectDisplayID](repeating:0, count:Int(count))
        CGGetActiveDisplayList(count,&displays,&count)
        let r=CGGammaValue(brightness)
        let g=CGGammaValue(brightness*(1.0-0.10*warmth))
        let b=CGGammaValue(brightness*(1.0-0.40*warmth))
        for d in displays { CGSetDisplayTransferByFormula(d,0,r,1,0,g,1,0,b,1) }
    }

    // MARK: - スリープ復帰・ディスプレイ変更

    private func registerForReapply() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector:#selector(reapplySoon), name:NSWorkspace.didWakeNotification, object:nil)
        CGDisplayRegisterReconfigurationCallback(displayReconfigCallback,
                                                 Unmanaged.passUnretained(self).toOpaque())
    }
    @objc private func reapplySoon() {
        DispatchQueue.main.asyncAfter(deadline:.now()+0.5) { [weak self] in self?.applyGamma() }
    }
}

// MARK: - グローバル C コールバック

private func hotKeyEventCallback(
    _ handler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event=event, let userData=userData else { return OSStatus(eventNotHandledErr) }
    var keyID=EventHotKeyID()
    GetEventParameter(event, EventParamName(kEventParamDirectObject),
                      EventParamType(typeEventHotKeyID), nil,
                      MemoryLayout<EventHotKeyID>.size, nil, &keyID)
    let c=Unmanaged<AppController>.fromOpaque(userData).takeUnretainedValue()
    DispatchQueue.main.async { c.handleHotKey(id: keyID.id) }
    return noErr
}

private func displayReconfigCallback(
    _ display: CGDirectDisplayID,
    _ flags: CGDisplayChangeSummaryFlags,
    _ userInfo: UnsafeMutableRawPointer?
) {
    guard let p=userInfo else { return }
    let c=Unmanaged<AppController>.fromOpaque(p).takeUnretainedValue()
    DispatchQueue.main.asyncAfter(deadline:.now()+0.5) { c.applyGamma() }
}

// MARK: - エントリーポイント

let app=NSApplication.shared
let delegate=AppController()
app.delegate=delegate
app.setActivationPolicy(.accessory)
app.run()
