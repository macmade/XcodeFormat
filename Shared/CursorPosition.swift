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

import Foundation

/// A zero-based caret position within a text buffer, matching the line/column
/// convention of `XCSourceTextPosition` (columns are UTF-16 code-unit offsets).
public struct CursorPosition: Equatable
{
    /// Zero-based line index of the caret.
    public let line:   Int

    /// Zero-based column of the caret, measured in UTF-16 code units.
    public let column: Int

    /// Creates a cursor position from a line index and column.
    ///
    /// - Parameters:
    ///   - line:   Zero-based line index.
    ///   - column: Zero-based column, in UTF-16 code units.
    public init( line: Int, column: Int )
    {
        self.line   = line
        self.column = column
    }

    /// Computes where a caret previously at `(line, column)` should be restored
    /// within `text` after formatting.
    ///
    /// Line endings are normalized (CRLF / lone CR → LF) and the text is split
    /// on `"\n"`, so a CRLF pair counts as a single separator rather than two
    /// (which would create a spurious empty line). The column is clamped to the
    /// line's length, measured in **UTF-16 code units** to match
    /// `XCSourceTextPosition`, so multibyte text before the caret does not shift
    /// the restored position.
    ///
    /// Returns `nil` when `line` no longer exists in the formatted text.
    public static func restored( in text: String, line: Int, column: Int ) -> CursorPosition?
    {
        let normalized = text.replacingOccurrences( of: "\r\n", with: "\n" ).replacingOccurrences( of: "\r", with: "\n" )
        let lines      = normalized.components( separatedBy: "\n" )

        guard line >= 0, line < lines.count
        else
        {
            return nil
        }

        let length  = lines[ line ].utf16.count
        let clamped = min( max( column, 0 ), length )

        return CursorPosition( line: line, column: clamped )
    }
}
