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

@Suite( "FormatterOutcome.classify" )
struct FormatterOutcomeTests
{
    private func data( _ string: String ) -> Data
    {
        Data( string.utf8 )
    }

    @Test( "Returns .formatted when output differs and is non-empty" )
    func formattedWhenChanged() throws
    {
        let outcome = try FormatterOutcome.classify(
            executable:     "swiftformat",
            input:          "let x=1",
            status:         0,
            standardOutput: self.data( "let x = 1\n" ),
            standardError:  Data()
        )

        #expect( outcome == .formatted( "let x = 1\n" ) )
    }

    @Test( "Returns .unchanged when output equals input" )
    func unchangedWhenIdentical() throws
    {
        let outcome = try FormatterOutcome.classify(
            executable:     "swiftformat",
            input:          "let x = 1\n",
            status:         0,
            standardOutput: self.data( "let x = 1\n" ),
            standardError:  Data()
        )

        #expect( outcome == .unchanged )
    }

    @Test( "Returns .unchanged when output is empty after trimming" )
    func unchangedWhenBlankOutput() throws
    {
        let outcome = try FormatterOutcome.classify(
            executable:     "swiftformat",
            input:          "let x = 1\n",
            status:         0,
            standardOutput: self.data( "   \n\t " ),
            standardError:  Data()
        )

        #expect( outcome == .unchanged )
    }

    @Test( "Returns .unchanged when output is completely empty" )
    func unchangedWhenEmptyOutput() throws
    {
        let outcome = try FormatterOutcome.classify(
            executable:     "swiftformat",
            input:          "let x = 1\n",
            status:         0,
            standardOutput: Data(),
            standardError:  Data()
        )

        #expect( outcome == .unchanged )
    }

    @Test( "Throws .failed with stderr text on a non-zero status" )
    func throwsOnNonZeroStatus()
    {
        #expect( throws: FormatterError.failed( executable: "uncrustify", status: 1, message: "bad config at line 3" ) )
        {
            try FormatterOutcome.classify(
                executable:     "uncrustify",
                input:          "int x;",
                status:         1,
                standardOutput: Data(),
                standardError:  self.data( "bad config at line 3" )
            )
        }
    }
}
