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

/// A representation of a remote car.
class Car {
  /// A unique identifier for the car.
  final String id;

  /// The name of the car. This value could be empty.
  final String name;

  const Car(this.id, this.name);

  /// Cars are equal when their ids are the same.
  @override
  bool operator ==(Object anotherCar) =>
      identical(this, anotherCar) ||
      ((anotherCar is Car) && (id == anotherCar.id));

  @override
  int get hashCode => id.hashCode;
}
