## Compares the output of different prominence implementations.
## 'O' is the output of the old implementation, which is considered
## correct and used as a reference.
## 'N' is the output of the new implementation.
## If no output is requested, display the results.
function [O N] = prominence_checkalg(y)
	[~, L] = findpeaksp(y);
	O = prominence_old(y, L);     # Old implementation used as reference
	N = prominence(y);            # New implementation
	if (nargout == 0)
		if (all(N==O))
			disp("The results from different implementations match.");
		else
			disp("The results from different implementations do not match.");
			disp("See plot with erratic peaks marked in red.");
			E = find(N != O);
			plot(y, "", L, y(L), "vb", L(E), y(L(E)), "ro");
		endif
	endif
endfunction