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

/// A table row view with rounded corners, hover highlighting, and an
/// accent-colored selection background.
///
/// Tracks the mouse to highlight the row on hover, and optionally paints an
/// alternating background color when not hovered.
public class TableRowView: NSTableRowView
{
    /// The mouse-tracking area, recreated whenever the bounds change.
    private var trackingArea: NSTrackingArea?

    /// Closure invoked when the mouse enters the row, if set.
    public var onMouseEnter: ( () -> Void )?

    /// Closure invoked when the mouse exits the row, if set.
    public var onMouseExit:  ( () -> Void )?

    /// Whether to paint the alternating (odd-row) background color when not
    /// hovered. `nil` disables alternating-background painting.
    private var alternate: Bool?

    /// Whether the mouse is currently over the row; redraws on change.
    @objc private dynamic var mouseOver = false
    {
        didSet
        {
            self.needsDisplay = true
        }
    }

    /// Creates a row view that paints an alternating background color.
    ///
    /// - Parameters:
    ///   - frame:     The view's frame rectangle.
    ///   - alternate: `true` to paint the odd-row background color, `false` for
    ///                the even-row color.
    public convenience init( frame: NSRect, alternate: Bool )
    {
        self.init( frame: frame )

        self.alternate = alternate
    }

    /// Creates a row view with no alternating-background painting.
    ///
    /// - Parameter frame: The view's frame rectangle.
    public override init( frame: NSRect )
    {
        super.init( frame: frame )
    }

    /// Creates a row view from an unarchiver.
    ///
    /// - Parameter coder: The unarchiver to decode from.
    public required init?( coder: NSCoder )
    {
        super.init( coder: coder )
    }

    /// Rebuilds the mouse-tracking area to cover the current bounds so hover
    /// enter/exit events keep firing after layout changes.
    public override func updateTrackingAreas()
    {
        super.updateTrackingAreas()

        if let trackingArea = self.trackingArea
        {
            self.removeTrackingArea( trackingArea )
        }

        let trackingArea  = NSTrackingArea( rect: self.bounds, options: [ .activeInActiveApp, .mouseEnteredAndExited ], owner: self, userInfo: nil )
        self.trackingArea = trackingArea

        self.addTrackingArea( trackingArea )
    }

    /// Marks the row as hovered and invokes ``onMouseEnter``.
    ///
    /// - Parameter event: The mouse-entered event.
    public override func mouseEntered( with event: NSEvent )
    {
        super.mouseEntered( with: event )
        self.onMouseEnter?()

        self.mouseOver = true
    }

    /// Clears the hovered state and invokes ``onMouseExit``.
    ///
    /// - Parameter event: The mouse-exited event.
    public override func mouseExited( with event: NSEvent )
    {
        super.mouseExited( with: event )
        self.onMouseExit?()

        self.mouseOver = false
    }

    /// Draws the row's rounded background: an accent tint when hovered, or the
    /// alternating content color when ``alternate`` is set.
    ///
    /// - Parameter rect: The rectangle to fill.
    public override func drawBackground( in rect: NSRect )
    {
        if self.mouseOver
        {
            let color = NSColor.controlAccentColor.withAlphaComponent( 0.2 )
            let path  = NSBezierPath( roundedRect: rect, xRadius: 6, yRadius: 6 )

            color.setFill()
            path.fill()
        }
        else if let alternate = self.alternate
        {
            let colors = NSColor.alternatingContentBackgroundColors

            if colors.count < 2
            {
                return
            }

            let color = alternate ? colors[ 1 ] : colors[ 0 ]
            let path  = NSBezierPath( roundedRect: rect, xRadius: 6, yRadius: 6 )

            color.setFill()
            path.fill()
        }
    }

    /// Draws the selection highlight as a rounded, accent-colored fill.
    ///
    /// - Parameter rect: The rectangle to fill.
    public override func drawSelection( in rect: NSRect )
    {
        let color = NSColor.controlAccentColor
        let path  = NSBezierPath( roundedRect: rect, xRadius: 6, yRadius: 6 )

        color.setFill()
        path.fill()
    }
}
