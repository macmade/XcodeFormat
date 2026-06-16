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

/// Window controller for the "About" panel, displaying the app's name,
/// version, and copyright pulled from the main bundle's `Info.plist`.
public class AboutWindowController: NSWindowController
{
    /// App name, bound to the window; populated on load. KVO-observable.
    @objc private dynamic var name:      String?

    /// Human-readable version string, bound to the window. KVO-observable.
    @objc private dynamic var version:   String?

    /// Copyright notice, bound to the window. KVO-observable.
    @objc private dynamic var copyright: String?

    /// Name of the nib that backs this window controller.
    public override var windowNibName: NSNib.Name?
    {
        return "AboutWindowController"
    }

    /// Populates the displayed name, version, and copyright from the main
    /// bundle once the window has loaded.
    public override func windowDidLoad()
    {
        super.windowDidLoad()

        self.version   = Bundle.main.humanReadableVersion
        self.name      = Bundle.main.bundleName
        self.copyright = Bundle.main.humanReadableCopyright
    }
}
