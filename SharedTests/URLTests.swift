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

@Suite( "URL.sha256" )
struct URLTests
{
    @Test( "Produces a stable, known digest for a fixed URL" )
    func knownDigest() throws
    {
        let url    = try #require( URL( string: "https://example.com/config" ) )
        let sha256 = try #require( url.sha256 )

        #expect( sha256 == "096F81E86E5A9F7F9219421BB271490F74A542003D3AB1B42B437BF852F9FE85" )
    }

    @Test( "Is a 64-character hexadecimal string" )
    func digestShape() throws
    {
        let url    = try #require( URL( string: "https://raw.githubusercontent.com/macmade/cgl/main/config/uncrustify.cfg" ) )
        let sha256 = try #require( url.sha256 )

        #expect( sha256.count == 64 )
        #expect( sha256.allSatisfy { $0.isHexDigit } )
    }

    @Test( "Is deterministic across repeated calls" )
    func deterministic() throws
    {
        let url = try #require( URL( string: "https://example.com/some/path?query=1" ) )

        #expect( url.sha256 == url.sha256 )
    }

    @Test( "Differs for different URLs" )
    func distinctForDistinctURLs() throws
    {
        let a = try #require( URL( string: "https://example.com/a" ) )
        let b = try #require( URL( string: "https://example.com/b" ) )

        #expect( a.sha256 != b.sha256 )
    }
}
