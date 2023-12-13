# Zefir-spatial

## General info
Build, import data and maintain geospatial database in Zefir

## Development

### Install GDAL library

To make the project work, you need to have in your PATH `ogr2ogr` binary that is delivered within [GDAL library](https://gdal.org/). Installation can be made by at least three ways:

#### 1) Install from OS repository :
Resources:  
https://riptutorial.com/gdal/example/25193/installation-on-linux  
or (Ubuntu)
https://mothergeo-py.readthedocs.io/en/latest/development/how-to/gdal-ubuntu-pkg.html


#### 2) Install using conda:

[Conda](https://docs.conda.io/projects/conda/en/latest/index.html) is an open-source package management system and environment management system that runs on Windows, macOS, and Linux. Conda quickly installs, runs, and updates packages and their dependencies. GDAL is quite easy to install through this manager in the isolated environment. 

```
conda create --name gdal
conda activate gdal
conda install -c conda-forge gdal
```

Then you can deactivate the environment and add ogr2ogr to the $PATH

Ref: https://opensourceoptions.com/blog/how-to-install-gdal-with-anaconda/

Important info!
Remember to activate conda before activating pipenv shell (order matters!). If you do it in opposite way, then you may use python installed in conda instead python connected with your virtual env
```
conda activate gdal && pipenv shell
```
#### 3) Use docker container

You can use docker container to run GDAL binaries. 
You can create shell script in `bin` directory `bin/ogr2ogr` on your host:
```
#!/bin/bash
docker run --rm --name gdal -v ${TMP_DIR}:${TMP_DIR} -w / osgeo/gdal ogr2ogr "$@"
```
This script runs container using `osgeo/gdal` image and remove itself just after execution. It is assumed that files to process are placed in `TMP_DIR`.

Next, add `bin` to the PATH `export PATH=$PATH:~/zefir_spatial/bin`  
And point by `TMP_DIR` varaible,  directory where temporary files are placed (and where you have write/read/execute rights) 

#### Verify GDAL installation

Just call `ogr2ogr --help` 

### Install python dependencies using pipenv

Call `pipenv install`

Create `.env` file 
```
copy example.env .env
```
(you can add to `.env`  variable `TMP_DIR` if you need)

Activate shell with project context:

```
pipenv shell
```
### Setup a local database
Go to project folder
```
cd zefir-spatial
```
copy `example.env` to `.env`
```
cp example.env .env
```
Setup local database (using docker container)
```
docker-compose up -d
alembic upgrade head
```

Initialize a new database:
```
python -m db.initialize
```
## Usage
In `scripts` there are examples how to run imports for:
- EGIB 
- BDOT10k
- administrative boundaries
- address points
- KIUT layers

Just call it:
```
python scripts/run_egib.py
python scripts/run_bdot.py
python scripts/run_import_boundaries.py
python scripts/run_address.py
python scripts/run_maps.py
```

## Q&A
---
> (psycopg2.errors.UndefinedObject) type "geometry" does not exist"

The library requires Postgis extension to PostgreSQL ([ref](https://postgis.net/install/#binary-installers)). Call on yor local database SQL command:
```SQL
CREATE EXTENSION postgis;
```
---
> pydantic.error_wrappers.ValidationError: 3 validation errors for Settings

call `pipenv shell`