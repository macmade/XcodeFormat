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

/// Window controller for the Preferences window.
///
/// The window's content is driven entirely by bindings in its nib (e.g. to the
/// application delegate's `displayActiveConfiguration` and `startAtLogin`), so
/// the controller itself only loads the nib.
public class PreferencesWindowController: NSWindowController
{
    /// Creates the controller with no preloaded window.
    public init()
    {
        super.init( window: nil )
    }

    /// Not supported; this controller is not restored from a coder.
    ///
    /// - Parameter coder: The unarchiver (unused).
    /// - Returns: Always `nil`.
    public required init?( coder: NSCoder )
    {
        nil
    }

    /// Name of the nib that backs this window controller.
    public override var windowNibName: NSNib.Name?
    {
        "PreferencesWindowController"
    }

    /// Called once the window has loaded; no additional setup is required.
    public override func windowDidLoad()
    {
        super.windowDidLoad()
    }
}
