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

public class SourceEditorCommand: NSObject, XCSourceEditorCommand
{
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
            if uti == .swiftSource
            {
                self.format( buffer: invocation.buffer, executable: "swiftformat", arguments: [ "--config", $0.swiftFormat.path ] )
            }

            $0.finished()
            completionHandler( nil )
        }
        error:
        {
            completionHandler( nil )
        }
    }

    private func format( buffer: XCSourceTextBuffer, executable: String, arguments: [ String ] )
    {
        guard let data   = buffer.completeBuffer.data( using: .utf8 ),
              let task   = Task.run( name: executable, arguments: arguments, input: data ),
              let status = task.terminationStatus,
              let out    = String( data: task.standardOutput, encoding: .utf8 ),
              status     == 0
        else
        {
            return
        }

        buffer.completeBuffer = out
    }
}
