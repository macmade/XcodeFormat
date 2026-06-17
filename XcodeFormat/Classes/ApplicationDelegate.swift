/*******************************************************************************
 * The MIT License (MIT)
 *
 * Copyright (c) 2022, Jean-David Gadina - www.xs-labs.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the Software), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

import Cocoa
import GitHubUpdates

/// The application delegate and menu-bar agent entry point.
///
/// Manages the status-bar item and its configuration menu, owns the auxiliary
/// windows (About, Credits, Configurations, Preferences), seeds and keeps the
/// stored configurations downloaded, installs the Automator Quick Action
/// workflow, and drives GitHub-based update checks.
///
/// - Note: The menu-bar app is **intentionally not sandboxed** (its entitlements
///   request no `com.apple.security.app-sandbox`). It registers a login item and
///   installs an Automator Quick Action into the user's Library, neither of which
///   is permitted under the App Sandbox, so the app is **not Mac App Store
///   distributable** by design. It also downloads formatter configurations from
///   remote URLs; those downloads are hardened (https-only, status-checked,
///   timed out, content-hash verified) in `Configuration`. This is a deliberate
///   trade-off, not an oversight.
@main
public class ApplicationDelegate: NSObject, NSApplicationDelegate
{
    /// Controller for the About window.
    private let aboutWindowController          = AboutWindowController()

    /// Controller for the Credits window.
    private let creditsWindowController        = CreditsWindowController()

    /// Controller for the Configurations management window.
    private let configurationsWindowController = ConfigurationsWindowController()

    /// Controller for the Preferences window.
    private let preferencesWindowController    = PreferencesWindowController()

    /// Menu shown by the status-bar item, loaded from the main nib.
    @IBOutlet private var menu:    NSMenu!

    /// GitHub-based updater that checks for and installs new releases.
    @IBOutlet private var updater: GitHubUpdater!

    /// Timer that periodically re-downloads the stored configurations.
    private var downloadTimer:                  Timer?

    /// The menu-bar status item, recreated whenever its style changes.
    private var statusItem:                     NSStatusItem?

    /// KVO token observing changes to the stored configuration list.
    private var configurationsObserver:         NSKeyValueObservation?

    /// KVO token observing changes to the selected configuration.
    private var selectedConfigurationsObserver: NSKeyValueObservation?

    /// Whether the status item shows the active configuration's name.
    ///
    /// Backed by `UserDefaults`; changing it persists the value and rebuilds
    /// the status item. KVO-observable for binding to the Preferences UI.
    @objc public dynamic var displayActiveConfiguration = UserDefaults.standard.bool( forKey: "displayActiveConfiguration" )
    {
        didSet
        {
            UserDefaults.standard.set( self.displayActiveConfiguration, forKey: "displayActiveConfiguration" )
            self.updateStatusItem()
        }
    }

    /// Whether the app launches automatically at login.
    ///
    /// Reflects and updates the login-item registration. KVO-observable for
    /// binding to the Preferences UI.
    @objc public dynamic var startAtLogin = NSApp.isLoginItemEnabled()
    {
        didSet
        {
            NSApp.setLoginItemEnabled( self.startAtLogin )
        }
    }

    /// Runs the command-line interface and exits, before any AppKit setup, when
    /// the process was started from a shell rather than by launchd.
    ///
    /// Apps launched through LaunchServices — a Finder double-click, `open`, or
    /// a login item — are reparented to launchd, so their parent process is
    /// PID 1; those keep running as the menu-bar app. When the bundle binary is
    /// executed directly from a terminal its parent is the invoking shell, so
    /// this process acts as a formatter CLI instead, even when no arguments are
    /// given. ``XcodeFormatCLI`` parses, runs, and self-exits on help or error;
    /// on success it returns and this method exits explicitly so the GUI never
    /// starts.
    ///
    /// - Parameter notification: The launch notification (unused).
    public func applicationWillFinishLaunching( _ notification: Notification )
    {
        let runFromXcode = ProcessInfo.processInfo.arguments.count > 1 && ProcessInfo.processInfo.arguments[ 1 ].hasPrefix( "-NS" )

        if getppid() == 1 || runFromXcode
        {
            return
        }

        XcodeFormatCLI.main( Array( CommandLine.arguments.dropFirst() ) )
        exit( EXIT_SUCCESS )
    }

    /// Performs first-launch setup once the app has finished launching.
    ///
    /// Builds the status item, observes configuration changes, seeds the
    /// default configurations if none exist, downloads all configurations,
    /// builds the menu, installs the Quick Action workflow, schedules a
    /// background update check, and starts the hourly re-download timer.
    ///
    /// - Parameter notification: The launch notification (unused).
    public func applicationDidFinishLaunching( _ notification: Notification )
    {
        self.updateStatusItem()

        self.configurationsObserver = Preferences.shared.observe( \.configurations )
        {
            [ weak self ] _, _ in self?.rebuildMenu()
        }

        self.selectedConfigurationsObserver = Preferences.shared.observe( \.selectedConfiguration )
        {
            [ weak self ] _, _ in self?.updateStatusItem()
        }

        if Preferences.shared.configurations.isEmpty
        {
            Preferences.shared.configurations        = Configuration.defaultConfigurations
            Preferences.shared.selectedConfiguration = Preferences.shared.configurations.first
        }

        Preferences.shared.configurations.forEach
        {
            $0.download()
        }

        self.rebuildMenu()
        self.installWorkflowIfNeeded()

        DispatchQueue.main.asyncAfter( deadline: .now() + .seconds( 2 ) )
        {
            self.updater.checkForUpdatesInBackground()
        }

        self.downloadTimer = Timer.scheduledTimer( withTimeInterval: 3600, repeats: true )
        {
            _ in Preferences.shared.configurations.forEach
            {
                $0.download()
            }
        }
    }

    /// Invalidates the periodic download timer as the app terminates.
    ///
    /// - Parameter notification: The termination notification (unused).
    public func applicationWillTerminate( _ notification: Notification )
    {
        self.downloadTimer?.invalidate()
    }

    /// Keeps the app running as a menu-bar agent after its last window closes.
    ///
    /// - Parameter sender: The application instance (unused).
    /// - Returns: Always `false` so closing windows does not quit the app.
    public func applicationShouldTerminateAfterLastWindowClosed( _ sender: NSApplication ) -> Bool
    {
        false
    }

    /// Rebuilds the menu-bar status item to match the current display setting.
    ///
    /// Removes any existing item, then creates a variable-length item titled
    /// with the selected configuration's name (when ``displayActiveConfiguration``
    /// is enabled) or a square icon-only item otherwise, and attaches the menu.
    private func updateStatusItem()
    {
        if let existing = self.statusItem
        {
            NSStatusBar.system.removeStatusItem( existing )
        }

        if self.displayActiveConfiguration
        {
            self.statusItem                = NSStatusBar.system.statusItem( withLength: NSStatusItem.variableLength )
            self.statusItem?.button?.title = Preferences.shared.selectedConfiguration?.name ?? "--"
            self.statusItem?.button?.font  = NSFont.systemFont( ofSize: 10 )
        }
        else
        {
            self.statusItem = NSStatusBar.system.statusItem( withLength: NSStatusItem.squareLength )
        }

        self.statusItem?.button?.image         = NSImage( systemSymbolName: "curlybraces", accessibilityDescription: nil )
        self.statusItem?.button?.imagePosition = .imageLeading
        self.statusItem?.menu                  = self.menu
    }

    /// Installs (or refreshes) the bundled Automator Quick Action workflow into
    /// the user's `Library/Services` folder.
    ///
    /// Copies the bundled workflow when it is missing, or when the installed
    /// copy's `document.wflow` differs (by content hash) from the bundled one.
    /// Does nothing when the two already match. Failures are silently ignored.
    private func installWorkflowIfNeeded()
    {
        guard let library   = NSSearchPathForDirectoriesInDomains( .libraryDirectory, .userDomainMask, true ).first,
              let workflow1 = Bundle.main.url( forResource: "XcodeFormat", withExtension: "workflow" )
        else
        {
            return
        }

        let workflow2 = URL( fileURLWithPath: library ).appendingPathComponent( "Services/XcodeFormat.workflow" )
        let wflow1    = workflow1.appendingPathComponent( "Contents/document.wflow" )
        let wflow2    = workflow2.appendingPathComponent( "Contents/document.wflow" )

        if FileManager.default.fileExists( atPath: workflow2.path )
        {
            if let sha1 = try? Data( contentsOf: wflow1 ).sha256,
               let sha2 = try? Data( contentsOf: wflow2 ).sha256,
               sha1 == sha2
            {
                return
            }
        }

        try? FileManager.default.copyItem( at: workflow1, to: workflow2 )
    }

    /// Rebuilds the configuration entries at the top of the status-bar menu.
    ///
    /// Preserves the menu's static items, then inserts one entry per stored
    /// configuration, sorted ascending by name to match the configurations
    /// window. The selected configuration is shown checked, bold, and with a
    /// filled icon; the others are dimmed.
    private func rebuildMenu()
    {
        var items = self.menu.items.filter
        {
            $0.representedObject is Configuration == false
        }

        let selected = Preferences.shared.selectedConfiguration
        let image    = NSImage( systemSymbolName: "curlybraces.square.fill", accessibilityDescription: nil )
        let fontOn   = NSFont.boldSystemFont( ofSize: NSFont.systemFontSize )
        let fontOff  = NSFont.systemFont( ofSize: NSFont.systemFontSize )
        let colorOn  = NSColor.labelColor
        let colorOff = NSColor.secondaryLabelColor
        let imageOn  = image?.withSymbolConfiguration( NSImage.SymbolConfiguration( hierarchicalColor: colorOn ) )
        let imageOff = image?.withSymbolConfiguration( NSImage.SymbolConfiguration( hierarchicalColor: colorOff ) )

        // Ascending by name, matching the configurations window's sort. The
        // items are inserted as a block at the top so the rendered order is the
        // ascending sort order.
        let configurationItems: [ NSMenuItem ] = Preferences.shared.configurations.sorted
        {
            $0.name < $1.name
        }
        .map
        {
            let item               = NSMenuItem( title: $0.name, action: #selector( self.selectConfiguration( _: ) ), keyEquivalent: "" )
            item.target            = self
            item.representedObject = $0

            if $0 == selected
            {
                item.state           = .on
                item.image           = imageOn
                item.attributedTitle = NSAttributedString( string: item.title, attributes: [ .font: fontOn, .foregroundColor: colorOn ] )
            }
            else
            {
                item.state           = .off
                item.image           = imageOff
                item.attributedTitle = NSAttributedString( string: item.title, attributes: [ .font: fontOff, .foregroundColor: colorOff ] )
            }

            return item
        }

        items.insert( contentsOf: configurationItems, at: 0 )

        self.menu.items = items
    }

    /// Menu action that selects, or toggles off, a configuration.
    ///
    /// Reads the `Configuration` from the sender's represented object; selects
    /// it, or clears the selection if it was already the selected one.
    ///
    /// - Parameter sender: The `NSMenuItem` that triggered the action.
    @objc
    private func selectConfiguration( _ sender: Any? )
    {
        guard let item          = sender as? NSMenuItem,
              let configuration = item.representedObject as? Configuration
        else
        {
            return
        }

        if Preferences.shared.selectedConfiguration == configuration
        {
            Preferences.shared.selectedConfiguration = nil
        }
        else
        {
            Preferences.shared.selectedConfiguration = configuration
        }
    }

    /// Activates the app and brings the About window to the front, centering it
    /// the first time it is shown.
    ///
    /// - Parameter sender: The control that triggered the action.
    @IBAction
    public func showAboutWindow( _ sender: Any? )
    {
        NSApp.activate( ignoringOtherApps: true )

        if self.aboutWindowController.window?.isVisible == false
        {
            self.aboutWindowController.window?.layoutIfNeeded()
            self.aboutWindowController.window?.center()
        }

        self.aboutWindowController.window?.makeKeyAndOrderFront( sender )
    }

    /// Activates the app and brings the Credits window to the front, centering
    /// it the first time it is shown.
    ///
    /// - Parameter sender: The control that triggered the action.
    @IBAction
    public func showCreditsWindow( _ sender: Any? )
    {
        NSApp.activate( ignoringOtherApps: true )

        if self.creditsWindowController.window?.isVisible == false
        {
            self.creditsWindowController.window?.layoutIfNeeded()
            self.creditsWindowController.window?.center()
        }

        self.creditsWindowController.window?.makeKeyAndOrderFront( sender )
    }

    /// Activates the app and brings the Configurations window to the front,
    /// centering it the first time it is shown.
    ///
    /// - Parameter sender: The control that triggered the action.
    @IBAction
    public func showConfigurationsWindow( _ sender: Any? )
    {
        NSApp.activate( ignoringOtherApps: true )

        if self.configurationsWindowController.window?.isVisible == false
        {
            self.configurationsWindowController.window?.layoutIfNeeded()
            self.configurationsWindowController.window?.center()
        }

        self.configurationsWindowController.window?.makeKeyAndOrderFront( sender )
    }

    /// Activates the app and brings the Preferences window to the front,
    /// centering it the first time it is shown.
    ///
    /// - Parameter sender: The control that triggered the action.
    @IBAction
    public func showPreferencesWindow( _ sender: Any? )
    {
        NSApp.activate( ignoringOtherApps: true )

        if self.preferencesWindowController.window?.isVisible == false
        {
            self.preferencesWindowController.window?.layoutIfNeeded()
            self.preferencesWindowController.window?.center()
        }

        self.preferencesWindowController.window?.makeKeyAndOrderFront( sender )
    }

    /// Re-downloads every stored configuration's formatter files into the
    /// shared cache.
    ///
    /// Triggers the same download path used at launch and by the hourly timer,
    /// overwriting the cached files. Safe to invoke repeatedly: each
    /// configuration's `download()` self-coalesces while a download is already
    /// in progress.
    ///
    /// - Parameter sender: The control that triggered the action.
    @IBAction
    public func reloadConfigurations( _ sender: Any? )
    {
        Preferences.shared.configurations.forEach
        {
            $0.download()
        }
    }

    /// Opens the project's GitHub page in the default browser, beeping if the
    /// URL cannot be constructed.
    ///
    /// - Parameter sender: The control that triggered the action.
    @IBAction
    public func showHelp( _ sender: Any? )
    {
        guard let url = URL( string: "https://github.com/macmade/XcodeFormat" )
        else
        {
            NSSound.beep()

            return
        }

        NSWorkspace.shared.open( url )
    }
}
