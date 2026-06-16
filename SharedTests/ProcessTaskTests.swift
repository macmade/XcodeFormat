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
import Testing

@Suite( "ProcessTask — child-process I/O" )
struct TaskTests
{
    // A payload several times larger than the 64 KB kernel pipe buffer. If the
    // output is not drained while the child writes, the child blocks on write
    // and the parent deadlocks in waitUntilExit(); if reads are torn down too
    // early, the tail is truncated. Either way this round-trip fails.
    private static let largePayload = Data( ( 0 ..< ( 256 * 1024 ) ).map { UInt8( $0 & 0xFF ) } )

    @Test( "Collects complete stdout for input larger than the pipe buffer", .timeLimit( .minutes( 1 ) ) )
    func largeInputRoundTrip() throws
    {
        let task = try #require( ProcessTask.run( executableURL: URL( fileURLWithPath: "/bin/cat" ), arguments: [], input: Self.largePayload ) )

        #expect( task.terminationStatus == 0 )
        #expect( task.standardOutput.count == Self.largePayload.count )
        #expect( task.standardOutput == Self.largePayload )
    }

    @Test( "Captures standard error", .timeLimit( .minutes( 1 ) ) )
    func capturesStandardError() throws
    {
        let task = try #require( ProcessTask.run( executableURL: URL( fileURLWithPath: "/bin/sh" ), arguments: [ "-c", "printf 'boom' 1>&2" ], input: nil ) )

        #expect( task.terminationStatus == 0 )
        #expect( String( data: task.standardError, encoding: .utf8 ) == "boom" )
    }

    @Test( "Reports a non-zero termination status", .timeLimit( .minutes( 1 ) ) )
    func nonZeroTerminationStatus() throws
    {
        let task = try #require( ProcessTask.run( executableURL: URL( fileURLWithPath: "/bin/sh" ), arguments: [ "-c", "exit 3" ], input: nil ) )

        #expect( task.terminationStatus == 3 )
    }

    @Test( "Returns nil for a non-existent executable" )
    func missingExecutable()
    {
        #expect( ProcessTask.run( executableURL: URL( fileURLWithPath: "/nonexistent/executable" ), arguments: [], input: nil ) == nil )
    }
}
