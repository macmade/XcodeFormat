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

/// A named formatting profile pairing a SwiftFormat configuration URL with an
/// uncrustify configuration URL.
///
/// Configurations are persisted via ``Preferences`` and synced between the
/// main app and the editor extension. Each remote configuration file is
/// downloaded over HTTPS into the shared app-group container, keyed by a hash
/// of its URL and stored alongside a content hash so a tampered or partial
/// cache can be rejected at read time.
@objc
public class Configuration: NSObject, Codable
{
    /// User-visible name of the configuration.
    @objc public dynamic var name:         String

    /// URL of the SwiftFormat configuration file, or `nil` if none.
    @objc public dynamic var swiftFormat:  URL?

    /// URL of the uncrustify configuration file, or `nil` if none.
    @objc public dynamic var uncrustify:   URL?

    /// Whether a download of this configuration's files is in progress.
    /// KVO-observable so UI can show progress.
    @objc public dynamic var downloading = false

    /// The built-in configurations seeded on first launch.
    public static var defaultConfigurations: [ Configuration ]
    {
        [
            Configuration( name: "XS-Labs",       swiftFormat: URL( string: "https://raw.githubusercontent.com/macmade/cgl/main/config/swiftformat-xs" ),       uncrustify: URL( string: "https://raw.githubusercontent.com/macmade/cgl/main/config/uncrustify.cfg" ) ),
            Configuration( name: "XS-Labs (MIT)", swiftFormat: URL( string: "https://raw.githubusercontent.com/macmade/cgl/main/config/swiftformat-xs-mit" ),   uncrustify: URL( string: "https://raw.githubusercontent.com/macmade/cgl/main/config/uncrustify.cfg" ) ),
            Configuration( name: "DigiDNA",       swiftFormat: URL( string: "https://raw.githubusercontent.com/DigiDNA/cgl/main/config/swiftformat-ddna" ),     uncrustify: URL( string: "https://raw.githubusercontent.com/DigiDNA/cgl/main/config/uncrustify.cfg" ) ),
            Configuration( name: "DigiDNA (MIT)", swiftFormat: URL( string: "https://raw.githubusercontent.com/DigiDNA/cgl/main/config/swiftformat-ddna-mit" ), uncrustify: URL( string: "https://raw.githubusercontent.com/DigiDNA/cgl/main/config/uncrustify.cfg" ) ),
        ]
    }

    /// Creates a configuration from a name and an optional URL for each
    /// formatter.
    ///
    /// - Parameters:
    ///   - name:        User-visible name.
    ///   - swiftFormat: SwiftFormat configuration URL, or `nil`.
    ///   - uncrustify:  Uncrustify configuration URL, or `nil`.
    public init( name: String, swiftFormat: URL?, uncrustify: URL? )
    {
        self.name        = name
        self.swiftFormat = swiftFormat
        self.uncrustify  = uncrustify

        super.init()
    }

    /// A textual description including the configuration's name, for debugging.
    public override var description: String
    {
        "\( super.description ): \( self.name )"
    }

    /// Compares two configurations by value.
    ///
    /// - Parameter object: The object to compare against.
    /// - Returns: `true` when `object` is a `Configuration` with the same name
    ///            and formatter URLs.
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

    /// A hash derived from the name and formatter URLs, consistent with
    /// ``isEqual(_:)``.
    public override var hash: Int
    {
        var hasher = Hasher()

        hasher.combine( self.name )
        hasher.combine( self.swiftFormat )
        hasher.combine( self.uncrustify )

        return hasher.finalize()
    }

    /// Downloads this configuration's formatter files into the shared cache.
    ///
    /// Coalesces concurrent calls via the ``downloading`` flag (checked and set
    /// on the main queue), then fetches each non-`nil` URL on a background
    /// queue, clearing the flag when finished.
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

    /// Downloads a single configuration file and writes it to the shared cache.
    ///
    /// Rejects non-HTTPS URLs, names the cached file by the hash of its URL,
    /// and writes a `<hash>.sha256` sidecar holding the content hash so the
    /// cache can be integrity-checked on read. File writes are serialized
    /// through an `NSFileCoordinator`. Any failure is silently ignored, leaving
    /// the cache untouched.
    ///
    /// - Parameter url: HTTPS URL of the configuration file to fetch.
    private func download( url: URL )
    {
        guard url.scheme?.lowercased() == "https",
              let sha256    = url.sha256,
              let container = FileManager.sharedContainerURL?.appendingPathComponent( "Configurations" )
        else
        {
            return
        }

        guard let data = Configuration.fetch( url: url )
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

        // Store a content hash alongside the cached file so a tampered or
        // partially-written cache can be detected and rejected at read time.
        coordinator.coordinate( writingItemAt: container.appendingPathComponent( "\( sha256 ).sha256" ), error: &error )
        {
            try? Data( data.sha256.utf8 ).write( to: $0 )
        }
    }

    /// Fetches a configuration over HTTPS with an explicit timeout, returning
    /// the body only for a 2xx response. Runs synchronously; intended to be
    /// called from a background queue.
    ///
    /// - Parameter url: URL of the configuration file to fetch.
    /// - Returns: The response body for a 2xx response, or `nil` on a transport
    ///            error or non-2xx status.
    private static func fetch( url: URL ) -> Data?
    {
        var request        = URLRequest( url: url, timeoutInterval: 30 )
        request.httpMethod = "GET"

        let semaphore = DispatchSemaphore( value: 0 )
        var result:    Data?

        let task = URLSession.shared.dataTask( with: request )
        {
            data, response, error in

            defer
            {
                semaphore.signal()
            }

            guard error == nil,
                  let http = response as? HTTPURLResponse,
                  ( 200 ..< 300 ).contains( http.statusCode ),
                  let data = data
            else
            {
                return
            }

            result = data
        }

        task.resume()
        semaphore.wait()

        return result
    }

    /// Provides local copies of the cached configuration files to a closure,
    /// then lets the caller clean them up.
    ///
    /// Each available file is copied to a unique temporary location (its
    /// integrity verified against the stored content hash). If a configured URL
    /// has no valid cached copy, a fresh ``download()`` is triggered for next
    /// time. When neither file is available the `error` closure is called and
    /// `completion` is not. Otherwise `completion` receives the temporary URLs
    /// plus a `finished` closure that deletes them; the caller must invoke
    /// `finished` once done.
    ///
    /// - Parameters:
    ///   - completion: Called with the temporary `swiftFormat` / `uncrustify`
    ///                 URLs (either may be `nil`) and a `finished` cleanup
    ///                 closure.
    ///   - error:      Called instead of `completion` when no cached file is
    ///                 available.
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

    /// Copies a cached configuration file to a unique temporary URL after
    /// verifying its integrity.
    ///
    /// Locates the cached file by the hash of `url`, and — when a `<hash>.sha256`
    /// sidecar exists — rejects the copy if the bytes no longer match, so a
    /// tampered or partially written cache is never fed to the formatter. File
    /// access is serialized through an `NSFileCoordinator`.
    ///
    /// - Parameter url: The original configuration URL whose cached copy is
    ///                  wanted, or `nil`.
    /// - Returns: A temporary URL holding a fresh copy of the cached file, or
    ///            `nil` if `url` is `nil`, nothing is cached, or the integrity
    ///            check or copy fails.
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

            // If a content hash was stored at download time, the bytes we just
            // read must match it; otherwise the cache is tampered or partial and
            // must not be fed to the formatter.
            let hashURL = container.appendingPathComponent( "\( sha256 ).sha256" )

            if let expected = try? String( contentsOf: hashURL, encoding: .utf8 ), expected != data.sha256
            {
                writeError = NSError( domain: "com.xs-labs.XcodeFormat", code: -1, userInfo: [ NSLocalizedDescriptionKey: "The cached configuration failed its integrity check." ] )

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
