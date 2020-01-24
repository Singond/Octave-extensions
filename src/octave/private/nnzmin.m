function R = nnzmin(X)
	M = (X != 0);
	if (!any(M))
		## All elements are zeros
		R = min(X);
		return;
	endif
	Xmax = max(X(M)(:));
	if (Xmax < 0)
		## All values are negative, just find the minimum
		R = min(X);
	else
		## Shift all non-zero values by a constant down so that all
		## values are below zero.
		shift = Xmax + 1;
		X(M) -= shift;
		R = min(X);
		## Shift the values back
		R(R!=0) += shift;
	endif
endfunction

%!# With a row vector
%!assert(nnzmin([1 4 0]), 1);
%!assert(nnzmin([-1 4 0]), -1);
%!assert(nnzmin([-1 -4 0]), -4);
%!assert(nnzmin([-1 -4]), -4);

%!# With a column vector
%!assert(nnzmin([1 4 0]'), 1);
%!assert(nnzmin([-1 4 0]'), -1);
%!assert(nnzmin([-1 -4 0]'), -4);
%!assert(nnzmin([-1 -4]'), -4);

%!# With a matrix
%!assert(nnzmin([1 -4 0; -2 5 2]), [-2 -4 2]);
%!assert(nnzmin([1 -4 0; -2 5 0]), [-2 -4 0]);
%!assert(nnzmin([-1 -4 0; -2 -5 0]), [-2 -5 0]);

%!# With zeros
%!assert(nnzmin([0 0]), 0);
%!assert(nnzmin([0 0; 0 0]), [0 0]);
%!assert(full(nnzmin(sparse([0 0]))), 0);
%!assert(full(nnzmin(sparse([0 0; 0 0]))), [0 0]);
