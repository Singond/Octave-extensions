function [pks, loc] = findpeaksp(varargin)
#	[~, minslope, minprom] = parseparams(varargin, "Threshold", 0, "MinPeakProminence", 0);
	p = inputParser();
	p.FunctionName = "findpeaksp";
	p.addRequired("data", @isnumeric);
	p.addParameter("Threshold", 0, @isscalar);
	p.addParameter("MinPeakProminence", 0, @isscalar);
	p.parse(varargin{:});
	r = p.Results;
	y = r.data;
	minslope = r.Threshold;
	minprom = r.MinPeakProminence;

	## Ensure y is a row vector
	if (!isrow(y))
		y = y(:)';
	endif

	## Find local maxima
	## TODO: Handle flat peaks
	dy = diff(y);
	mask = [0 (dy(1:end-1) >= minslope) & (dy(2:end) <= -minslope) 0];
	mask(1) = dy(1) <= -minslope;
	mask(end) = dy(end) >= minslope;
	loc = find(mask);

	## Filter by prominence
	prom = prominence(y, loc);
	loc = loc(prom >= minprom);

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

%!# No criteria specified, find all local maxima
%!assert(p = findpeaksp([1 2 3]), 3);
%!assert(p = findpeaksp([3 2 1]), 3);
%!assert(p = findpeaksp([1 2 1]), 2);
%!assert(p = findpeaksp([6 3 4]), [6 4]);

%!# The output should always be a row vector, regardless of the shape of input
%!assert(p = findpeaksp([1 4 1 5 1 6 1]'), [4 5 6]);

%!# Set minimum prominence
%!assert(p = findpeaksp([1 2 1 3 1 4 1 5 1 6 1], "MinPeakProminence", 3), [4 5 6]);
%!assert(p = findpeaksp([1 2 3 4 5 4 3 2 1],     "MinPeakProminence", 3), 5);
%!assert(p = findpeaksp([7 8 2 5 3 8 7],         "MinPeakProminence", 2), 5);
%!assert(p = findpeaksp([6 3 4],                 "MinPeakProminence", 2), 6);

%!# Set minimum slope on each side
%!assert(findpeaksp([1 1.9 1 5 6 5 1 3 1], "Threshold", 0), [1.9 6 3]);
%!assert(findpeaksp([1 1.9 1 5 6 5 1 3 1], "Threshold", 1), [6 3]);
%!assert(findpeaksp([1 1.9 1 5 6 5 1 3 1], "Threshold", 2), [3]);
