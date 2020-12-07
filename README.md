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
1. Put your library somewhere public in git.
2. Edit [repos.json](https://github.com/OpenModelica/OMLibraries/blob/master/repos.json) and add the URL to your library with the gittag or hash and branch name.

    **Example for a public GitHub repository using a git tag:**
    ```json
    [...]
    {
        "core": true,                               // Is your library a core library (true) or another library (false)
        "dest": "LibraryName",                      // The name of your library
        "options": {
            "gitbranch": "master",                  // Git branch (optional)
            "gittag": "v1.0.0",                     // Git tag pointing to commit to be used
            "license": "bsd3"                       // Under what license is your library published (optional)
        },
        "rev": "v1.0.0",                            // Version of your library you tagged
        "url": "https://github.com/UserName/LibraryName/.git"        // URL of your GitHub repository
    },
    [...]
    ```

    **Example for a public GitHub repository using a branch and commit hash:**
    ```json
    [...]
    {
        "core": true,                               // Is your library a core library (true) or another library (false)
        "dest": "LibraryName",                      // The name of your library
        "options": {
            "gitbranch": "v1.0.0-maintenance",      // Git branch
            "license": "bsd3"                       // Under what license is your library published (optional)
        },
        "rev": "802e7d85e35e14asdg53dsg1sdd6911804382f29",           // Version of your library you tagged
        "url": "https://github.com/UserName/LibraryName/.git"        // URL of your GitHub repository
    },
    [...]
    ```
    Note that JSON doesn't allow comments, so delete all comments from the above examples.
3. Create a pull request with your changes.
4. One of the developers will then run the Hudson Job: OpenModelica_UPDATE_LIBRARIES to update the Makefiles