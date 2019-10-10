function [prom, isol] = prominence(y, idx)
	## Make sure y is a column vector
	y = y(:);
	## Pad difference with some value to handle endpoints gracefully
	#dy = [1; diff(y); -1];
	## Filter out indices which are not peaks
	#idx = (dy(idx) >=0) & (dy(idx+1) <= 0);

	if (isscalar(idx))
		[prom, isol] = prominence_point(y, idx);
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
	prom = 0;
	isol = [left right];        # The isolation interval of the peak
	## TODO: Return the actual prominence
endfunction

%!error <The value at index 1 is not a peak> prominence([1 2 1],  1);
%!error <The value at index 3 is not a peak> prominence([1 2 1],  3);
%!
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
%!
%!# Behaviour at right edge
%!assert(isol([1 4 8 7 2 1 4 2 5 9 10], 11), [1 11]);