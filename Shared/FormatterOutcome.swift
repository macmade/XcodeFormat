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

/// The result of classifying a completed formatter run.
public enum FormatterOutcome: Equatable
{
    /// Nothing to apply — the formatter made no change (or produced no usable
    /// output). The buffer is left untouched and no error is reported.
    case unchanged

    /// The formatter produced new, non-empty output that should replace the
    /// buffer's contents.
    case formatted( String )

    /// Classifies a finished formatter run into an outcome, throwing a
    /// `FormatterError` for failures the user can act on.
    ///
    /// - A non-zero `status` throws `.failed`, carrying the formatter's stderr.
    /// - Output that is undecodable, identical to the input, or empty after
    ///   trimming is treated as `.unchanged` (a silent no-op).
    /// - Otherwise the new output is returned as `.formatted`.
    public static func classify( executable: String, input: String, status: Int32, standardOutput: Data, standardError: Data ) throws -> FormatterOutcome
    {
        guard status == 0
        else
        {
            throw FormatterError.failed( executable: executable, status: status, message: String( data: standardError, encoding: .utf8 ) ?? "" )
        }

        guard let output = String( data: standardOutput, encoding: .utf8 )
        else
        {
            return .unchanged
        }

        if output == input
        {
            return .unchanged
        }

        if output.trimmingCharacters( in: .whitespacesAndNewlines ).isEmpty
        {
            return .unchanged
        }

        return .formatted( output )
    }
}
