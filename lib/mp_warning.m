function mp_warning(varargin)
% mp_warning  Replacment for ``warning()`` that can redirect output.
% ::
%
%   mp.logger.manager('init', 'my-log-file.txt');
%   mp_warning('my warning message');
%   mp_warning('my warning message %d', 2);
%   mp.logger.manager('clear');
%
% Optionally redirects the output of ``warning()`` to a file via an mp.logger
% object, or elsewhere via a custom mp.logger subclass. Inputs are identical
% to those of ``warning()``. Note that this function is only for throwing a
% warning, not querying or controlling warning status, and the on/off state
% of a warning has no effect on redirected output.
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
    warning(varargin{:});
else
    logger.warning(varargin{:});
    if logger.write_to_console
        warning(varargin{:});
    end
end
