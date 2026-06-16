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

/// Window controller for the Credits window.
///
/// Shows a list of third-party ``Credit`` entries; selecting one embeds a
/// ``CreditViewController`` in the detail pane to display its license text.
public class CreditsWindowController: NSWindowController, NSTableViewDelegate, NSTableViewDataSource
{
    /// The credited projects shown in the list. KVO-observable.
    @objc private dynamic var items         = [ Credit ]()

    /// Detail view controller for the selected credit, or `nil` when none is
    /// selected. KVO-observable.
    @objc private dynamic var viewController: CreditViewController?

    /// Array controller backing the credits list.
    @IBOutlet private var arrayController: NSArrayController!

    /// The credits list table view.
    @IBOutlet private var tableView:       NSTableView!

    /// Container view that hosts the selected credit's detail view.
    @IBOutlet private var contentView:     NSView!

    /// KVO token observing the array controller's selection.
    private var selectionObserver: NSKeyValueObservation?

    /// Name of the nib that backs this window controller.
    public override var windowNibName: NSNib.Name
    {
        return "CreditsWindowController"
    }

    /// Populates the credits, observes the selection to swap in the matching
    /// detail view, and sorts the list by title once the window has loaded.
    public override func windowDidLoad()
    {
        super.windowDidLoad()

        self.items = [
            Credit(
                title:           "Uncrustify",
                abstract:        "Ben Gardner",
                descriptionText: "A source code beautifier for C, C++, C#, Objective-C, D, Java, Pawn and Vala.",
                url:             "https://github.com/uncrustify/uncrustify",
                license:         "GPL",
                licenseFile:     "License-Uncrustify"
            ),
            Credit(
                title:           "SwiftFormat",
                abstract:        "Nick Lockwood",
                descriptionText: "SwiftFormat is a code library and command-line tool for reformatting Swift code on macOS or Linux.",
                url:             "https://github.com/nicklockwood/SwiftFormat",
                license:         "MIT",
                licenseFile:     "License-SwiftFormat"
            ),
        ]

        self.selectionObserver = self.arrayController.observe( \.selection )
        {
            [ weak self ] o, c in guard let self = self else { return }

            guard let credit = self.arrayController.selectedObjects.first as? Credit
            else
            {
                self.contentView.subviews.forEach { $0.removeFromSuperview() }

                self.viewController = nil

                return
            }

            let controller = CreditViewController( credit: credit )

            self.contentView.addFillingSubview( controller.view )

            self.viewController = controller
        }

        self.arrayController.sortDescriptors = [ NSSortDescriptor( key: "title", ascending: true, selector: #selector( NSString.localizedCaseInsensitiveCompare( _: ) ) ) ]
    }

    /// Provides a custom, rounded row view for each row of the credits table.
    ///
    /// - Parameters:
    ///   - tableView: The requesting table view.
    ///   - row:       Index of the row needing a view.
    /// - Returns: A ``TableRowView`` instance.
    public func tableView( _ tableView: NSTableView, rowViewForRow row: Int ) -> NSTableRowView?
    {
        TableRowView( frame: NSZeroRect )
    }
}
