function uninstall(varargin)
    % UNINSTALL(varargin)
    %   Description:
    %     Provides a way to directly 'uninstall' MATLAB Community Toolboxes from 
    %     Github.
    %   Inputs:
    %     toolboxName[required]: <string> Toolbox name to be uninstalled e.g. 'toolbox1'
    %   Assumptions:
    %     - Users do not wish to have multiple simultaneous versions installed i.e. all
    %       versions of specified toolbox are uninstalled (if applicable).
    %   Examples:
    %     ghtb.uninstall('compareVersions') % uninstalls all versions of Toolbox
    clear('functions'); %needed for uninstall of mex-based toolboxes
    s = settings;
    p = inputParser;
    addRequired(p, 'toolboxName');
    parse(p, varargin{:});
    toolboxName = p.Results.toolboxName;
    % determine toolbox root
    if verLessThan('matlab', '9.2')
        toolboxRoot = [strrep(s.matlab.addons.InstallationFolder.ActiveValue, '\', '/') ...
                       '/Toolboxes/' toolboxName '/code'];
    else
        toolboxRoot = [strrep(s.matlab.addons.InstallationFolder.ActiveValue, '\', '/') ...
                       '/Toolboxes/' toolboxName];
    end
    % remove all versions of toolbox
    warning('off','toolboxmanagement_matlab_api:uninstallToolbox:manualCleanupNeeded');
    try
        matlab.addons.uninstall(toolboxName, 'All');
    catch ME
        if strcmp(ME.identifier, 'MATLAB:undefinedVarOrClass')
            toolboxes = matlab.addons.toolbox.installedToolboxes;
            matched = toolboxes(strcmp(toolboxName, {toolboxes.Name}));
            arrayfun(@(x) matlab.addons.toolbox.uninstallToolbox(x), matched, ...
                     'UniformOutput', false);
        else
            rethrow(ME);
        end
    end
    warning('on','toolboxmanagement_matlab_api:uninstallToolbox:manualCleanupNeeded');
    if exist(toolboxRoot, 'dir')
        rmdir(toolboxRoot);
    end
    % remove mex-based path if applicable
    paths = strsplit(path, ':');
    pathfile = fullfile(userpath, 'startup.m');
    for x = paths(cellfun(@(x) contains(x, toolboxRoot), paths, 'uni', true))
        rmpath(x{1});
        if exist(pathfile, 'file') == 2
            fid = fopen(pathfile, 'r');
            f = fread(fid, '*char')';
            fclose(fid);
            f = regexprep(f,strrep(['\naddpath(''' x{1} ''');\n'], ...
                                   ')', '\)'), '');
            fid = fopen(pathfile, 'w');
            fprintf(fid,'%s',f);
            fclose(fid);
        end
    end
end