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

/// Runs an external command-line tool to completion, feeding it optional
/// standard input and capturing its full standard output, standard error, and
/// exit status.
///
/// Output is drained on background queues before standard input is written and
/// before the call blocks waiting for exit, so a child that produces a large
/// amount of output cannot deadlock by filling a pipe buffer. Instances are
/// created and run through the ``run(name:arguments:input:)`` /
/// ``run(executableURL:arguments:input:)`` factory methods.
public class ProcessTask
{
    /// The underlying process being run.
    private var task:    Process

    /// Pipe capturing the child's standard output.
    private var pipeOut: Pipe

    /// Pipe capturing the child's standard error.
    private var pipeErr: Pipe

    /// The child's exit status, or `nil` until the process has finished.
    public private( set ) var terminationStatus: Int32?

    /// The complete bytes the child wrote to standard output.
    public private( set ) var standardOutput:    Data

    /// The complete bytes the child wrote to standard error.
    public private( set ) var standardError:     Data

    /// Runs an executable bundled alongside the host's main executable.
    ///
    /// Resolves `name` relative to the directory containing the main bundle's
    /// executable, then runs it synchronously via
    /// ``run(executableURL:arguments:input:)``.
    ///
    /// - Parameters:
    ///   - name:      File name of the sibling executable to run.
    ///   - arguments: Command-line arguments passed to the executable.
    ///   - input:     Data to write to the child's standard input, or `nil` for
    ///                no standard input.
    /// - Returns: The finished task, or `nil` if the executable URL could not be
    ///            resolved or the file does not exist.
    public class func run( name: String, arguments: [ String ], input: Data? ) -> ProcessTask?
    {
        guard let executable = Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent( name )
        else
        {
            return nil
        }

        return self.run( executableURL: executable, arguments: arguments, input: input )
    }

    /// Runs the executable at a given URL synchronously and returns the
    /// finished task.
    ///
    /// - Parameters:
    ///   - executableURL: Location of the executable to run.
    ///   - arguments:     Command-line arguments passed to the executable.
    ///   - input:         Data to write to the child's standard input, or `nil`
    ///                    for no standard input.
    /// - Returns: The finished task, or `nil` if no file exists at
    ///            `executableURL`.
    public class func run( executableURL: URL, arguments: [ String ], input: Data? ) -> ProcessTask?
    {
        guard FileManager.default.fileExists( atPath: executableURL.path )
        else
        {
            return nil
        }

        let task = ProcessTask( executable: executableURL, arguments: arguments )

        task.run( input: input )

        return task
    }

    /// Configures the process and its output pipes without launching it.
    ///
    /// - Parameters:
    ///   - executable: Location of the executable to run.
    ///   - arguments:  Command-line arguments passed to the executable.
    private init( executable: URL, arguments: [ String ] )
    {
        self.pipeOut = Pipe()
        self.pipeErr = Pipe()
        self.task    = Process()

        self.task.launchPath     = executable.path
        self.task.arguments      = arguments
        self.task.standardOutput = self.pipeOut
        self.task.standardError  = self.pipeErr

        self.standardOutput = Data()
        self.standardError  = Data()
    }

    /// Launches the process, writes optional standard input, blocks until the
    /// child exits, and publishes its output and exit status.
    ///
    /// Both output pipes are drained to EOF on background queues before
    /// standard input is written and before the call blocks, so the child
    /// cannot deadlock on a full pipe buffer and its output is captured in
    /// full. In `DEBUG` builds any captured standard-error text is printed.
    ///
    /// - Parameter input: Data to write to the child's standard input, or `nil`
    ///                    to provide no standard input.
    public func run( input: Data? )
    {
        if let _ = input
        {
            self.task.standardInput = Pipe()
        }

        self.task.launch()

        // Drain both output pipes to EOF on background queues, started before we
        // write stdin and before we block in waitUntilExit(). This guarantees the
        // child can never deadlock by filling a pipe buffer we aren't reading, and
        // that the full output is collected rather than truncated.
        let group   = DispatchGroup()
        var outData = Data()
        var errData = Data()

        DispatchQueue.global( qos: .userInitiated ).async( group: group )
        {
            outData = self.pipeOut.fileHandleForReading.readDataToEndOfFile()
        }

        DispatchQueue.global( qos: .userInitiated ).async( group: group )
        {
            errData = self.pipeErr.fileHandleForReading.readDataToEndOfFile()
        }

        if let input = input, let pipe = self.task.standardInput as? Pipe
        {
            let handle = pipe.fileHandleForWriting

            handle.write( input )
            try? handle.close()
        }

        self.task.waitUntilExit()

        // The child has exited and closed its pipe ends, so both reads have hit
        // (or are about to hit) EOF. Join them before publishing the results.
        group.wait()

        self.standardOutput    = outData
        self.standardError     = errData
        self.terminationStatus = self.task.terminationStatus

        #if DEBUG
            if let err = String( data: self.standardError, encoding: .utf8 )?.trimmingCharacters( in: .whitespacesAndNewlines )
            {
                print( err )
            }
        #endif
    }
}
