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
## @deftypefn  {} {@var{B} =} dimfun (@var{fcn}, @var{dim}, @var{A})
## @deftypefnx {} {@var{B} =} dimfun (@var{fcn}, @var{dim}, @var{A1}, @
##     @var{A2}, @dots{})
##
## Evaluate a function on each vector of an array.
##
## All vectors of the array @var{A} in dimension @var{dim}
## are passed one by one to the function @var{fcn} and the results
## are collected to the output array @var{B}.
## That is, if @var{dim} is 1, @var{fcn} is evaluated for each column,
## if @var{dim} is 2, for each row, and similarly for any
## higher-dimensional slice of @var{A}.
##
## This is similar to @code{arrayfun}, but passes whole vectors
## of @var{A} instead of single elements into the function.
##
## @var{fcn} can be a function handle or an anonymous function.
##
## Multiple arguments @var{A1}, @var{A2}, @dots{} can be passed
## to @var{fcn}, provided they are of compatible dimensions.
## These arguments are passed vector by vector like the first argument.
##
## The output array @var{B} has the same dimensionality as @var{A}.
## The size in dimensions other than @var{dim} is preserved.
## The size in dimension @var{dim} is the number of elements
## in the return value of @var{fcn}, which must be the same
## for each invocation.
##
## @seealso{arrayfun, cellfun}
## @end deftypefn

## Author: Jan "Singon" Slany <singond@seznam.cz>
## Created: March 2024
## Keywords: utilities
function R = dimfun(fcn, dim, varargin)
	if (nargin < 3)
		print_usage
	end

	## Determine dimensions
	dims = 1:max(cellfun("ndims", varargin)(:));
	otherdims = dims(dims != dim);
	maxdim = dims(end);

	## Check dimensions
	argsize = ones(size(dims));
	for d = otherdims
		sizes = cellfun("size", varargin, d);
		argsize(d) = max(sizes(:));
		if (!all(sizes == argsize(d) | sizes == 1))
			error("dimfun: nonconformant arguments");
		end
	end

	## Broadcast to common shape
	if (length(varargin) > 1)
		args = cell(size(varargin));
		for k = 1:length(varargin)
			argk = varargin{k};
			rep = argsize;
			sz = postpad(size(argk), maxdim, 1);
			rep(sz > 1) = 1;
			rep(dim) = 1;
			args{k} = repmat(argk, rep);
		end
	else
		args = varargin;
	end

	## Move dimension DIM to the beginning
	## and squash higher dimensions to obtain a 2D array.
	argsp = cell(size(args));
	for k = 1:length(args)
		argk = args{k};
		len = size(argk, dim);
		argk = permute(argk, [dim otherdims]);
		argsp(k) = reshape(argk, len, []);
	end

	## Process each column
	R = [];
	for c = 1:columns(argsp{1})
		fargs = cell(size(argsp));
		for k = 1:length(argsp)
			fargs(k) = argsp{k}(:,c);
		endfor
		r = fcn(fargs{:});
		if (isempty(R))
			rlen = numel(r);
			R = zeros(rlen, columns(argsp{1}));
		end
		R(:,c) = r;
	end

	## Make the result match the input in dimensions
	## other than DIM.
	R = reshape(R, [rlen argsize(otherdims)]);
	R = ipermute(R, [dim otherdims]);
end

%!shared X
%! X = [28  13  50  84
%!      19  13  99  10
%!       8  59  86 100
%!      13  19  14  25];

%!assert(dimfun(@sum, 1, X), sum(X, 1));
%!assert(dimfun(@sum, 2, X), sum(X, 2));
%!assert(dimfun(@mean, 1, X), mean(X, 1));
%!assert(dimfun(@mean, 2, X), mean(X, 2));

%!assert(dimfun(@sort, 1, X), [ 8  13  14  10
%!                             13  13  50  25
%!                             19  19  86  84
%!                             28  59  99 100]);
%!assert(dimfun(@sort, 2, X), [13  28  50  84
%!                             10  13  19  99
%!                              8  59  86 100
%!                             13  14  19  25]);

%!# With anonymous function
%!assert(dimfun(@(x) (x(1) - x(2)) / (x(3) + x(4)), 1, X),
%!       [9/21  0  -49/100  74/125]);
%!assert(dimfun(@(x) (x(1) - x(2)) / (x(3) + x(4)), 2, X),
%!       [15/134;  6/109;  -51/186;  -6/39]);

%!demo
%! p = dimfun(@polyfit, 1, [1 2; 3 4; 12 8], [10 20; 1 2; 4 7], 2);
%! x = linspace(0, 12);
%! hold on
%! dimfun(@plot, 1, [1 2; 3 4; 12 8], [10 20; 1 2; 4 7], ["d" "o"]);
%! set(gca, "colororderindex", 1);
%! plot(x, dimfun(@polyval, 1, p, x'), "--");
%! hold off

%!demo
%! X = [1 2; 3 4; 12 8];
%! Y = [10 20; 1 2; 4 7];
%! fit1 = dimfun(@polyfit, 1, X, Y, 2);
%! fit2 = dimfun(@polyfit, 2, X, Y, 1);
%! x = linspace(0, 12);
%! hold on
%! title("Fits of two 3x2 matrices");
%! dimfun(@plot, 1, [1 2; 3 4; 12 8], [10 20; 1 2; 4 7], ["d" "o"]);
%! set(gca, "colororderindex", 1);
%! plot(x, dimfun(@polyval, 1, fit1, x'), "-", "displayname", "by columns");
%! plot(x, dimfun(@polyval, 2, fit2, x), "k--", "displayname", "by rows");
%! ylim([-10 40]);
%! legend show;
%! hold off
