classdef logger < handle
% mp.logger - Handles console output redirection for mp_disp and mp_printf.
%
% Example usage::
%
%   mp.logger.manager('init', log_file_path);
%   mp_disp(...);
%   mp_printf(...);
%   mp.logger.manager('clear');
%
% mp.logger Properties:
%   * fid - file ID returned by ``fopen()``
%   * log_file_path - path to log file
%   * write_to_console - writes to both console **and** file, if true
%   * manual_flush - true by default on Octave, requiring fflush()
%
% mp.logger Methods:
%   * logger - constructor
%   * init - initialize logger object (open log file)
%   * set_file - open log file, after closing any already open
%   * printf - prints to log
%   * manage - handle actions forwarded from mp.logger.manager
%   * finalize - finalize logger object (close log file)
%   * manager - manage the logger object used by mp_printf and mp_disp
%
% See also mp_disp, mp_printf.

%   MP-Test
%   Copyright (c) 2026, Ray Zimmerman
%   by Ray Zimmerman
%
%   This file is part of MP-Test.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See https://github.com/MATPOWER/mptest for more info.

    properties
        fid                 % file ID returned by ``fopen()``
        log_file_path       % path to log file
        write_to_console    % writes to both console **and** file, if true
        manual_flush=false; % true by default on Octave, requiring fflush()
    end     %% properties

    methods
        function obj = logger(varargin)
            % Constructor.
            % ::
            %
            %   obj = mp.logger()
            %   obj = mp.logger(log_file_path)
            %   obj = mp.logger(log_file_path, permission)
            %   obj = mp.logger(log_file_path, permission, write_to_console)
            %
            % Inputs:
            %   log_file_path (char array) : path to directory or file to which
            %       all output will be logged; if it points to an existing
            %       directory, ``'mp.logger_log.txt'`` will be appended
            %   permission (char array) : *(default = 'a')* permissions for
            %       ``fopen()``
            %   write_to_console (logical) : *(default = 0)* writes to both
            %       console **and** file, if true

            obj.init(varargin{:});
        end

        function obj = init(obj, varargin)
            % Initialize logger object (open log file).
            % ::
            %
            %   obj.init(log_file_path)
            %   obj.init(log_file_path, permission)
            %   obj.init(log_file_path, permission, write_to_console)
            %
            % Inputs:
            %   log_file_path (char array) : path to directory or file to which
            %       all output will be logged; if it points to an existing
            %       directory, ``'mp.logger_log.txt'`` will be appended
            %   permission (char array) : *(default = 'a')* permissions for
            %       ``fopen()``
            %   write_to_console (logical) : *(default = 0)* writes to both
            %       console **and** file, if true

            if have_feature('octave')
                obj.manual_flush = true;
            end
            obj.set_file(varargin{:});
        end

        function obj = set_file(obj, log_file_path, permission, write_to_console)
            % Open log file, after closing any already open.
            % ::
            %
            %   obj.set_file(log_file_path)
            %   obj.set_file(log_file_path, permission)
            %   obj.set_file(log_file_path, permission, write_to_console)
            %
            % Inputs:
            %   log_file_path (char array) : path to directory or file to which
            %       all output will be logged; if it points to an existing
            %       directory, ``'mp.logger_log.txt'`` will be appended
            %   permission (char array) : *(default = 'a')* permissions for
            %       ``fopen()``
            %   write_to_console (logical) : *(default = 0)* writes to both
            %       console **and** file, if true

            %% set default inputs
            default_log_file_name = 'mp.logger_log.txt';
            if nargin < 4 || isempty(write_to_console)
                write_to_console = false;
            end
            if nargin < 3 || isempty(permission)
                permission = 'a';
            end
            if nargin < 2
                log_file_path = '';
            end
            if isempty(log_file_path) || exist(log_file_path, 'dir')
                log_file_path = fullfile(log_file_path, default_log_file_name);
            end

            %% close any currently open file
            if obj.fid > 2
                fclose(obj.fid);
            end

            %% open new log file
            [fid, msg] = fopen(log_file_path, permission);
            if fid == -1
                error('mp.logger.set_file: unable to open log file: %s', log_file_path);
            else
                obj.fid = fid;
            end

            obj.write_to_console = write_to_console;
            obj.log_file_path = log_file_path;
        end

        function obj = printf(obj, varargin)
            % Print to log.
            % ::
            %
            %   obj.printf(...)
            %
            % Inputs are identical to those of ``fprintf()``.

            if nargin < 2
                error('mp.logger.printf: nothing to print');
            elseif ischar(varargin{1}) || varargin{1} == 1 || varargin{1} == 2
                if obj.fid > 0      %% print to log file
                    if ischar(varargin{1})
                        fprintf(obj.fid, varargin{:});
                    else    %% use our fid, instead of 1 or 2
                        fprintf(obj.fid, varargin{2:end});
                    end
                    if obj.manual_flush
                        fflush(obj.fid);
                    end
                    if obj.write_to_console
                        fprintf(varargin{:});
                    end
                else
                    error('mp.logger.printf: log file not open');
                end
            elseif varargin{1} > 2     %% writing to file with provided file ID
                fprintf(varargin{:});
            else
                error('mp.logger.printf: first argument must be char array or file ID');
            end
        end

        function varargout = manage(obj, action, varargin)
            % Handle actions forwarded from mp.logger.manager.
            % ::
            %
            %   log_file_path = obj.manage('path');
            %   [varargout{1:nargout}] = obj.manage('<action>', varargin);
            %
            % Inputs:
            %   action (char array) : this class defines a ``'path'`` action
            %       to return the log file path; subclasses can define others
            %
            % Outputs:
            %   log_file_path (char array) : path to log file
            %   <arbitrary> : defined by subclasses for other actions
            %
            % Currently defines a single ``'path'`` action to query the logger
            % for the path of the open log file, which may be a relative
            % path if that is what was used to create the object.

            switch action
            case 'path'
                [varargout{1:nargout}] = obj.log_file_path;
            otherwise
                error('mp.logger.manage: action ''%s'' not implemented by %s', class(obj));
            end
        end

        function obj = finalize(obj, varargin)
            % Finalize logger object (close log file).
            % ::
            %
            %   obj.init(log_file_path)
            %   obj.init(log_file_path, permission)
            %   obj.init(log_file_path, permission, write_to_console)
            %
            % Inputs:
            %   log_file_path (char array) : path to directory or file to which
            %       all output will be logged; if it points to an existing
            %       directory, ``'mp.logger_log.txt'`` will be appended
            %   permission (char array) : *(default = 'a')* permissions for
            %       ``fopen()``
            %   write_to_console (logical) : *(default = 0)* writes to both
            %       console **and** file, if true

            if obj.fid > 2
                fclose(obj.fid);
                obj.fid = [];
                obj.log_file_path = '';
            end
        end
    end     %% methods

    methods (Static)
        function varargout = manager(action, varargin)
            % Manage the logger object used by mp_printf and mp_disp.
            % ::
            %
            %   mp.logger.manager('init');
            %   mp.logger.manager('init', logger);
            %   mp.logger.manager('init', log_file_path);
            %   mp.logger.manager('init', log_file_path, permission);
            %   mp.logger.manager('init', log_file_path, permission, write_to_console);
            %   logger = mp.logger.manager('get');
            %   log_file_path = mp.logger.manager('path');
            %   TorF = mp.logger.manager('write_to_console');
            %   TorF = mp.logger.manager('active');
            %   mp.logger.manager('pause');
            %   mp.logger.manager('resume');
            %   mp.logger.manager('clear');
            %
            % Inputs:
            %   action (char array) : one of:
            %
            %       - ``'init'`` - initialize logger object, after clearing any
            %         existing one
            %       - ``'active'`` - return true if a logger is active
            %       - ``'get'`` - retreive logger object
            %       - ``'clear'`` - clear logger object
            %       - ``'write_to_console'`` - return true if logger writes
            %         to console in addition to logging to file
            %       - ``'pause'`` - pause (temporarily disable) logger
            %       - ``'resume'`` - resume (re-enable) paused logger
            %       - ``<other>`` - any other action, along with subsequent
            %         input arguments is passed to the manage() method of the
            %         logger object
            %         
            %   logger (mp.logger) : an existing, ready-to-use logger object
            %   log_file_path (char array) : path to directory or file to which
            %       all output will be logged; if it points to an existing
            %       directory, ``'mp.logger_log.txt'`` will be appended
            %   permission (char array) : *(default = 'a')* permissions for
            %       ``fopen()``
            %   write_to_console (logical) : *(default = 0)* writes to both
            %       console **and** file, if true
            %
            % Output:
            %   logger (mp.logger) : the mp.logger object for ``'get'``
            %   <arbitrary> : for any action other than ``'get'``, ``'init'``,
            %       and ``'clear'`` e.g. ``'path'``,  the logger object's
            %       manage() method determines the number and content of output
            %       arguments

            persistent logger;          %% logger object (or empty)
            persistent logger_paused;   %% inactive (paused) logger object (or empty)

            switch lower(action)
            case 'active'
                [varargout{1:nargout}] = ~isempty(logger);
            case 'get'
                [varargout{1:nargout}] = logger;
            case 'init'
                mp.logger.manager('clear');
                if nargin < 2
                    logger = mp.logger();
                elseif ischar(varargin{1}) || isstring(varargin{1})
                    logger = mp.logger(varargin{:});
                elseif isa(varargin{1}, 'mp.logger')
                    logger = varargin{1};
                else
                    error('mp.logger.manager: second argument must be a file name or mp.logger object, not a %s', class(varargin{1}));
                end
            case 'clear'
                if ~isempty(logger)
                    logger.finalize();
                    logger = [];
                end
                if ~isempty(logger_paused)
                    logger_paused.finalize();
                    logger_paused = [];
                end
            case 'write_to_console'
                if ~isempty(logger)
                    if length(varargin) > 0
                        logger.write_to_console = varargin{1} ~= 0;
                    else
                        [varargout{1:nargout}] = logger.write_to_console;
                    end
                else
                    if length(varargin) == 0
                        [varargout{1:nargout}] = true;
                    end
                end
            case 'pause'
                if ~isempty(logger) && isempty(logger_paused)
                    logger_paused = logger;
                    logger = [];
                end
            case 'resume'
                if ~isempty(logger_paused) && isempty(logger)
                    logger = logger_paused;
                    logger_paused = [];
                end
            otherwise
                if isempty(logger)
                    [varargout{1:nargout}] = [];
                else
                    [varargout{1:nargout}] = logger.manage(action, varargin{:});
                end
            end
        end
    end     %% methods
end         %% classdef
