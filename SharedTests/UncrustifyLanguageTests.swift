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
import UniformTypeIdentifiers

@Suite( "UncrustifyLanguage" )
struct UncrustifyLanguageTests
{
    @Test( "Maps C source to C" )
    func cSource()
    {
        #expect( UncrustifyLanguage.argument( for: .cSource ) == "C" )
    }

    @Test( "Maps C++ source to CPP" )
    func cPlusPlusSource()
    {
        #expect( UncrustifyLanguage.argument( for: .cPlusPlusSource ) == "CPP" )
    }

    @Test( "Maps Objective-C source to OC" )
    func objectiveCSource()
    {
        #expect( UncrustifyLanguage.argument( for: .objectiveCSource ) == "OC" )
    }

    @Test( "Maps Objective-C++ source to OC+" )
    func objectiveCPlusPlusSource()
    {
        #expect( UncrustifyLanguage.argument( for: .objectiveCPlusPlusSource ) == "OC+" )
    }

    @Test( "Defaults ambiguous C headers to OC" )
    func cHeader()
    {
        #expect( UncrustifyLanguage.argument( for: .cHeader ) == "OC" )
    }

    @Test( "Maps C++ headers to CPP" )
    func cPlusPlusHeader()
    {
        #expect( UncrustifyLanguage.argument( for: .cPlusPlusHeader ) == "CPP" )
    }

    @Test( "Returns nil for Swift source" )
    func swiftSourceIsUnsupported()
    {
        #expect( UncrustifyLanguage.argument( for: .swiftSource ) == nil )
    }

    @Test( "Returns nil for unrelated types" )
    func unrelatedTypesAreUnsupported()
    {
        #expect( UncrustifyLanguage.argument( for: .plainText ) == nil )
        #expect( UncrustifyLanguage.argument( for: .json ) == nil )
    }
}
