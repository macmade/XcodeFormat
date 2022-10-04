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

public class ConfigurationWindowController: NSWindowController
{
    @objc public dynamic var name         = ""
    @objc public dynamic var swiftFormat  = ""
    @objc public dynamic var uncrustify   = ""
    @objc public dynamic var configuration: Configuration?
    {
        didSet
        {
            self.name        = self.configuration?.name                       ?? ""
            self.swiftFormat = self.configuration?.swiftFormat.absoluteString ?? ""
            self.uncrustify  = self.configuration?.uncrustify.absoluteString  ?? ""
        }
    }

    public init()
    {
        super.init( window: nil )
    }

    required init?( coder: NSCoder )
    {
        nil
    }

    public override var windowNibName: NSNib.Name?
    {
        "ConfigurationWindowController"
    }

    public override func windowDidLoad()
    {
        super.windowDidLoad()
    }

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

        guard self.name.isEmpty        == false,
              self.swiftFormat.isEmpty == false,
              self.uncrustify.isEmpty  == false
        else
        {
            let alert             = NSAlert()
            alert.messageText     = "Invalid Values"
            alert.informativeText = "Please enter a valid value for all fields."

            alert.addButton( withTitle: "OK" )
            alert.runModal()

            return
        }

        guard let swiftFormat = URL( string: self.swiftFormat ),
              let uncrustify  = URL( string: self.uncrustify )
        else
        {
            let alert             = NSAlert()
            alert.messageText     = "Invalid URLs"
            alert.informativeText = "Please enter valid URLs."

            alert.addButton( withTitle: "OK" )
            alert.runModal()

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
}
