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

public class ConfigurationsWindowController: NSWindowController
{
    @objc public private( set ) var configurations: [ Configuration ] = []

    @IBOutlet private var arrayController: NSArrayController!

    private var configurationWindowController: ConfigurationWindowController?

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
        "ConfigurationsWindowController"
    }

    public override func windowDidLoad()
    {
        super.windowDidLoad()

        self.arrayController.sortDescriptors = [ NSSortDescriptor( key: "name", ascending: true ) ]

        self.reload()
    }

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

        controller.configuration           = configuration
        self.configurationWindowController = controller

        window.beginSheet( sheet )
        {
            if $0 == .OK
            {
                Preferences.shared.configurations = self.arrayController.content as? [ Configuration ] ?? []
            }
        }
    }
}
