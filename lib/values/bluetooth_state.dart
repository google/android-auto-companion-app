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

/// The possible states that bluetooth can be in.
class BluetoothState {
  /// The Bluetooth adapter is in an error state. The connection manager will
  /// not function correctly when Bluetooth is in this state.
  static const error = '0';

  /// Bluetooth is on and the connection manager can be used to scan and connect
  /// to cars.
  static const on = '1';

  /// Bluetooth is off and the connection manager cannot be used to scan and
  /// connect to cars.
  static const off = '2';
}
