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
import Testing

@Suite( "CursorPosition.restored" )
struct CursorPositionTests
{
    @Test( "Keeps a column that sits within the line" )
    func columnWithinLine()
    {
        let restored = CursorPosition.restored( in: "let x = 1\nlet y = 2\n", line: 1, column: 4 )

        #expect( restored == CursorPosition( line: 1, column: 4 ) )
    }

    @Test( "Clamps a column past the end of the line to its length" )
    func clampsBeyondEnd()
    {
        // "let y = 2" is 9 UTF-16 units.
        let restored = CursorPosition.restored( in: "let x = 1\nlet y = 2\n", line: 1, column: 99 )

        #expect( restored == CursorPosition( line: 1, column: 9 ) )
    }

    @Test( "Returns nil when the line no longer exists" )
    func lineOutOfRange()
    {
        #expect( CursorPosition.restored( in: "a\nb\n", line: 9, column: 0 ) == nil )
    }

    @Test( "Measures columns in UTF-16 units, not characters" )
    func utf16Columns()
    {
        // "😀abc": 😀 is 2 UTF-16 units + "abc" = 5 units, but only 4 Characters.
        // A caret at the end is column 5 in UTF-16 terms; the old Character-count
        // logic would have clamped it to 4.
        let restored = CursorPosition.restored( in: "😀abc", line: 0, column: 5 )

        #expect( restored == CursorPosition( line: 0, column: 5 ) )

        let clamped = CursorPosition.restored( in: "😀abc", line: 0, column: 99 )

        #expect( clamped == CursorPosition( line: 0, column: 5 ) )
    }

    @Test( "Treats CRLF as a single separator (no spurious empty line)" )
    func crlfSplitting()
    {
        // "ab\r\ncd" is two lines: "ab" and "cd". Splitting on the newlines
        // character set would treat CR and LF as two separators, inserting a
        // spurious empty line between them.
        let restored = CursorPosition.restored( in: "ab\r\ncd", line: 1, column: 99 )

        #expect( restored == CursorPosition( line: 1, column: 2 ) )

        // And there is no third line.
        #expect( CursorPosition.restored( in: "ab\r\ncd", line: 2, column: 0 ) == nil )
    }
}
