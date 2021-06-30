#!/bin/bash

# ------------------------------------------------------------------------------
# There are some info about dumpling used mysqldump.
# ------------------------------------------------------------------------------
DUMP_USER='root'
# The passwd should use single quotation symbol ！
#DUMP_PASSWORD='mG!2tyS@0cC*aXt' 
DUMP_PASSWORD='gsctidbtest2020' 
DUMP_HOST='9.1.179.15'
DUMP_PORT='4000'
DUMP_DATABASE='uastest_dev'
# The Path of "DUMP_RESULT_FOLDER" will be used to contain table value.
DUMP_TABLE_PATH='./DUMP_TABLES_CHECK.prm'



# ------------------------------------------------------------------------------
# Start to dump table values using 'mysqldump" tool !
# ------------------------------------------------------------------------------

for TABLE in `cat ${DUMP_TABLE_PATH}`
do :
echo "-----------------^-------------------------------^------------------"
mysql   --host=${DUMP_HOST} \
            --user=${DUMP_USER} \
            --password=${DUMP_PASSWORD} \
            --port=${DUMP_PORT} \
            -D  ${DUMP_DATABASE} -e "select count(*)  from ${TABLE}" >> ./check_target.log
echo " --:-- dump table ${TABLE} end is --:--" $(date +"%Y-%m-%d %H:%M:%S")
echo "-----------------^-------------------------------^------------------"
done
