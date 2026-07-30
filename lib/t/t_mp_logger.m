function t_mp_logger(quiet)
% t_mp_logger - Test mp.logger class and mp_disp and mp_printf functions.
% ::
%
%   t_mp_logger
%   t_mp_logger(quiet)

%   MP-Test
%   Copyright (c) 2026, Ray Zimmerman
%   by Ray Zimmerman
%
%   This file is part of MP-Test.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See https://github.com/MATPOWER/mptest for more info.

if nargin < 1
    quiet = 0;
end

n_tests = 44;

t_begin(n_tests, quiet);

if isempty(mp.logger.manager('get'))
    %% path to expected output files
    [p, n, e] = fileparts(which('t_mp_logger'));
    if have_feature('octave')
        if have_feature('octave', 'vnum') < 6
            redir_disp_fname = fullfile(p, 't_mp_logger', 'redir-disp-octave-old.txt');
        else
            redir_disp_fname = fullfile(p, 't_mp_logger', 'redir-disp-octave.txt');
        end
    else
        redir_disp_fname = fullfile(p, 't_mp_logger', 'redir-disp.txt');
    end
    redir_printf_fname = fullfile(p, 't_mp_logger', 'redir-printf.txt');
    
    %% no redirection
    t = 'no redirection : ';
    t_ok(~mp.logger.manager('active'), [t 'not active']);
    t_ok(mp.logger.manager('write_to_console'), [t 'write_to_console']);
    fname_got = mp.logger.manager('path');
    t_ok(isempty(fname_got), [t 'log file path (empty)']);
    c = evalc('mp_disp(sprintf(''This is %d\nlines of\ntext (%s).\n'', 3, ''I think'')); mp_disp(exp(1));');
    if have_feature('octave')
        if have_feature('octave', 'vnum') < 6
            expected = sprintf('This is 3\nlines of\ntext (I think).\n\n 2.7183\n');
        else
            expected = sprintf('This is 3\nlines of\ntext (I think).\n\n2.7183\n');
        end
    else
        expected = sprintf('This is 3\nlines of\ntext (I think).\n\n    2.7183\n\n');
    end
    if ~t_str_match(c, expected, [t 'mp_disp - outputs to console']);
        fprintf('\ngot:\n"%s"\n', c);
        fprintf('exp:\n"%s"\n', expected);
    end
    
    c = evalc('mp_printf(''Hello %s!\n\n'', ''mp_printf''); mp_printf(''This is %d\nlines of\ntext (%s).\n'', 3, ''I think'');');
    expected = sprintf('Hello mp_printf!\n\nThis is 3\nlines of\ntext (I think).\n');
    t_str_match(c, expected, [t 'mp_printf - outputs to console']);
    
    %% redirect to file
    t = 'redirect to file : ';
    fname = sprintf('redir-disp-%d.txt', fix(rand*1e8));
    mp.logger.manager('init', fname);
    active = mp.logger.manager('active');
    write_to_console = mp.logger.manager('write_to_console');
    mp_disp(exp(1));
    c = evalc('mp_disp(sprintf(''This is %d\nlines of\ntext (%s).\n'', 3, ''I think''));');
    fname_got = mp.logger.manager('path');
    mp.logger.manager('clear', fname);
    t_ok(active, [t 'active']);
    t_ok(~write_to_console, [t 'not write_to_console']);
    t_str_match(fname_got, fname, [t 'log file path']);
    t_file_match(fname, redir_disp_fname, [t 'mp_disp - file w/expected content'], {}, true);
    t_ok(isempty(c), [t 'mp_disp - no console output']);
    t_ok(isempty(mp.logger.manager('get')), [t 'mp.logger.manage(''clear'')']);
    
    fname = sprintf('redir-printf-%d.txt', fix(rand*1e8));
    mp.logger.manager('init', fname);
    active = mp.logger.manager('active');
    write_to_console = mp.logger.manager('write_to_console');
    mp_printf('This is %d\nlines of\ntext (%s).\n', 3, 'I think');
    c = evalc('mp_printf(''Hello %s!\n\n'', ''mp_printf'');');
    fname_got = mp.logger.manager('path');
    mp.logger.manager('clear', fname);
    t_ok(active, [t 'active']);
    t_ok(~write_to_console, [t 'not write_to_console']);
    t_str_match(fname_got, fname, [t 'log file path']);
    t_file_match(fname, redir_printf_fname, [t 'mp_printf - file w/expected content'], {}, true);
    t_ok(isempty(c), [t 'mp_printf - no console output']);
    t_ok(isempty(mp.logger.manager('get')), [t 'mp.logger.manage(''clear'')']);
    
    %% both
    t = 'both : ';
    fname = sprintf('redir-disp-%d.txt', fix(rand*1e8));
    mp.logger.manager('init', fname, 'a', 1);
    active = mp.logger.manager('active');
    write_to_console = mp.logger.manager('write_to_console');
    c = evalc('mp_disp(exp(1)); mp_disp(sprintf(''This is %d\nlines of\ntext (%s).\n'', 3, ''I think''));');
    if have_feature('octave')
        if have_feature('octave', 'vnum') < 6
            expected = sprintf(' 2.7183\nThis is 3\nlines of\ntext (I think).\n\n');
        else
            expected = sprintf('2.7183\nThis is 3\nlines of\ntext (I think).\n\n');
        end
    else
        expected = sprintf('    2.7183\n\nThis is 3\nlines of\ntext (I think).\n\n');
    end
    fname_got = mp.logger.manager('path');
    mp.logger.manager('clear', fname);
    t_ok(active, [t 'active']);
    t_ok(write_to_console, [t 'write_to_console']);
    t_str_match(fname_got, fname, [t 'log file path']);
    t_file_match(fname, redir_disp_fname, [t 'mp_disp - file w/expected content'], {}, true);
    if ~t_str_match(c, expected, [t 'mp_disp - outputs to console']);
        fprintf('\ngot:\n"%s"\n', c);
        fprintf('exp:\n"%s"\n', expected);
    end
    t_ok(isempty(mp.logger.manager('get')), [t 'mp.logger.manage(''clear'')']);
    
    fname = sprintf('redir-printf-%d.txt', fix(rand*1e8));
    mp.logger.manager('init', fname, 'w', 1);
    active = mp.logger.manager('active');
    write_to_console = mp.logger.manager('write_to_console');
    c = evalc(' mp_printf(''This is %d\nlines of\ntext (%s).\n'', 3, ''I think''); mp_printf(''Hello %s!\n\n'', ''mp_printf'');');
    expected = sprintf('This is 3\nlines of\ntext (I think).\nHello mp_printf!\n\n');
    fname_got = mp.logger.manager('path');
    mp.logger.manager('clear', fname);
    t_ok(active, [t 'active']);
    t_ok(write_to_console, [t 'write_to_console']);
    t_str_match(fname_got, fname, [t 'log file path']);
    t_file_match(fname, redir_printf_fname, [t 'mp_printf - file w/expected content'], {}, true);
    t_str_match(c, expected, [t 'mp_printf - outputs to console']);
    t_ok(isempty(mp.logger.manager('get')), [t 'mp.logger.manage(''clear'')']);
    t_ok(~mp.logger.manager('active'), [t 'not active']);
    t_ok(mp.logger.manager('write_to_console'), [t 'write_to_console']);
    
    fname_got = mp.logger.manager('path');
    t_ok(isempty(fname_got), [t 'log file path (empty)']);

    %% pause
    t = 'pause : ';
    fname = sprintf('redir-printf-%d.txt', fix(rand*1e8));
    mp.logger.manager('init', fname);
    active = mp.logger.manager('active');
    write_to_console = mp.logger.manager('write_to_console');
    mp.logger.manager('pause');
    t_ok(active, [t 'active (before pause)']);
    t_ok(~write_to_console, [t 'not write_to_console (before pause)']);
    t_ok(~mp.logger.manager('active'), [t 'not active']);
    t_ok(mp.logger.manager('write_to_console'), [t 'write_to_console']);
    fname_got = mp.logger.manager('path');
    t_ok(isempty(fname_got), [t 'log file path (empty)']);
    c = evalc('mp_printf(''Hello %s!\n\n'', ''mp_printf''); mp_printf(''This is %d\nlines of\ntext (%s).\n'', 3, ''I think'');');
    expected = sprintf('Hello mp_printf!\n\nThis is 3\nlines of\ntext (I think).\n');
    t_str_match(c, expected, [t 'mp_printf - outputs to console']);

    %% resume
    t = 'resume : ';
    mp.logger.manager('resume');
    active = mp.logger.manager('active');
    write_to_console = mp.logger.manager('write_to_console');
    mp_printf('This is %d\nlines of\ntext (%s).\n', 3, 'I think');
    c = evalc('mp_printf(''Hello %s!\n\n'', ''mp_printf'');');
    fname_got = mp.logger.manager('path');
    mp.logger.manager('clear', fname);
    t_ok(active, [t 'active']);
    t_ok(~write_to_console, [t 'not write_to_console']);
    t_str_match(fname_got, fname, [t 'log file path']);
    t_file_match(fname, redir_printf_fname, [t 'mp_printf - file w/expected content'], {}, true);
    t_ok(isempty(c), [t 'mp_printf - no console output']);
    t_ok(isempty(mp.logger.manager('get')), [t 'mp.logger.manage(''clear'')']);
else
    t_skip(n_tests, 'mp.logger object in use, tests will not work');
end

t_end;
