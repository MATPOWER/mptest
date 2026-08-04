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

n_tests = 59;

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
        redir_warning_fname = fullfile(p, 't_mp_logger', 'redir-warning-octave.txt');
    else
        redir_disp_fname = fullfile(p, 't_mp_logger', 'redir-disp.txt');
        redir_warning_fname = fullfile(p, 't_mp_logger', 'redir-warning.txt');
    end
    redir_printf_fname = fullfile(p, 't_mp_logger', 'redir-printf.txt');

    reps = {
        {'</?a[^>]*>', '', 1},          %% strip HTML anchor tags in MATLAB
        {'.\x08', ''},                  %% strip backspace and preceding char
        {'at (\d+)', '(line $1)', 1},   %% old to new MATLAB format
        {'  In', 'In'},                 %% old to new MATLAB format
        {'\s+\n', '\n', 1},             %% old to new MATLAB format
        {'(In t_mp_logger \(line \d+\)\n).*?(?=Warning|$)', '$1', 1},
        {'(t_mp_logger at line \d+ column \d+\n).*?(?=warning|$)', '$1', 1},
        {'column \d+', 'column 7', 1, 1},   %% inconsistent col #s in Octave
        {'\n+', '\n', 1, 1},                %% inconsisent # of \n in Octave
    };

    %% no redirection
    t = 'no redirection : ';
    t_ok(~mp.logger.manager('active'), [t 'not active']);
    t_ok(mp.logger.manager('write_to_console'), [t 'write_to_console']);
    fname_got = mp.logger.manager('path');
    t_ok(isempty(fname_got), [t 'log file path (empty)']);
    got = evalc('mp_disp(sprintf(''This is %d\nlines of\ntext (%s).\n'', 3, ''I think'')); mp_disp(exp(1));');
    if have_feature('octave')
        if have_feature('octave', 'vnum') < 6
            expected = sprintf('This is 3\nlines of\ntext (I think).\n\n 2.7183\n');
        else
            expected = sprintf('This is 3\nlines of\ntext (I think).\n\n2.7183\n');
        end
    else
        expected = sprintf('This is 3\nlines of\ntext (I think).\n\n    2.7183\n\n');
    end
    if ~t_str_match(got, expected, [t 'mp_disp - outputs to console'])
        fprintf('\ngot:\n"%s"\n', got);
        fprintf('exp:\n"%s"\n', expected);
    end

    got = evalc('mp_printf(''Hello %s!\n\n'', ''mp_printf''); mp_printf(''This is %d\nlines of\ntext (%s).\n'', 3, ''I think'');');
    expected = sprintf('Hello mp_printf!\n\nThis is 3\nlines of\ntext (I think).\n');
    t_str_match(got, expected, [t 'mp_printf - outputs to console']);

    line_no = '78';     %% must be line number of line below this one
    got = evalc('mp_warning(''expected warning %d'', 1); mp_warning(''expected warning %d'', 2);');
    if have_feature('octave')
        expected = sprintf('warning: expected warning 1\nwarning: called from\n    mp_warning at line 28 column 7\n    t_mp_logger at line %s column 7\nwarning: expected warning 2\nwarning: called from\n    mp_warning at line 28 column 5\n    t_mp_logger at line %s column 7\n', line_no, line_no);
    else
        expected = sprintf('Warning: expected warning 1\n> In mp_warning (line 28)\nIn t_mp_logger (line %s)\nWarning: expected warning 2\n> In mp_warning (line 28)\nIn t_mp_logger (line %s)\n', line_no, line_no);
    end
    if ~t_str_match(got, expected, [t 'mp_warning - outputs to console'], reps)
        fprintf('\ngot:\n"%s"\n', got);
        fprintf('exp:\n"%s"\n', expected);
    end

    %% redirect to file
    t = 'redirect to file : ';
    fname = sprintf('redir-disp-%d.txt', fix(rand*1e8));
    mp.logger.manager('init', fname);
    active = mp.logger.manager('active');
    write_to_console = mp.logger.manager('write_to_console');
    mp_disp(exp(1));
    got = evalc('mp_disp(sprintf(''This is %d\nlines of\ntext (%s).\n'', 3, ''I think''));');
    fname_got = mp.logger.manager('path');
    mp.logger.manager('clear', fname);
    t_ok(active, [t 'active']);
    t_ok(~write_to_console, [t 'not write_to_console']);
    t_str_match(fname_got, fname, [t 'log file path']);
    t_file_match(fname, redir_disp_fname, [t 'mp_disp - file w/expected content'], {}, true);
    t_ok(isempty(got), [t 'mp_disp - no console output']);
    t_ok(isempty(mp.logger.manager('get')), [t 'mp.logger.manage(''clear'')']);

    fname = sprintf('redir-printf-%d.txt', fix(rand*1e8));
    mp.logger.manager('init', fname);
    active = mp.logger.manager('active');
    write_to_console = mp.logger.manager('write_to_console');
    mp_printf('This is %d\nlines of\ntext (%s).\n', 3, 'I think');
    got = evalc('mp_printf(''Hello %s!\n\n'', ''mp_printf'');');
    fname_got = mp.logger.manager('path');
    mp.logger.manager('clear', fname);
    t_ok(active, [t 'active']);
    t_ok(~write_to_console, [t 'not write_to_console']);
    t_str_match(fname_got, fname, [t 'log file path']);
    t_file_match(fname, redir_printf_fname, [t 'mp_printf - file w/expected content'], {}, true);
    t_ok(isempty(got), [t 'mp_printf - no console output']);
    t_ok(isempty(mp.logger.manager('get')), [t 'mp.logger.manage(''clear'')']);

    fname = sprintf('redir-warning-%d.txt', fix(rand*1e8));
    mp.logger.manager('init', fname);
    active = mp.logger.manager('active');
    write_to_console = mp.logger.manager('write_to_console');
    %% These are the line numbers of the two mp_warning calls below, and they
    %% are hard coded in the result files and must be updated if the line
    %% numbers change.
    line_no_1 = '130';
    line_no_2 = '131';  
    mp_warning('expected warning %d', 1);
    got = evalc('mp_warning(''expected warning %d'', 2);');
    fname_got = mp.logger.manager('path');
    mp.logger.manager('clear', fname);
    t_ok(active, [t 'active']);
    t_ok(~write_to_console, [t 'not write_to_console']);
    t_str_match(fname_got, fname, [t 'log file path']);
    t_file_match(fname, redir_warning_fname, [t 'mp_warning - file w/expected content'], reps, true);
    t_ok(isempty(got), [t 'mp_warning - no console output']);
    t_ok(isempty(mp.logger.manager('get')), [t 'mp.logger.manage(''clear'')']);

    %% both
    t = 'both : ';
    fname = sprintf('redir-disp-%d.txt', fix(rand*1e8));
    mp.logger.manager('init', fname, 'a', 1);
    active = mp.logger.manager('active');
    write_to_console = mp.logger.manager('write_to_console');
    got = evalc('mp_disp(exp(1)); mp_disp(sprintf(''This is %d\nlines of\ntext (%s).\n'', 3, ''I think''));');
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
    if ~t_str_match(got, expected, [t 'mp_disp - outputs to console']);
        fprintf('\ngot:\n"%s"\n', got);
        fprintf('exp:\n"%s"\n', expected);
    end
    t_ok(isempty(mp.logger.manager('get')), [t 'mp.logger.manage(''clear'')']);

    fname = sprintf('redir-printf-%d.txt', fix(rand*1e8));
    mp.logger.manager('init', fname, 'w', 1);
    active = mp.logger.manager('active');
    write_to_console = mp.logger.manager('write_to_console');
    got = evalc('mp_printf(''This is %d\nlines of\ntext (%s).\n'', 3, ''I think''); mp_printf(''Hello %s!\n\n'', ''mp_printf'');');
    expected = sprintf('This is 3\nlines of\ntext (I think).\nHello mp_printf!\n\n');
    fname_got = mp.logger.manager('path');
    mp.logger.manager('clear', fname);
    t_ok(active, [t 'active']);
    t_ok(write_to_console, [t 'write_to_console']);
    t_str_match(fname_got, fname, [t 'log file path']);
    t_file_match(fname, redir_printf_fname, [t 'mp_printf - file w/expected content'], {}, true);
    t_str_match(got, expected, [t 'mp_printf - outputs to console']);
    t_ok(isempty(mp.logger.manager('get')), [t 'mp.logger.manage(''clear'')']);
    t_ok(~mp.logger.manager('active'), [t 'not active']);
    t_ok(mp.logger.manager('write_to_console'), [t 'write_to_console']);

    fname = sprintf('redir-warning-%d.txt', fix(rand*1e8));
    mp.logger.manager('init', fname, 'w', 1);
    active = mp.logger.manager('active');
    write_to_console = mp.logger.manager('write_to_console');
    line_no = '191';    %% must be line number of line below this one
    got = evalc('mp_warning(''expected warning %d'', 1); mp_warning(''expected warning %d'', 2);');
    if have_feature('octave')
        expected = sprintf('warning: expected warning 1\nwarning: called from\n    mp_warning at line 32 column 9\n    t_mp_logger at line %s column 7\nwarning: expected warning 2\nwarning: called from\n    mp_warning at line 32 column 7\n    t_mp_logger at line %s column 7\n', line_no, line_no);
    else
        expected = sprintf('Warning: expected warning 1\n> In mp_warning (line 32)\nIn t_mp_logger (line %s)\nWarning: expected warning 2\n> In mp_warning (line 32)\nIn t_mp_logger (line %s)\n', line_no, line_no);
    end
    fname_got = mp.logger.manager('path');
    mp.logger.manager('clear', fname);
    t_ok(active, [t 'active']);
    t_ok(write_to_console, [t 'write_to_console']);
    t_str_match(fname_got, fname, [t 'log file path']);
    t_file_match(fname, redir_warning_fname, [t 'mp_warning - file w/expected content'], {{line_no_1, line_no, 0, 1}, {line_no_2, line_no, 0, 1}, reps{:}}, true);
    if ~t_str_match(got, expected, [t 'mp_warning - outputs to console'], reps)
        fprintf('\ngot:\n"%s"\n', got);
        fprintf('exp:\n"%s"\n', expected);
    end
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
    got = evalc('mp_printf(''Hello %s!\n\n'', ''mp_printf''); mp_printf(''This is %d\nlines of\ntext (%s).\n'', 3, ''I think'');');
    expected = sprintf('Hello mp_printf!\n\nThis is 3\nlines of\ntext (I think).\n');
    t_str_match(got, expected, [t 'mp_printf - outputs to console']);

    %% resume
    t = 'resume : ';
    mp.logger.manager('resume');
    active = mp.logger.manager('active');
    write_to_console = mp.logger.manager('write_to_console');
    mp_printf('This is %d\nlines of\ntext (%s).\n', 3, 'I think');
    got = evalc('mp_printf(''Hello %s!\n\n'', ''mp_printf'');');
    fname_got = mp.logger.manager('path');
    mp.logger.manager('clear', fname);
    t_ok(active, [t 'active']);
    t_ok(~write_to_console, [t 'not write_to_console']);
    t_str_match(fname_got, fname, [t 'log file path']);
    t_file_match(fname, redir_printf_fname, [t 'mp_printf - file w/expected content'], {}, true);
    t_ok(isempty(got), [t 'mp_printf - no console output']);
    t_ok(isempty(mp.logger.manager('get')), [t 'mp.logger.manage(''clear'')']);
else
    t_skip(n_tests, 'mp.logger object in use, tests will not work');
end

t_end;
