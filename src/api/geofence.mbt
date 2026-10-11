///|
/// Discrete transition event emitted when an entity crosses or resides within a geofence.
pub(all) enum GeofenceEvent {
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
  priv inner : @geofence.GeofenceMonitor
} derive(Eq, Debug, Default)

///|
/// Instantiates a new GeofenceMonitor indexing the supplied geofence bounding boxes.
pub fn GeofenceMonitor::new(
  fences : Array[(Rect, Int)],
  node_capacity? : Int = 16,
) -> GeofenceMonitor {
  let inner = @geofence.GeofenceMonitor::new(fences, node_capacity~)
  GeofenceMonitor::{ inner, }
}

///|
fn map_event(ev : @geofence.GeofenceEvent) -> GeofenceEvent {
  match ev {
    Enter(item_id, fence_id) => GeofenceEvent::Enter(item_id, fence_id)
    Exit(item_id, fence_id) => GeofenceEvent::Exit(item_id, fence_id)
    Stay(item_id, fence_id) => GeofenceEvent::Stay(item_id, fence_id)
  }
}

///|
/// Updates entity position with a 2D bounding rectangle and returns generated transition events.
pub fn GeofenceMonitor::update_rect(
  self : GeofenceMonitor,
  item_id : Int,
  bounds : Rect,
) -> Array[GeofenceEvent] {
  let evs = self.inner.update_rect(item_id, bounds)
  let res : Array[GeofenceEvent] = []
  for i = 0; i < evs.length(); i = i + 1 {
    res.push(map_event(evs[i]))
  }
  res
}

///|
/// Updates entity position with a 2D point coordinate (x, y) and returns generated events.
pub fn GeofenceMonitor::update_point(
  self : GeofenceMonitor,
  item_id : Int,
  x : Double,
  y : Double,
) -> Array[GeofenceEvent] {
  let evs = self.inner.update_point(item_id, x, y)
  let res : Array[GeofenceEvent] = []
  for i = 0; i < evs.length(); i = i + 1 {
    res.push(map_event(evs[i]))
  }
  res
}

///|
/// Unregisters tracked entity and returns Exit events for all fences it was previously inside.
pub fn GeofenceMonitor::remove_item(
  self : GeofenceMonitor,
  item_id : Int,
) -> Array[GeofenceEvent] {
  let evs = self.inner.remove_item(item_id)
  let res : Array[GeofenceEvent] = []
  for i = 0; i < evs.length(); i = i + 1 {
    res.push(map_event(evs[i]))
  }
  res
}

///|
/// Returns currently active geofence IDs occupied by the entity.
pub fn GeofenceMonitor::active_fences(
  self : GeofenceMonitor,
  item_id : Int,
) -> Array[Int] {
  self.inner.active_fences(item_id)
}

///|
/// Returns true if the entity is currently tracked inside the specified geofence.
pub fn GeofenceMonitor::is_in_fence(
  self : GeofenceMonitor,
  item_id : Int,
  fence_id : Int,
) -> Bool {
  self.inner.is_in_fence(item_id, fence_id)
}

///|
/// Returns the number of currently tracked entities.
pub fn GeofenceMonitor::tracked_count(self : GeofenceMonitor) -> Int {
  self.inner.tracked_count()
}

///|
/// Clears all tracked entities.
pub fn GeofenceMonitor::clear(self : GeofenceMonitor) -> Unit {
  self.inner.clear()
}
