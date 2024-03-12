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
