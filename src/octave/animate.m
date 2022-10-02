## -*- texinfo -*-
## @deftypefn  {} {} animate (@var{img})
## @deftypefnx {} {} animate (@var{img}, @var{framelength})
## @deftypefnx {} {} animate (@dots{}, @qcode{"loop"})
## @deftypefnx {} {} animate (@dots{}, @var{args})
##
## Display a sequence of images @var{img} as an animation.
##
## The image sequence @var{img} should be a 3D array where individual
## frames are stacked along the last dimension.
## The delay between images in seconds can be set by @var{framelength}.
## If it is not seet, a default delay of 1 second is used.
##
## Automatic looping can be set by the @qcode{"loop"} option.
## If set, the animation restarts after reaching the last frame.
##
## The frames are displayed using @code{imshow}.
## Any unmatched arguments are passed to this function.
## @end deftypefn
function animate(img, framelength = 1, varargin)
	nframes = size(img, 3);

	unmatched = {};
	loop = false;
	n = 0;
	while (++n <= numel(varargin))
		arg = varargin{n};
		if (strcmp(arg, "loop"))
			loop = true;
		else
			unmatched{end + 1} = arg;
		endif
	endwhile

	h = imshow(img(:,:,1), unmatched{:});
	ax = gca();
	f = 0;
	while (++f <= nframes)
		set(h, "cdata", img(:,:,f));
		title(sprintf("frame %d", f));
		if (loop && f == nframes)
			f = 0;
		endif
		if (framelength > 0)
			pause(framelength);
		endif
	endwhile
endfunction
