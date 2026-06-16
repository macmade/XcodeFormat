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
import UniformTypeIdentifiers

/// Namespace that maps a source file's uniform type to the language token
/// uncrustify expects on its `-l` command-line option.
public enum UncrustifyLanguage
{
    /// Maps a source buffer's `UTType` to the uncrustify `-l` language hint.
    ///
    /// Returns `nil` for types uncrustify does not handle (e.g. Swift), so the
    /// caller can fall through to its no-op / error path.
    ///
    /// A `.h` file is genuinely ambiguous between C and Objective-C; because
    /// this is an Xcode/Apple-platform tool, ambiguous C headers default to
    /// `OC`. C++ headers (`.hpp`, `.hh`) are unambiguous and map to `CPP`.
    public static func argument( for type: UTType ) -> String?
    {
        switch type
        {
            case .cSource:                  return "C"
            case .cPlusPlusSource:          return "CPP"
            case .objectiveCSource:         return "OC"
            case .objectiveCPlusPlusSource: return "OC+"
            case .cHeader:                  return "OC"
            case .cPlusPlusHeader:          return "CPP"
            default:                        return nil
        }
    }
}
