## Copyright (C) 2024 Jan Slany
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
## @deftypefn  {} {@var{p} =} polyfitm (@var{x}, @var{y}, @var{n})
## @deftypefnx {} {@var{p} =} polyfitm (@var{x}, @var{y}, @var{n}, @var{dim})
##
## Fit polynomial to columns of matrix.
##
## This is a matrix wrapper of the @code{polyfit} function from
## the standard library, which simply calls it on each column
## of matrices @var{x} and @var{y}.
##
## If @var{dim} is given, operate along that dimension instead of columns.
##
## @seealso{polyfit}
## @end deftypefn

## Author: Jan "Singon" Slany <singond@seznam.cz>
## Created: March 2024
## Keywords: optimization, least squares
function p = polyfitm(x, y, n, dim=1)
	if (nargin < 3)
		print_usage
	end

	dims = 1:max([ndims(x) ndims(y)]);
	otherdims = dims(dims != dim);

	## Move dimension DIM to the beginning and squash higher
	## dimensions to obtain a 2D array for each argument,
	## unless it is a vector
	xsize = size(x);
	ysize = size(y);
	basesize = [];
	resultsize = [];
	if (isvector(x))
		xlen = length(x);
		x = x(:);
		xcols = 1;
	else
		xlen = xsize(dim);
		basesize = xsize;
		x = permute(x, [dim otherdims]);
		x = reshape(x, xlen, []);
		xcols = columns(x);
	end
	if (isvector(y))
		ylen = length(y);
		y = y(:);
		ycols = 1;
	else
		ylen = ysize(dim);
		if (xlen != ylen)
			error("polyfitm: nonconformant arguments");
		end
		if (!isempty(basesize) && basesize != ysize)
			error("polyfitm: nonconformant arguments");
		else
			basesize = ysize;
		end
		y = permute(y, [dim otherdims]);
		y = reshape(y, ylen, []);
		ycols = columns(y);
	end

	## Determine size of single result
	if (isnumeric(n))
		prows = n + 1;
	else
		prows = length(n);
	end

	## Process each column of the flattened array
	pcols = max([xcols ycols]);
	p = zeros(prows, pcols);
	if (xcols == 1)
		## Compute manually to reuse the QR factorization.
		## See {@code help qr} for more information.
		## Using the permutation matrix P makes this run much faster.
		X = vander(x, prows);
		if (islogical(n))
			X = X(:,n);
		end
		[Q, R, P] = qr(X, 0); ## Same as qr(X, "econ"), but backwards-compatible
		for c = 1:pcols
			cy = c;
			if (ycols == 1)
				cy = 1;
			end
			p(P,c) = R \ (Q' * y(:,cy));
		end
	else
		for c = 1:pcols;
			cx = cy = c;
			if (ycols == 1)
				cy = 1;
			end
			p(:,c) = polyfit(x(:,cx), y(:,cy), n);
		end
	end

	## Make the result match the input in dimensions
	## other than DIM
	resultsize = basesize;
	resultsize(dim) = prows;
	p = reshape(p, [prows basesize(otherdims)]);
	p = ipermute(p, [dim otherdims]);
end

%!shared y
%! y = [10 20; 1 2; 4 7];

%!test
%! p = polyfitm(1:3, y, 1);
%! assert(p, [-3 -6.5; 11 22.6667], -1e6);

%!test
%! p = polyfitm(1:2, y, 1, 2);
%! assert(p, [10 0; 1 0; 3 1], -1e6);

%!shared y
%! y = [10 20; 1 2; 4 7];
%! y = cat(3, y, 2*y);

%!test
%! p = polyfitm(1:3, y, 1);
%! assert(size(p), [2 2 2]);
%! assert(p(:,:,1), [-3 -6.5; 11 22.6667], -1e6);
%! assert(p(:,:,2), [-3 -13; 11 45.3333], -1e6);

%!test
%! p = polyfitm(1:2, y, 1, 2);
%! assert(size(p), [3 2 2]);
%! assert(p(:,:,1), [10 0; 1 0; 3 1], -1e6);
%! assert(p(:,:,2), [10 0; 1 0; 3 2], -1e6);

%!test
%! p = polyfitm(1:2, y, 1, 3);
%! assert(size(p), [3 2 2]);
%! assert(p(:,:,1), [10 20; 1 2; 4 7], -1e6);
%! assert(p(:,:,2), [0 0; 0 0; 0 0], -1e6);
