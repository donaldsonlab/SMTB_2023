% Script to compile and concatenate behavioral video clips from within a
% recording and/or across multiple recordings on same day (i.e., multiple
% videos within a single trial and multiple trials within a single session)
% 
% Also will convert behavioral video into new playback speed if needed -
% this part is a slight modification to a script from Samara Miller (UCLA).
% This is to roughly approximate the minicam and miniscope alignment as a
% first pass without matching up the timestamps (an early attempt to import
% into Bento without understanding the timestamp funcdztionality). These
% lines are commented out for now. If you need to do this, uncomment those
% lines.
%
% 220720 note: minicams seem to always be recorded at 50 FPS for WMS recordings -> playback
% speed = 60 FPS in .avi video
%
% miniscope is recorded at 30 FPS -> playback speed = 60 FPS
%
% Note: this script assumes your behavioral videos directory is organized
% in the following format:
% ...animal/session_date/trials_times/devices/videos. This organization can
% be set up in the miniscope software userConfig files
%
%
% MEK Edits
% -natsort permanently added to path https://www.mathworks.com/matlabcentral/fileexchange/47434-natural-order-filename-sort?s_tid=mwa_osa_a
% -minicam1or2 variable 
% -video is compiled based on a single subfolder (e.g. 13_56_20, not 2022_12_15)
% -inputVideo frameRate metadata is incorrectly 60fps even when recorded at 50fps. hardcoded as inputVideoFrameRate
% -each frame is resized to 480x720 for compatibility with cleversys
% -fileNames in original folder are only renamed when moved into '_compiled' folder

%% 
clc;clear;

minicam1or2 = 1;
inputVideoFrameRate = 50;
moveFiles = 1;


% %choose date folder (e.g., "2022_07_09") containing all trials from a single session/animal to
% %be concatenated and set as current directory
 cd(uigetdir);
 folder = cd;

% 
% %identify each time (=trial) folder
% trials = dir; %ID trial folders (=times)
% trials = trials(~ismember({trials.name},{'.','..'})); %get rid of '.' and '..' in list
% datefrmts = regexp({trials.name},'\d\d.\d\d.\d\d');
% datefrmts_indx = ~cellfun(@isempty,datefrmts)
% trials = trials(datefrmts_indx);
% 
% 
% %reorganize folders by temporal order (first->last, likely already the case)
% A = datetime({trials.name}, 'InputFormat', 'HH_mm_ss', 'Format', 'preserveinput');
% [B,I] = sort(A); %B=sorted times, I=corresponding indices in A
% 
% formatOut = 'HH_MM_SS';
% for l = 1:length(B)
%     ordered_trials {l} = datestr(B(l),formatOut);
% end

%create new subfolder under date folder to compile all minicam trial
%videos into
mkdir(sprintf('minicam%d_compiled',minicam1or2))
%mkdir minicam2_compiled


if moveFiles==1
%loop to 1) identify each subdirectory containing the desired minicam videos for that trial, 
% 2) rename each video file in that subdirectory according to order of
% trial to be concatenated in correct order
%for j = 1:length(ordered_trials)
%    a = ordered_trials{j};
%    date = cd(a);
j = 1; % due to starting in time folder
    %get into the folder w the minicam videos
    trial = cd(sprintf('MiniCam%d',minicam1or2)); %trial = cd('MiniCam2');
    %compile folder's video files into a list 
    files = dir('*.avi');
    for k = 1:length(files)
        LIST {k} = files(k).name;
        indx(k) = k;
    end

    %rename each file
    for I = 1:length(indx)
    id = indx(I); 
    
    %determine what new file name will be and rewrite
    prefix = num2str(j-1); %first digit corresponds to loop iteration

    [~, f,ext] = fileparts(files(id).name);
    rename = strcat(prefix,'_',f,ext) ; %define new file name
    copyfile(files(I).name,fullfile(folder, sprintf('minicam%d_compiled',minicam1or2),rename))
    %movefile(files(id).name, rename); %overwrite existing file name
    end
    
    %save copies of all the newly named videos in the new miniscope_compiled folder
    %copyfile *.avi ../../minicam1_compiled
    
    %copyfile *.avi ../minicam1_compiled
    
    %copyfile *.avi ../../minicam2_compiled

    %re-set directory back to the date folder for next loop iteration
    cd(folder);
end

%end


%% section for loading timestamp files, lookig for big gaps/frame drops,
% alerting user if so, and also copying that timestamp file into the new
% compiled output video folder


%%
%change directory to the folder containing newly compiled minicam files
cd(sprintf('minicam%d_compiled',minicam1or2)); %cd('minicam2_compiled')

%create list of all file names
myFiles = dir('*.avi'); %gets all avi files in struct
for j = 1:length(myFiles) %place avi file names into list
        file_list{j} = myFiles(j).name;
        indx(j) = j;
end

%reorder file names so they are concatenated in correct order
sortedFiles = natsortfiles(file_list);


%% Optional section if want to change playback speed to 100 FPS
% %make directory to compile sped-up copies of clips
%mkdir('100FPS'); 

% %make copies of all video clips at a new playback speed of 100 FPS
%for k = 1:length(sortedFiles)
%    baseFileName = sortedFiles(k);
%    fullFileName = fullfile(cd, baseFileName); %change folder to minicam1_compiled, i think
%    obj = VideoReader(fullFileName{1}); 
%    newFileName = fullfile(cd, '\100FPS\', baseFileName); 
%    obj2= VideoWriter(newFileName{1}); % Write in new variable 
%    obj2.FrameRate = 100; %speed up playback of new video copy to 100FPS
%    % % for reading frames one by one
%    open(obj2)
%    while hasFrame(obj)              
%     k = readFrame(obj); 
%   
%     % write the frames in obj2.         
%     obj2.writeVideo(k);          
%    end
%    close(obj2)

%end
%% CONCATENATE VIDEOS
videoList = cell(1,length(sortedFiles)); 

for f = 1:length(sortedFiles)
    videoList{1,f} = fullfile(cd, sortedFiles(f));
end

%if converting playback speed to 100FPS, instead run:
%for f = 1:length(sortedFiles)
%    videoList{f} = fullfile(cd, '\100FPS\' , sortedFiles(f));
%end

% create output in seperate folder (to avoid accidentally using it as input)
mkdir('output');
outputVideo = VideoWriter(fullfile(cd,sprintf('output/mergedVideo_minicam%d.avi',minicam1or2)));

% if all clips are from the same source/have the same specifications
% just initialize with the settings of the first video in videoList
%keyboard
inputVideo_init = VideoReader(videoList{1,1}{1}); % first video
outputVideo.FrameRate = inputVideoFrameRate; %FrameRate = 100 if speeding up, will stay at 60 FPS playback speed if not
inputVideoRows = inputVideo_init.Height;
inputVideoColumns = inputVideo_init.Width;

outputVideoRows = 480;
outputVideoColumns = 720;


%keyboard

open(outputVideo) % >> open stream
% iterate over all videos you want to merge (e.g. in videoList)
for i = 1:length(videoList)
    % select i-th clip (assumes they are in order in this list!)
    inputVideo = VideoReader(videoList{i}{1});
   % inputVideo.NumFrames = 1000;
    % -- stream your inputVideo into an outputVideo
    while hasFrame(inputVideo)
        thisInputFrame = readFrame(inputVideo);
        outputFrame = imresize(thisInputFrame, [outputVideoRows, outputVideoColumns]);
        %writeVideo(outputVideo, readFrame(inputVideo));
        writeVideo(outputVideo, outputFrame);
        %writeVideo(outputVideo, thisInputFrame);
    end
    disp(i)
end
close(outputVideo) % << close after having iterated through all videos