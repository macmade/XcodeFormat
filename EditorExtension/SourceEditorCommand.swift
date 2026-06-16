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
import XcodeKit

/// The Xcode source editor command that formats the active buffer.
///
/// Invoked from Xcode's *Editor ▸ XcodeFormat* menu, it picks the formatter
/// matching the buffer's type — SwiftFormat for Swift, uncrustify for the C
/// family — using the user's selected configuration, then rewrites the buffer
/// and restores the caret.
public class SourceEditorCommand: NSObject, XCSourceEditorCommand
{
    /// Entry point Xcode calls to run the command on the current buffer.
    ///
    /// Resolves the selected configuration and the buffer's uniform type, makes
    /// the needed configuration files available locally, and formats the buffer
    /// with the matching tool. Does nothing (reporting success) when there is no
    /// selected configuration or the buffer's type is unknown.
    ///
    /// - Parameters:
    ///   - invocation:        The buffer and command context provided by Xcode.
    ///   - completionHandler: Called once formatting finishes; receives an error
    ///                        to surface in Xcode's banner, or `nil` on success
    ///                        or a silent no-op.
    public func perform( with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping ( Error? ) -> Void )
    {
        guard let configuration = Preferences.shared.selectedConfiguration,
              let uti           = UTType( invocation.buffer.contentUTI )
        else
        {
            completionHandler( nil )

            return
        }

        configuration.withConfigurations
        {
            do
            {
                if uti == .swiftSource, let config = $0.swiftFormat?.path
                {
                    try self.format( buffer: invocation.buffer, executable: "swiftformat", arguments: [ "--config", config ] )
                }
                else if let language = UncrustifyLanguage.argument( for: uti ), let config = $0.uncrustify?.path
                {
                    try self.format( buffer: invocation.buffer, executable: "uncrustify", arguments: [ "-c", config, "-l", language, "-q" ] )
                }

                $0.finished()
                completionHandler( nil )
            }
            catch
            {
                $0.finished()
                completionHandler( error )
            }
        }
        error:
        {
            completionHandler( nil )
        }
    }

    /// Runs a formatter over the buffer's full contents and, if it produced
    /// changed output, replaces the buffer and restores the caret.
    ///
    /// The buffer text is piped to the executable as UTF-8 standard input. The
    /// result is classified by ``FormatterOutcome``; only a `.formatted`
    /// outcome rewrites the buffer. When a single (empty) selection exists, its
    /// caret is mapped onto the formatted text via
    /// ``CursorPosition/restored(in:line:column:)``.
    ///
    /// - Parameters:
    ///   - buffer:     The source buffer to read from and write back to.
    ///   - executable: Name of the formatter executable to run.
    ///   - arguments:  Command-line arguments for the formatter.
    /// - Throws: ``FormatterError/executableNotFound(_:)`` if the tool could not
    ///           be launched, or ``FormatterError/failed(executable:status:message:)``
    ///           if it exited with a non-zero status.
    private func format( buffer: XCSourceTextBuffer, executable: String, arguments: [ String ] ) throws
    {
        guard let data = buffer.completeBuffer.data( using: .utf8 )
        else
        {
            return
        }

        guard let task = ProcessTask.run( name: executable, arguments: arguments, input: data )
        else
        {
            throw FormatterError.executableNotFound( executable )
        }

        guard let status = task.terminationStatus
        else
        {
            throw FormatterError.failed( executable: executable, status: -1, message: "" )
        }

        let outcome = try FormatterOutcome.classify( executable: executable, input: buffer.completeBuffer, status: status, standardOutput: task.standardOutput, standardError: task.standardError )

        guard case .formatted( let out ) = outcome
        else
        {
            return
        }

        let selections = buffer.selections as? [ XCSourceTextRange ] ?? []
        let insertion  = selections.first
        {
            $0.start.line == $0.end.line && $0.start.column == $0.end.column
        }

        buffer.completeBuffer = out

        buffer.selections.removeAllObjects()

        guard let insertion = insertion,
              let restored  = CursorPosition.restored( in: out, line: insertion.start.line, column: insertion.start.column )
        else
        {
            return
        }

        let pos = XCSourceTextPosition( line: restored.line, column: restored.column )

        buffer.selections.add( XCSourceTextRange( start: pos, end: pos ) )
    }
}
