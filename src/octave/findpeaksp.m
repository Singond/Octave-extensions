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
## @deftypefn  {} {[@var{pks}, @var{locs}] =} findpeaksp (@var{data})
## @deftypefnx {} {[@dots{}] =} findpeaksp (@dots{}, @var{option}, @dots{})
## @deftypefnx {} {[@dots{}] =} findpeaksp (@dots{}, @var{param1}, @var{value1}, @dots{})
## @deftypefnx {} {} findpeaksp (@dots{})
##
## Find local maxima in @var{data}.
##
## The return value @var{pks} is a row vector of the values of @var{data}
## at the peaks. The corresponding indices of the peak locations are returned
## in @var{loc}.
##
## Options (@var{option}, @dots{}) are specified after the
## required arguments. Currently, only the following flag is supported:
## @table @asis
##
## @item Ascending
## When sorting the peaks in the return value (see below), the default sort
## order is @emph{descending} (ie. from highest to lowest, from most prominent
## to least prominent, etc.). Use this switch to reverse that direction.
##
## @item Annotate
## When plotting, mark the peak height and width by lines.
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
## @item FlatPeaks
## How to handle flat peaks.
## Supported values are @qcode{"left"}, @qcode{"right"}, @qcode{"center"}
## or @qcode{"ignore"}.
## When a flat peak is encountered, one of the points on the plateau has
## to be chosen as the location of the peak.
## The options @qcode{"left"}, @qcode{"right"}, @qcode{"center"} control how
## this point is chosen: @qcode{"left"} and @qcode{"right"} use the left
## and right edge, respectively, while @qcode{"center"} tries to find the
## point nearest to the centre, rounding to nearest integer index if necessary.
## The @qcode{"ignore"} option discards flat peaks altogether.
##
## The default value is @qcode{"left"}.
##
## @item MinPeakProminence
## Minimum prominence of a peak (non-negative scalar).
## The prominence of a peak is the vertical distance between this peak and
## its highest saddle. A "saddle" is here understood to mean the lowest point
## on any path leading from the peak to a higher value.
## Use this parameter to return only those peaks whose prominence is at least
## the given value.
##
## @item MinPeakWidth
## Minimum width of a peak (non-negative scalar).
## The width of a peak is measured at a reference height. By default,
## this reference height is the half-prominence of the peak in question.
## Use this parameter to return only peaks with the given width or wider.
##
## @item MaxPeakWidth
## Maximum width of a peak (non-negative scalar).
## Use this parameter to return only peaks with the given width or narrower.
## See @qcode{"MinPeakWidth"} for more information on how the width
## is calculated.
##
## @item Sort
## Criterion for sorting the peaks in the returned vector.
## Can be either @qcode{"value"} or @qcode{"prominence"}.
## If left unspecified, the peaks are sorted by their occurence in @var{data}.
##
## @item NPeaks
## Number of peaks to return (positive integer).
## When given with a value of @var{n}, @code{findpeaksp} returns only the
## first @var{n} peaks of those that would be returned otherwise.
## This is useful in combination with the @qcode{"Sort"} parameter and the
## @qcode{"Ascending"} option. For example, using
##
## @example
##     findpeaksp(data, "Sort", "prominence", "NPeaks", 4)
## @end example
##
## will return only the four most prominent peaks. To return the four
## @emph{least} prominent peaks, add the @qcode{"Ascending"} option.
## @end table
##
## When called without output arguments, @code{findpeaksp} plots the data
## with peaks highlighted.
##
## @seealso{peakwidth, prominence, findpeaks}
## @end deftypefn

## Author: Jan "Singon" Slany <singond@seznam.cz>
## Created: October 2019
## Keywords: signal processing, peak finding
function [pks, loc] = findpeaksp(varargin)
	p = inputParser();
	p.FunctionName = "findpeaksp";
	p.addRequired("data", @isnumeric);
	p.addParameter("Threshold", -1, @isscalar);
	p.addParameter("FlatPeaks", "left", ...
			@(s) any(strcmp(s, {"left", "right", "center", "ignore"})));
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
	threshold = r.Threshold;
	flatPeaks = r.FlatPeaks;
	minprom = r.MinPeakProminence;
	minwidth = r.MinPeakWidth;
	maxwidth = r.MaxPeakWidth;
	sortby = r.Sort;
	npeaks = r.NPeaks;
	ascending = r.Ascending;
	annotate = r.Annotate;

	## Ensure y is a column vector
	if (!iscolumn(y))
		y = y(:);
	endif

	## Find local maxima

	dy = diff(y);
	## Find sharp peaks (they go down on both sides)
	if (threshold > 0)
		## Find points whose difference to neighbour is at least 'threshold'
		sh = find((dy(1:end-1) >= threshold) & (dy(2:end) <= -threshold)) + 1;
	else
		## No threshold given, use all points higher than neighbours
		sh = find((dy(1:end-1) > 0) & (dy(2:end) < 0)) + 1;
	endif

	## Find flat peaks
	if (!strcmp("ignore", flatPeaks))
		## Mark plateau edges into "fl":
		## 1 is left edge after a rise, 2 is right edge before a rise,
		## 4 is left edge after a drop, 8 is right edge before a drop.
		fl = zeros(size(y), "int8");
		if (threshold > 0)
			fl((2:end-1)((dy(1:end-1) >= threshold) & (dy(2:end) == 0))) = 1;
			fl((2:end-1)((dy(1:end-1) == 0) & (dy(2:end) >= threshold))) = 2;
			fl((2:end-1)((dy(1:end-1) <= threshold) & (dy(2:end) == 0))) = 4;
			fl((2:end-1)((dy(1:end-1) == 0) & (dy(2:end) <= threshold))) = 8;
		else
			fl((2:end-1)((dy(1:end-1) > 0) & (dy(2:end) == 0))) = 1;
			fl((2:end-1)((dy(1:end-1) == 0) & (dy(2:end) > 0))) = 2;
			fl((2:end-1)((dy(1:end-1) < 0) & (dy(2:end) == 0))) = 4;
			fl((2:end-1)((dy(1:end-1) == 0) & (dy(2:end) < 0))) = 8;
		endif
		## Filter-out plateaux which are not peaks
		fli = find(fl);
		fli_pk = find((fl(fli)(1:end-1) == 1) & (fl(fli)(2:end) == 8));
		fll = fli(fli_pk);
		flr = fli(fli_pk + 1);
		clear fl fli fli_pk;
		## Mark each peak with one point only
		if (strcmp(flatPeaks, "left"))
			fl = fll;
		elseif (strcmp(flatPeaks, "right"))
			fl = flr;
		elseif (strcmp(flatPeaks, "center"))
			fl = round(mean([fll flr]')');
		endif
	else
		fl = [];
	endif
	## Combine sharp and flat peaks
	loc = sort([sh; fl]);

	needwidth = minwidth > 0 || maxwidth > 0 || nargout > 2 || annotate;
	needprom = minprom > 0 || annotate || needwidth || !strcmp(sortby, "none");

	## Filter by prominence
	if (needprom)
		prom = sparse(length(y), 1);
		prom(loc) = prominence(y, loc);
		loc(prom(loc) < minprom) = [];
	endif

	## Calculate width (if required)
	if (needwidth)
		w = sparse(length(y), 1);
		refh = sparse(loc, 1, y(loc) - prom(loc)/2);    # Reference height
		if (annotate)
			ext = sparse(length(y), 2);
			[w(loc), ext(loc,:)] = peakwidth(y, loc, refh(loc));
		else
			w(loc) = arrayfun(@(idx) peakwidth(y, idx, refh(idx)), loc);
		endif
	endif

	## Filter by width
	if (minwidth > 0)
		loc(w(loc) < minwidth) = [];
	endif
	if (maxwidth > 0)
		loc(w(loc) > maxwidth) = [];
	endif

	## Sort
	if (!strcmp(sortby, "none"))
		if (ischar(sortby))
			sortcols = sortcriteria(sortby) + 1;
		elseif (iscell(sortby))
			sortcols = cellfun(@sortcriteria, sortby) + 1;
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
			## Line styles
			prom_ls = {"color", "r"};
			width_ls = {"color", [1 0.6 0]};
			b = sparse(loc, 1, y(loc) - prom(loc));     # Prominence baseline
			for idx = loc(:)'
				## Prominence
				line([idx idx], [y(idx) b(idx)], prom_ls{:});
				## Width
				line(ext(idx,:), [refh(idx) refh(idx)], width_ls{:});
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

%!# Handle flat peaks
%!test a({[2 1 1 1 2]}, [], []);
%!test a({[1 2 2 1 3 3 3 4 1]}, [2 4], [2 8]);
%!test a({[1 6 2 4 4 4 2 6 1]}, [6 4 6], [2 4 8]);
%!test a({[1 2 2 5 4 4 2]}, 5, 4);
%!shared Y
%!	Y = [1 2 2 2 1 3 3 1 4 4 5 7 7 4 4 1];
%!test a({Y},                         [2 3 7], [2 6 12]);
%!test a({Y, "FlatPeaks", "left"},    [2 3 7], [2 6 12]);
%!test a({Y, "FlatPeaks", "right"},   [2 3 7], [4 7 13]);
%!test a({Y, "FlatPeaks", "ignore"},  [], []);

%!# Filter by minimum prominence
%!test a({[1 2 1 3 1 4 1 5 1 6 1], "MinPeakProminence", 3}, [4 5 6], [6 8 10]);
%!test a({[1 2 3 4 5 4 3 2 1],     "MinPeakProminence", 3}, 5, 5);
%!test a({[7 8 2 5 3 8 7],         "MinPeakProminence", 2}, 5, 4);
%!test a({[1 6 3 4],               "MinPeakProminence", 2}, 6, 2);
%!# With flat peaks
%!test a({[1 2 1 3 3 1 5 5 1 6 6 1], "MinPeakProminence", 3}, [5 6], [7 10]);

%!# Filter by minimum slope on each side
%!test a({[1 1.9 1 5 6 5 1 3 1], "Threshold", 0}, [1.9 6 3], [2 5 8]);
%!test a({[1 1.9 1 5 6 5 1 3 1], "Threshold", 1}, [6 3], [5 8]);
%!test a({[1 1.9 1 5 6 5 1 3 1], "Threshold", 2}, [3], [8]);
%!test a({[1 2 2 1 4 4 1], "Threshold", 2}, [4], [5]);

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
%!	Y = [0 10 0 7 7 0 2 2 2 0];
%!test a({Y, "MinPeakWidth", 2}, [7 2], [4 7]);
%!test a({Y, "MinPeakWidth", 2.5}, [2], [7]);
%!test a({Y, "MaxPeakWidth", 2}, [10 7], [2 4]);
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

%!demo
%! x = 0.1:0.1:100;
%! p = [12 20 35 50 62 75 92];
%! s = [ 3  2  4  3  6  4 10];
%! m = [ 3  2  4  5  4  4  5];
%! yy = arrayfun(@(p,s,m) m*exp(-(x-p).^2./(2*s^2)), p, s, m, "UniformOutput", false);
%! y = sum(cell2mat(yy'))';
%! findpeaksp(y);
%! #--------------------------------------------------------
%! # You should now see a signal with seven marked peaks.

%!demo
%! x = 0.1:0.1:100;
%! p = [12 20 35 50 62 75 92];
%! s = [ 3  2  4  3  6  4 10];
%! m = [ 3  2  4  5  4  4  5];
%! yy = arrayfun(@(p,s,m) m*exp(-(x-p).^2./(2*s^2)), p, s, m, "UniformOutput", false);
%! y = sum(cell2mat(yy'))';
%! findpeaksp(y, "MinPeakProminence", 2, "Annotate");
%! #--------------------------------------------------------
%! # You should now see a signal with only the 1st, 3rd and 4th peaks marked
%! # along with their width and prominence.
