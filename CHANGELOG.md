Changelog
=========

Unreleased
----------
### Fixed
- Added support fot flat peaks in the peak finding functions.
  `findpeaksp` and related functions should now no longer crash upon
  encountering a flat peak. See `help findpeaksp` for details.

[0.1.0] - 2019-10-30
--------------------
### Added
- Functions for analyzing peaks in a signal (`findpeaksp`, `prominence`,
  `peakwidth`).
