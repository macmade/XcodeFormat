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

/// Detail view controller showing a single ``Credit``'s description and the
/// full license text rendered in a text view.
public class CreditViewController: NSViewController
{
    /// The credit being displayed. KVO-observable.
    @objc public private( set ) dynamic var credit:      Credit

    /// The credit's license text styled for display, or `nil` if none.
    /// KVO-observable.
    @objc private               dynamic var licenseText: NSAttributedString?

    /// Text view that renders the license text.
    @IBOutlet private var textView: NSTextView!

    /// Creates the controller for a given credit.
    ///
    /// - Parameter credit: The credit to display.
    public init( credit: Credit )
    {
        self.credit = credit

        super.init( nibName: nil, bundle: nil )
    }

    /// Not supported; this controller is not restored from a coder.
    ///
    /// - Parameter coder: The unarchiver (unused).
    /// - Returns: Always `nil`.
    required init?( coder: NSCoder )
    {
        return nil
    }

    /// Name of the nib that backs this view controller.
    public override var nibName: NSNib.Name?
    {
        "CreditViewController"
    }

    /// Insets the text view and renders the credit's license text, if any, once
    /// the view has loaded.
    public override func viewDidLoad()
    {
        super.viewDidLoad()

        self.textView.textContainerInset = NSMakeSize( 10, 10 )

        if let text = self.credit.licenseText
        {
            self.licenseText = NSAttributedString( string: text, attributes: [ .foregroundColor: NSColor.textColor ] )
        }
    }

    /// Opens the credit's URL in the default browser, beeping if it has none.
    ///
    /// - Parameter sender: The control that triggered the action.
    @IBAction
    private func openURL( _ sender: Any? )
    {
        guard let url = self.credit.url
        else
        {
            NSSound.beep()

            return
        }

        NSWorkspace.shared.open( url )
    }
}
