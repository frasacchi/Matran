fprintf('Computing sol144')    
nastran_exe = 'C:\MSC.Software\MSC_Nastran\20181\bin\nastran.exe';

dat_file = fullfile(pwd,'data','A320_half_model_SOL144.dat');
command = [nastran_exe,' ',dat_file,];%' 1>NUL 2>NUL'];
system(command);