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

/// A value transformer that reports whether an array is empty, for binding UI
/// (such as enabling an empty-state view) to a collection's emptiness.
///
/// Non-array input is treated as empty.
@objc( ArrayIsEmpty )
public class ArrayIsEmpty: ValueTransformer
{
    /// The class of the transformed value: `NSNumber` (a boolean).
    public override class func transformedValueClass() -> AnyClass
    {
        NSNumber.self
    }

    /// Indicates the transformation is one-way.
    ///
    /// - Returns: Always `false`.
    public override class func allowsReverseTransformation() -> Bool
    {
        false
    }

    /// Transforms an array into whether it is empty.
    ///
    /// - Parameter value: The value to transform, expected to be an array.
    /// - Returns: `true` if `value` is an empty array or not an array at all;
    ///            otherwise `false`.
    public override func transformedValue( _ value: Any? ) -> Any?
    {
        guard let value = value as? [ Any ]
        else
        {
            return true
        }

        return value.isEmpty
    }
}
