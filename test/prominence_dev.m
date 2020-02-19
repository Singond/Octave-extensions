addpath ../src/octave

y = Y1;
#y = Y1(111:190);
#y = Y2(136135:136151);

[P, L] = findpeaksp(y); tic; N = prominence(y, L); toc; tic;...
	O = prominence_old(y, L); toc; all(N==O)
E = find(N != O)
plot(y, "", L, y(L), "vb", L(E), y(L(E)), "ro");
#prominence(y, L);