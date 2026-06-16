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

/// Hashing and validation helpers for configuration URLs.
public extension URL
{
    /// The SHA-256 digest of the URL's absolute string as an uppercase
    /// hexadecimal string, used to derive a stable cache file name for a
    /// configuration URL.
    var sha256: String?
    {
        self.absoluteString.sha256
    }

    /// Validates a user-entered configuration URL string.
    ///
    /// - An empty string means "no URL provided" and returns `nil`.
    /// - A string that does not parse as a URL throws `.malformed`.
    /// - A URL that does not use the `https` scheme throws `.insecure`.
    /// - Otherwise the parsed `https` URL is returned.
    static func configurationURL( from string: String ) throws -> URL?
    {
        if string.isEmpty
        {
            return nil
        }

        guard let url = URL( string: string )
        else
        {
            throw ConfigurationURLError.malformed
        }

        guard url.scheme?.lowercased() == "https"
        else
        {
            throw ConfigurationURLError.insecure
        }

        return url
    }
}
