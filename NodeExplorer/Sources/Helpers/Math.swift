//  Copyright © 2018 JABT. All rights reserved.

import Foundation


public func clamp<T: Comparable>(_ val: T, min: T, max: T) -> T {
    assert(min < max, "min has to be less than max")
    if val < min { return min }
    if val > max { return max }
    return val
}
