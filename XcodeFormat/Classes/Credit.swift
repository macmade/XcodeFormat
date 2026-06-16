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

/// A third-party acknowledgment shown in the Credits window, bundling a
/// project's name, author, description, link, license name, and the full
/// license text loaded from a bundled file.
public class Credit: NSObject
{
    /// Name of the credited project.
    @objc public dynamic var title:           String

    /// Short attribution, typically the author's name.
    @objc public dynamic var abstract:        String

    /// Longer description of the project.
    @objc public dynamic var descriptionText: String

    /// Homepage or repository URL, or `nil` if none / unparseable.
    @objc public dynamic var url:             URL?

    /// Short license identifier (e.g. `"MIT"`), or `nil`.
    @objc public dynamic var license:         String?

    /// Full license text loaded from the bundled file, or `nil` if absent.
    @objc public dynamic var licenseText:     String?

    /// Creates a credit, parsing the URL string and loading the license text
    /// from the bundle when provided.
    ///
    /// - Parameters:
    ///   - title:           Name of the credited project.
    ///   - abstract:        Short attribution, typically the author.
    ///   - descriptionText: Longer description of the project.
    ///   - url:             Homepage/repository URL string, or `nil`.
    ///   - license:         Short license identifier, or `nil`.
    ///   - licenseFile:     Base name of a bundled `.txt` license file whose
    ///                      contents populate ``licenseText``, or `nil`.
    public init( title: String, abstract: String, descriptionText: String, url: String?, license: String?, licenseFile: String? )
    {
        self.title           = title
        self.abstract        = abstract
        self.descriptionText = descriptionText
        self.license         = license

        if let url = url
        {
            self.url = URL( string: url )
        }

        if let licenseFile = licenseFile,
           let url         = Bundle.main.url( forResource: licenseFile, withExtension: "txt" ),
           let data        = try? Data( contentsOf: url ),
           let text        = String( data: data, encoding: .utf8 )
        {
            self.licenseText = text
        }
    }
}
