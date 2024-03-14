Changelog
=========

[0.4.1] - 2024-03-14
--------------------
### Changed
- Made `polyfitm` compatible with older versions of Octave
  (where `qr` does not know the `"econ"` parameter).

[0.4.0] - 2024-03-13
--------------------
### Added
- A utility function `dimfun` to apply arbitrary function on vectors
  of an array, analogous to what `arrayfun` does on single elements.

### Changed
- Made minor edits to function documentation.

### Fixed
- Corrected wrong information in function header.

[0.3.0] - 2024-03-11
--------------------
### Added
- Matrix version of `polyfit` from standard library.
  See `polyfitm`.

[0.2.2] - 2022-12-28
--------------------
### Added
- Missing license in the `animate` function header.

### Changed
- Unified the style of all function headers. The words "Function file"
  have been removed and a blank line has been added after the synopsis.

[0.2.1] - 2022-12-28 [YANKED]
-----------------------------
Removed due to missing version data in sources.

[0.2.0] - 2022-10-02
--------------------
### Added
- The `animate` function.

### Changed
- Re-implemented `prominence`. By default, the function now uses a new
  algorithm which performs better on large data with many peaks.
  The old algorithm is still used if the isolation interval is to be
  calculated.
- Endpoints of data are no more considered peaks in `prominence`.

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
