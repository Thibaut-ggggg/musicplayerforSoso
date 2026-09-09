import AppKit
import SwiftUI

/// A borderless, Nano-shaped window. Operates either as a floating panel
/// (always on top, joins all spaces) or as a regular window pinned to one
/// Mission Control space.
final class NanoPanel: NSPanel {
    private var shadowPanel: NanoShadowPanel?

    init<Content: View>(rootView: Content, size: CGSize, mode: WindowMode) {
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.hasShadow = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.titlebarAppearsTransparent = true
        self.isMovable = true
        self.isMovableByWindowBackground = true
        self.titleVisibility = .hidden
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true

        let hosting = NSHostingView(rootView: rootView)
        hosting.frame = NSRect(origin: .zero, size: size)
        hosting.autoresizingMask = [.width, .height]
        self.contentView = hosting
        self.setContentSize(size)

        apply(mode: mode)

        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let origin = NSPoint(
                x: visible.maxX - size.width - 32,
                y: visible.maxY - size.height - 32
            )
            self.setFrameOrigin(origin)
        }
    }

    func apply(mode: WindowMode) {
        switch mode {
        case .floating:
            self.isFloatingPanel = true
            self.level = .floating
            self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        case .window:
            self.isFloatingPanel = false
            self.level = .normal
            self.collectionBehavior = [.managed, .participatesInCycle]
        }
        shadowPanel?.apply(mode: mode)
    }

    func attachShadowPanel(_ shadowPanel: NanoShadowPanel) {
        let margin = NanoMetrics.shadowMargin
        shadowPanel.setFrameOrigin(NSPoint(
            x: frame.minX - margin,
            y: frame.minY - margin
        ))
        addChildWindow(shadowPanel, ordered: .below)
        self.shadowPanel = shadowPanel
    }

    func apply(shell: ShellStyle) {
        guard frame.size != shell.size else { return }

        // Keep the top-right corner in place when switching device shapes.
        var newFrame = NSRect(
            x: frame.maxX - shell.size.width,
            y: frame.maxY - shell.size.height,
            width: shell.size.width,
            height: shell.size.height
        )
        if let visible = screen?.visibleFrame {
            newFrame.origin.x = max(visible.minX, min(newFrame.minX, visible.maxX - newFrame.width))
            newFrame.origin.y = max(visible.minY, min(newFrame.minY, visible.maxY - newFrame.height))
        }
        setFrame(newFrame, display: true)

        let margin = NanoMetrics.shadowMargin
        shadowPanel?.setFrame(NSRect(
            x: newFrame.minX - margin,
            y: newFrame.minY - margin,
            width: shell.shadowSize.width,
            height: shell.shadowSize.height
        ), display: true)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// A click-through child window that carries the visual shadow without
/// participating in the parent window's screen-edge constraints.
final class NanoShadowPanel: NSPanel {
    init<Content: View>(rootView: Content, size: CGSize, mode: WindowMode) {
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.hasShadow = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true

        let hosting = NSHostingView(rootView: rootView)
        hosting.frame = NSRect(origin: .zero, size: size)
        hosting.autoresizingMask = [.width, .height]
        self.contentView = hosting
        self.setContentSize(size)

        apply(mode: mode)
    }

    func apply(mode: WindowMode) {
        switch mode {
        case .floating:
            self.level = .floating
            self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        case .window:
            self.level = .normal
            self.collectionBehavior = [.managed, .participatesInCycle]
        }
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
