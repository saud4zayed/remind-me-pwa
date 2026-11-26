import SwiftUI
import AVKit

@main struct EdgeApp: App {
    @StateObject var model = EdgeModel()
    var body: some Scene { WindowGroup { EdgeScreen().environmentObject(model) } }
}

struct EdgeScreen: View {
    @EnvironmentObject var model: EdgeModel
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.03, green: 0.06, blue: 0.10),
                                     Color(red: 0.08, green: 0.13, blue: 0.20)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("REMIND ME · EDGE LAB").font(.caption).tracking(2).foregroundStyle(.cyan)
                    Text("Can iPhone hear the swipe?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("Try the same gestures INSIDE the app and in PiP over Home. We log which buttons and swipes reach our code.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.7))
                    SourcePanel(model: model).frame(height: 148)
                    HStack {
                        Button("START PiP") { model.start() }.buttonStyle(.borderedProminent)
                        Button("STOP PiP") { model.stop() }.buttonStyle(.bordered)
                    }
                    Text(model.status).font(.caption).foregroundStyle(.cyan)
                    Text("EVENT LOG").font(.caption).bold()
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(Array(model.events.enumerated()), id: \.offset) { _, event in
                            Text(event).font(.system(size: 11, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }.padding(12).background(.white.opacity(0.07),
                                            in: RoundedRectangle(cornerRadius: 12))
                    Text("Research only. Voice, reminders and confirmation are simulated. PiP is designed for video calls.")
                        .font(.caption2).foregroundStyle(.white.opacity(0.45))
                }.foregroundStyle(.white).padding(20)
            }
        }
    }
}

struct SourcePanel: UIViewRepresentable {
    @ObservedObject var model: EdgeModel
    func makeUIView(context: Context) -> UIView {
        let panel = TouchPanel(label: "IN APP") { [weak model] event in
            Task { @MainActor in model?.log(event) }
        }
        DispatchQueue.main.async { [weak model, weak panel] in
            if let panel { model?.attach(panel) }
        }
        return panel
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

final class TouchPanel: UIView {
    private let label: String
    private let logAction: (String)->Void
    private var phase=0
    private var expanded=false
    private let heading=UILabel()
    private let bodyLabel=UILabel()
    private let expand=UIButton(type: .system)
    private let next=UIButton(type: .system)

    init(label: String, log: @escaping (String)->Void) {
        self.label=label
        self.logAction=log
        super.init(frame: .zero)
        backgroundColor=UIColor(red: 0.09, green: 0.14, blue: 0.23, alpha: 1)
        layer.cornerRadius=16
        heading.font = .systemFont(ofSize: 12, weight: .bold)
        heading.textColor = .white
        bodyLabel.font = .systemFont(ofSize: 12)
        bodyLabel.textColor = UIColor(white: 0.88, alpha: 1)
        bodyLabel.numberOfLines=3
        expand.setTitle("⌄ MORE", for: .normal)
        next.setTitle("● NEXT", for: .normal)
        for b in [expand, next] {
            b.tintColor = .white
            b.backgroundColor=UIColor(red: 0.19, green: 0.34, blue: 0.59, alpha: 1)
            b.layer.cornerRadius=8
        }
        expand.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
        next.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        let actions=UIStackView(arrangedSubviews: [expand,next])
        actions.axis = .horizontal
        actions.distribution = .fillEqually
        actions.spacing=8
        let stack=UIStackView(arrangedSubviews: [heading,bodyLabel,actions])
        stack.axis = .vertical
        stack.spacing=6
        stack.translatesAutoresizingMaskIntoConstraints=false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        let pan=UIPanGestureRecognizer(target: self, action: #selector(swiped(_:)))
        pan.cancelsTouchesInView=false
        addGestureRecognizer(pan)
        refresh()
    }
    required init?(coder: NSCoder) { fatalError("Not supported") }

    private func refresh() {
        switch phase {
        case 0:
            heading.text="01 · QUICK GLANCE · "+label
            bodyLabel.text=expanded ? "10:00 Clinic\n11:30 Ahmed\n15:00 Meeting" :
                                      "10:00 Clinic\n11:30 Ahmed"
            expand.isHidden=false
        case 1:
            heading.text="02 · VOICE (SIMULATED)"
            bodyLabel.text="▂▇▃▅▂ · Voice bar preview"
            expand.isHidden=true
        default:
            heading.text="03 · CONFIRM (SIMULATED)"
            bodyLabel.text="Meet Ahmed · Tomorrow · 10:00"
            expand.isHidden=true
        }
    }
    @objc private func swiped(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let x=Int(gesture.translation(in: self).x)
        guard abs(x) > 40 else { return }
        phase=(phase+1)%3
        logAction(label+" SWIPE dx="+String(x)+" phase="+String(phase))
        refresh()
    }
    @objc private func moreTapped() {
        expanded.toggle()
        logAction(label+" EXPAND tapped")
        refresh()
    }
    @objc private func nextTapped() {
        phase=(phase+1)%3
        logAction(label+" BUTTON tapped phase="+String(phase))
        refresh()
    }
}

@MainActor
final class EdgeModel: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
    @Published var events: [String]=[]
    @Published var status="Preparing source ..."
    private var controller: AVPictureInPictureController?
    private var videoContent: AVPictureInPictureVideoCallViewController?
    private var possibleObservation: NSKeyValueObservation?

    func log(_ line: String) {
        let time=DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        events.insert(time+" · "+line, at: 0)
        if events.count>50 { events.removeLast() }
    }
    func attach(_ source: UIView) {
        guard controller == nil else { return }
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            status="PiP unsupported on this device"; return
        }
        let content=AVPictureInPictureVideoCallViewController()
        content.preferredContentSize=CGSize(width: 320, height: 150)
        content.view.backgroundColor = .clear
        let floating=TouchPanel(label: "PIP") { [weak self] event in
            Task { @MainActor in self?.log(event) }
        }
        floating.translatesAutoresizingMaskIntoConstraints=false
        content.view.addSubview(floating)
        NSLayoutConstraint.activate([
            floating.leadingAnchor.constraint(equalTo: content.view.leadingAnchor),
            floating.trailingAnchor.constraint(equalTo: content.view.trailingAnchor),
            floating.topAnchor.constraint(equalTo: content.view.topAnchor),
            floating.bottomAnchor.constraint(equalTo: content.view.bottomAnchor)
        ])
        let src=AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: source, contentViewController: content)
        let c=AVPictureInPictureController(contentSource: src)
        c.delegate=self
        c.canStartPictureInPictureAutomaticallyFromInline=false
        controller=c
        videoContent=content
        possibleObservation=c.observe(\.isPictureInPicturePossible, options: [.initial,.new]) {
            [weak self] observed, _ in
            let possible=observed.isPictureInPicturePossible
            Task { @MainActor in self?.status=possible ? "PiP ready" : "PiP not possible yet" }
        }
        log("Source attached; test controls INSIDE APP first")
    }
    func start() {
        guard let c=controller, c.isPictureInPicturePossible else {
            log("PiP start unavailable"); return
        }
        log("START requested")
        c.startPictureInPicture()
    }
    func stop() { controller?.stopPictureInPicture(); log("STOP requested") }
    func pictureInPictureControllerDidStartPictureInPicture(_ c: AVPictureInPictureController) {
        status="PiP running — test Home"
        log("PIP STARTED")
    }
    func pictureInPictureControllerDidStopPictureInPicture(_ c: AVPictureInPictureController) {
        status="PiP stopped"; log("PIP STOPPED")
    }
    func pictureInPictureController(_ c: AVPictureInPictureController,
                                   failedToStartPictureInPictureWithError error: Error) {
        status="PiP failed"
        log("PIP ERROR "+error.localizedDescription)
    }
    func pictureInPictureController(_ c: AVPictureInPictureController,
                                   restoreUserInterfaceForPictureInPictureStopWithCompletionHandler done: @escaping (Bool)->Void) {
        done(true)
    }
}
