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

/// Formats source files on disk with the bundled command-line formatters.
///
/// This is the file-based counterpart to the Xcode editor command: it picks the
/// formatter matching a file's type — SwiftFormat for Swift, uncrustify for the
/// C family — runs it over the file's contents, and rewrites the file in place
/// when the output differs. It carries no editor/cursor logic and is used by the
/// command-line mode.
public enum FileFormatter
{
    /// The formatter that applies to a given file, along with any language hint
    /// it needs.
    public enum Tool: Equatable
    {
        /// Format with SwiftFormat.
        case swiftFormat

        /// Format with uncrustify, using the given `-l` language token.
        case uncrustify( language: String )
    }

    /// A pre-flight failure that prevents formatting from starting.
    public enum ValidationError: LocalizedError, Equatable
    {
        /// No file exists at the given path.
        case fileNotFound( URL )

        /// The file's type maps to no available formatter.
        case unsupportedType( URL )

        /// The formatter for the file has no configuration file available.
        case missingConfiguration( URL )

        /// A localized, user-facing description of the failure.
        public var errorDescription: String?
        {
            switch self
            {
                case .fileNotFound( let url ):

                    return "No such file: \( url.path )"

                case .unsupportedType( let url ):

                    return "Unsupported file type: \( url.path )"

                case .missingConfiguration( let url ):

                    return "No formatter configuration available for: \( url.path )"
            }
        }
    }

    /// Resolves the formatter that applies to a file, based on its path
    /// extension.
    ///
    /// Mirrors the editor command's type handling: Swift source uses
    /// SwiftFormat, while the C family is delegated to
    /// ``UncrustifyLanguage/argument(for:)``. Returns `nil` for types neither
    /// formatter handles.
    ///
    /// - Parameter url: The file whose extension is examined.
    /// - Returns: The matching ``Tool``, or `nil` when the type is unsupported.
    public static func tool( for url: URL ) -> Tool?
    {
        guard let type = UTType( filenameExtension: url.pathExtension )
        else
        {
            return nil
        }

        if type == .swiftSource
        {
            return .swiftFormat
        }

        if let language = UncrustifyLanguage.argument( for: type )
        {
            return .uncrustify( language: language )
        }

        return nil
    }

    /// Validates every file before any formatting begins, so a bad input aborts
    /// the whole run without modifying anything.
    ///
    /// Each file must exist, resolve to a supported ``Tool``, and have the
    /// configuration file its formatter requires.
    ///
    /// - Parameters:
    ///   - files:             Files to be formatted.
    ///   - swiftFormatConfig: The available SwiftFormat configuration, or `nil`.
    ///   - uncrustifyConfig:  The available uncrustify configuration, or `nil`.
    /// - Throws: A ``ValidationError`` for the first file that fails a check.
    public static func validate( files: [ URL ], swiftFormatConfig: URL?, uncrustifyConfig: URL? ) throws
    {
        try files.forEach
        {
            url in

            guard FileManager.default.fileExists( atPath: url.path )
            else
            {
                throw ValidationError.fileNotFound( url )
            }

            guard let tool = self.tool( for: url )
            else
            {
                throw ValidationError.unsupportedType( url )
            }

            switch tool
            {
                case .swiftFormat:

                    if swiftFormatConfig == nil
                    {
                        throw ValidationError.missingConfiguration( url )
                    }

                case .uncrustify:

                    if uncrustifyConfig == nil
                    {
                        throw ValidationError.missingConfiguration( url )
                    }
            }
        }
    }

    /// Formats a single file in place, rewriting it only when the formatter
    /// produced changed output.
    ///
    /// The file's bytes are piped to the matching formatter as standard input.
    /// The result is classified by ``FormatterOutcome``; only a `.formatted`
    /// outcome overwrites the file.
    ///
    /// - Parameters:
    ///   - url:               The file to format in place.
    ///   - swiftFormatConfig: SwiftFormat configuration file, or `nil`.
    ///   - uncrustifyConfig:  Uncrustify configuration file, or `nil`.
    /// - Returns: `true` if the file was rewritten, `false` if it was left
    ///            unchanged.
    /// - Throws: ``ValidationError`` when the type or configuration is
    ///           unusable, or ``FormatterError`` when the formatter cannot be
    ///           launched or exits with a non-zero status.
    @discardableResult
    public static func format( file url: URL, swiftFormatConfig: URL?, uncrustifyConfig: URL? ) throws -> Bool
    {
        let executable: String
        let arguments:  [ String ]

        switch self.tool( for: url )
        {
            case .swiftFormat:

                guard let config = swiftFormatConfig?.path
                else
                {
                    throw ValidationError.missingConfiguration( url )
                }

                executable = "swiftformat"
                arguments  = [ "--config", config ]

            case .uncrustify( let language ):

                guard let config = uncrustifyConfig?.path
                else
                {
                    throw ValidationError.missingConfiguration( url )
                }

                executable = "uncrustify"
                arguments  = [ "-c", config, "-l", language, "-q" ]

            case nil:

                throw ValidationError.unsupportedType( url )
        }

        let input = try Data( contentsOf: url )

        guard let task = ProcessTask.run( name: executable, arguments: arguments, input: input )
        else
        {
            throw FormatterError.executableNotFound( executable )
        }

        guard let status = task.terminationStatus
        else
        {
            throw FormatterError.failed( executable: executable, status: -1, message: "" )
        }

        let outcome = try FormatterOutcome.classify( executable: executable, input: String( data: input, encoding: .utf8 ) ?? "", status: status, standardOutput: task.standardOutput, standardError: task.standardError )

        guard case .formatted( let output ) = outcome
        else
        {
            return false
        }

        try Data( output.utf8 ).write( to: url )

        return true
    }
}
