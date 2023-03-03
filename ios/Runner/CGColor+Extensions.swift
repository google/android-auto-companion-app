// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import UIKit

extension CGColor {
  /// Returns the color as ARGB value.
  public func argb() -> UInt32 {
    let color = UIColor.init(cgColor: self)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0

    color.getRed(&r, green: &g, blue: &b, alpha: &a)

    return UInt32(a * 255) << 24 | UInt32(r * 255) << 16 | UInt32(g * 255) << 8 | UInt32(b * 255)
  }
}
