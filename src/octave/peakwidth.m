function [w, ext] = peakwidth(y, p, h)
	x = [1:length(y)]';
	if (!iscolumn(y))
		y = y(:);
	endif
	if (!size_equal(x, y))
		error("x and y must have the same size");
	endif
	if (!size_equal(p, h))
		error("p and h must have the same size");
	endif
	if (p < min(x) || p > max(x))
		error("Position out of bounds");
	endif

	if (isscalar(p))
		[w, ext] = peakwidth_point(y, x, p, h);
	else
		p = p(:);
		h = h(:);
		[w, ext] = arrayfun(@(_p, _h) peakwidth_point(y, x, _p, _h), p, h, ...
				"UniformOutput", false);
		w = cell2mat(w);
		ext = cell2mat(ext);
	endif
endfunction

function [w, ext] = peakwidth_point(y, x, p, h)
	L = find(y < h);
	Lleft = L(L < p);
	if (!isempty(Lleft))
		low = max(Lleft);
		high = low + 1;
		left = interp1(y([low high]), x([low high]), h);
	else
		left = 1;
	endif
	Lright = L(L > p);
	if (!isempty(Lright))
		low = min(Lright);
		high = low - 1;
		right = interp1(y([high low]), x([high low]), h);
	else
		right = length(x);
	endif
	w = right - left;
	if (nargin > 1)
		ext = [left right];
	endif;
endfunction