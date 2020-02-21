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
## @deftypefn  {Function file} {@var{prom} =} prominence(@var{data})
## @deftypefnx {Function file} {@var{prom} =} prominence(@var{data}, @var{loc})
## @deftypefnx {Function file} {[@var{prom}, @var{isol}] =} prominence(@dots{})
## Return the prominence of peaks at @var{loc} in @var{data}.
##
## @var{loc} can be either indices of the peaks in @var{data} or a logical
## array specifying the peaks. If omitted, it defaults to all peaks.
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

	if (nargin > 1)
		if (islogical(loc))
			loc = find(loc);
		endif
		if (!iscolumn(loc))
			loc = loc(:);
		endif
	else
		loc = [];       # Calculate all peaks
	endif

	if (nargout > 1)
		## If isolation interval is requested, we need the naive algorithm
		algorithm = "naive";
	else
		algorithm = "loopall";
	endif

	switch (algorithm)
		case "naive"
			if (isscalar(loc))
				[prom, isol] = prominence_point(y, loc);
			else
				if (isempty(loc))
					[~, loc] = findpeaksp(y);
				endif
				[prom, isol] = arrayfun(@(p) prominence_point(y, p), loc, ...
						"UniformOutput", false);
				prom = cell2mat(prom);
				isol = cell2mat(isol);
			endif
		case "loopall"
			[prom L] = prominence_loopall(y);
			if (!isempty(loc))
				if (any(!ismember(loc, L)))
					## Some indices in 'loc' were not recognized as peaks.
					## This may happen even for valid peaks, if the peak
					## in question is flat and it is referenced by a point
					## other than its left edge (as done in L).
					##
					## Try normalizing indices of flat peaks to their left edge:
					## Denote the left and right edge of peak as L and R,
					## respectively. For sharp peaks, the only valid index
					## is L == R. For flat peaks, valid indices are all
					## indices L <= index <= R. If an index does not fall
					## between L and R corresponding to the same peak,
					## it is not a peak at all.

					## For all indices in 'loc', find the preceding L
					## and following R.
					[~, R] = findpeaksp(y, "FlatPeaks", "right");
					idxl = lookup(L, loc);              # Nearest preceding L
					idxr = flip(length(R) + 1 ...
						- lookup(flip([-Inf R]), loc)); # Nearest following R
					## (idxl and idxr are indices in L, R)
					validloc = (idxl == idxr & idxl > 0 & idxl <= length(L));
					if (all(validloc))
						## All indices in 'loc' are between L and R
						## corresponding to the same peak, therefore,
						## they are peaks.
						## Normalize those to the left edge:
						loc = L(idxl);
					else
						## Some indices in 'loc' are not peaks
						error("The value at index %d is not a peak\n",...
							loc(!validloc));
					endif
				endif

				assert(all(ismember(loc, L)));
				## Select only peaks requested in 'loc'
				promsparse = zeros(size(y));
				promsparse(L) = prom;
				prom = promsparse(loc);
			endif
		otherwise
			error("Unknown algorithm name: %s", algorithm);
	endswitch
endfunction

function [prom, isol] = prominence_point(y, p)
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
	if (saddle < y(p))
		prom = y(p) - saddle;
	else
		error("The value at index %d is not a peak", p);
	endif
endfunction

function [prom pks] = prominence_loopall(y)
	[h, pks] = findpeaksp(y);
	[~, vls] = findpeaksp(-y);

	## If no peaks are found, return now;
	if (isempty(pks))
		prom = [];
		return;
	endif

	h = h';                         # Heights of peaks
	pks = pks';                     # Indices of peaks
	vls = vls';                     # Indices of valleys between peaks

	lpk = [0 1:(length(h)-1)]';     # Index of peak to the left of h
	rpk = [2:(length(h)) 0]';       # Index of peak to the right of h

	## Pad list of valleys so that every peak has a valley to the left and right
	if (isempty(vls))
		## Single peak with no valleys around: pad both sides
		leftpad = y(1);
		rightpad = y(end);
	else
		if (vls(1) > pks(1))
			## There is no valley before first peak: assume first y-value
			leftpad = y(1);
		else
			leftpad = [];
		endif
		if (vls(end) < pks(end))
			## There is no valley after last peak: assume last y-value
			rightpad = y(end);
		else
			rightpad = [];
		endif
	endif
	v = [leftpad; y(vls); rightpad];
	lv = v(1:end-1);                # Height of valley to the left of peak
	rv = v(2:end);                  # Height of valley to the right of peak

	[~, s] = sort(h);               # Indices of peaks sorted in ascending ord.

	key = zeros(size(h));
	kmax = length(h);
#	sk = 1;                     # Debug only
	vg = [];                    # Valleys around adjacent peaks of equal height
	vgi = 0;                    # Index of current position in vg
	k0 = 0;                     # Index of first peak in sequence
	for k = s'
#		# Debug only
#		processed = pks(s(1:sk-1));
#		waiting = pks(s(sk+1:end));
#		plot(y, "", pks(k), y(pks(k)), "rv",...
#			processed, y(processed), "bv", "markerfacecolor", "none",...
#			waiting, y(waiting), "bv");
#		hold on;
#		if (k != 1 && lpk(k) != 0)
#			_l = pks(lpk(k));
#		else
#			_l = 1;
#		endif
#		if (k != kmax && rpk(k) != 0)
#			_r = pks(rpk(k));
#		else
#			_r = length(y);
#		endif
#		plot([_l pks(k)], lv(k)([1 1]), "g");
#		plot([pks(k) _r], rv(k)([1 1]), "g");
#		if (!isempty(vg))
#			fidx = pks(k0:k0+length(vg)-2);
#			plot(fidx, y(fidx), "g+");
#		endif
#		hold off;
#		sk += 1;

		## Assume that peak to the left is always higher than current peak
		## (due to sorting of s and looping from left to right).
		## Check if peak to the right is strictly higher.
		rpksame = rpk(k) != 0 && h(rpk(k)) == h(k);

		if (isempty(vg) && !rpksame)
			## Not in special mode for handling peaks of equal height
			## and the peak to the right is higher: calculate prominence,
			## knowing that both neighbouring peaks are higher than this,
			## ie. that the saddles at each sides are the adjacent valleys.
			vv = sort([lv(k) rv(k)]);
			vk = vv(1);                 # Valley to keep
			key(k) = vv(2);             # Key saddle for this peak

			## Remove the key saddle from the valley list
			if (lpk(k) > 0)
				rv(lpk(k)) = vk;
				rpk(lpk(k)) = rpk(k);
			endif
			if (rpk(k) > 0)
				lv(rpk(k)) = vk;
				lpk(rpk(k)) = lpk(k);
			endif
			continue;
		endif

		if (isempty(vg))
			## Peak to the right is the same height: start special mode,
			## assuming the current position is the beginning of the
			## sequence of equally high peaks.
#			warning("Peak %d has the same height as peak %d\n", rpk(k), k);
			hh = find(h > h(k));        # Indices of higher peaks
			nhi = min(hh(hh > k));      # Index of next strictly higher peak
#			if (isempty(nhi))
#				nhi = peaks(end);
#			endif
			f = k:lpk(nhi);
			f(h(f) < h(k)) = [];        # Indices of peaks in the sequence
			vg = [lv(f); rv(f(end))];
			vgi = 1;
			k0 = k;
		endif

		## In special mode: evaluating subsequent peaks of equal height
		lvk = min(vg(1:vgi));
		rvk = min(vg(vgi+1:end));
		key(k) = max(lvk, rvk);

		if (!rpksame)
			## Next peak (if any) is higher: terminate special mode...
			minv = min(vg);             # Lowest valley
			vg = [];
			vgi = 0;
			## ... and remove the whole sequence of peaks/valleys from the list
			if (lpk(k0) > 0)
				rv(lpk(k0)) = minv;
				rpk(lpk(k0)) = rpk(k);
			endif
			if (rpk(k) > 0)
				lv(rpk(k)) = minv;
				lpk(rpk(k)) = lpk(k0);
			endif
		else
			## More peaks of this height follow: mark the next position
			vgi += 1;
		endif
	endfor
	## Calculate prominence from the key saddle
	prom = h - key;
endfunction

%!# Error detection
%!error <The value at index 1 is not a peak> prominence([1 2 1],  1);
%!error <The value at index 2 is not a peak> prominence([2 1 2],  2);
%!error <The value at index 3 is not a peak> prominence([1 2 1],  3);
%!
%!error prominence([1], 1);

%!# Working with logical array
%!test
%!	A = [1 4 8 7 2 1 4 2 5 9 1];
%!	p = [0 0 1 0 0 0 1 0 0 1 0];
%!	assert(prominence(A,  logical(p)),  [7 2 8]');

%!# Prominence of left edge
%!#assert(prominence([5 4 8 7 2 1 4 2 5 9 1],  1),  1); # TODO: Consider edges as peaks?
%!#assert(prominence([10 4 8 7 2 1 4 2 5 9 1], 1),  9); # TODO: Consider edges as peaks?
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
%!#assert(prominence([1 4 8 7 2 1 4 2 5 9 10], 11), 9); # TODO: Consider edges as peaks?

%!# Prominence of flat peaks
%!assert(prominence([1 4 4 1], 2), 3);
%!assert(prominence([1 4 4 1], 3), 3);
%!error <The value at index 1 is not a peak> prominence([1 4 4 1], 1);
%!error <The value at index 4 is not a peak> prominence([1 4 4 1], 4);
%
%!assert(prominence([1 4 4 2 5 5 1], 2), 2);
%!assert(prominence([1 4 4 2 5 5 1], 3), 2);
%!assert(prominence([1 4 4 2 5 5 1], 5), 4);
%!assert(prominence([1 4 4 2 5 5 1], 6), 4);
%!error <The value at index 1 is not a peak> prominence([1 4 4 2 5 5 1], 1);
%!error <The value at index 4 is not a peak> prominence([1 4 4 2 5 5 1], 4);
%!error <The value at index 7 is not a peak> prominence([1 4 4 2 5 5 1], 7);
%
%!error <The value at index 2 is not a peak> prominence([1 4 4 5 1], 2);

%!# Subsequent peaks of equal height (affects loopall algorithm)
%!assert(prominence([5 6 3 3 7 5 5 7 5 2 7 6 3 4 11 17 8 0]), [1 4 4 4 15]');

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