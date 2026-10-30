// Copyright 2026 Antigravity Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// Online streaming trajectory compressor performing real-time decimation against error tolerance.
pub struct StreamingTrajectoryCompressor {
  epsilon : Double
  use_sed : Bool
  mut buffer : Array[TrajectoryPoint]
  emitted : Array[TrajectoryPoint]
  mut total_received : Int32
} derive(Eq, Debug)

///|
/// Instantiates an online trajectory compressor with error bound epsilon and optional SED calculation.
pub fn StreamingTrajectoryCompressor::new(
  epsilon : Double,
  use_sed~ : Bool = false,
) -> StreamingTrajectoryCompressor {
  StreamingTrajectoryCompressor::{
    epsilon,
    use_sed,
    buffer: [],
    emitted: [],
    total_received: 0,
  }
}

///|
/// Ingests a new trajectory waypoint and returns any newly finalized anchor waypoints.
pub fn StreamingTrajectoryCompressor::push(
  self : StreamingTrajectoryCompressor,
  pt : TrajectoryPoint,
) -> Array[TrajectoryPoint] {
  self.total_received = self.total_received + 1

  if self.buffer.length() == 0 {
    self.buffer.push(pt)
    self.emitted.push(pt)
    return [pt]
  }

  if self.buffer.length() == 1 {
    self.buffer.push(pt)
    return []
  }

  // Check if adding pt violates error bound for any intermediate point in buffer
  let anchor = self.buffer[0]
  let mut violated = false

  for i = 1; i < self.buffer.length(); i = i + 1 {
    let mid = self.buffer[i]
    let dist = if self.use_sed {
      synchronized_euclidean_distance(mid, anchor, pt)
    } else {
      perpendicular_distance(mid.x, mid.y, anchor.x, anchor.y, pt.x, pt.y)
    }
    if dist > self.epsilon {
      violated = true
      break
    }
  }

  if violated {
    // Lock in the previous point
    let prev = self.buffer[self.buffer.length() - 1]
    self.emitted.push(prev)
    self.buffer = [prev, pt]
    [prev]
  } else {
    self.buffer.push(pt)
    []
  }
}

///|
/// Flushes the remaining trajectory stream and returns all preserved decimated waypoints.
pub fn StreamingTrajectoryCompressor::finish(
  self : StreamingTrajectoryCompressor,
) -> Array[TrajectoryPoint] {
  if self.buffer.length() > 1 {
    let last = self.buffer[self.buffer.length() - 1]
    let mut already_emitted = false
    if self.emitted.length() > 0 {
      let tail = self.emitted[self.emitted.length() - 1]
      if tail.x == last.x && tail.y == last.y && tail.t == last.t {
        already_emitted = true
      }
    }
    if !already_emitted {
      self.emitted.push(last)
    }
  }

  let res : Array[TrajectoryPoint] = []
  for i = 0; i < self.emitted.length(); i = i + 1 {
    res.push(self.emitted[i])
  }
  res
}

///|
/// Returns total number of incoming points received so far.
pub fn StreamingTrajectoryCompressor::total_received(
  self : StreamingTrajectoryCompressor,
) -> Int32 {
  self.total_received
}

///|
/// Returns total number of finalized waypoints emitted so far.
pub fn StreamingTrajectoryCompressor::total_emitted(
  self : StreamingTrajectoryCompressor,
) -> Int32 {
  self.emitted.length()
}

///|
/// Computes point decimation percentage ((1 - emitted / received) * 100).
pub fn StreamingTrajectoryCompressor::compression_ratio(
  self : StreamingTrajectoryCompressor,
) -> Double {
  if self.total_received <= 0 {
    0.0
  } else {
    (1.0 - self.emitted.length().to_double() / self.total_received.to_double()) *
    100.0
  }
}
