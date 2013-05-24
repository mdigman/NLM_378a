function run_condor(run_script)
  manycores = parallel.importProfile('matlab/manycores.settings');
  matlabpool open manycores 12;
  
  run_script();
  
  matlabpool close manycores;
end
