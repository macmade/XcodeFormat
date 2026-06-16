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

@Suite( "FileFormatter" )
struct FileFormatterTests
{
    @Test( "Maps Swift files to SwiftFormat" )
    func swiftFileUsesSwiftFormat()
    {
        #expect( FileFormatter.tool( for: URL( fileURLWithPath: "Example.swift" ) ) == .swiftFormat )
    }

    @Test( "Maps C++ files to uncrustify with the CPP language" )
    func cPlusPlusFileUsesUncrustify()
    {
        #expect( FileFormatter.tool( for: URL( fileURLWithPath: "Example.cpp" ) ) == .uncrustify( language: "CPP" ) )
    }

    @Test( "Maps Objective-C files to uncrustify with the OC language" )
    func objectiveCFileUsesUncrustify()
    {
        #expect( FileFormatter.tool( for: URL( fileURLWithPath: "Example.m" ) ) == .uncrustify( language: "OC" ) )
    }

    @Test( "Maps C headers to uncrustify with the OC language" )
    func cHeaderUsesUncrustify()
    {
        #expect( FileFormatter.tool( for: URL( fileURLWithPath: "Example.h" ) ) == .uncrustify( language: "OC" ) )
    }

    @Test( "Returns nil for unsupported file types" )
    func unsupportedTypeReturnsNil()
    {
        #expect( FileFormatter.tool( for: URL( fileURLWithPath: "Example.txt" ) ) == nil )
        #expect( FileFormatter.tool( for: URL( fileURLWithPath: "Example" ) ) == nil )
    }

    @Test( "Validation rejects a missing file" )
    func validationRejectsMissingFile() throws
    {
        let missing = URL( fileURLWithPath: NSTemporaryDirectory() ).appendingPathComponent( "\( UUID().uuidString ).swift" )

        #expect( throws: FileFormatter.ValidationError.fileNotFound( missing ) )
        {
            try FileFormatter.validate( files: [ missing ], swiftFormatConfig: URL( fileURLWithPath: "/tmp/config" ), uncrustifyConfig: nil )
        }
    }

    @Test( "Validation rejects an unsupported file type" )
    func validationRejectsUnsupportedType() throws
    {
        let file = try Self.makeTemporaryFile( extension: "txt" )

        defer
        {
            try? FileManager.default.removeItem( at: file )
        }

        #expect( throws: FileFormatter.ValidationError.unsupportedType( file ) )
        {
            try FileFormatter.validate( files: [ file ], swiftFormatConfig: URL( fileURLWithPath: "/tmp/config" ), uncrustifyConfig: URL( fileURLWithPath: "/tmp/config" ) )
        }
    }

    @Test( "Validation rejects a supported file with no matching configuration" )
    func validationRejectsMissingConfiguration() throws
    {
        let file = try Self.makeTemporaryFile( extension: "swift" )

        defer
        {
            try? FileManager.default.removeItem( at: file )
        }

        #expect( throws: FileFormatter.ValidationError.missingConfiguration( file ) )
        {
            try FileFormatter.validate( files: [ file ], swiftFormatConfig: nil, uncrustifyConfig: URL( fileURLWithPath: "/tmp/config" ) )
        }
    }

    @Test( "Validation passes for a supported file with its configuration present" )
    func validationPasses() throws
    {
        let file = try Self.makeTemporaryFile( extension: "swift" )

        defer
        {
            try? FileManager.default.removeItem( at: file )
        }

        #expect( throws: Never.self )
        {
            try FileFormatter.validate( files: [ file ], swiftFormatConfig: URL( fileURLWithPath: "/tmp/config" ), uncrustifyConfig: nil )
        }
    }

    /// Creates an empty temporary file with the given extension, returning its
    /// URL. The caller is responsible for removing it.
    private static func makeTemporaryFile( extension ext: String ) throws -> URL
    {
        let url = URL( fileURLWithPath: NSTemporaryDirectory() ).appendingPathComponent( "\( UUID().uuidString ).\( ext )" )

        try Data().write( to: url )

        return url
    }
}
