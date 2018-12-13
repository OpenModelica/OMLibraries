# OMLibraries

A collection of Modelica libraries for use with OpenModelica.
The libraries are tested to parse correctly and are then updated in the database.

## Dependencies
```bash
sudo apt-get install git subversion devscripts
sudo apt-get install python-requests python-simplejson python-parallel python-joblib
sudo apt-get install libxml-xpath-perl
sudo apt-get install omc
```

### Add a new library
1. Put your library somewere public in git (or svn).
2. Edit repos.json and add the URL to your library and the commit hash (revision number for svn).
3. Commit your change.
4. Make sure you run the Hudson Job: OpenModelica_UPDATE_LIBRARIES to update the Makefiles

