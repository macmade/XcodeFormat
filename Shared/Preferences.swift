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

public class Preferences: NSObject
{
    static let shared                = Preferences()
    static let defaultsChanged = Notification.Name( "com.xs-labs.XcodeFormat.Preferences.ConfigurationsChanged" )

    private var defaults        = UserDefaults( suiteName: "326Y53CJMD.com.xs-labs.XcodeFormat.Shared" )
    private var defaultsObserver: Any?

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

            self.willChangeValue( for: \.configurations )
            self.didChangeValue(  for: \.configurations )

            self.willChangeValue( for: \.selectedConfiguration )
            self.didChangeValue(  for: \.selectedConfiguration )
        }
    }

    @objc public dynamic var configurations: [ Configuration ]
    {
        get
        {
            if let data    = self.defaults?.object( forKey: "configurations" ) as? Data,
               let decoded = try? PropertyListDecoder().decode( Array< Configuration >.self, from: data )
            {
                return decoded
            }

            return []
        }

        set( value )
        {
            if let data = try? PropertyListEncoder().encode( value )
            {
                self.defaults?.setValue( data, forKey: "configurations" )
                DistributedNotificationCenter.default().post( name: Preferences.defaultsChanged, object: nil )
            }
        }
    }

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
        }
    }
}
