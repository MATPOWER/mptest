function mp_printf(varargin)
% mp_printf  Replacment for ``fprintf()`` that can redirect output.
% ::
%
%   mp.logger.manager('init', 'my-log-file.txt');
%   mp_printf('A line of %s to be printed.\n', 'text');
%   mp.logger.manager('clear');
%
% Optionally redirects the output of ``fprintf()`` to a file via an mp.logger
% object, or elsewhere via a custom mp.logger subclass. If the first argument
% is a file ID, it does not redirect anything.
%
% See also mp.logger.manager, mp.logger.

%   MP-Test
%   Copyright (c) 2026, Ray Zimmerman
%   by Ray Zimmerman
%
%   This file is part of MP-Test.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See https://github.com/MATPOWER/mptest for more info.

logger = mp.logger.manager('get');
if isempty(logger)
    fprintf(varargin{:});
else
    logger.printf(varargin{:});
end
