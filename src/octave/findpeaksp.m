function [pks, loc] = findpeaksp(y, min_prom)
	minslope = 0;

	## Find local maxima
	## TODO: Handle flat peaks
	dy = diff(y);
	mask = (dy(1:end-1) > minslope) & (dy(2:end) < -minslope);
	loc = find(mask) + 1;

	## Filter by prominence
	prom = prominence(y, loc);
	loc = loc(prom >= min_prom);

	pks = y(loc);
endfunction