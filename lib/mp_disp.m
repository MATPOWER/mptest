function mp_disp(obj)
% mp_disp  Replacment for ``disp()`` that can redirect output.
% ::
%
%   mp.logger.manager('init', 'my-log-file.txt');
%   mp_disp(something_to_be_displayed);
%   mp.logger.manager('clear');

logger = mp.logger.manager('get');
if isempty(logger)
    disp(obj);
else
    logger.printf(evalc('disp(obj)'));
end
