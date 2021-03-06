Changelog
=========

[0.1.2] - 2019-12-03
--------------------
### Changed
- Optimized `findpeaksp` to avoid calculating peak prominence when
  it is not needed.

### Fixed
- Fixed a bug caused wherein consecutive flat sections of data were
  sometimes considered a peak, even when they were not.

[0.1.1] - 2019-11-21
--------------------
### Fixed
- Added support fot flat peaks in the peak finding functions.
  `findpeaksp` and related functions should now no longer crash upon
  encountering a flat peak. See `help findpeaksp` for details.

[0.1.0] - 2019-10-30
--------------------
### Added
- Functions for analyzing peaks in a signal (`findpeaksp`, `prominence`,
  `peakwidth`).
