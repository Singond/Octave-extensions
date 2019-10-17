function [pks, loc] = findpeaksp(varargin)
	p = inputParser();
	p.FunctionName = "findpeaksp";
	p.addRequired("data", @isnumeric);
	p.addParameter("Threshold", 0, @isscalar);
	p.addParameter("MinPeakProminence", 0, @isscalar);
	p.addParameter("Sort", "none", @(s) any(strcmp(s, sortcriteria())));
	p.addParameter("NPeaks", -1);
	p.addSwitch("Ascending");
	p.parse(varargin{:});
	r = p.Results;
	y = r.data;
	minslope = r.Threshold;
	minprom = r.MinPeakProminence;
	sort = r.Sort;
	npeaks = r.NPeaks;
	ascending = r.Ascending;

	## Ensure y is a row vector
	if (!isrow(y))
		y = y(:)';
	endif

	## Find local maxima with minimum slope
	## TODO: Handle flat peaks
	dy = diff(y);
	mask = [0 (dy(1:end-1) >= minslope) & (dy(2:end) <= -minslope) 0];
	mask(1) = dy(1) <= -minslope;
	mask(end) = dy(end) >= minslope;
	loc = find(mask);

	## Filter by prominence
	prom = prominence(y, loc);
	mask = prom >= minprom;
	loc = loc(mask);
	prom = prom(mask);

	## Sort
	if (!strcmp(sort, "none"))
		if (ischar(sort))
			sortcols = sortcriteria(sort) + 1;
		elseif (iscell(sort))
			sortcols = cellfun(@sortcriteria, sort) + 1;
		endif;
		if (!ascending)
			sortcols = -sortcols;
		endif
		[~, sortedrows] = sortrows([loc', y(loc)', prom'], sortcols);
		loc = loc(sortedrows);
	endif

	## Select n most (or least, if 'last' is given) important peaks
	if (npeaks > 0 && npeaks <= length(loc))
		loc = loc(1:npeaks);
	endif

	## If no output value is requested, display the results in a plot
	if (nargout == 0)
		clf;
		hold on;
		coloridx = get(gca, "ColorOrderIndex");
		plot(y);
		set(gca, "ColorOrderIndex", coloridx);
		plot(loc, y(loc), "v", "markerfacecolor", "auto");
		hold off;
		return;
	endif

	## Return peak values
	pks = y(loc);
endfunction

function R = sortcriteria(name)
	persistent sortcriteria = {"value", "prominence"};
	if (nargin == 0)
		R = sortcriteria;
	else
		R = find(strcmp(sortcriteria, name));
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

%!# Sort by various criteria
%!test
%!	Y = [1 2 1 7 3 9 6 8 7 1 5 2 6 1];
%!	assert(p = findpeaksp(Y),                                    [2 7 9 8 5 6]);
%!	assert(p = findpeaksp(Y, "Sort", "value"),                   [9 8 7 6 5 2]);
%!	assert(p = findpeaksp(Y, "Sort", "value", "ascending"),      [2 5 6 7 8 9]);
%!	assert(p = findpeaksp(Y, "Sort", "value", "NPeaks", 3),      [9 8 7]);
%!	assert(p = findpeaksp(Y, "Sort", "prominence"),              [9 6 7 5 8 2]);
%!	assert(p = findpeaksp(Y, "Sort", "prominence", "ascending"), [2 8 5 7 6 9]);
%!	assert(p = findpeaksp(Y, "Sort", "prominence", "Npeaks", 3), [9 6 7]);

%!test
%!	Y = [1 2 1 7 3 9 6 8 7 1 5 2 6 1];
%!	p = findpeaksp(Y, "MinPeakProminence", 4, "Sort", "value");
%!	assert(p, [9 7 6]);

%!test
%!	Y = [1 2 1 7 3 9 6 8 7 1 5 2 6 1];
%!	p = findpeaksp(Y, "MinPeakProminence", 4, "Sort", "prominence");
%!	assert(p, [9 6 7]);

%!test
%!	Y = [1 2 1 7 3 9 6 8 7 1 5 2 6 1];
%!	p = findpeaksp(Y, "MinPeakProminence", 4, "Sort", "value", "Npeaks", 2);
%!	assert(p, [9 7]);