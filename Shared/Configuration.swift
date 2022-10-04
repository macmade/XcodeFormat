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

@objc public class Configuration: NSObject, Codable
{
    @objc public dynamic var name:        String
    @objc public dynamic var swiftFormat: URL
    @objc public dynamic var uncrustify:  URL

    public static var defaultConfigurations: [ Configuration ]
    {
        [
            Configuration( name: "XS-Labs",       swiftFormat: "https://raw.githubusercontent.com/macmade/cgl/main/config/swiftformat-xs",       uncrustify: "https://raw.githubusercontent.com/macmade/cgl/main/config/uncrustify.cfg" ),
            Configuration( name: "XS-Labs (MIT)", swiftFormat: "https://raw.githubusercontent.com/macmade/cgl/main/config/swiftformat-xs-mit",   uncrustify: "https://raw.githubusercontent.com/macmade/cgl/main/config/uncrustify.cfg" ),
            Configuration( name: "DigiDNA",       swiftFormat: "https://raw.githubusercontent.com/DigiDNA/cgl/main/config/swiftformat-ddna",     uncrustify: "https://raw.githubusercontent.com/DigiDNA/cgl/main/config/uncrustify.cfg" ),
            Configuration( name: "DigiDNA (MIT)", swiftFormat: "https://raw.githubusercontent.com/DigiDNA/cgl/main/config/swiftformat-ddna-mit", uncrustify: "https://raw.githubusercontent.com/DigiDNA/cgl/main/config/uncrustify.cfg" ),
        ]
        .compactMap { $0 }
    }

    public convenience init?( name: String, swiftFormat: String, uncrustify: String )
    {
        guard let swiftFormat = URL( string: swiftFormat ),
              let uncrustify  = URL( string: uncrustify )
        else
        {
            return nil
        }

        self.init( name: name, swiftFormat: swiftFormat, uncrustify: uncrustify )
    }

    public init( name: String, swiftFormat: URL, uncrustify: URL )
    {
        self.name        = name
        self.swiftFormat = swiftFormat
        self.uncrustify  = uncrustify
    }

    public override var description: String
    {
        "\( super.description ): \( self.name )"
    }

    public override func isEqual( to object: Any? ) -> Bool
    {
        self.isEqual( object )
    }

    public override func isEqual( _ object: Any? ) -> Bool
    {
        guard let configuration = object as? Configuration
        else
        {
            return false
        }

        if self.name        == configuration.name,
           self.swiftFormat == configuration.swiftFormat,
           self.uncrustify  == configuration.uncrustify
        {
            return true
        }

        return false
    }
}
