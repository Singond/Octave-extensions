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
		data;
		fig;
		plt;
		ax;
		frame = 0;
		paused = false;
		loop = true;
		framerate = 10;
		frameduration = 0.1;
		forwardbtn;
		backwardbtn;
		pausebtn;
		loopcontrol;
		rangeedit1;
		rangeedit2;
	end

	methods
		function p = VideoPlayer(varargin)
			ip = inputParser;
			ip.addRequired("data");
			ip.addSwitch("loop");
			ip.addParameter("framerate", 10, @(v) isnumeric(v) && isscalar(v));
			ip.addParameter("displayrange", [], @isnumeric);
			ip.addParameter("colormap", []);
			ip.addParameter("xdata", [], @isnumeric);
			ip.addParameter("ydata", [], @isnumeric);
			ip.parse(varargin{:});

			p.data = ip.Results.data;
			p.loop = ip.Results.loop;
			p.framerate = ip.Results.framerate;
			p.frameduration = 1 / ip.Results.framerate;
			imshowargs = {};
			imshowargs{end+1} = "displayrange";
			imshowargs{end+1} = ip.Results.displayrange;
			if (!isempty((value = ip.Results.colormap)))
				imshowargs{end+1} = "colormap";
				imshowargs{end+1} = value;
			end
			if (!isempty((value = ip.Results.xdata)))
				imshowargs{end+1} = "xdata";
				imshowargs{end+1} = value;
			end
			if (!isempty((value = ip.Results.ydata)))
				imshowargs{end+1} = "ydata";
				imshowargs{end+1} = value;
			end

			p.plt = imshow(p.data(:,:,1), imshowargs{:});
			p.fig = gcf;
			p.ax = get(p.fig, "currentaxes");

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
			p.loopcontrol = uicontrol(panel,
				"style", "checkbox",
				"string", "Loop",
				"value", p.loop,
				"position", [240 10 50 30],
				"callback", @(hsrc, evt) p.setloop);
			range = get(p.ax, "clim");
			uicontrol(panel,
				"style", "text",
				"string", "Range:",
				"horizontalalignment", "right",
				"position", [300 10 50 30]);
			p.rangeedit1 = uicontrol(panel,
				"style", "edit",
				"string", num2str(range(1)),
				"position", [360 10 50 30],
				"callback", @(hsrc, evt) p.setrange);
			p.rangeedit2 = uicontrol(panel,
				"style", "edit",
				"string", num2str(range(2)),
				"position", [420 10 50 30],
				"callback", @(hsrc, evt) p.setrange);
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
				if (p.frameduration > 0)
					pause(p.frameduration);
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

		function setloop(p)
			p.loop = get(gcbo, "value");
		end

		function setrange(p)
			low = get(p.rangeedit1, "string");
			high = get(p.rangeedit2, "string");
			low = str2num(low);
			high = str2num(high);
			if (!isempty(low) && !isempty(high))
				set(p.ax, "clim", [low high]);
			endif
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
