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

@main
public class ApplicationDelegate: NSObject, NSApplicationDelegate
{
    private let aboutWindowController          = AboutWindowController()
    private let creditsWindowController        = CreditsWindowController()
    private let configurationsWindowController = ConfigurationsWindowController()

    @IBOutlet private var menu:    NSMenu!
    @IBOutlet private var updater: GitHubUpdater!

    private var downloadTimer:          Timer?
    private var statusItem:             NSStatusItem?
    private var configurationsObserver: NSKeyValueObservation?

    @objc public dynamic var startAtLogin = NSApp.isLoginItemEnabled()
    {
        didSet
        {
            NSApp.setLoginItemEnabled( self.startAtLogin )
        }
    }

    public func applicationDidFinishLaunching( _ notification: Notification )
    {
        self.statusItem                        = NSStatusBar.system.statusItem( withLength: NSStatusItem.squareLength )
        self.statusItem?.button?.image         = NSImage( systemSymbolName: "curlybraces", accessibilityDescription: nil )
        self.statusItem?.button?.imagePosition = .imageLeading
        self.statusItem?.menu                  = self.menu

        self.configurationsObserver = Preferences.shared.observe( \.configurations )
        {
            [ weak self ] _, _ in self?.rebuildMenu()
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

    public func applicationWillTerminate( _ notification: Notification )
    {
        self.downloadTimer?.invalidate()
    }

    public func applicationShouldTerminateAfterLastWindowClosed( _ sender: NSApplication ) -> Bool
    {
        false
    }

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

        Preferences.shared.configurations.sorted
        {
            $0.name > $1.name
        }
        .forEach
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

            items.insert( item, at: 0 )
        }

        self.menu.items = items
    }

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
