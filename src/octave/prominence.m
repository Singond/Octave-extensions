## Copyright (C) 2019 Jan Slany
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
## @deftypefn  {Function file} {prom =} prominence(data, loc)
## @deftypefnx {Function file} {[prom, isol] =} prominence(data, loc)
## Return the prominence of peaks at @var{loc} in @var{data}.
##
## @var{loc} can be either indices of the peaks in @var{data} or a logical
## array specifying the peaks.
##
## The optional return value @var{isol} is a two-column matrix containing
## at each row the interval of isolation of a corresponding peak in @var{prom}.
## The value in the first column is the lower bound, while the value in the
## second column is the upper bound of the interval.
## @end deftypefn

## Author: Jan "Singon" Slany <singond@seznam.cz>
## Created: October 2019
## Keywords: signal processing, peak finding
function [prom, isol] = prominence(y, loc)
	if (length(y) < 2)
		error("Data must have at least two elements");
	endif
	## Make sure y is a column vector
	y = y(:);

	if (islogical(loc))
		idx = find(loc);
	else
		idx = loc;
	endif
	if (!iscolumn(idx))
		idx = idx(:);
	endif

	if (isscalar(idx))
		[prom, isol] = prominence_point(y, idx);
	else
		[prom, isol] = arrayfun(@(p) prominence_point(y, p), idx, ...
				"UniformOutput", false);
		prom = cell2mat(prom);
		isol = cell2mat(isol);
	endif
endfunction

function [prom, isol] = prominence_point(y, p)
	if (!((p == 1 || y(p-1) < y(p)) && (p == length(y) || y(p) > y(p+1))))
		error("The value at index %d is not a peak", p);
	endif

	## First, determine the isolation interval of the peak.
	## This is the widest interval in which the peak is the highest value.
	H = find(y > y(p));         # Indices of points higher than peak
	Hleft = H(H < p);           # All higher points left of peak
	if (!isempty(Hleft))
		left = max(Hleft);
	else
		left = 1;
	endif
	Hright = H(H > p);          # All higher points right of peak
	if (!isempty(Hright))
		right = min(Hright);
	else
		right = length(y);
	endif
	if (nargout > 1)
		isol = [left right];    # The isolation interval of the peak
	endif

	if (left == p)
		saddle = min(y(p:right));
	elseif (right == p)
		saddle = min(y(left:p));
	else
		saddle = max(min(y(left:p)), min(y(p:right)));
	endif
	prom = y(p) - saddle;
endfunction

%!# Error detection
%!error <The value at index 1 is not a peak> prominence([1 2 1],  1);
%!error <The value at index 2 is not a peak> prominence([2 1 2],  2);
%!error <The value at index 3 is not a peak> prominence([1 2 1],  3);
%!
%!error prominence([1], 1);

%!# Prominence of left edge
%!assert(prominence([5 4 8 7 2 1 4 2 5 9 1],  1),  1);
%!assert(prominence([10 4 8 7 2 1 4 2 5 9 1], 1),  9);
%!
%!# Prominence of midpoints
%!assert(prominence([1 4 8 7 2 1 4 2 5 9 1],  3),  7);
%!assert(prominence([1 4 8 7 2 3 4 2 5 9 1],  3),  6);
%!assert(prominence([1 4 8 7 2 1 4 2 5 9 1],  7),  2);
%!assert(prominence([1 4 8 7 2 1 4 2 5 9 1],  10), 8);
%!assert(prominence([1 4 8 7 2 1 4 2 5 9 1],  [3 7 10]),  [7 2 8]');
%!# Always return column vectors
%!assert(prominence([1 4 8 7 2 1 4 2 5 9 1],  [3 7 10]'), [7 2 8]');
%!assert(prominence([1 4 8 7 2 1 4 2 5 9 1]', [3 7 10]),  [7 2 8]');
%!assert(prominence([1 4 8 7 2 1 4 2 5 9 1]', [3 7 10]'), [7 2 8]');
%!test
%!	A = [1 4 8 7 2 1 4 2 5 9 1];
%!	assert(prominence(A, A > 7), [7 8]');
%!	assert(prominence(A, A > 8), 8);
%!
%!# Prominence of right edge
%!assert(prominence([1 4 8 7 2 1 4 2 5 9 10], 11), 9);

%!# Extract the isolation interval output value
%!function isol = isol(y, p)
%!	[~, isol] = prominence(y, p);
%!endfunction
%!
%!# Behaviour at left edge
%!assert(isol([5 4 8 7 2 1 4 2 5 9 1],  1),  [1 3]);
%!assert(isol([10 4 8 7 2 1 4 2 5 9 1], 1),  [1 11]);
%!
%!# Peaks not at endpoints
%!assert(isol([1 4 8 7 2 1 4 2 5 9 1],  3),  [1 10]);
%!assert(isol([1 4 8 7 2 1 4 2 5 9 1],  7),  [4 9]);
%!assert(isol([1 4 8 7 2 1 4 2 5 9 1],  10), [1 11]);
%!assert(isol([1 4 8 7 2 1 4 2 5 9 1],  [3 7 10]),  [1, 10; 4, 9; 1, 11]);
%!# Always return column vectors
%!assert(isol([1 4 8 7 2 1 4 2 5 9 1],  [3 7 10]'), [1, 10; 4, 9; 1, 11]);
%!assert(isol([1 4 8 7 2 1 4 2 5 9 1]', [3 7 10]),  [1, 10; 4, 9; 1, 11]);
%!assert(isol([1 4 8 7 2 1 4 2 5 9 1]', [3 7 10]'), [1, 10; 4, 9; 1, 11]);
%!
%!# Behaviour at right edge
%!assert(isol([1 4 8 7 2 1 4 2 5 9 10], 11), [1 11]);