#!/bin/bash
# Copyright (c) 2010, Brian Case
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

dsname="LANDSAT_TM_USGS"
#baseurl="http://edcftp.cr.usgs.gov/pub/data/disaster/201004_Oilspill_GulfOfMexico/data/LANDSAT_TM_USGS/"
baseurl="http://edcftp.cr.usgs.gov/pub/data/disaster/201008_Hurricane_Earl/data/LANDSAT_TM_USGS/"
basedir="/storage/data/deephorizon/"
indir="${basedir}/source/${dsname}/"
outdir="${basedir}/done/${dsname}/"
mapfile="${basedir}/deephorizon.map"

tmp=/mnt/ram2/

mapserverpath="/usr/local/src/mapserver/mapserver"

##### setup proccess management #####

((limit=1))

source dwh-generic.bash

dofunc="LANDSAT_TM_USGS_dofile"

dateregex='s:.*/LS[0-9]\{8\}\([0-9]\{8\}\).*:\1:'

doovr="no"

#################################################################################################
# function to proccess a file
#################################################################################################

function LANDSAT_TM_USGS_dofile {
    
    myline=$1
    zipfile="${myline##*/}"

    tifs="${zipfile%_*}"

    ts="${zipfile:10:8}"

    if echo "$myline" | grep -e "^get" > /dev/null
    then

        tmpdir=$(mktemp -d -p "$tmp" "${dsname}XXXXXXXXXX")
        
        lftp -e "$(echo "$myline" | sed "s:get -O [/_.A-Za-z0-9]*:get -O ${tmpdir}:") ; exit"
        
	    if ! [ -d "$outdir/${ts}" ]
        then
            mkdir -p "$outdir/${ts}"
        fi

	    unzip "${tmpdir}/${zipfile}" "${tifs}_B0[123].TIF" -d "$tmpdir"

        gdalbuildvrt -srcnodata 0 -separate "${tmpdir}/${tifs}.vrt" "${tmpdir}/${tifs}_B03.TIF" "${tmpdir}/${tifs}_B02.TIF" "${tmpdir}/${tifs}_B01.TIF"
        
        gdalwarp -t_srs EPSG:4326 "${tmpdir}/${tifs}.vrt" "${tmpdir}/${tifs}.tif"

        gdaladdo -r average "${tmpdir}/${tifs}.tif" 2 4 8 16 32
      
        mv "${tmpdir}/${tifs}.tif" "$outdir/${ts}/${tifs}.tif"
	    mv "${tmpdir}/${zipfile}" "$indir"
	    
	    rm -rf "${tmpdir}/"

        gdaltindex "${outdir}/${dsname}${ts}.shp" "$outdir/${ts}/${tifs}.tif"

    fi
    echo >&3
}

main


