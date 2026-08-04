function mp_disp(obj)
% mp_disp  Replacment for ``disp()`` that can redirect output.
% ::
%
%   mp.logger.manager('init', 'my-log-file.txt');
%   mp_disp(something_to_be_displayed);
%   mp.logger.manager('clear');
%
% Optionally redirects the output of ``disp()`` to a file via an mp.logger
% object, or elsewhere via a custom mp.logger subclass.
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
    disp(obj);
else
    logger.printf(evalc('disp(obj)'));
end
