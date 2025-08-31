## Copyright (C) 2025 Jan Slany
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
## @deftp {Class} VideoPlayer
##
## Plots sequences of images as animated plot.
## @end deftp
classdef VideoPlayer < handle
	properties
		data
		fig
		plt
		frame = 0;
		paused = false;
		loop = true;
		framelength = 0.1;
		forwardbtn;
		backwardbtn;
		pausebtn;
	end

	methods
		function p = VideoPlayer(data)
			p.data = data;
			p.plt = imshow(data(:,:,1), []);
			p.fig = gcf;
			panel = uipanel(p.fig,
				"units", "pixels",
				"position", [0 0 600 50]);
			p.backwardbtn = uicontrol(panel,
				"style", "pushbutton",
				"string", "<",
				"position", [10 10 40 30],
				"callback", @(hsrc, evt) p.stepbackward);
			p.pausebtn = uicontrol(panel,
				"style", "pushbutton",
				"string", "Pause",
				"position", [60 10 120 30],
				"callback", @(hsrc, evt) p.togglepause);
			p.forwardbtn = uicontrol(panel,
				"style", "pushbutton",
				"string", ">",
				"position", [190 10 40 30],
				"callback", @(hsrc, evt) p.stepforward);
		end

		function play(p)
			set(p.pausebtn, "string", "Pause");
			set(p.backwardbtn, "enable", "off");
			set(p.forwardbtn, "enable", "off");
			p.paused = false;
			nframes = size(p.data, 3);
			while (!p.paused && ((++p.frame <= nframes) || p.loop))
				if (p.loop && p.frame > size(p.data, 3))
					p.frame = 1;
				endif
				p.setframe(p.frame);
				if (p.framelength > 0)
					pause(p.framelength);
				endif
			endwhile
		end

		function stop(p)
			p.paused = true;
			set(p.pausebtn, "string", "Play");
			if (p.frame > 1)
				set(p.backwardbtn, "enable", "on");
			endif
			if (p.frame < size(p.data, 3))
				set(p.forwardbtn, "enable", "on");
			endif
		end

		function togglepause(p)
			if (p.paused)
				p.play;
			else
				p.stop;
			end
		end

		function stepforward(p, nframes = size(p.data, 3))
			if (++p.frame > nframes)
				if (p.loop)
					p.frame = 1;
				elseif
					error("Already at end");
				end
			end
			p.setframe(p.frame);
		end

		function stepbackward(p, nframes = size(p.data, 3))
			if (--p.frame < 1)
				if (p.loop)
					p.frame = nframes;
				elseif
					error("Already at beginning");
				end
			end
			p.setframe(p.frame);
		end
	end

	methods (Access = private)
		function setframe(p, frame, nframes = size(p.data, 3))

			## Set button states (only if paused)
			if (p.paused && !p.loop)
				if (frame <= 1)
					set(p.backwardbtn, "enable", "off");
				elseif (frame >= nframes)
					set(p.forwardbtn, "enable", "off");
				else
					set(p.backwardbtn, "enable", "on");
					set(p.forwardbtn, "enable", "on");
				end
			end

			## Set graphics state
			set(p.plt, "cdata", p.data(:,:,frame));
			title(sprintf("frame %d", frame));
		end
	end
end
