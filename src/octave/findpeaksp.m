function [pks, loc] = findpeaksp(y, min_prom)
	minslope = 0;

	## Find local maxima
	## TODO: Handle flat peaks
	dy = diff(y);
	mask = [0 (dy(1:end-1) > minslope) & (dy(2:end) < -minslope) 0];
	mask(1) = dy(1) < -minslope;
	mask(end) = dy(end) > minslope;
	loc = find(mask);

	## Filter by prominence
	prom = prominence(y, loc);
	loc = loc(prom >= min_prom);

	## Return peak values
	pks = y(loc);

	## If no output value is requested, display the results in a plot
	if (nargout == 0)
		clf;
		hold on;
		coloridx = get(gca, "ColorOrderIndex");
		plot(y);
		set(gca, "ColorOrderIndex", coloridx);
		#plot(loc, pks, "v", "linemarkerfacecolor", "auto");
		plot(loc, pks, "v");
		hold off;
	endif
endfunction

%!assert(findpeaksp([1 2 3], 0), 3);
%!assert(findpeaksp([3 2 1], 0), 3);
%!assert(findpeaksp([1 2 1], 0), 2);
%!assert(findpeaksp([6 3 4], 0), [6 4]);

%!assert(findpeaksp([1 2 1 3 1 4 1 5 1 6 1], 3), [4 5 6]);
%!assert(findpeaksp([1 2 3 4 5 4 3 2 1], 3), 5);
%!assert(findpeaksp([7 8 2 5 3 8 7], 2), 5);
%!assert(findpeaksp([6 3 4], 2), 6);
