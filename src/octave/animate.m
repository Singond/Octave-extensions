## Copyright (C) 2022, 2025 Jan Slany
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; see the file COPYING.  If not, see
## <https://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn  {} {} animate (@var{img})
## @deftypefnx {} {} animate (@dots{}, @qcode{"framerate"}, @var{frate})
## @deftypefnx {} {} animate (@dots{}, @qcode{"displayrange"}, [@var{lo} @var{hi}])
## @deftypefnx {} {} animate (@dots{}, @qcode{"colormap"}, @var{cmap})
## @deftypefnx {} {} animate (@dots{}, @qcode{"xdata"}, @var{xdata})
## @deftypefnx {} {} animate (@dots{}, @qcode{"ydata"}, @var{ydata})
## @deftypefnx {} {} animate (@dots{}, @qcode{"loop"})
##
## Display a sequence of images @var{img} as an animation.
##
## The image sequence @var{img} should be a 3D array where individual
## frames are stacked along the last dimension.
## The framerate in images per second can be set by @var{frate}.
## If it is not set, a default delay of 10 images per second is used.
##
## Automatic looping can be set by the @qcode{"loop"} option.
## If set, the animation restarts after reaching the last frame.
##
## The parameters @qcode{"displayrange"}, @qcode{"colormap"},
## @qcode{"xdata"} and @qcode{"ydata"} do the same thing as in @code{imshow}.
##
## @seealso{imshow}
## @end deftypefn

## Author: Jan "Singon" Slany <singond@seznam.cz>
## Created: October 2022
## Keywords: image processing, animation
function animate(img, varargin)
	player = VideoPlayer(img, varargin{:});
	player.play();
endfunction
