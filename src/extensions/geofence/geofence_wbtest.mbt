///|
test "GeofenceMonitor streaming transitions" {
  let fences = [
    (@geometry.Rect::new(0.0, 0.0, 10.0, 10.0), 101),
    (@geometry.Rect::new(5.0, 5.0, 15.0, 15.0), 102),
    (@geometry.Rect::new(50.0, 50.0, 60.0, 60.0), 103),
  ]
  let monitor = GeofenceMonitor::new(fences, node_capacity=2)
  assert_eq(monitor.tracked_count(), 0)

  // Step 1: Object 1 spawns at (2, 2) -> Enters fence 101
  let events_1 = monitor.update_point(1, 2.0, 2.0)
  assert_eq(events_1.length(), 1)
  assert_eq(events_1[0], GeofenceEvent::Enter(1, 101))
  assert_eq(events_1[0].item_id(), 1)
  assert_eq(events_1[0].fence_id(), 101)
  assert_eq(events_1[0].to_string(), "Enter(1, 101)")
  assert_true(monitor.is_in_fence(1, 101))
  assert_false(monitor.is_in_fence(1, 102))
  assert_eq(monitor.tracked_count(), 1)

  // Step 2: Object 1 moves to (7, 7) -> In overlap of 101 & 102 -> Stay(1, 101) and Enter(1, 102)
  let events_2 = monitor.update_point(1, 7.0, 7.0)
  assert_eq(events_2.length(), 2)
  assert_true(events_2.contains(GeofenceEvent::Stay(1, 101)))
  assert_true(events_2.contains(GeofenceEvent::Enter(1, 102)))
  assert_true(monitor.is_in_fence(1, 101))
  assert_true(monitor.is_in_fence(1, 102))

  // Step 3: Object 1 moves to (12, 12) -> Exits 101, Stays in 102
  let events_3 = monitor.update_point(1, 12.0, 12.0)
  assert_eq(events_3.length(), 2)
  assert_true(events_3.contains(GeofenceEvent::Stay(1, 102)))
  assert_true(events_3.contains(GeofenceEvent::Exit(1, 101)))
  assert_false(monitor.is_in_fence(1, 101))
  assert_true(monitor.is_in_fence(1, 102))

  // Step 4: Rect update into fence 103
  let events_4 = monitor.update_rect(
    1,
    @geometry.Rect::new(51.0, 51.0, 55.0, 55.0),
  )
  assert_eq(events_4.length(), 2)
  assert_true(events_4.contains(GeofenceEvent::Exit(1, 102)))
  assert_true(events_4.contains(GeofenceEvent::Enter(1, 103)))
  assert_eq(monitor.active_fences(1), [103])

  // Step 5: Remove entity 1 -> Emits Exit(1, 103)
  let remove_events = monitor.remove_item(1)
  assert_eq(remove_events, [GeofenceEvent::Exit(1, 103)])
  assert_eq(monitor.tracked_count(), 0)
  assert_false(monitor.is_in_fence(1, 103))
}
