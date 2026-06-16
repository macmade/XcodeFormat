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

/// Sheet controller for adding or editing a single ``Configuration``.
///
/// Presented modally by ``ConfigurationsWindowController``. It edits the name
/// and the two formatter URL strings, validates them on save, and surfaces
/// per-field error messages. On a successful save it updates the bound
/// ``configuration`` (or creates a new one) and ends the sheet with `.OK`.
public class ConfigurationWindowController: NSWindowController
{
    /// Edited configuration name; clears errors when changed.
    @objc public dynamic var name            = "" { didSet { self.resetErrors() } }

    /// Edited SwiftFormat URL string; clears errors when changed.
    @objc public dynamic var swiftFormat     = "" { didSet { self.resetErrors() } }

    /// Edited uncrustify URL string; clears errors when changed.
    @objc public dynamic var uncrustify      = "" { didSet { self.resetErrors() } }

    /// Validation message for the name field, or `nil` when valid.
    @objc public dynamic var nameError:        String?

    /// Validation message for the SwiftFormat URL field, or `nil` when valid.
    @objc public dynamic var swiftFormatError: String?

    /// Validation message for the uncrustify URL field, or `nil` when valid.
    @objc public dynamic var uncrustifyError:  String?

    /// Validation message not tied to a specific field, or `nil` when none.
    @objc public dynamic var otherError:       String?

    /// The configuration being edited.
    ///
    /// Setting it (e.g. for an edit) populates the editable fields from the
    /// configuration's values. `nil` means a new configuration is being created.
    @objc public dynamic var configuration:    Configuration?
    {
        didSet
        {
            self.name        = self.configuration?.name                        ?? ""
            self.swiftFormat = self.configuration?.swiftFormat?.absoluteString ?? ""
            self.uncrustify  = self.configuration?.uncrustify?.absoluteString  ?? ""
        }
    }

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
        "ConfigurationWindowController"
    }

    /// Called once the window has loaded; no additional setup is required.
    public override func windowDidLoad()
    {
        super.windowDidLoad()
    }

    /// Dismisses the sheet without saving, ending it with `.cancel`.
    ///
    /// - Parameter sender: The control that triggered the action.
    @IBAction
    private func cancel( _ sender: Any? )
    {
        guard let sheet  = self.window,
              let window = self.window?.sheetParent
        else
        {
            NSSound.beep()

            return
        }

        sheet.orderOut( nil )
        window.endSheet( sheet, returnCode: .cancel )
    }

    /// Validates the fields and, on success, applies them to the configuration
    /// before ending the sheet with `.OK`.
    ///
    /// Sets the relevant error message and returns without dismissing when the
    /// name is empty, both URLs are empty, or either URL fails
    /// ``configurationURL(from:)`` validation. On success it updates the
    /// existing ``configuration`` in place, or creates a new one when none was
    /// being edited.
    ///
    /// - Parameter sender: The control that triggered the action.
    @IBAction
    private func save( _ sender: Any? )
    {
        guard let sheet  = self.window,
              let window = self.window?.sheetParent
        else
        {
            NSSound.beep()

            return
        }

        if self.name.isEmpty
        {
            self.nameError = "Please enter a name"

            return
        }

        if self.swiftFormat.isEmpty, self.uncrustify.isEmpty
        {
            self.otherError = "Please enter at least one configuration URL"

            return
        }

        let swiftFormat: URL?
        let uncrustify:  URL?

        do
        {
            swiftFormat = try URL.configurationURL( from: self.swiftFormat )
        }
        catch
        {
            self.swiftFormatError = error.localizedDescription

            return
        }

        do
        {
            uncrustify = try URL.configurationURL( from: self.uncrustify )
        }
        catch
        {
            self.uncrustifyError = error.localizedDescription

            return
        }

        if let configuration = self.configuration
        {
            configuration.name        = self.name
            configuration.swiftFormat = swiftFormat
            configuration.uncrustify  = uncrustify
        }
        else
        {
            self.configuration = Configuration( name: self.name, swiftFormat: swiftFormat, uncrustify: uncrustify )
        }

        sheet.orderOut( nil )
        window.endSheet( sheet, returnCode: .OK )
    }

    /// Clears all field and general validation messages.
    private func resetErrors()
    {
        self.nameError        = nil
        self.swiftFormatError = nil
        self.uncrustifyError  = nil
        self.otherError       = nil
    }
}
