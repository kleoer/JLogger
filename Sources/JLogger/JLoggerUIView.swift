#if canImport(UIKit)
import Combine
import UIKit

public final class JLoggerUIView: UIView {
    private static weak var currentView: JLoggerUIView?
    private static var pendingShowWorkItem: DispatchWorkItem?

    public static func show(_ window: UIWindow? = nil) {
        DispatchQueue.main.async {
            let targetWindow = window ?? resolveWindow()
            guard let targetWindow else {
                pendingShowWorkItem?.cancel()
                let workItem = DispatchWorkItem {
                    show(window)
                }
                pendingShowWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem)
                return
            }

            pendingShowWorkItem?.cancel()
            pendingShowWorkItem = nil

            if let existingView = currentView {
                if existingView.superview !== targetWindow {
                    existingView.removeFromSuperview()
                    targetWindow.addSubview(existingView)
                    existingView.frame = targetWindow.bounds
                    existingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                }
                targetWindow.bringSubviewToFront(existingView)
                return
            }

            let loggerView = JLoggerUIView(frame: targetWindow.bounds)
            loggerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            targetWindow.addSubview(loggerView)
            targetWindow.bringSubviewToFront(loggerView)
            currentView = loggerView
        }
    }

    public static func hide() {
        DispatchQueue.main.async {
            pendingShowWorkItem?.cancel()
            pendingShowWorkItem = nil
            currentView?.removeFromSuperview()
            currentView = nil
        }
    }

    private static func resolveWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows)
            .first
    }

    private let logger = JLogger.shared
    private var cancellables = Set<AnyCancellable>()
    private var dragStartCenter: CGPoint = .zero
    private let miniSize = CGSize(width: 60, height: 60)

    private lazy var floatingButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        button.layer.cornerRadius = miniSize.width / 2
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        button.tintColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(toggleConsole), for: .touchUpInside)

        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(handleFloatingButtonDrag(_:)))
        button.addGestureRecognizer(dragGesture)
        return button
    }()

    private lazy var consoleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Console"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        return label
    }()

    private lazy var clearButton: UIButton = makeBarButton(systemName: "trash", action: #selector(clearLogs))
    private lazy var shareButton: UIButton = makeBarButton(systemName: "square.and.arrow.up", action: #selector(shareLogs))
    private lazy var minimizeButton: UIButton = makeBarButton(systemName: "minus", action: #selector(toggleConsole))

    private lazy var actionButtons: [UIButton] = [clearButton, shareButton, minimizeButton]

    private lazy var headerView: UIStackView = {
        let spacer = UIView()
        let actions = UIStackView(arrangedSubviews: actionButtons)
        actions.axis = .horizontal
        actions.alignment = .center
        actions.distribution = .fillEqually
        actions.spacing = 12

        let stack = UIStackView(arrangedSubviews: [titleLabel, spacer, actions])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        stack.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        return stack
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 52
        tableView.showsVerticalScrollIndicator = true
        tableView.register(LogCell.self, forCellReuseIdentifier: LogCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private lazy var floatingCenterXConstraint = floatingButton.centerXAnchor.constraint(equalTo: leadingAnchor, constant: defaultFloatingCenter.x)
    private lazy var floatingCenterYConstraint = floatingButton.centerYAnchor.constraint(equalTo: topAnchor, constant: defaultFloatingCenter.y)
    private lazy var consoleBottomConstraint = consoleView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)

    private var defaultFloatingCenter: CGPoint {
        let bounds = superview?.bounds ?? UIScreen.main.bounds
        return CGPoint(x: bounds.width - 50, y: bounds.height - 110)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        bindLogger()
        updateUI(isMinimized: logger.isMinimized)
        updateFloatingButtonTitle(logCount: logger.logs.count)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }
        floatingCenterXConstraint.constant = defaultFloatingCenter.x
        floatingCenterYConstraint.constant = defaultFloatingCenter.y
    }

    private func setupUI() {
        backgroundColor = .clear
        isUserInteractionEnabled = true

        addSubview(consoleView)
        addSubview(floatingButton)

        consoleView.addSubview(headerView)
        consoleView.addSubview(tableView)

        NSLayoutConstraint.activate([
            floatingButton.widthAnchor.constraint(equalToConstant: miniSize.width),
            floatingButton.heightAnchor.constraint(equalToConstant: miniSize.height),
            floatingCenterXConstraint,
            floatingCenterYConstraint,

            consoleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            consoleView.trailingAnchor.constraint(equalTo: trailingAnchor),
            consoleBottomConstraint,
            consoleView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5),

            headerView.topAnchor.constraint(equalTo: consoleView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: consoleView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: consoleView.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: consoleView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: consoleView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: consoleView.bottomAnchor)
        ])

        headerView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func bindLogger() {
        logger.$logs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] logs in
                guard let self else { return }
                self.updateFloatingButtonTitle(logCount: logs.count)
                self.tableView.reloadData()
                if !logs.isEmpty {
                    let lastRow = logs.count - 1
                    self.tableView.scrollToRow(at: IndexPath(row: lastRow, section: 0), at: .bottom, animated: true)
                }
            }
            .store(in: &cancellables)

        logger.$isMinimized
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isMinimized in
                self?.updateUI(isMinimized: isMinimized)
            }
            .store(in: &cancellables)
    }

    private func updateUI(isMinimized: Bool) {
        floatingButton.isHidden = !isMinimized
        consoleView.isHidden = isMinimized
        isUserInteractionEnabled = true
    }

    private func updateFloatingButtonTitle(logCount: Int) {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        floatingButton.setImage(UIImage(systemName: "terminal", withConfiguration: config), for: .normal)
        floatingButton.setTitle(" \(logCount)", for: .normal)
    }

    private func makeBarButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        button.layer.cornerRadius = 22
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.imageView?.contentMode = .scaleAspectFit
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc
    private func toggleConsole() {
        logger.isMinimized.toggle()
    }

    @objc
    private func clearLogs() {
        logger.clearLogs()
    }

    @objc
    private func shareLogs() {
        let content = logger.logs.map(formatLogEntry(_:)).joined(separator: "\n")
        guard !content.isEmpty else { return }
        let activity = UIActivityViewController(activityItems: [content], applicationActivities: nil)
        topViewController()?.present(activity, animated: true)
    }

    @objc
    private func handleFloatingButtonDrag(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            dragStartCenter = CGPoint(x: floatingCenterXConstraint.constant, y: floatingCenterYConstraint.constant)
        case .changed:
            let translation = gesture.translation(in: self)
            let bounds = self.bounds.insetBy(dx: miniSize.width / 2, dy: miniSize.height / 2)
            floatingCenterXConstraint.constant = min(max(dragStartCenter.x + translation.x, bounds.minX + miniSize.width / 2), bounds.maxX - miniSize.width / 2)
            floatingCenterYConstraint.constant = min(max(dragStartCenter.y + translation.y, bounds.minY + miniSize.height / 2), bounds.maxY - miniSize.height / 2)
        default:
            break
        }
    }

    private func formatLogEntry(_ entry: JLogger.LogEntry) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return "[\(entry.level)] \(dateFormatter.string(from: entry.timestamp)) \(entry.message)"
    }

    private func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? resolveRootViewController()
        if let nav = root as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = root?.presentedViewController {
            return topViewController(base: presented)
        }
        return root
    }

    private func resolveRootViewController() -> UIViewController? {
        if let windowScene = window?.windowScene {
            return windowScene.windows.first(where: \.isKeyWindow)?.rootViewController
                ?? windowScene.windows.first?.rootViewController
        }
        return Self.resolveWindow()?.rootViewController
    }
}

extension JLoggerUIView: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        logger.logs.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LogCell.reuseIdentifier, for: indexPath) as? LogCell else {
            return UITableViewCell()
        }
        cell.configure(with: logger.logs[indexPath.row], formatter: formatLogEntry(_:))
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIPasteboard.general.string = formatLogEntry(logger.logs[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

private final class LogCell: UITableViewCell {
    static let reuseIdentifier = "JLogger.LogCell"

    private let levelLabel = UILabel()
    private let timeLabel = UILabel()
    private let messageLabelView = UILabel()
    private let stackView = UIStackView()
    private let headerStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with entry: JLogger.LogEntry, formatter: (JLogger.LogEntry) -> String) {
        levelLabel.text = "[\(entry.level)]"
        levelLabel.textColor = levelColor(entry.level)
        levelLabel.backgroundColor = levelColor(entry.level).withAlphaComponent(0.2)
        timeLabel.text = Self.timeFormatter.string(from: entry.timestamp)
        messageLabelView.text = entry.message
        accessibilityLabel = formatter(entry)
    }

    private func setupUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.03)
        selectionStyle = .none

        levelLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        levelLabel.layer.cornerRadius = 4
        levelLabel.layer.masksToBounds = true
        levelLabel.textAlignment = .center

        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = .gray

        messageLabelView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        messageLabelView.textColor = .white
        messageLabelView.numberOfLines = 0

        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 8
        headerStack.addArrangedSubview(levelLabel)
        headerStack.addArrangedSubview(timeLabel)

        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(headerStack)
        stackView.addArrangedSubview(messageLabelView)

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    private func levelColor(_ level: String) -> UIColor {
        switch level.lowercased() {
        case "error":
            return .systemRed
        case "warning":
            return .systemOrange
        case "debug":
            return .systemPurple
        default:
            return .systemBlue
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
#endif
