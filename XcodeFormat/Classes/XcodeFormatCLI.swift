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

import ArgumentParser
import Foundation

/// The command-line interface for the app, used when the bundle binary is run
/// directly with arguments instead of being launched as the menu-bar app.
///
/// It can list the available configurations (`--list`) or format a set of files
/// in place with a named configuration (`--config <name> file…`). It shares the
/// app's stored configurations and the bundled formatters, so it works whether
/// or not the menu-bar app is running, and even before it has ever run.
public struct XcodeFormatCLI: ParsableCommand
{
    /// ArgumentParser metadata: the command name shown in help and usage.
    public static let configuration = CommandConfiguration(
        commandName: "XcodeFormat",
        abstract:    "Format source files using a named XcodeFormat configuration."
    )

    /// Whether to list the available configuration names and exit.
    @Flag( name: [ .customShort( "l" ), .long ], help: "List the available configurations." )
    var list = false

    /// Name of the configuration to format with.
    @Option( name: [ .customShort( "c" ), .long ], help: "Name of the configuration to use." )
    var config: String?

    /// Files to format in place.
    @Argument( help: "Source files to format in place." )
    var files: [ String ] = []

    /// Creates an empty command; ArgumentParser populates the properties.
    public init()
    {}

    /// Runs the command: lists configurations, formats files, or shows help.
    ///
    /// - Throws: ``CLIError`` for resolution/availability failures,
    ///           ``FileFormatter/ValidationError`` for bad inputs, or
    ///           ``FormatterError`` for formatter failures. ArgumentParser
    ///           prints the message and exits non-zero. A help request exits
    ///           with status zero.
    public func run() throws
    {
        let configurations = Self.availableConfigurations()

        if self.list
        {
            configurations.forEach
            {
                print( $0.name )
            }

            return
        }

        guard let name = self.config, self.files.isEmpty == false
        else
        {
            throw CleanExit.helpRequest( self )
        }

        guard let configuration = configurations.first( where: { $0.name == name } )
        else
        {
            throw CLIError.configurationNotFound( name: name, available: configurations.map { $0.name } )
        }

        try Self.format( files: self.files.map { URL( fileURLWithPath: $0 ) }, using: configuration )
    }

    /// The configurations available to the CLI.
    ///
    /// Uses the app's stored configurations when present; otherwise falls back
    /// to the built-in defaults in memory, without persisting them, so the CLI
    /// works standalone before the menu-bar app has ever seeded them.
    private static func availableConfigurations() -> [ Configuration ]
    {
        let stored = Preferences.shared.configurations

        return stored.isEmpty ? Configuration.defaultConfigurations : stored
    }

    /// Validates and formats the files with the resolved configuration.
    ///
    /// Downloads any missing configuration files synchronously, validates every
    /// file up front (so a bad input formats nothing), then formats each file
    /// in place, reporting per-file results on standard error.
    ///
    /// - Parameters:
    ///   - files:         Files to format in place.
    ///   - configuration: The configuration to format with.
    /// - Throws: ``CLIError`` when the configuration files cannot be obtained,
    ///           or the first validation/formatter error encountered.
    private static func format( files: [ URL ], using configuration: Configuration ) throws
    {
        configuration.downloadSynchronouslyIfNeeded()

        var caught:   Error?
        var resolved = false

        configuration.withConfigurations
        {
            configs in

            resolved = true

            do
            {
                try FileFormatter.validate( files: files, swiftFormatConfig: configs.swiftFormat, uncrustifyConfig: configs.uncrustify )

                try files.forEach
                {
                    url in

                    let changed = try FileFormatter.format( file: url, swiftFormatConfig: configs.swiftFormat, uncrustifyConfig: configs.uncrustify )

                    FileHandle.standardError.write( Data( "\( changed ? "Formatted" : "Unchanged" ): \( url.path )\n".utf8 ) )
                }
            }
            catch
            {
                caught = error
            }

            configs.finished()
        }
        error:
        {
            caught = CLIError.configurationFilesUnavailable( name: configuration.name )
        }

        if let caught = caught
        {
            throw caught
        }

        if resolved == false
        {
            throw CLIError.configurationFilesUnavailable( name: configuration.name )
        }
    }
}
