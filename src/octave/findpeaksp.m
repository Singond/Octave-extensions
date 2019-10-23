## -*- texinfo -*-
## @deftypefn {Function file} {[@var{pks}, @var{locs}] =} findpeaksp(@var{data})
## @deftypefnx {Function file} {[@dots{}] =} findpeaksp(@dots{}, @var{option}, @dots{})
## @deftypefnx {Function file} {[@dots{}] =} findpeaksp(@dots{}, @var{param1}, @var{value1}, @dots{})
## @deftypefnx {Function file} {} findpeaksp(@dots{})
## Find local maxima in @var{data}.
##
## The return value @var{pks} is a row vector of the values of @var{data}
## at the peaks. The corresponding indices of the peak locations are returned
## in @var{loc}.
##
## Options (@var{option}, @dots{}) are specified after the
## required arguments. Currently, only the following flag is supported:
## @table @asis
## @item Ascending
## When sorting the peaks in the return value (see below), the default sort
## order is @emph{descending} (ie. from highest to lowest, from most prominent
## to least prominent, etc.). Use this switch to reverse that direction.
## @end table
##
## Further options can be specified as key-value pairs. In each pair, the
## parameter name (a string) comes first and is followed by the value of the
## parameter.
## The following parameters are recognized:
##
## @table @asis
## @item Threshold
## Minimum height difference from neighbours (non-negative scalar).
## Use this to return only those peaks whose minimum vertical separation
## from the neighbouring samples is greater than or equal to this value.
##
## @item MinPeakProminence
## Minimum prominence of a peak (non-negative scalar).
## The prominence of a peak is the vertical distance between this peak and
## its highest saddle. A "saddle" is here understood to mean the lowest point
## on any path leading from the peak to a higher value.
## Use this parameter to return only those peaks whose prominence is at least
## the given value.
##
## @item Sort
## Criterion for sorting the peaks in the returned vector.
## Can be either @code{"value"} or @code{"prominence"}.
## If left unspecified, the peaks are sorted by their occurence in @var{data}.
##
## @item NPeaks
## Number of peaks to return (positive integer).
## When given with a value of @var{n}, @code{findpeaksp} returns only the
## first @var{n} peaks of those that would be returned otherwise.
## This is useful in combination with the @code{Sort} parameter and the
## @code{Ascending} option.
## For example, using @code{"Sort", "prominence", "NPeaks", 4} will return
## only the four most prominent peaks. To return the four @emph{least}
## prominent peaks, add the @code{"Ascending"} option.
## @end table
##
## When called without output arguments, @code{findpeaksp} plots the data
## with peaks highlighted.
## @end deftypefn
function [pks, loc] = findpeaksp(varargin)
	p = inputParser();
	p.FunctionName = "findpeaksp";
	p.addRequired("data", @isnumeric);
	p.addParameter("Threshold", 0, @isscalar);
	p.addParameter("MinPeakProminence", 0, @isscalar);
	p.addParameter("MinPeakWidth", -1, @isscalar);
	p.addParameter("MaxPeakWidth", -1, @isscalar);
	p.addParameter("Sort", "none", @(s) any(strcmp(s, sortcriteria())));
	p.addParameter("NPeaks", -1);
	p.addSwitch("Ascending");
	## TODO: Make "Annotate" a parameter (see MATLAB implementation)
	p.addSwitch("Annotate");
	p.parse(varargin{:});
	r = p.Results;
	y = r.data;
	minslope = r.Threshold;
	minprom = r.MinPeakProminence;
	minwidth = r.MinPeakWidth;
	maxwidth = r.MaxPeakWidth;
	sort = r.Sort;
	npeaks = r.NPeaks;
	ascending = r.Ascending;
	annotate = r.Annotate;

	## Ensure y is a column vector
	if (!iscolumn(y))
		y = y(:);
	endif

	## Find local maxima with minimum slope
	## TODO: Handle flat peaks
	dy = diff(y);
	loc = find((dy(1:end-1) >= minslope) & (dy(2:end) <= -minslope)) + 1;

	## Filter by prominence
	prom = sparse(length(y), 1);
	prom(loc) = prominence(y, loc);
	loc(prom(loc) < minprom) = [];

	if (minwidth > 0 || maxwidth > 0 || nargout > 2)
		w = sparse(length(y), 1);
		refh = sparse(loc, 1, y(loc) - prom(loc)/2);    # Reference height
		w(loc) = arrayfun(@(idx) peakwidth(y, idx, refh(idx)), loc);
	endif

	## Filter by width
	if (minwidth > 0)
		loc(w(loc) < minwidth) = [];
	endif
	if (maxwidth > 0)
		loc(w(loc) > maxwidth) = [];
	endif

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
		[~, sortedrows] = sortrows([loc, y(loc), prom(loc)], sortcols);
		loc = loc(sortedrows);
	endif

	## Select the first n peaks in the sorted output
	if (npeaks > 0 && npeaks <= length(loc))
		loc = loc(1:npeaks);
	endif

	## If no output value is requested, display the results in a plot
	if (nargout == 0)
		clf;
		hold on;
		## Data
		coloridx = get(gca, "ColorOrderIndex");
		plot(y);
		## Annotations
		if (annotate)
			## Prominence
			b = sparse(loc, 1, y(loc) - prom(loc));     # Prominence baseline
			for idx = loc(:)'
				line([idx idx], [y(idx) b(idx)], "color", "r");
			endfor
		endif
		## Peaks (plot these at end to make them appear over annotations)
		set(gca, "ColorOrderIndex", coloridx);
		plot(loc, y(loc), "v", "markerfacecolor", "auto");
		hold off;
		return;
	endif

	## Set return values
	pks = y(loc)';
	loc = loc';
endfunction

function R = sortcriteria(name)
	persistent sortcriteria = {"value", "prominence"};
	if (nargin == 0)
		R = sortcriteria;
	else
		R = find(strcmp(sortcriteria, name));
	endif
endfunction

%!# Test the return values of findpeaksp
%!function a(args, pks_exp, loc_exp)
%!	[pks, loc] = findpeaksp(args{:});
%!	if (nargin > 1)
%!		if (isempty(pks_exp))
%!			assert(isempty(pks));
%!		else
%!			assert(pks, pks_exp);
%!		endif
%!	endif
%!	if (nargin > 2)
%!		if (isempty(loc_exp))
%!			assert(isempty(loc));
%!		else
%!			assert(loc, loc_exp);
%!		endif
%!	endif
%!endfunction

%!# No criteria specified, find all local maxima
%!test a({[1 2 3 1]}, 3, 3);
%!test a({[1 3 2 1]}, 3, 2);
%!test a({[1 2 1]}, 2, 2);
%!test a({[1 6 3 4 1]}, [6 4], [2 4]);
%!test a({[6 3 4]}, [], []);

%!# The output should always be a row vector, regardless of the shape of input
%!test a({[1 4 1 5 1 6 1]'}, [4 5 6], [2 4 6]);

%!# Filter by minimum prominence
%!test a({[1 2 1 3 1 4 1 5 1 6 1], "MinPeakProminence", 3}, [4 5 6], [6 8 10]);
%!test a({[1 2 3 4 5 4 3 2 1],     "MinPeakProminence", 3}, 5, 5);
%!test a({[7 8 2 5 3 8 7],         "MinPeakProminence", 2}, 5, 4);
%!test a({[1 6 3 4],               "MinPeakProminence", 2}, 6, 2);

%!# Filter by minimum slope on each side
%!test a({[1 1.9 1 5 6 5 1 3 1], "Threshold", 0}, [1.9 6 3], [2 5 8]);
%!test a({[1 1.9 1 5 6 5 1 3 1], "Threshold", 1}, [6 3], [5 8]);
%!test a({[1 1.9 1 5 6 5 1 3 1], "Threshold", 2}, [3], [8]);

%!# Filter by peak width
%!shared Y
%!	Y = [0 10 0 1 7 8 7 1 0];
%!test a({Y, "MinPeakWidth", 1}, [10 8], [2 6]);
%!test a({Y, "MinPeakWidth", 3}, 8, 6);
%!test a({Y, "MinPeakWidth", 4}, [], []);
%!test a({Y, "MaxPeakWidth", 3}, [10 8], [2 6]);
%!test a({Y, "MaxPeakWidth", 1}, 10, 2);
%!test a({Y, "MaxPeakWidth", 0.5}, [], []);
%!shared Y
%!	Y = [0 10 0 1 7 8 7 1 0 10 9 12 11 9 0];
%!test a({Y},                    [10 8 10 12], [2 6 10 12]);
%!test a({Y, "MinPeakWidth", 1}, [10 8 12], [2 6 12]);
%!test a({Y, "MinPeakWidth", 3}, [8 12], [6 12]);
%!test a({Y, "MinPeakWidth", 4}, [12], [12]);
%!test a({Y, "MinPeakWidth", 2, "MaxPeakWidth", 4}, 8, 6);

%!# Sort by various criteria
%!shared Y
%!	Y = [1 2 1 7 3 9 6 8 7 1 5 2 6 1];
%!test a({Y},                                    [2 7 9 8 5 6]);
%!test a({Y, "Sort", "value"},                   [9 8 7 6 5 2]);
%!test a({Y, "Sort", "value", "ascending"},      [2 5 6 7 8 9]);
%!test a({Y, "Sort", "value", "NPeaks", 3},      [9 8 7]);
%!test a({Y, "Sort", "prominence"},              [9 6 7 5 8 2]);
%!test a({Y, "Sort", "prominence", "ascending"}, [2 8 5 7 6 9]);
%!test a({Y, "Sort", "prominence", "Npeaks", 3}, [9 6 7]);

%!test a({Y, "MinPeakProminence", 4, "Sort", "value"},      [9 7 6]);
%!test a({Y, "MinPeakProminence", 4, "Sort", "prominence"}, [9 6 7]);
%!test a({Y, "MinPeakProminence", 4, "Sort", "value", "Npeaks", 2}, [9 7]);
