function printFailures(results)
%printFailures Prints the test diagnostics of failed/errored results.
%
% Syntax:
%   >> r = runtests('TestQrgBulkLayout'); printFailures(r)

fprintf('PASS %d  FAIL %d  INCOMPLETE %d\n', nnz([results.Passed]), ...
    nnz([results.Failed]), nnz([results.Incomplete]));
for r = results(:)'
    if r.Passed || (r.Incomplete && ~r.Failed)
        continue
    end
    fprintf('--- %s\n', r.Name);
    recs = r.Details.DiagnosticRecord;
    for j = 1 : numel(recs)
        txt = '';
        if isprop(recs(j), 'TestDiagnosticResults') && ~isempty(recs(j).TestDiagnosticResults)
            txt = strjoin({recs(j).TestDiagnosticResults.DiagnosticText}, newline);
        end
        if isempty(txt) && isprop(recs(j), 'Exception') && ~isempty(recs(j).Exception)
            txt = recs(j).Exception.getReport('basic');
        end
        if isempty(txt)
            txt = recs(j).Report;
        end
        fprintf('    %s\n', strrep(strtrim(txt), newline, [newline, '    ']));
    end
end
end
