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

@Suite( "FormatterError" )
struct FormatterErrorTests
{
    @Test( "Failed error description includes executable, status and stderr" )
    func failedErrorDescription()
    {
        let error       = FormatterError.failed( executable: "uncrustify", status: 2, message: "  parse error\n" )
        let description = error.errorDescription

        #expect( description?.contains( "uncrustify" ) == true )
        #expect( description?.contains( "2" ) == true )
        #expect( description?.contains( "parse error" ) == true )
    }

    @Test( "Failed error description omits the colon when stderr is empty" )
    func failedErrorDescriptionWithoutStderr() throws
    {
        let error       = FormatterError.failed( executable: "swiftformat", status: 1, message: "   \n" )
        let description  = try #require( error.errorDescription )

        #expect( description.contains( "swiftformat" ) )
        #expect( description.contains( "1" ) )
        #expect( description.hasSuffix( ":" ) == false )
    }

    @Test( "Executable-not-found error description includes the name" )
    func executableNotFoundDescription() throws
    {
        let error       = FormatterError.executableNotFound( "swiftformat" )
        let description = try #require( error.errorDescription )

        #expect( description.contains( "swiftformat" ) )
    }
}
