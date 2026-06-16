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

/// Window controller listing the stored formatter configurations and letting
/// the user add, edit, and remove them.
///
/// Edits are made through a modal ``ConfigurationWindowController`` sheet, and
/// changes are written back to ``Preferences``.
public class ConfigurationsWindowController: NSWindowController
{
    /// Backing list of configurations exposed for binding. KVO-observable.
    @objc public private( set ) var configurations: [ Configuration ] = []

    /// Array controller backing the configurations table.
    @IBOutlet private var arrayController: NSArrayController!

    /// Strong reference to the currently presented add/edit sheet controller,
    /// retained while its sheet is open.
    private var configurationWindowController: ConfigurationWindowController?

    /// Creates the controller with no preloaded window.
    public init()
    {
        super.init( window: nil )
    }

    /// Not supported; this controller is not restored from a coder.
    ///
    /// - Parameter coder: The unarchiver (unused).
    /// - Returns: Always `nil`.
    required init?( coder: NSCoder )
    {
        nil
    }

    /// Name of the nib that backs this window controller.
    public override var windowNibName: NSNib.Name?
    {
        "ConfigurationsWindowController"
    }

    /// Configures the table's ascending-by-name sort and loads the stored
    /// configurations once the window has loaded.
    public override func windowDidLoad()
    {
        super.windowDidLoad()

        self.arrayController.sortDescriptors = [ NSSortDescriptor( key: "name", ascending: true ) ]

        self.reload()
    }

    /// Replaces the table's contents with the configurations currently stored
    /// in ``Preferences``.
    public func reload()
    {
        if let content = self.arrayController.content as? [ Any ]
        {
            self.arrayController.remove( contentsOf: content )
        }

        Preferences.shared.configurations.forEach
        {
            self.arrayController.addObject( $0 )
        }
    }

    /// Presents a sheet to create a new configuration and, if confirmed, adds
    /// it to the table and persists the updated list.
    ///
    /// - Parameter sender: The control that triggered the action.
    @IBAction
    private func new( _ sender: Any? )
    {
        let controller = ConfigurationWindowController()

        guard let window        = self.window,
              let sheet         = controller.window
        else
        {
            NSSound.beep()

            return
        }

        self.configurationWindowController = controller

        window.beginSheet( sheet )
        {
            if $0 == .OK, let configuration = controller.configuration
            {
                self.arrayController.addObject( configuration )

                Preferences.shared.configurations = self.arrayController.content as? [ Configuration ] ?? []
            }
        }
    }

    /// Removes the selected configuration from the table and persists the
    /// updated list, beeping if there is no selection.
    ///
    /// - Parameter sender: The control that triggered the action.
    @IBAction
    private func remove( _ sender: Any? )
    {
        guard let configuration = self.arrayController.selectedObjects.first as? Configuration
        else
        {
            NSSound.beep()

            return
        }

        self.arrayController.removeObject( configuration )

        Preferences.shared.configurations = self.arrayController.content as? [ Configuration ] ?? []
    }

    /// Presents a sheet to edit the selected configuration and, if confirmed,
    /// persists the changes.
    ///
    /// Because the persisted selection is a separate decoded snapshot, it is
    /// re-synced after the edit when the edited row was the selected one, so the
    /// extension picks up the new URLs.
    ///
    /// - Parameter sender: The control that triggered the action.
    @IBAction
    private func edit( _ sender: Any? )
    {
        let controller = ConfigurationWindowController()

        guard let configuration = self.arrayController.selectedObjects.first as? Configuration,
              let window        = self.window,
              let sheet         = controller.window
        else
        {
            NSSound.beep()

            return
        }

        // Capture whether this row is the persisted selection *before* the sheet
        // edits the object in place. selectedConfiguration is a separate decoded
        // snapshot, so without re-syncing it would keep the pre-edit URLs.
        let wasSelected = Preferences.shared.selectedConfiguration.map { configuration.isEqual( $0 ) } ?? false

        controller.configuration           = configuration
        self.configurationWindowController = controller

        window.beginSheet( sheet )
        {
            if $0 == .OK
            {
                Preferences.shared.configurations = self.arrayController.content as? [ Configuration ] ?? []

                if wasSelected
                {
                    Preferences.shared.selectedConfiguration = configuration
                }
            }
        }
    }
}
