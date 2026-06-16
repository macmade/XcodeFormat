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

@Suite( "Configuration" )
struct ConfigurationTests
{
    @Test( "Round-trips through PropertyList encoding" )
    func codableRoundTrip() throws
    {
        let configuration = Configuration(
            name:        "Test",
            swiftFormat: URL( string: "https://example.com/swiftformat" ),
            uncrustify:  URL( string: "https://example.com/uncrustify.cfg" )
        )

        let data    = try PropertyListEncoder().encode( configuration )
        let decoded = try PropertyListDecoder().decode( Configuration.self, from: data )

        #expect( decoded.name        == configuration.name )
        #expect( decoded.swiftFormat == configuration.swiftFormat )
        #expect( decoded.uncrustify  == configuration.uncrustify )
    }

    @Test( "Round-trips an array of configurations" )
    func codableArrayRoundTrip() throws
    {
        let configurations = Configuration.defaultConfigurations
        let data           = try PropertyListEncoder().encode( configurations )
        let decoded        = try PropertyListDecoder().decode( [ Configuration ].self, from: data )

        #expect( decoded.count == configurations.count )

        for ( lhs, rhs ) in zip( decoded, configurations )
        {
            #expect( lhs == rhs )
        }
    }

    @Test( "Round-trips a configuration with nil URLs" )
    func codableNilURLs() throws
    {
        let configuration = Configuration( name: "Empty", swiftFormat: nil, uncrustify: nil )
        let data          = try PropertyListEncoder().encode( configuration )
        let decoded       = try PropertyListDecoder().decode( Configuration.self, from: data )

        #expect( decoded.name        == "Empty" )
        #expect( decoded.swiftFormat == nil )
        #expect( decoded.uncrustify  == nil )
    }

    @Test( "Considers configurations with identical fields equal" )
    func equalityForIdenticalFields()
    {
        let lhs = Configuration( name: "X", swiftFormat: URL( string: "https://a" ), uncrustify: URL( string: "https://b" ) )
        let rhs = Configuration( name: "X", swiftFormat: URL( string: "https://a" ), uncrustify: URL( string: "https://b" ) )

        #expect( lhs == rhs )
        #expect( lhs.isEqual( rhs ) )
    }

    @Test( "Distinguishes configurations differing by any field" )
    func inequalityForDifferingFields()
    {
        let base = Configuration( name: "X", swiftFormat: URL( string: "https://a" ), uncrustify: URL( string: "https://b" ) )

        let differentName        = Configuration( name: "Y", swiftFormat: URL( string: "https://a" ), uncrustify: URL( string: "https://b" ) )
        let differentSwiftFormat = Configuration( name: "X", swiftFormat: URL( string: "https://c" ), uncrustify: URL( string: "https://b" ) )
        let differentUncrustify  = Configuration( name: "X", swiftFormat: URL( string: "https://a" ), uncrustify: URL( string: "https://c" ) )

        #expect( base != differentName )
        #expect( base != differentSwiftFormat )
        #expect( base != differentUncrustify )
    }

    @Test( "Is not equal to non-Configuration objects" )
    func inequalityForOtherTypes()
    {
        let configuration = Configuration( name: "X", swiftFormat: nil, uncrustify: nil )

        #expect( configuration.isEqual( "X" ) == false )
        #expect( configuration.isEqual( nil ) == false )
    }

    @Test( "Equal configurations produce equal hashes" )
    func equalConfigurationsHaveEqualHashes()
    {
        let lhs = Configuration( name: "X", swiftFormat: URL( string: "https://a" ), uncrustify: URL( string: "https://b" ) )
        let rhs = Configuration( name: "X", swiftFormat: URL( string: "https://a" ), uncrustify: URL( string: "https://b" ) )

        #expect( lhs == rhs )
        #expect( lhs.hash == rhs.hash )
        #expect( lhs.hashValue == rhs.hashValue )
    }

    @Test( "Equal configurations coalesce in a Set" )
    func equalConfigurationsCoalesceInASet()
    {
        let lhs = Configuration( name: "X", swiftFormat: URL( string: "https://a" ), uncrustify: URL( string: "https://b" ) )
        let rhs = Configuration( name: "X", swiftFormat: URL( string: "https://a" ), uncrustify: URL( string: "https://b" ) )

        let set: Set< Configuration > = [ lhs, rhs ]

        #expect( set.count == 1 )
    }

    @Test( "Equal configurations with nil URLs produce equal hashes" )
    func equalConfigurationsWithNilURLsHaveEqualHashes()
    {
        let lhs = Configuration( name: "Empty", swiftFormat: nil, uncrustify: nil )
        let rhs = Configuration( name: "Empty", swiftFormat: nil, uncrustify: nil )

        #expect( lhs == rhs )
        #expect( lhs.hash == rhs.hash )
    }
}
