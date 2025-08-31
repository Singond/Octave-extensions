## Copyright (C) 2022 Jan Slany
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
## @deftypefnx {} {} animate (@var{img}, @var{framelength})
## @deftypefnx {} {} animate (@dots{}, @qcode{"loop"})
## @deftypefnx {} {} animate (@dots{}, @var{args})
##
## Display a sequence of images @var{img} as an animation.
##
## The image sequence @var{img} should be a 3D array where individual
## frames are stacked along the last dimension.
## The delay between images in seconds can be set by @var{framelength}.
## If it is not seet, a default delay of 1 second is used.
##
## Automatic looping can be set by the @qcode{"loop"} option.
## If set, the animation restarts after reaching the last frame.
##
## The frames are displayed using @code{imshow}.
## Any unmatched arguments are passed to this function.
##
## @seealso{imshow}
## @end deftypefn

## Author: Jan "Singon" Slany <singond@seznam.cz>
## Created: October 2022
## Keywords: image processing, animation
function animate(img, framelength = 1, varargin)
	nframes = size(img, 3);

	unmatched = {};
	loop = false;
	n = 0;
	while (++n <= numel(varargin))
		arg = varargin{n};
		if (strcmp(arg, "loop"))
			loop = true;
		else
			unmatched{end + 1} = arg;
		endif
	endwhile

##	h = imshow(img(:,:,1), unmatched{:});
##	ax = gca();

	paused = false;

##	function pause
##	uicontrol(f1, "string", "Pause", "position", [10 10 120 30],
##		"callback", @() paused = true);

	player = VideoPlayer(img);
	player.play();
##	f = 0;
##	while (!paused && ++f <= nframes)
##		set(h, "cdata", img(:,:,f));
##		title(sprintf("frame %d", f));
##		if (loop && f == nframes)
##			f = 0;
##		endif
##		if (framelength > 0)
##			pause(framelength);
##		endif
##	endwhile
endfunction
