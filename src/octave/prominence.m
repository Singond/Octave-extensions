function [prom, isol] = prominence(y, idx)
	if (length(y) < 2)
		error("Data must have at least two elements");
	endif
	## Make sure y is a column vector
	y = y(:);

	if (isscalar(idx))
		[prom, isol] = prominence_point(y, idx);
	else
		[prom, isol] = arrayfun(@(p) prominence_point(y, p), idx, ...
				"UniformOutput", false);
		prom = cell2mat(prom);
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
	isol = [left right];        # The isolation interval of the peak

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
%!assert(prominence([1 4 8 7 2 1 4 2 5 9 1],  [3 7 10]), [7 2 8]);
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
%!assert(isol([1 4 8 7 2 1 4 2 5 9 1],  [3 7 10]), {[1 10], [4 9], [1 11]});
%!
%!# Behaviour at right edge
%!assert(isol([1 4 8 7 2 1 4 2 5 9 10], 11), [1 11]);