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

@Suite( "URL.configurationURL" )
struct ConfigurationURLTests
{
    @Test( "Returns nil for an empty string (no URL provided)" )
    func emptyIsNil() throws
    {
        #expect( try URL.configurationURL( from: "" ) == nil )
    }

    @Test( "Accepts a well-formed https URL" )
    func acceptsHTTPS() throws
    {
        let url = try URL.configurationURL( from: "https://example.com/config" )

        #expect( url == URL( string: "https://example.com/config" ) )
    }

    @Test( "Rejects an http URL as insecure" )
    func rejectsHTTP()
    {
        #expect( throws: ConfigurationURLError.insecure )
        {
            try URL.configurationURL( from: "http://example.com/config" )
        }
    }

    @Test( "Rejects a non-https scheme as insecure" )
    func rejectsOtherSchemes()
    {
        #expect( throws: ConfigurationURLError.insecure )
        {
            try URL.configurationURL( from: "ftp://example.com/config" )
        }
    }

    @Test( "Rejects a URL with no scheme as insecure" )
    func rejectsSchemeless()
    {
        #expect( throws: ConfigurationURLError.insecure )
        {
            try URL.configurationURL( from: "example.com/config" )
        }
    }

    @Test( "Rejects a malformed URL string" )
    func rejectsMalformed()
    {
        #expect( throws: ConfigurationURLError.malformed )
        {
            try URL.configurationURL( from: "https://exa mple.com/has spaces" )
        }
    }

    @Test( "Error messages are user-facing and distinct" )
    func errorMessages()
    {
        #expect( ConfigurationURLError.malformed.errorDescription?.isEmpty == false )
        #expect( ConfigurationURLError.insecure.errorDescription?.isEmpty == false )
        #expect( ConfigurationURLError.malformed.errorDescription != ConfigurationURLError.insecure.errorDescription )
    }
}
