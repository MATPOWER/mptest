classdef logger < handle
% mp.logger - Handles output typically sent to console.
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
%   * write_to_console - writes to both console **and** file, if true
%
% mp.logger Methods:
%   * logger - constructor
%   * init - initialize logger object (open log file)
%   * printf - prints to log
%   * finalize - finalize logger object (close log file)

%   MATPOWER
%   Copyright (c) 2026, Ray Zimmerman
%   by Ray Zimmerman
%
%   This file is part of MP-Test.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See https://github.com/MATPOWER/mptest for more info.

    properties
        fid                 % file ID returned by ``fopen()``
        write_to_console    % writes to both console **and** file, if true
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
            %   permission (char array) : *(default = ``'a'``)* permissions for
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
            %   permission (char array) : *(default = ``'a'``)* permissions for
            %       ``fopen()``
            %   write_to_console (logical) : *(default = 0)* writes to both
            %       console **and** file, if true

            obj.set_file(varargin{:});
        end

        function obj = set_file(obj, log_file_path, permission, write_to_console)
            % Open log file.
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
            %   permission (char array) : *(default = ``'a'``)* permissions for
            %       ``fopen()``
            %   write_to_console (logical) : *(default = 0)* writes to both
            %       console **and** file, if true

            %% set default inputs
            default_log_file_name = 'mp.logger_log.txt';
            if nargin < 4
                write_to_console = false;
                if nargin < 3
                    permission = 'a';
                end
            end
            if nargin < 2 || isempty(log_file_path)
                log_file_path = '.';
            end
            if exist(log_file_path, 'dir')
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
                    fprintf(obj.fid, varargin{:});
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
            %   permission (char array) : *(default = ``'a'``)* permissions for
            %       ``fopen()``
            %   write_to_console (logical) : *(default = 0)* writes to both
            %       console **and** file, if true

            if obj.fid > 2
                fclose(obj.fid);
                obj.fid = [];
            end
        end
    end     %% methods

    methods (Static)
        function obj = manager(action, varargin)
            % Manage the logger object used by mp_printf() and mp_disp().
            % ::
            %
            %   mp.logger.manager('init');
            %   mp.logger.manager('init', logger);
            %   mp.logger.manager('init', log_file_path);
            %   mp.logger.manager('init', log_file_path, permission);
            %   mp.logger.manager('init', log_file_path, permission, write_to_console);
            %   logger = mp.logger.manager('get');
            %   logger = mp.logger.manager('clear');
            %
            % Input:
            %   action (char array) : one of:
            %
            %       - ``'init'`` - initialize logger object, after clearing any
            %         existing one
            %       - ``'get'`` - retreive logger object
            %       - ``'clear'`` - clear logger object
            %   logger (mp.logger) : an existing, ready-to-use logger object
            %   log_file_path (char array) : path to directory or file to which
            %       all output will be logged; if it points to an existing
            %       directory, ``'mp.logger_log.txt'`` will be appended
            %   permission (char array) : *(default = ``'a'``)* permissions for
            %       ``fopen()``
            %   write_to_console (logical) : *(default = 0)* writes to both
            %       console **and** file, if true

            persistent logger;      %% logger object (or empty)

            switch lower(action)
            case 'get'
                obj = logger;
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
            end
        end
    end     %% methods
end         %% classdef
