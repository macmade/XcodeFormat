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

/// A command-line failure with a user-facing message, surfaced by
/// ``XcodeFormatCLI`` through ArgumentParser's error output.
public enum CLIError: LocalizedError, Equatable
{
    /// No configuration matched the requested name.
    case configurationNotFound( name: String, available: [ String ] )

    /// The configuration's files could not be downloaded or located.
    case configurationFilesUnavailable( name: String )

    /// A localized, user-facing description of the failure.
    public var errorDescription: String?
    {
        switch self
        {
            case .configurationNotFound( let name, let available ):

                let list = available.isEmpty ? "(none)" : available.joined( separator: ", " )

                return "Configuration not found: \"\( name )\". Available configurations: \( list )."

            case .configurationFilesUnavailable( let name ):

                return "Could not download or locate the configuration files for \"\( name )\"."
        }
    }
}
