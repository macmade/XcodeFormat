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

import Cocoa

/// Shared, process-wide store for the app's formatter configurations and the
/// currently selected one.
///
/// State is persisted in an app-group `UserDefaults` suite so the main app and
/// the Xcode source editor extension share the same data, and changes are
/// broadcast across processes through `DistributedNotificationCenter` so each
/// process can refresh its view.
public class Preferences: NSObject
{
    /// The single, shared instance used throughout the app and the extension.
    static let shared                = Preferences()

    /// Name of the distributed notification posted whenever the stored
    /// configurations or selection change, in this or another process.
    static let defaultsChanged = Notification.Name( "com.xs-labs.XcodeFormat.Preferences.ConfigurationsChanged" )

    /// Backing defaults store, scoped to the shared app group so the app and
    /// the editor extension read and write the same values.
    private var defaults        = UserDefaults( suiteName: "326Y53CJMD.com.xs-labs.XcodeFormat.Shared" )

    /// Opaque token for the distributed-notification observer, retained for the
    /// lifetime of the instance.
    private var defaultsObserver: Any?

    /// Creates the shared instance and begins observing cross-process change
    /// notifications.
    ///
    /// When a change is observed the in-memory cache is invalidated and manual
    /// KVO notices are emitted for ``configurations`` and
    /// ``selectedConfiguration`` so bound UI updates.
    private override init()
    {
        super.init()

        self.defaultsObserver = DistributedNotificationCenter.default().addObserver( forName: Preferences.defaultsChanged, object: nil, queue: nil )
        {
            [ weak self ] _ in

            guard let self = self
            else
            {
                return
            }

            // A change elsewhere (or in another process) invalidates the cache
            // so the next read re-decodes the stored plist.
            self.cachedConfigurations = nil

            self.willChangeValue( for: \.configurations )
            self.didChangeValue(  for: \.configurations )

            self.willChangeValue( for: \.selectedConfiguration )
            self.didChangeValue(  for: \.selectedConfiguration )
        }
    }

    /// In-memory cache of the decoded configurations, avoiding a property-list
    /// decode on every read. `nil` means the cache is empty or has been
    /// invalidated and must be re-decoded on the next read.
    private var cachedConfigurations: [ Configuration ]?

    /// The persisted list of formatter configurations.
    ///
    /// Reading decodes the stored property list (caching the result); writing
    /// re-encodes it, refreshes the cache, and posts ``defaultsChanged`` so
    /// other processes reload. KVO-observable.
    @objc public dynamic var configurations: [ Configuration ]
    {
        get
        {
            if let cached = self.cachedConfigurations
            {
                return cached
            }

            let decoded: [ Configuration ]

            if let data    = self.defaults?.object( forKey: "configurations" ) as? Data,
               let stored  = try? PropertyListDecoder().decode( [ Configuration ].self, from: data )
            {
                decoded = stored
            }
            else
            {
                decoded = []
            }

            self.cachedConfigurations = decoded

            return decoded
        }

        set( value )
        {
            if let data = try? PropertyListEncoder().encode( value )
            {
                self.cachedConfigurations = value
                self.defaults?.setValue( data, forKey: "configurations" )
                DistributedNotificationCenter.default().post( name: Preferences.defaultsChanged, object: nil )
            }
        }
    }

    /// The configuration the editor extension currently applies, or `nil` when
    /// none is selected.
    ///
    /// Reading decodes the stored property list; writing re-encodes it (or
    /// clears it when the value or encoding is `nil`) and posts
    /// ``defaultsChanged``. KVO-observable.
    @objc public dynamic var selectedConfiguration: Configuration?
    {
        get
        {
            if let data    = self.defaults?.object( forKey: "selectedConfiguration" ) as? Data,
               let decoded = try? PropertyListDecoder().decode( Configuration.self, from: data )
            {
                return decoded
            }

            return nil
        }

        set( value )
        {
            if let data = try? PropertyListEncoder().encode( value )
            {
                self.defaults?.setValue( data, forKey: "selectedConfiguration" )
                DistributedNotificationCenter.default().post( name: Preferences.defaultsChanged, object: nil )
            }
            else
            {
                self.defaults?.setValue( nil, forKey: "selectedConfiguration" )
                DistributedNotificationCenter.default().post( name: Preferences.defaultsChanged, object: nil )
            }
        }
    }
}
