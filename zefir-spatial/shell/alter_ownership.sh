#!/bin/bash

usage()
{
cat << EOF
usage: $0 options
This script set ownership for all table, sequence and views for a given database
Credit: Based on http://stackoverflow.com/a/2686185/305019 by Alex Soto
        Also merged changes from @sharoonthomas
OPTIONS:
   -h      Show this message
   -d      Database name
   -s      Schema
   -o      Owner
EOF
}

DB_NAME=
SCHEMA=
NEW_OWNER=

while getopts "hd:s:o:" OPTION 
do
    case $OPTION in
        h)  
            usage
            exit 1
            ;;  
        d)  
            DB_NAME=$OPTARG
            ;; 
        s)
            SCHEMA=$OPTARG
            ;;
        o)  
            NEW_OWNER=$OPTARG
            ;;

    esac
done

echo "Database: ${DB_NAME}"
echo "Schema: ${SCHEMA}"
echo "User: ${NEW_OWNER}"

if [[ -z $DB_NAME ]] || [[ -z $SCHEMA ]] || [[ -z $NEW_OWNER ]]  
then
     usage
     exit 1
fi

for tbl in `psql -qAt -c "select tablename from pg_tables where schemaname = '${SCHEMA}';" ${DB_NAME}` \
           `psql -qAt -c "select sequence_name from information_schema.sequences where sequence_schema = '${SCHEMA}';" ${DB_NAME}` \
           `psql -qAt -c "select table_name from information_schema.views where table_schema = '${SCHEMA}';" ${DB_NAME}` ;
do  
    psql -c "alter table ${SCHEMA}.\"$tbl\" owner to ${NEW_OWNER}" ${DB_NAME} ;
    # echo "alter table ${SCHEMA}.\"$tbl\" owner to ${NEW_OWNER}" ${DB_NAME} ;
done