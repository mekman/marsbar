function varargout=marsbar(varargin) 
% Startup, callback and utility routine for Marsbar
%
% MarsBaR: Marseille Boite a Regions d'interet 
%          Marseille Region of Interest Toolbox 
%
% MarsBaR (the collection of files listed by contents.m) is copyright under
% the GNU general public license.  Please see mars_licence.man for details.
% 
% Marsbar written by 
% Jean-Luc Anton, Matthew Brett, Jean-Baptiste Poline, Romain Valabregue 
%
% Portions of the code rely heavily on (or are copied from) SPM99 and SPM2
% (http://www.fil.ion.ucl.ac.uk/spm), which is also released under the GNU
% public licence.  Many thanks the SPM authors: (John Ashburner, Karl
% Friston, Andrew Holmes et al, and of course our own Jean-Baptiste).
%
% This software is MarsBaRWare. It is written in the hope that it is
% helpful; if you find it so, please let us know by sending a Mars bar to:
% The Jean-Luc confectionery collection, Centre IRMf, CHU La Timone, 264,
% Rue Saint Pierre 13385 Marseille Cedex 05, France
% 
% If you find that it actively hinders your work, do send an
% elderly sardine to the same address.
%
% Please visit our friends at The Visible Mars Bar project:
% http://totl.net/VisibleMars
%
% $Id$

% Programmer's help
% -----------------
% For a list of the functions implemented here, try
% grep "^case " marsbar.m
  
% Marsbar version
MBver = '0.32';  % Third SPM2 development release 

% Various working variables in global variable structure
global MARS;

%-Format arguments
%-----------------------------------------------------------------------
if nargin == 0, Action='Startup'; else, Action = varargin{1}; end

%=======================================================================
switch lower(Action), case 'startup'                     %-Start marsbar
%=======================================================================

%-Turn on warning messages for debugging
warning backtrace

% splash screen once per session
splashf = isempty(MARS);

% promote spm directory to top of path, read defaults
marsbar('on');

%-Open startup window, set window defaults
%-----------------------------------------------------------------------
S = get(0,'ScreenSize');
if all(S==1), error('Can''t open any graphics windows...'), end
PF = spm_platform('fonts');

% Splash screen
%------------------------------------------
if splashf
  marsbar('splash');
end

%-Draw marsbar window
%-----------------------------------------------------------------------
Fmenu = marsbar('CreateMenuWin','off');

%-Reveal windows
%-----------------------------------------------------------------------
set([Fmenu],'Visible','on')

%=======================================================================
case 'on'                                           %-Initialise MarsBaR
%=======================================================================

% promote spm replacement directory, affichevol directories
mbpath = fileparts(which('marsbar.m'));
spmV = spm('ver');
MARS.ADDPATHS = {fullfile(mbpath, ['spm' spmV(4:end)]),...
		 fullfile(mbpath, 'fonct'),...
		 fullfile(mbpath, 'init')};
addpath(MARS.ADDPATHS{:}, '-begin');
fprintf('MarsBaR analysis functions prepended to path\n');

% check SPM defaults are loaded
mars_veropts('defaults');

% set up the ARMOIRE stuff
% see mars_armoire help for details
filter_specs  = {mars_veropts('design_filter_spec'), ...
		 {'*_mdata.mat','MarsBaR data file (*_mdata.mat)'},...
		 {'*_mres.mat', 'MarsBaR results (*_mres.mat)'}};

mars_armoire('add_if_absent','def_design', ...
	     struct('default_file_name', 'untitled_mdes.mat',...	  
		    'filter_spec', {filter_specs{1}},...
		    'title', 'default design',...
		    'set_action', 'mars_arm_call(''set_design'',I)'));
mars_armoire('add_if_absent','roi_data',...
	     struct('default_file_name', 'untitled_mdata.mat',...
		    'filter_spec', {filter_specs{2}},...
		    'title', 'ROI data',...
		    'set_action', 'mars_arm_call(''set_data'',I)'));
mars_armoire('add_if_absent','est_design',...
	     struct('default_file_name', 'untitled_mres.mat',...
		    'filter_spec', {filter_specs{3}},...
		    'title', 'MarsBaR estimated design',...
		    'set_action', 'mars_arm_call(''set_results'',data)'));

% and workspace
if ~isfield(MARS, 'WORKSPACE'), MARS.WORKSPACE = []; end

% read any necessary defaults
if ~mars_struct('isthere', MARS, 'OPTIONS')
  loadf = 1;
  MARS.OPTIONS = [];
else
  loadf = 0;
end
[mbdefs sourcestr] = mars_options('Defaults');
MARS.OPTIONS = mars_options('fill',MARS.OPTIONS, mbdefs);
mars_options('put');
if loadf
  fprintf('Loaded MarsBaR defaults from %s\n',sourcestr);
end

%=======================================================================
case 'off'                                              %-Unload MarsBaR 
%=======================================================================
% marsbar('Off')
%-----------------------------------------------------------------------
% save outstanding information
mars_armoire('save_ui', 'all', 'y');

% leave if no signs of marsbar
if isempty(MARS)
  return
end

% remove marsbar added directories
rmpath(MARS.ADDPATHS{:});
fprintf('MarsBaR analysis functions removed from path\n');

%=======================================================================
case 'quit'                                        %-Quit MarsBaR window
%=======================================================================
% marsbar('Quit')
%-----------------------------------------------------------------------

% do path stuff, save any pending changes
marsbar('off');

% leave if no signs of MARSBAR
if isempty(MARS)
  return
end

%-Close any existing 'MarsBaR' 'Tag'ged windows
delete(spm_figure('FindWin','MarsBaR'))
fprintf('Au revoir...\n\n')

%=======================================================================
case 'cfgfile'                                  %-finds MarsBaR cfg file
%=======================================================================
% cfgfn  = marsbar('cfgfile')
cfgfile = 'marsbarcfg.mat';
varargout = {which(cfgfile), cfgfile}; 

%=======================================================================
case 'createmenuwin'                          %-Draw MarsBaR menu window
%=======================================================================
% Fmenu = marsbar('CreateMenuWin',Vis)
if nargin<2, Vis='on'; else, Vis=varargin{2}; end

%-Close any existing 'MarsBaR' 'Tag'ged windows
delete(spm_figure('FindWin','MarsBaR'))

% Version etc info
[MBver,MBc] = marsbar('Ver');

%-Get size and scalings and create Menu window
%-----------------------------------------------------------------------
WS   = spm('WinScale');				%-Window scaling factors
FS   = spm('FontSizes');			%-Scaled font sizes
PF   = spm_platform('fonts');			%-Font names (for this platform)
Rect = [50 600 300 275];           	%-Raw size menu window rectangle
bno = 6; bgno = bno+1;
bgapr = 0.25;
bh = Rect(4) / (bno + bgno*bgapr);      % Button height
gh = bh * bgapr;                        % Button gap
by = fliplr(cumsum([0 ones(1, bno-1)*(bh+gh)])+gh);
bx = Rect(3)*0.1;
bw = Rect(3)*0.8;
Fmenu = figure('IntegerHandle','off',...
	'Name',sprintf('%s',MBc),...
	'NumberTitle','off',...
	'Tag','MarsBaR',...
	'Position',Rect.*WS,...
	'Resize','off',...
	'Color',[1 1 1]*.8,...
	'UserData',struct('MBver',MBver,'MBc',MBc),...
	'MenuBar','none',...
	'DefaultTextFontName',PF.helvetica,...
	'DefaultTextFontSize',FS(12),...
	'DefaultUicontrolFontName',PF.helvetica,...
	'DefaultUicontrolFontSize',FS(12),...
	'DefaultUicontrolInterruptible','on',...
	'Renderer','zbuffer',...
	'Visible','off');

%-Objects with Callbacks - main MarsBaR routines
%=======================================================================

funcs = {'mars_display_roi(''display'');',...
	 'affichevol',...
	 'mars_blob_ui;',...
	 'marsbar(''buildroi'');',...
	 'marsbar(''transform'');',...
	 'marsbar(''import_rois'');',...
	 'marsbar(''export_rois'');'};

uicontrol(Fmenu,'Style','PopUp',...
	  'String',['ROI definition',...
		    '|View...'...
		    '|Draw...'...
		    '|Get SPM cluster(s)...'...
		    '|Build...',...
		    '|Transform...',...
		    '|Import...',...
		    '|Export...'],...
	  'Position',[bx by(1) bw bh].*WS,...
	  'ToolTipString','Draw / build / combine ROIs...',...
	  'CallBack','spm(''PopUpCB'',gcbo)',...
	  'UserData',funcs);

% Design menu
funcs = {...
    'marsbar(''make_design'', ''pet'');',...
    'marsbar(''make_design'', ''fmri'');',...
    'marsbar(''make_design'', ''basic'');',...
    'marsbar(''design_report'')',...
    'marsbar(''design_filter'')',...
    'marsbar(''add_images'')',...
    'marsbar(''edit_filter'')',...
    'marsbar(''check_images'')',...
    'marsbar(''ana_cd'')',...
    'marsbar(''ana_desmooth'')',...
    'marsbar(''def_from_est'')',...
    ['mars_armoire(''set_ui'', ''def_design'');' ...
     'marsbar(''design_report'')'],...
    'mars_armoire(''save_ui'', ''def_design'', ''fw'');'};

uicontrol(Fmenu,'Style','PopUp',...
	  'String',['Design...'...
		    '|PET models',...
		    '|FMRI models',...
		    '|Basic models',...
		    '|Explore',...
		    '|Frequencies (event+data)',...
		    '|Add images to FMRI design',...
		    '|Add/edit filter for FMRI design',...	
		    '|Check image names in design',...
		    '|Change design path to images',...
		    '|Convert to unsmoothed',...
		    '|Set design from estimated',...
		    '|Set design from file',...
		    '|Save design to file'],...
	  'Position',[bx by(2) bw bh].*WS,...
	  'ToolTipString','Set/specify design...',...
	  'CallBack','spm(''PopUpCB'',gcbo)',...
	  'UserData',funcs);

% Data menu
funcs = {'marsbar(''extract_data'', ''default'');',...
	 'marsbar(''extract_data'', ''full'');',...
	 'marsbar(''set_defregion'');',...
	 'marsbar(''plot_data'', ''raw'');',...
	 'marsbar(''plot_data'', ''full'');',...
	 'marsbar(''import_data'');',...
	 'marsbar(''export_data'');',...
	 'marsbar(''split_data'');',...
	 'marsbar(''join_data'');',...
	 'mars_armoire(''set_ui'', ''roi_data'');',...
	 'mars_armoire(''save_ui'', ''roi_data'', ''fw'');'};

uicontrol(Fmenu,'Style','PopUp',...
	  'String',['Data...'...
		    '|Extract ROI (default)',...
		    '|Extract ROIs (full options)',...
		    '|Default region...',...
		    '|Plot data (simple)',...
		    '|Plot data (full)',...		    
		    '|Import data',...
		    '|Export data',...
		    '|Split regions into files',...
		    '|Merge data files',...
		    '|Set data from file',...
		    '|Save data to file'],...
	  'Position',[bx by(3) bw bh].*WS,...
	  'ToolTipString','Extract/set/save data...',...
	  'CallBack','spm(''PopUpCB'',gcbo)',...
	  'UserData',funcs);

% results menu
funcs = {...
    'marsbar(''estimate'');',...
    'marsbar(''merge_contrasts'');',...
    'marsbar(''add_trial_f'');',...
    'marsbar(''set_defcon'');',...
    'marsbar(''set_defregion'');',...
    'marsbar(''plot_residuals'');',...
    'marsbar(''spm_graph'');',...
    'marsbar(''stat_table'');',...
    'marsbar(''signal_change'');',...
    'marsbar(''set_results'');',...
    'mars_armoire(''save_ui'', ''est_design'', ''fw'');'};

uicontrol(Fmenu,'Style','PopUp',...
	  'String',['Results...'...
		    '|Estimate results',...
		    '|Import contrasts',...
		    '|Add trial-specific F',...
		    '|Default contrast...',...
		    '|Default region...',...
		    '|Plot residuals',...
		    '|MarsBaR SPM graph',...
		    '|Statistic table',...
		    '|% signal change',...
		    '|Set results from file',...
		    '|Save results to file'],...
	  'Position',[bx by(4) bw bh].*WS,...
	  'ToolTipString','Write/display contrasts...',...
	  'CallBack','spm(''PopUpCB'',gcbo)',...
	  'UserData',funcs);

% options menu
funcs = {['global MARS; '...
	 'MARS.OPTIONS=mars_options(''edit'');mars_options(''put'');'],...
	 ['global MARS; '...
	  '[MARS.OPTIONS str]=mars_options(''defaults'');' ...
	  'mars_options(''put''); '...
	  'fprintf(''Defaults loaded from %s\n'', str)'],...
	 ['global MARS; '...
	  '[MARS.OPTIONS str]=mars_options(''basedefaults'');' ...
	  'mars_options(''put''); '...
	  'fprintf(''Defaults loaded from %s\n'', str)'],...
	 ['global MARS; '...
	  'MARS.OPTIONS=mars_options(''load'');mars_options(''put'');'],...
	 'mars_options(''save'');'...
	};
	 
uicontrol(Fmenu,'Style','PopUp',...
	  'String',['Options...'...
		    '|Edit options'...
		    '|Restore defaults'...
		    '|Base defaults',...
		    '|Set options from file'...
		    '|Save options to file'],...
	  'Position',[bx by(5) bw bh].*WS,...
	  'ToolTipString','Load/save/edit MarsBaR options',...
	  'CallBack','spm(''PopUpCB'',gcbo)',...
	  'UserData',funcs);

% quit button
uicontrol(Fmenu,'String','Quit',...
	  'Position',[bx by(6) bw bh].*WS,...
	  'ToolTipString','exit MarsBaR',...
	  'ForeGroundColor','r',...
	  'Interruptible','off',...
	  'CallBack','marsbar(''Quit'')');

% Set quit action if MarsBaR window is closed
%-----------------------------------------------------------------------
set(Fmenu,'CloseRequestFcn','marsbar(''Quit'')')
set(Fmenu,'Visible',Vis)

varargout = {Fmenu};

%=======================================================================
case {'ver', 'version'}                         %-Return MarsBaR version
%=======================================================================
% [v [,banner]] = marsbar('Ver')
%-----------------------------------------------------------------------
varargout = {MBver, 'MarsBaR - Marseille ROI toolbox'};

%=======================================================================
case 'splash'                                       %-show splash screen
%=======================================================================
% marsbar('splash')
%-----------------------------------------------------------------------
% Shows splash screen  
WS   = spm('WinScale');		%-Window scaling factors
[X,map] = imread('marsbar.jpg');
aspct = size(X,1) / size(X,2);
ww = 400;
srect = [200 300 ww ww*aspct] .* WS;   %-Scaled size splash rectangle
h = figure('visible','off',...
	   'menubar','none',...
	   'numbertitle','off',...
	   'name','Welcome to MarsBaR',...
	   'pos',srect);
im = image(X);
colormap(map);
ax = get(im, 'Parent');
axis off;
axis image;
axis tight;
set(ax,'plotboxaspectratiomode','manual',...
       'unit','pixels',...
       'pos',[0 0 srect(3:4)]);
set(h,'visible','on');
pause(3);
close(h);
 
%=======================================================================
case 'buildroi'                                     %-build and save ROI
%=======================================================================
% o = marsbar('buildroi')
%-----------------------------------------------------------------------
% build and save object
varargout = {[]};
o = mars_build_roi;
if ~isempty(o)
  varargout = {marsbar('saveroi', o)};
end

%=======================================================================
case 'transform'                                        %-transform ROIs
%=======================================================================
% marsbar('transform')
%-----------------------------------------------------------------------
marsbar('mars_menu', 'Transform ROI', 'Transform:', ...
	{{'combinerois'},{'flip_lr'}},...
	{'Combine ROIs','Flip L/R'});

%=======================================================================
case 'import_rois'                                       %- import ROIs!
%=======================================================================
% marsbar('import_rois')
%-----------------------------------------------------------------------

marsbar('mars_menu', 'Import ROIs', 'Import ROIs from:',...
	{{'img2rois','c'},...
	 {'img2rois','i'}},...
	{'cluster image',...
	 'number labelled ROI image'});

%=======================================================================
case 'export_rois'                                         %-export ROIs
%=======================================================================
% marsbar('export_rois')
%-----------------------------------------------------------------------

marsbar('mars_menu', 'Export ROI(s)', 'Export ROI(s) to:',...
	{{'roi_as_image'},...
	 {'rois2img', 'c'},...
	 {'rois2img', 'i'}},...
	{'image', 'cluster image',...
	'number labelled ROI image'});

%=======================================================================
case 'img2rois'                                       %-import ROI image
%=======================================================================
%  marsbar('img2rois', roi_type)
%-----------------------------------------------------------------------

if nargin < 2
  roi_type = 'c'; % default is cluster image
else
  roi_type = varargin{2};
end
mars_img2rois('','','',roi_type);

%=======================================================================
case 'rois2img'                                       %-export ROI image
%=======================================================================
%  marsbar('roi2img', roi_type)
%-----------------------------------------------------------------------

if nargin < 2
  roi_type = 'c'; % default is cluster image
else
  roi_type = varargin{2};
end
mars_rois2img('','','',roi_type);

%=======================================================================
case 'saveroi'                                                %-save ROI
%=======================================================================
% o = marsbar('saveroi', obj, flags)
%-----------------------------------------------------------------------
% flags will usually be empty, or one or more characters from
% 'n'   do not ask for label or description
% 'l'   use label to make filename, rather than source field

if nargin < 2 | isempty(varargin{2})
  return
end
if nargin < 3
  flags = '';
end
if isempty(flags), flags = ' '; end
o = varargin{2};
varargout = {[]};

% Label, description
if ~any(flags=='n')
  d = spm_input('Description of ROI', '+1', 's', descrip(o));
  o = descrip(o,d);
  l = spm_input('Label for ROI', '+1', 's', label(o));
  o = label(o,l);
end

fn = source(o);
if isempty(fn) | any(flags=='l')
  fn = maroi('filename', marsbar('str2fname', label(o)));
end

f_f = ['*' maroi('classdata', 'fileend')];
[f p] = mars_uifile('put', ...
		    {f_f, ['ROI files (' f_f ')']},...
		    'File name for ROI', fn);
if any(f~=0)
  roi_fname = maroi('filename', fullfile(p, f));
  try
    varargout = {saveroi(o, roi_fname)};
  catch
    warning([lasterr ' Error saving ROI to file ' roi_fname])
  end
end

%=======================================================================
case 'combinerois'                                        %-combine ROIs
%=======================================================================
% marsbar('combinerois')
%-----------------------------------------------------------------------
roilist = spm_get(Inf,maroi('classdata', 'fileend'), ...
		  'Select ROI(s) to combine');
if isempty(roilist)
  return
end
roilist = maroi('load_cell', roilist);
[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Combine ROIs');
spm_input('(r1 & r2) & ~r3',1,'d','Example function:');
func = spm_input('Function to combine ROIs', '+1', 's', '');
if isempty(func), retnrn, end
for i = 1:length(roilist)
  eval(sprintf('r%d = roilist{%d};', i, i));
end
try
  eval(['o=' func ';']);
catch
  warning(['Hmm, probem with function ' func ': ' lasterr]);
  return
end
if isempty(o)
  warning('Empty object resulted');
  return
end
if is_empty_roi(o)
  warning('No volume resulted for ROI');
  return
end

% save ROI
if isa(o, 'maroi')
  o = label(o, func);
  o = marsbar('saveroi', o); 
  fprintf('\nSaved ROI as %s\n', source(o));
else
  warning(sprintf('\nNo ROI resulted from function %s...\n', func));
end

%=======================================================================
case 'flip_lr'                                          %-flip roi L<->R
%=======================================================================
% marsbar('flip_lr')
%-----------------------------------------------------------------------
roilist = spm_get([0 1],maroi('classdata', 'fileend'),...
		  'Select ROI to flip L/R');
if isempty(roilist)
  return
end
[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Flip ROI L<->R');
o = maroi('load', roilist);
o = flip_lr(o);

% save ROI
o = marsbar('saveroi', o, 'l'); 
fprintf('\nSaved ROI as %s\n', source(o));

%=======================================================================
case 'show_volume'                  %- shows ROI volume in mm to console 
%=======================================================================
% marsbar('show_volume')
%-----------------------------------------------------------------------
roi_names = spm_get([0 Inf], 'roi.mat', 'Select ROIs tp get volume');
if isempty(roi_names),return,end
rois = maroi('load_cell', roi_names);
for i = 1:size(rois, 1)
  fprintf('Volume of %s: %6.2f\n', source(rois{i}), volume(rois{i}));
end
return

%=======================================================================
case 'roi_as_image'                               %- writes ROI as image 
%=======================================================================
% marsbar('roi_as_image')
%-----------------------------------------------------------------------
[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Write ROI to image');

roi = spm_get([0 1], 'roi.mat', 'Select ROI to write');
if isempty(roi),return,end
[pn fn ext] = fileparts(roi);
roi = maroi('load', roi);

% space of object
spopts = {'spacebase','image'};
splabs =  {'Base space for ROIs','From image'};
if has_space(roi)
  spopts = {spopts{:} 'native'};
  splabs = {splabs{:} 'ROI native space'};
end
spo = spm_input('Space for ROI image', '+1', 'm',splabs,...
		spopts, 1);
switch char(spo)
 case 'spacebase'
   sp = maroi('classdata', 'spacebase');
 case 'image'
  img = spm_get([0 1], 'img', 'Image defining space');
  if isempty(img),return,end
  sp = mars_space(img);
 case 'native'
  sp = [];
end

% remove ROI file ending
gend = maroi('classdata', 'fileend');
lg = length(gend);
f2 = [fn ext];
if length(f2)>=lg & strcmp(gend, [f2(end - lg +1 : end)])
  f2 = f2(1:end-lg);
else
  f2 = fn;
end

fname = marsbar('get_img_name', f2);
if isempty(fname), return, end
save_as_image(roi, fname, sp);
fprintf('Saved ROI as %s\n',fname);

%=======================================================================
case 'attach_image'                          %- attaches image to ROI(s)
%=======================================================================
% marsbar('attach_image' [,img [,roilist]])
%-----------------------------------------------------------------------
if nargin < 2
  V = spm_get([0 1], 'img', 'Image to attach');
  if isempty(V), return, end
else
  V = varargin{1};
end
if nargin < 3
  rois = spm_get([0 Inf], maroi('classdata', 'fileend'), ...
		 'Select ROIs to attach image to');
  
  if isempty(rois), return, end
else
  rois = varargin{2};
end
if ischar(V), V = spm_vol(V); end
for i = 1:size(rois, 1)
  n = deblank(rois(i,:));
  try 
    r = maroi('load', n);
  catch
    if ~strmatch(lasterr, 'Cant map image file.')
      error(lasterr);
    end
  end
  if isempty(r)
    continue
  end
  if ~isa(r, 'maroi_image')
    fprintf('ROI %s is not an image ROI - ignored\n', n);
    continue
  end

  r = vol(r, V);
  saveroi(r, n);
  fprintf('Saved ROI %s, attached to image %s\n',...
	  n, V.fname)
end
return

%=======================================================================
case 'make_design'                       %-runs design creation routines
%=======================================================================
% marsbar('make_design', des_type)
%-----------------------------------------------------------------------
if nargin < 2
  des_type = 'basic';
else
  des_type = varargin{2};
end
D = ui_build(mars_veropts('default_design'), des_type);
mars_armoire('set','def_design', D);
marsbar('design_report');

%=======================================================================
case 'list_images'                     %-lists image files in SPM design
%=======================================================================
% marsbar('list_images')
%-----------------------------------------------------------------------
marsD = mars_armoire('get','def_design');
if isempty(marsD), return, end;
if has_images(marsD)
  P = image_names(marsD);
  strvcat(P{:})
else
  disp('Design does not contain images');
end

%=======================================================================
case 'check_images'                   %-checks image files in SPM design
%=======================================================================
% marsbar('check_images')
%-----------------------------------------------------------------------
marsD = mars_armoire('get','def_design');
if isempty(marsD), return, end;
if ~has_images(marsD)
  disp('Design does not contain images');
  return
end

P = image_names(marsD);
P = strvcat(P{:});
ok_f = 1;
for i = 1:size(P, 1)
  fname = deblank(P(i,:));
  if ~exist(fname, 'file');
    fprintf('Image %d: %s does not exist\n', i, fname);
    ok_f = 0;
  end
end
if ok_f
  disp('All images in design appear to exist');
end

%=======================================================================
case 'ana_cd'                      %-changes path to files in SPM design
%=======================================================================
% marsbar('ana_cd')
%-----------------------------------------------------------------------
marsD = mars_armoire('get','def_design');
if isempty(marsD), return, end;

% Setup input window
[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Change image path in design', 0);

% root path shown in output window
P = image_names(marsD);
P = strvcat(P{:});
root_names = spm_str_manip(P, 'H');
spm_input(deblank(root_names(1,:)),1,'d','Common path is:');

% new root
newpath = spm_get([-1 0], '', 'New directory root for files');
if isempty(newpath), return, end

% do
marsD = cd_images(marsD, newpath);
mars_armoire('set', 'def_design', marsD);

%=======================================================================
case 'ana_desmooth'           %-makes new SPM design for unsmoothed data
%=======================================================================
% marsbar('ana_desmooth')
%-----------------------------------------------------------------------
marsD = mars_armoire('get','def_design');
if isempty(marsD), return, end;
marsD = prefix_images(marsD, 'remove', 's');
mars_armoire('set', 'def_design', marsD);
disp('Done');

%=======================================================================
case 'add_images'                            %-add images to FMRI design
%=======================================================================
% marsbar('add_images')
%-----------------------------------------------------------------------
marsD = mars_armoire('get','def_design');
if isempty(marsD), return, end
if ~is_fmri(marsD), return, end
marsD = fill(marsD, {'images'});
mars_armoire('update', 'def_design', marsD);
mars_armoire('file_name', 'def_design', '');

%=======================================================================
case 'edit_filter'                   %-add / edit filter for FMRI design
%=======================================================================
% marsbar('edit_filter')
%-----------------------------------------------------------------------
marsD = mars_armoire('get','def_design');
if isempty(marsD), return, end
if ~is_fmri(marsD), return, end
tmp = {'filter'};
if ~strcmp(type(marsD), 'SPM99'), tmp = [tmp {'autocorr'}]; end
marsD = fill(marsD, tmp);
mars_armoire('update', 'def_design', marsD);
mars_armoire('file_name', 'def_design', '');

%=======================================================================
case 'def_from_est'          %-sets default design from estimated design
%=======================================================================
% marsbar('def_from_est')
%-----------------------------------------------------------------------
marsE = mars_armoire('get','est_design');
if isempty(marsE), return, end;
mars_armoire('set', 'def_design', marsE);
marsbar('design_report');

%=======================================================================
case 'design_report'                         %-does explore design thing
%=======================================================================
% marsbar('design_report')
%-----------------------------------------------------------------------
marsD = mars_armoire('get','def_design');
if isempty(marsD), return, end;
spm('FnUIsetup','Explore design', 0);

fprintf('%-40s: ','Design reporting');
ui_report(marsD, 'DesMtx');
ui_report(marsD, 'DesRepUI');
fprintf('%30s\n','...done');

%=======================================================================
case 'design_filter'                      %-shows FFT of data and design
%=======================================================================
% marsbar('design_filter')
%-----------------------------------------------------------------------
marsD = mars_armoire('get','def_design');
if isempty(marsD), return, end;
marsY = mars_armoire('get','roi_data');
if isempty(marsY), return, end
ui_ft_design_data(marsD, marsY);

%=======================================================================
case 'extract_data'                       % gets data maybe using design
%=======================================================================
% marsY = marsbar('extract_data'[, roi_list [, 'full'|'default']]);

if nargin < 2
  etype = 'default';
else
  etype = varargin{2};
end
if nargin < 3
  roi_list = '';
else
  roi_list = varargin{3};
end
if isempty(roi_list)
  roi_list = spm_get(Inf,'roi.mat','Select ROI(s) to extract data for');
end

varargout = {[]};
if isempty(roi_list), return, end

[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Extract data', 0);

if strcmp(etype, 'default')
  marsD = mars_armoire('get','def_design');
  if isempty(marsD), return, end;
  if ~has_images(marsD),
    marsD = fill(marsD, 'images');
    mars_armoire('update', 'def_design', marsD);
  end
  VY = marsD;
  row = block_rows(marsD);
else  % full options extraction
  % question for design
  
  marsD = [];
  if spm_input('Use SPM design?', '+1', 'b', 'Yes|No', [1 0], 1)
    marsD = mars_armoire('get','def_design');
    if ~has_images(marsD),
      marsD = fill(marsD, 'images');
      mars_armoire('update', 'def_design', marsD);
    end
  end
  [VY row] = mars_image_scaling(marsD);
end

% Summary function
sumfunc = sf_get_sumfunc(MARS.OPTIONS.statistics.sumfunc);

% ROI names to objects
o = maroi('load_cell', roi_list);

% Do data extraction
marsY = get_marsy(o{:}, VY, sumfunc, 'v');
marsY = block_rows(marsY, row);
if ~n_regions(marsY)
  msgbox('No data returned','Data extraction', 'warn');
  return
end

% set into armoire
mars_armoire('set', 'roi_data', marsY);

varargout = {marsY};

%=======================================================================
case 'plot_data'                                       %- it plots data!
%=======================================================================
% marsbar('plot_data', p_type)
%-----------------------------------------------------------------------
% p_type     - plot type: one of 'raw','acf','fft','all' or 'full'
% where 'full' results in a options to filter and choice of plot

if nargin < 2
  p_type = [];
else
  p_type = varargin{2};
end
if isempty(p_type)
  p_type = 'full';
end
marsY = mars_armoire('get','roi_data');
if isempty(marsY), return, end

[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Plot data', 0);
if strcmp(p_type, 'full')
  if ~mars_armoire('isempty', 'def_design')
    D = mars_armoire('get', 'def_design');
    if has_filter(D)
      if spm_input('Use design filter?', '+1', 'y/n', [1 0], 1)
	flags = {};
	if has_whitener(D) 
	  if ~spm_input('Use whitening filter?', '+1', 'y/n', [1 0], 1)
	    flags = 'no_whitening';
	  end
	end
	marsY = apply_filter(D, marsY, flags);
      end
    end
  end
  p_type = char(spm_input('Type of plot', '+1', 'm', ...
			 'All|Time course|FFT|ACF', ...
			 {'all','raw','fft','acf'}));
end

ns  = region_name(marsY);
rno = mars_struct('getifthere', MARS, 'WORKSPACE', 'default_region');
if ~isempty(rno)
  fprintf('Using default region: %s\n', ns{rno});
end
ui_plot(marsY, struct('types', p_type, 'r_nos', rno));

%=======================================================================
case 'import_data'                                    %- it imports data
%=======================================================================
% marsbar('import_data')
%-----------------------------------------------------------------------

[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Import data', 0);

r_f = spm_input('Import what?', '+1', 'm', ...
		['Sample time courses for one region'...
		 '|Summary time course(s) for region(s)'],...
		[1 0], 2);

Ls = 		['Matlab workspace' ...
		 '|Text file',...
		 '|Lotus spreadsheet'];,...
Os =            {'matlab','txt','wk1'};

if ~isempty(which('xlsread'))
  Ls = [Ls  '|Excel spreadsheet'];
  Os = [Os {'xls'}];
end

src = spm_input('Import fron?', '+1', 'm', Ls, Os, 1);
  
switch src{1}
 case 'matlab'
  Y = spm_input('Matlab expression', '+1', 'e');
  fn = 'Matlab input';
  pn_fn = lower(fn);
 case 'txt'
  [fn, pn] = mars_uifile('get',  ...
      {'*.txt;*.dat;*.csv', 'Text files (*.txt, *.dat, *.csv)'; ...
       '*.*',                   'All Files (*.*)'}, ...
      'Select a text file');
  if isequal(fn,0), return, end
  pn_fn = fullfile(pn, fn);
  Y = spm_load(pn_fn);
 case 'wk1'
  [fn, pn] = mars_uifile('get',  ...
      {'*.wk1', 'Lotus spreadsheet files (*.wk1)'; ...
       '*.*',                   'All Files (*.*)'}, ...
      'Select a Lotus file');
  if isequal(fn,0), return, end
  pn_fn = fullfile(pn, fn);
  Y = wk1read(pn_fn);
 case 'xls'
  [fn, pn] = mars_uifile('get',  ...
      {'*.xls', 'Excel spreadsheet files (*.xls)'; ...
       '*.*',                   'All Files (*.*)'}, ...
      'Select an Excel file');
  if isequal(fn,0), return, end
  pn_fn = fullfile(pn, fn);
  Y = xlsread(pn_fn);
 otherwise
  error('Strange source');
end
if r_f   % region data
  s_f = sf_get_sumfunc(MARS.OPTIONS.statistics.sumfunc);
  r_st = struct('name', fn,...
		'descrip', pn_fn);
  s_st = struct('descrip', ['Region data loaded from ' pn_fn],...
		'sumfunc', s_f);
  marsY = marsy({Y},r_st, s_st);
  pref = '';  % Region name prefix not used, as names are set
else     % summary data  
  s_st = struct('descrip', ['Summary data loaded from ' pn_fn]);
  marsY = marsy(Y, '', s_st);
  pref = spm_input('Prefix for region names', '+1', 's', [fn '_']);
end

% Names
stop_f = 0;
ns = region_name(marsY, [], [], pref);
spm_input('Return name with spaces only to abort entry','+1','d');
for r = 1:length(ns)
  ns{r} = spm_input(...
      sprintf('Name for region %d', r),...
      '+1', 's', ns{r});
  if all(ns{r}==' '), stop_f = 1; break, end
end
if ~stop_f
  marsY = region_name(marsY, [], ns);
end

mars_armoire('set', 'roi_data', marsY);
disp(['Data loaded from ' pn_fn]);

%=======================================================================
case 'export_data'                                            %- exports
%=======================================================================
% marsbar('export_data')
%-----------------------------------------------------------------------
marsY = mars_armoire('get','roi_data');
if isempty(marsY), return, end

[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Export data', 0);

r_f = spm_input('Export what?', '+1', 'm', ...
		['Sample time courses for one region'...
		 '|Summary time course(s) for region(s)'],...
		[1 0], 2);

Ls = 		['Matlab workspace' ...
		 '|Text file',...
		 '|Lotus spreadsheet'];,...
Os =            {'matlab','txt','wk1'};

if ~isempty(which('xlswrite'))
  xls_write = 1;
elseif ~isempty(which('xlswrite5'))
  xls_write = 2;
else
  xls_write = 0;
end

if xls_write
  Ls = [Ls  '|Excel spreadsheet'];
  Os = [Os {'xls'}];
end

src = spm_input('Export to?', '+1', 'm', Ls, Os, 1);

if r_f
  rno = marsbar('get_region', region_name(marsY));
  Y = region_data(marsY, rno);
  Y = Y{1};
else
  Y = summary_data(marsY);
end

switch src{1}
 case 'matlab'
  str = '';
  while ~marsbar('is_valid_varname', str)
    str = spm_input('Matlab variable name', '+1', 's');
    if isempty(str), return, end
  end
  assignin('base', str, Y);
  fn = ['Matlab variable: ' str];
 case 'txt'
  [fn, pn] = mars_uifile('put',  ...
      {'*.txt;*.dat;*.csv', 'Text files (*.txt, *.dat, *.csv)'; ...
       '*.*',                   'All Files (*.*)'}, ...
      'Text file name');
  if isequal(fn,0), return, end
  save(fullfile(pn,fn), 'Y', '-ascii');
 case 'wk1'
  [fn, pn] = mars_uifile('put',  ...
      {'*.wk1', 'Lotus spreadsheet files (*.wk1)'; ...
       '*.*',                   'All Files (*.*)'}, ...
      'Lotus spreadsheet file');
  if isequal(fn,0), return, end
  wk1write(fullfile(pn,fn), Y);
 case 'xls'
  [fn, pn] = mars_uifile('put',  ...
      {'*.xls', 'Excel spreadsheet files (*.wk1)'; ...
       '*.*',                   'All Files (*.*)'}, ...
      'Excel spreadsheet file');
  if isequal(fn,0), return, end
  if xls_write == 1
    xlswrite(fullfile(pn,fn), Y);
  else
    xlswrite5(fullfile(pn,fn), Y);
  end
 otherwise
  error('Strange source');
end
disp(['Data saved to ' fn]);

%=======================================================================
case 'split_data'                %- splits data into one file per region 
%=======================================================================
% marsbar('split_data')
%-----------------------------------------------------------------------
marsY = mars_armoire('get','roi_data');
if isempty(marsY), return, end
if n_regions(marsY) == 1
  disp('Only one region in ROI data');
  return
end

% Setup input window
[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Split regions to files', 0);

d = spm_get([-1 0], '', 'New directory root for files');
if isempty(d), return, end

def_f = summary_descrip(marsY);
if ~isempty(def_f)
  def_f = marsbar('str2fname', def_f);
end
f = spm_input('Root filename for regions', '+1', 's', def_f);
f = marsbar('str2fname', f);
mYarr = split(marsY);
for i = 1:length(mYarr)
  fname = fullfile(d, sprintf('%s_region_%d_mdata.mat', f, i));
  savestruct(mYarr(i), fname);
  fprintf('Saved region %d as %s\n', i, fname);
end

%=======================================================================
case 'join_data'                %- joins many data files into one object 
%=======================================================================
% marsbar('join_data')
%-----------------------------------------------------------------------

P = spm_get([0 Inf], '*_mdata.mat', 'Select data files to join');

if isempty(P), return, end
for i = 1:size(P,1)
  d_o{i} = marsy(deblank(P(i,:)));
end
marsY = join(d_o{:});
mars_armoire('set', 'roi_data', marsY);
disp(P)
disp('Files merged and set as current data')

%=======================================================================
case 'estimate'                                       %-Estimates design
%=======================================================================
% marsbar('estimate')
%-----------------------------------------------------------------------
marsD = mars_armoire('get', 'def_design');
if isempty(marsD), return, end
marsY = mars_armoire('get', 'roi_data');
if isempty(marsY), return, end
if ~can_mars_estimate(marsD)
  marsD = fill(marsD, 'for_estimation');
  mars_armoire('update', 'def_design', marsD);
end
marsRes = estimate(marsD, marsY,{'redo_covar','redo_whitening'});
mars_armoire('set', 'est_design', marsRes);

%=======================================================================
case 'set_results'          %-sets estimated design into global stucture
%=======================================================================
% donef = marsbar('set_results')
%-----------------------------------------------------------------------
varargout = {0};
marsRes = mars_armoire('set_ui', 'est_design');
if isempty(marsRes), return, end
fprintf('%-40s: ','Design reporting');
ui_report(marsRes, 'DesMtx');
ui_report(marsRes, 'DesRepUI');
fprintf('%30s\n','...done');
varargout = {1};
return

%=======================================================================
case 'plot_residuals'                  %-plots residuals from estimation
%=======================================================================
% marsbar('plot_residuals')
%-----------------------------------------------------------------------
marsRes = mars_armoire('get', 'est_design');
if isempty(marsRes), return, end
Y = residuals(marsRes);
ns  = region_name(Y);
rno = mars_struct('getifthere', MARS, 'WORKSPACE', 'default_region');
if ~isempty(rno)
  fprintf('Using default region: %s\n', ns{rno});
end
[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Plot residuals', 1);
p_type = char(spm_input('Type of plot', '+1', 'm', ...
			'All|Time course|FFT|ACF', ...
			{'all','raw','fft','acf'}));
ui_plot(Y, struct('types', p_type, 'r_nos', rno));

%=======================================================================
case 'set_defcon'                                 %-set default contrast
%=======================================================================
% Ic = marsbar('set_defcon')
%-----------------------------------------------------------------------
varargout = {[]};
marsRes = mars_armoire('get', 'est_design');
if isempty(marsRes), return, end

% Setup input window
[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Default contrast', 0);
Ic = mars_struct('getifthere',MARS, 'WORKSPACE', 'default_contrast');
if isempty(Ic)
  cname = '[Not set]';
else 
  xCon = get_contrasts(marsRes);
  cname = xCon(Ic).name; 
end
spm_input(cname, 1, 'd', 'Default contrast');
opts = {'Quit', 'Set new default'};
if ~isempty(Ic), opts = [opts {'Clear default contrast'}]; end
switch spm_input('What to do?', '+1', 'm', opts, [1:length(opts)], 1);
 case 1
 case 2
  [Ic marsRes changef] = ui_get_contrasts(marsRes, 'T|F',1,...
			 'Select default contrast','',1);
  if changef, mars_armoire('update', 'est_design', marsRes); end
 case 3
  Ic = [];
end
MARS.WORKSPACE.default_contrast = Ic;
varargout = {Ic};

%=======================================================================
case 'set_defregion'                                %-set default region
%=======================================================================
% rno = marsbar('set_defregion')
%-----------------------------------------------------------------------
varargout = {[]};
marsY = mars_armoire('get', 'roi_data');
if isempty(marsY), return, end
ns = region_name(marsY);
if length(ns) == 1
  disp('Only one region in data');
  MARS.WORKSPACE.default_region = 1;
  varargout = {1};
  return
end

% Setup input window
[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Default region', 0);
rno = mars_struct('getifthere',MARS, 'WORKSPACE', 'default_region');
if isempty(rno), rname = '[Not set]'; else rname = ns{rno}; end
spm_input(rname, 1, 'd', 'Default region:');
opts = {'Quit', 'Set new default'};
if ~isempty(rno), opts = [opts {'Clear default region'}]; end
switch spm_input('What to do?', '+1', 'm', opts, [1:length(opts)], 1);
 case 1
 case 2
  rno = marsbar('get_region', ns);
  disp(['Default region set to: ' ns{rno}]); 
 case 3
  rno = [];
end
MARS.WORKSPACE.default_region = rno;
varargout = {rno};

%=======================================================================
case 'get_region'                                  %-ui to select region
%=======================================================================
% select region from list box / input
% rno = marsbar('get_region', names, prompt)
% names is cell array of strings identifying regions
% prompt is prompt string
%-----------------------------------------------------------------------

if nargin < 2
  error('Need region names to select from');
else
  names = varargin{2};
end
if nargin < 3
  prompt = 'Select region';
else
  prompt = varargin{3};
end

% maximum no of items in list box
maxlist = 200;
if length(names) > maxlist
  % text input, maybe
  error('Too many regions');
end
if length(names) == 1
  rno = 1;
elseif isempty(names)
  rno = []
else
  % listbox
  rno = spm_input(prompt, '+1', 'm', names);  
end
varargout = {rno};

%=======================================================================
case 'spm_graph'                                         %-run spm_graph
%=======================================================================
% marsbar('spm_graph')
%-----------------------------------------------------------------------
marsRes = mars_armoire('get', 'est_design');
if isempty(marsRes), return, end

% Setup input window
[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Mars SPM graph', 1);

ns  = region_name(get_data(marsRes));
rno = mars_struct('getifthere', MARS, 'WORKSPACE', 'default_region');
if ~isempty(rno)
  fprintf('Using default region: %s\n', ns{rno});
else
  rno = marsbar('get_region', ns, 'Select region to plot');
end

Ic = mars_struct('getifthere', MARS, 'WORKSPACE', 'default_contrast');
if ~isempty(Ic)
  xCon = get_contrasts(marsRes);
  fprintf('Using default contrast: %s\n', xCon(Ic).name);
end

% Variables returned in field names to allow differences
% in return variables between versions of spm_graph
[r_st marsRes changef] = mars_spm_graph(marsRes, rno, Ic);

% Dump field names to global workspace as variables
fns = fieldnames(r_st);
for f = 1:length(fns)
  assignin('base', fns{f}, getfield(r_st, fns{f}));
end

% Store if changed
if changef, mars_armoire('update', 'est_design', marsRes); end

%=======================================================================
case 'stat_table'                                       %-run stat_table
%=======================================================================
% marsbar('stat_table')
%-----------------------------------------------------------------------
marsRes = mars_armoire('get', 'est_design');
if isempty(marsRes), return, end
Ic = mars_struct('getifthere', MARS, 'WORKSPACE', 'default_contrast');
if ~isempty(Ic)
  xCon = get_contrasts(marsRes);
  fprintf('Using default contrast: %s\n', xCon(Ic).name);
end
[strs marsS marsRes changef] = ... 
    stat_table(marsRes, Ic);
disp(char(strs));
assignin('base', 'marsS', marsS);
if changef, mars_armoire('update', 'est_design', marsRes); end

%=======================================================================
case 'signal_change'                             % percent signal change
%=======================================================================
% marsbar('signal_change')
%-----------------------------------------------------------------------
marsRes = mars_armoire('get', 'est_design');
if isempty(marsRes), return, end
if ~is_fmri(marsRes)
  fprintf('Need FMRI design for %% signal change\n');
  return
end

% Setup input window
[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Percent signal change', 0);

dur       = spm_input('Event duration', '+1', 'e', 0);
[e_s e_n] = ui_get_event(marsRes);
pc        = event_signal(marsRes, e_s, dur, 'max');
rns       = region_name(get_data(marsRes));
disp('Sort-of % signal change');
disp(['Event: ' e_n]);
disp(sprintf('Duration: %3.2f seconds', dur));
for r = 1:length(rns)
  disp(sprintf('Region: %40s; %5.3f', rns{r}, pc(r)));
end
assignin('base', 'pc', pc);

%=======================================================================
case 'merge_contrasts'                                %-import contrasts
%=======================================================================
% marsbar('merge_contrasts')
%-----------------------------------------------------------------------
D = mars_armoire('get', 'est_design');
if isempty(D), return, end
filter_spec = {...
    'SPM.mat','SPM: SPM.mat';...
    '*_mres.mat','MarsBaR: *_mres.mat';...
    '*x?on.mat','xCon.mat file'};
[fn pn] = mars_uifile('get', ...
    filter_spec, ...
    'Source design/contrast file...');
if isequal(fn,0) | isequal(pn,0), return, end
fname = fullfile(pn, fn);
D2 = mardo(fname);

% has this got contrasts?
if ~has_contrasts(D2)
  error(['Cannot find contrasts in design/contrast file ' fname]);
end
  
% now try to trap case of contrast only file
if ~is_valid(D2)
  D2 = get_contrasts(D2);
end

[D Ic changef] = add_contrasts(D, D2, 'ui');
if changef
  mars_armoire('update', 'est_design', D);
end

%=======================================================================
case 'add_trial_f'            %-add trial-specific F contrasts to design
%=======================================================================
% marsbar('add_trial_f')
%-----------------------------------------------------------------------
D = mars_armoire('get', 'est_design');
if isempty(D), return, end
if ~is_fmri(D)
  disp('Can only add trial specific F contrasts for FMRI designs');
  return
end
[D changef] = add_trial_f(D);
disp('Done');
if changef
  mars_armoire('update', 'est_design', D);
end

%=======================================================================
case 'str2fname'                                   %-string to file name
%=======================================================================
% fname = marsbar('str2fname', str)
%-----------------------------------------------------------------------
% accepts string, attempts return of string for valid filename
% The passed string should be without path or extension
if nargin < 2
  error('Need to specify string');
end
str = varargin{2};
% forbidden chars in file name
badchars = unique([filesep '/\ :;.''"~*?<>|&']);

tmp = find(ismember(str, badchars));   
if ~isempty(tmp)
  str(tmp) = '_';
  dt = diff(tmp);
  if ~isempty(dt)
    str(tmp(dt==1))=[];
  end
end
varargout={str};
 
%=======================================================================
case 'is_valid_varname'        %- tests if string is valid variable name
%=======================================================================
% tf = marsbar('is_valid_varname', str)
%-----------------------------------------------------------------------
% accepts string, tests if it is a valid variable name
if nargin < 2
  error('Need to specify string');
end
str = varargin{2};
try 
  eval([str '= [];']);
  varargout={1};
catch
  varargout = {0};
end
 
%=======================================================================
case 'error_log'                  %- makes file to help debugging errors
%=======================================================================
% fname = marsbar('error_log', fname);
%-----------------------------------------------------------------------
if nargin < 2
  fname = 'error_log.mat';
else
  fname = varargin{2};
end

e_log = struct('last_error', lasterr, ...
	       'marmoire', mars_armoire('dump'), ...
	       'm_ver', marsbar('ver'),...
	       'mars', MARS);
savestruct(fname, e_log);
if ~isempty(which('zip'))
  zip([fname '.zip'], fname);
  fname = [fname '.zip'];
end
disp(['Saved error log as ' fname]);

%=======================================================================
case 'get_img_name'          %-gets name of image, checks for overwrite
%=======================================================================
% P = marsbar('get_img_name', fname, flags);
%-----------------------------------------------------------------------
if nargin < 2
  fname = '';
else
  fname = varargin{2};
end
if nargin < 3
  flags = '';
else 
  flags = varargin{3};
end
if isempty(flags)
  flags = 'k';
end

varargout = {''};
fdir = spm_get(-1, '', 'Directory to save image');
fname = spm_input('Image filename', '+1', 's', fname);
if isempty(fname), return, end

% set img extension and make absolute path
[pn fn ext] = fileparts(fname);
fname = fullfile(fdir, [fn '.img']);
fname = spm_get('cpath', fname);

if any(flags == 'k') & exist(fname, 'file')
  if ~spm_input(['Overwrite ' fn], '+1', ...
		'b','Yes|No',[1 0], 1)
    return
  end
end
varargout = {fname};

%=======================================================================
case 'mars_menu'                    %-menu selection of marsbar actions 
%=======================================================================
% marsbar('mars_menu',tstr,pstr,tasks_str,tasks)
%-----------------------------------------------------------------------

[tstr pstr optfields optlabs] = deal(varargin{2:5}); 
if nargin < 6
  optargs = cell(1, length(optfields));
else
  optargs = varargin{6};
end

[Finter,Fgraph,CmdLine] = spm('FnUIsetup',tstr);
of_end = length(optfields)+1;
my_task = spm_input(pstr, '+1', 'm',...
	      {optlabs{:} 'Quit'},...
	      [1:of_end],of_end);
if my_task == of_end, return, end
marsbar(optfields{my_task}{:});

%=======================================================================
otherwise                                        %-Unknown action string
%=======================================================================
error('Unknown action string')

%=======================================================================
end
return

% subfunctions
function sum_func = sf_get_sumfunc(sum_func)
if strcmp(sum_func, 'ask')
  sum_func = char(spm_input('Summary function', '+1','m',...
			   'Mean|Weighted mean|Median|1st eigenvector',...
			   {'mean','wtmean','median','eigen1'}, 1));
end
return

