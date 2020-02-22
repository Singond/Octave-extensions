## Compare the running times for prominence algorithms on first 'N'
## points of data 'Y'. 'N' can be an array.
## Example:
##   [T, N] = prominence_time(y, [100:100:1000]);
##   plot(N, T, "d");
function [T, N] = prominence_time(Y, N)
	N = N(:);
	if (nargin < 2)
		N = length(Y);
	endif
	T = zeros(length(N), 2);
	for i = 1:length(N)
		n = N(i);
		y = Y(1:n);

		## New implementation
		printf("Testing prominence with %d data points\n", n);
		tic;
		prominence(y);
		tm = toc;
		printf("Took %f seconds\n", tm);
		T(i, 1) = tm;

		## Old implementation
		printf("Testing prominence_old with %d data points\n", n);
		[~, loc] = findpeaksp(y);
		tic;
		prominence_old(y, loc);
		tm = toc;
		printf("Took %f seconds\n", tm);
		T(i, 2) = tm;
	endfor
endfunction