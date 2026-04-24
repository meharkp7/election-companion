/// Step status for journey progress display.
///
/// This is purely a UI concern for step progress cards.
/// The backend controls actual state transitions — this enum only
/// determines visual styling (locked/active/done).
enum StepStatus {
  locked,
  active,
  done,
}
