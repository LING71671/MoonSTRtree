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
/// Discrete transition event emitted when an entity crosses or resides within a geofence.
pub enum GeofenceEvent {
  Enter(Int, Int)
  Exit(Int, Int)
  Stay(Int, Int)
} derive(Eq, Debug)

///|
/// Formats geofence transition event.
pub fn GeofenceEvent::to_string(self : GeofenceEvent) -> String {
  match self {
    Enter(item_id, fence_id) =>
      "Enter(" + item_id.to_string() + ", " + fence_id.to_string() + ")"
    Exit(item_id, fence_id) =>
      "Exit(" + item_id.to_string() + ", " + fence_id.to_string() + ")"
    Stay(item_id, fence_id) =>
      "Stay(" + item_id.to_string() + ", " + fence_id.to_string() + ")"
  }
}

///|
/// Extracts the moving entity ID.
pub fn GeofenceEvent::item_id(self : GeofenceEvent) -> Int {
  match self {
    Enter(id, _) => id
    Exit(id, _) => id
    Stay(id, _) => id
  }
}

///|
/// Extracts the target geofence ID.
pub fn GeofenceEvent::fence_id(self : GeofenceEvent) -> Int {
  match self {
    Enter(_, fid) => fid
    Exit(_, fid) => fid
    Stay(_, fid) => fid
  }
}

///|
/// State tracker monitoring moving entity positions against a spatial index of geofences.
pub struct GeofenceMonitor {
  fence_tree : StrTree
  tracked_item_ids : Array[Int]
  tracked_fences : Array[Array[Int]]
} derive(Eq, Debug, Default)

///|
/// Instantiates a new GeofenceMonitor indexing the supplied geofence bounding boxes.
pub fn GeofenceMonitor::new(
  fences : Array[(@geometry.Rect, Int)],
  node_capacity? : Int = 16,
) -> GeofenceMonitor {
  let fence_tree = StrTree::build(fences, node_capacity~)
  GeofenceMonitor::{ fence_tree, tracked_item_ids: [], tracked_fences: [], }
}

///|
/// Locates index of tracked entity in internal array, or -1 if unregistered.
fn GeofenceMonitor::find_item_idx(self : GeofenceMonitor, item_id : Int) -> Int {
  for i = 0; i < self.tracked_item_ids.length(); i = i + 1 {
    if self.tracked_item_ids[i] == item_id {
      return i
    }
  }
  -1
}

///|
/// Compares previous and current active fence lists, updating internal tracking and returning transition events.
fn GeofenceMonitor::compute_transitions(
  self : GeofenceMonitor,
  item_id : Int,
  current_fences : Array[Int],
) -> Array[GeofenceEvent] {
  let idx = self.find_item_idx(item_id)
  let prev_fences : Array[Int] = if idx >= 0 {
    self.tracked_fences[idx]
  } else {
    []
  }

  let events : Array[GeofenceEvent] = []

  // Check Stay and Enter
  for i = 0; i < current_fences.length(); i = i + 1 {
    let fid = current_fences[i]
    let mut existed = false
    for j = 0; j < prev_fences.length(); j = j + 1 {
      if prev_fences[j] == fid {
        existed = true
        break
      }
    }
    if existed {
      events.push(GeofenceEvent::Stay(item_id, fid))
    } else {
      events.push(GeofenceEvent::Enter(item_id, fid))
    }
  }

  // Check Exit
  for j = 0; j < prev_fences.length(); j = j + 1 {
    let fid = prev_fences[j]
    let mut still_present = false
    for i = 0; i < current_fences.length(); i = i + 1 {
      if current_fences[i] == fid {
        still_present = true
        break
      }
    }
    if !still_present {
      events.push(GeofenceEvent::Exit(item_id, fid))
    }
  }

  // Update tracking record
  if idx >= 0 {
    self.tracked_fences[idx] = current_fences
  } else {
    self.tracked_item_ids.push(item_id)
    self.tracked_fences.push(current_fences)
  }

  events
}

///|
/// Updates entity position with a 2D bounding rectangle and returns generated Enter, Exit, and Stay events.
pub fn GeofenceMonitor::update_rect(
  self : GeofenceMonitor,
  item_id : Int,
  bounds : @geometry.Rect,
) -> Array[GeofenceEvent] {
  let current_fences = self.fence_tree.query(bounds)
  self.compute_transitions(item_id, current_fences)
}

///|
/// Updates entity position with a 2D point coordinate (x, y) and returns generated events.
pub fn GeofenceMonitor::update_point(
  self : GeofenceMonitor,
  item_id : Int,
  x : Double,
  y : Double,
) -> Array[GeofenceEvent] {
  let current_fences = self.fence_tree.query_point(x, y)
  self.compute_transitions(item_id, current_fences)
}

///|
/// Unregisters tracked entity and returns Exit events for all fences it was previously inside.
pub fn GeofenceMonitor::remove_item(
  self : GeofenceMonitor,
  item_id : Int,
) -> Array[GeofenceEvent] {
  let idx = self.find_item_idx(item_id)
  if idx < 0 {
    return []
  }

  let prev_fences = self.tracked_fences[idx]
  let events : Array[GeofenceEvent] = []
  for i = 0; i < prev_fences.length(); i = i + 1 {
    events.push(GeofenceEvent::Exit(item_id, prev_fences[i]))
  }

  // Remove from arrays by shifting tail
  let last_idx = self.tracked_item_ids.length() - 1
  if idx != last_idx {
    self.tracked_item_ids[idx] = self.tracked_item_ids[last_idx]
    self.tracked_fences[idx] = self.tracked_fences[last_idx]
  }
  let _ = self.tracked_item_ids.pop()
  let _ = self.tracked_fences.pop()

  events
}

///|
/// Returns currently active geofence IDs occupied by the entity.
pub fn GeofenceMonitor::active_fences(
  self : GeofenceMonitor,
  item_id : Int,
) -> Array[Int] {
  let idx = self.find_item_idx(item_id)
  if idx >= 0 {
    self.tracked_fences[idx]
  } else {
    []
  }
}

///|
/// Returns true if the entity is currently tracked inside the specified geofence.
pub fn GeofenceMonitor::is_in_fence(
  self : GeofenceMonitor,
  item_id : Int,
  fence_id : Int,
) -> Bool {
  let idx = self.find_item_idx(item_id)
  if idx < 0 {
    return false
  }
  for i = 0; i < self.tracked_fences[idx].length(); i = i + 1 {
    if self.tracked_fences[idx][i] == fence_id {
      return true
    }
  }
  false
}

///|
/// Returns the number of currently tracked entities.
pub fn GeofenceMonitor::tracked_count(self : GeofenceMonitor) -> Int {
  self.tracked_item_ids.length()
}

///|
/// Clears all tracked entities.
pub fn GeofenceMonitor::clear(self : GeofenceMonitor) -> Unit {
  self.tracked_item_ids.clear()
  self.tracked_fences.clear()
}

///|
/// Returns reference to the internal packed StrTree index of geofences.
pub fn GeofenceMonitor::fence_tree(self : GeofenceMonitor) -> StrTree {
  self.fence_tree
}
