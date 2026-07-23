function mp_printf(varargin)
% mp_printf  Replacment for ``fprintf()`` that can redirect output.
% ::
%
%   mp.logger.manager('init', 'my-log-file.txt');
%   mp_printf('A line of %s to be printed.\n', 'text');
%   mp.logger.manager('clear');

logger = mp.logger.manager('get');
if isempty(logger)
    fprintf(varargin{:});
else
    logger.printf(varargin{:});
end
