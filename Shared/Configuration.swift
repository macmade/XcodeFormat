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

import CryptoKit
import Foundation

@objc
public class Configuration: NSObject, Codable
{
    @objc public dynamic var name:         String
    @objc public dynamic var swiftFormat:  URL?
    @objc public dynamic var uncrustify:   URL?
    @objc public dynamic var downloading = false

    public static var defaultConfigurations: [ Configuration ]
    {
        [
            Configuration( name: "XS-Labs",       swiftFormat: URL( string: "https://raw.githubusercontent.com/macmade/cgl/main/config/swiftformat-xs" ),       uncrustify: URL( string: "https://raw.githubusercontent.com/macmade/cgl/main/config/uncrustify.cfg" ) ),
            Configuration( name: "XS-Labs (MIT)", swiftFormat: URL( string: "https://raw.githubusercontent.com/macmade/cgl/main/config/swiftformat-xs-mit" ),   uncrustify: URL( string: "https://raw.githubusercontent.com/macmade/cgl/main/config/uncrustify.cfg" ) ),
            Configuration( name: "DigiDNA",       swiftFormat: URL( string: "https://raw.githubusercontent.com/DigiDNA/cgl/main/config/swiftformat-ddna" ),     uncrustify: URL( string: "https://raw.githubusercontent.com/DigiDNA/cgl/main/config/uncrustify.cfg" ) ),
            Configuration( name: "DigiDNA (MIT)", swiftFormat: URL( string: "https://raw.githubusercontent.com/DigiDNA/cgl/main/config/swiftformat-ddna-mit" ), uncrustify: URL( string: "https://raw.githubusercontent.com/DigiDNA/cgl/main/config/uncrustify.cfg" ) ),
        ]
    }

    public init( name: String, swiftFormat: URL?, uncrustify: URL? )
    {
        self.name        = name
        self.swiftFormat = swiftFormat
        self.uncrustify  = uncrustify

        super.init()
    }

    public override var description: String
    {
        "\( super.description ): \( self.name )"
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

    public override var hash: Int
    {
        var hasher = Hasher()

        hasher.combine( self.name )
        hasher.combine( self.swiftFormat )
        hasher.combine( self.uncrustify )

        return hasher.finalize()
    }

    public func download()
    {
        DispatchQueue.main.async
        {
            if self.downloading
            {
                return
            }

            self.downloading = true

            DispatchQueue.global( qos: .userInitiated ).async
            {
                if let url = self.swiftFormat
                {
                    self.download( url: url )
                }

                if let url = self.uncrustify
                {
                    self.download( url: url )
                }

                DispatchQueue.main.async
                {
                    self.downloading = false
                }
            }
        }
    }

    private func download( url: URL )
    {
        guard let sha256    = url.sha256,
              let data      = try? Data( contentsOf: url ),
              let container = FileManager.sharedContainerURL?.appendingPathComponent( "Configurations" )
        else
        {
            return
        }

        try? FileManager.default.createDirectory( at: container, withIntermediateDirectories: true )

        let coordinator = NSFileCoordinator( filePresenter: nil )
        var error:        NSError?

        coordinator.coordinate( writingItemAt: container.appendingPathComponent( sha256 ), error: &error )
        {
            try? data.write( to: $0 )
        }
    }

    public func withConfigurations( completion: ( ( swiftFormat: URL?, uncrustify: URL?, finished: () -> Void ) ) -> Void, error: () -> Void )
    {
        let swiftFormat = self.copy( url: self.swiftFormat )
        let uncrustify  = self.copy( url: self.uncrustify )

        if ( self.swiftFormat != nil && swiftFormat == nil ) || ( self.uncrustify != nil && uncrustify == nil )
        {
            self.download()
        }

        if swiftFormat == nil, uncrustify == nil
        {
            error()

            return
        }

        let finished: () -> Void =
        {
            [
                swiftFormat,
                uncrustify,
            ]
            .compactMap
            {
                $0
            }
            .forEach
            {
                try? FileManager.default.removeItem( at: $0 )
            }
        }

        completion( ( swiftFormat: swiftFormat, uncrustify: uncrustify, finished: finished ) )
    }

    private func copy( url: URL? ) -> URL?
    {
        guard let url       = url,
              let sha256    = url.sha256,
              let container = FileManager.sharedContainerURL?.appendingPathComponent( "Configurations" )
        else
        {
            return nil
        }

        let config = container.appendingPathComponent( sha256 )

        guard FileManager.default.fileExists( atPath: config.path )
        else
        {
            return nil
        }

        let copy             = container.appendingPathComponent( "Temp" ).appendingPathComponent( UUID().uuidString )
        let coordinator      = NSFileCoordinator( filePresenter: nil )
        var coordinationError: NSError?
        var writeError:        NSError?

        coordinator.coordinate( readingItemAt: config, error: &coordinationError )
        {
            guard let data = try? Data( contentsOf: $0 )
            else
            {
                return
            }

            do
            {
                try FileManager.default.createDirectory( at: copy.deletingLastPathComponent(), withIntermediateDirectories: true )
                try data.write( to: copy )
            }
            catch let e
            {
                writeError = e as NSError
            }
        }

        return coordinationError == nil && writeError == nil ? copy : nil
    }
}
