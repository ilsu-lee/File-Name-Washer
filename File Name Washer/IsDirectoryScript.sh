#!/bin/sh

#  IsDirectoryScript.sh
#  File Name Washer
#
#  Copyright (C) 2023 ILSU LEE

#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or 3 any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 
 
if [ -d "$1" ]; then
  ### Take action if $DIR exists ###
  echo "Found directory : $1"
  exit 0
else
  ###  Control will jump here if $DIR does NOT exists ###
  echo "Error: $1 not found. Can not continue."
  exit 1
fi
