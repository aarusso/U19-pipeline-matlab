
# Overview
This is a data pipeline, constructed in datajoint, used across Princeton's U19.
It specifies a number of tables and their relational structure to organizes all metadata to
* mouse mangament,
* training management,
* microscope management,
* und recording

in one coherent framework.

# Connection to database (for MATLAB >= 2016b)
1. Install datajoint for matlab 
      
      a) Utilize MATLAB built-in GUI i.e. Top Ribbon -> Add-Ons -> Get Add-Ons
      
      b) Search and Select DataJoint
      
      c) Select Add from GitHub
      
2. Clone this repository.
3. Add this repository to your Matlab Path.         
4. ``` setenv('DB_PREFIX', 'u19_') ```
5. ``` dj.conn('datajoint00.pni.princeton.edu') (Enter username and password) ```

# Go through Tutorial
Follow the steps to go through the tutorial:
1. Fork the repository to your own GitHub account
2. Clone from your own GitHub repository. 
3. Get into the directory of the current tutorial `tutorials/202001/`
4. Run `startup.m`
5. Put in the username and password when they prompt
6. Run live scripts session01 and session02

# Backend
The backend is a SQL server [MariaDB].

# Integration into rigs.
The rigs talk to the database directly [SSL, wired connection].

