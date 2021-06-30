#!/bin/bash

# ------------------------------------------------------------------------------
# There are some info about dumpling used mysqldump.
# ------------------------------------------------------------------------------
DUMP_USER='root'
# The passwd should use single quotation symbol ！
DUMP_PASSWORD='mG!2tyS@0cC*aXt' 
DUMP_HOST='9.1.192.66'
DUMP_PORT='8066'
DUMP_DATABASE='TESTDB'
# The Path of "DUMP_RESULT_FOLDER" will be used to contain table value.
DUMP_RESULT_FOLDER='/data/tidb_dump/DM-for-mycat/mycat_test_dump'
DUMP_TABLE_PATH='./DUMP_TABLES.prm'
DUMP_VAR_WHERE=""
#DUMP_VAR_WHERE="where orgcd in ('11000000','12000000')"
#DUMP_VAR_WHERE="where orgcd in ('11000000','12000000')"
#DUMP_VAR_WHERE="where orgcd in ('11000000','12000000')"

# ------------------------------------------------------------------------------
# There are some info about loading used symbol of "<".
# ------------------------------------------------------------------------------
LOAD_USER='root'
# the passwd should use single quotation symbol ！
LOAD_PASSWORD='' 
LOAD_HOST='9.1.179.15'
LOAD_PORT='8000'
LOAD_DATABASE='uastest_dev'



# ------------------------------------------------------------------------------
# Start to dump table values using 'mysqldump" tool !
# ------------------------------------------------------------------------------
mkdir ${DUMP_RESULT_FOLDER}
# ------------------------------------------------------------------------------
# Justify the where name
# ------------------------------------------------------------------------------
if [ "${DUMP_VAR_WHERE}" = "" ] ;then
	${DUMP_VAR_WHERE} = "1=1"
fi


for TABLE in `cat ${DUMP_TABLE_PATH}`
do :
echo "-----------------^-------------------------------^------------------"
mkdir ${DUMP_RESULT_FOLDER}/${TABLE}
echo "start to dump table  from database : ${DATABASE} "
echo " --:-- dump table ${TABLE} start is --:--" $(date +"%Y-%m-%d %H:%M:%S")
mysqldump   --host=${DUMP_HOST} \
            --user=${DUMP_USER} \
            --password=${DUMP_PASSWORD} \
            --port=${DUMP_PORT} \
            --where=${DUMP_VAR_WHERE} \
            --skip-extended-insert \
            --complete-insert --skip-add-locks -t -n ${DUMP_DATABASE} ${TABLE} > ${DUMP_RESULT_FOLDER}/${TABLE}/dm_dump_${TABLE}.sql
echo " --:-- dump table ${TABLE} end is --:--" $(date +"%Y-%m-%d %H:%M:%S")
echo "-----------------^-------------------------------^------------------"
done

# ------------------------------------------------------------------------------
# Divid one file ,contain numerous query of "INSERT",into some sub_file !
# ------------------------------------------------------------------------------

for TABLE in `cat ${DUMP_TABLE_PATH}`
do :
echo "-----------------^-------------------------------^------------------"
sudo split -l 100000 ${DUMP_RESULT_FOLDER}/${TABLE}/dm_dump_${TABLE}.sql ${DUMP_RESULT_FOLDER}/${TABLE}/result.sql.
sudo rm -rf ${DUMP_RESULT_FOLDER}/${TABLE}/dm_dump_${TABLE}.sql
echo "-----------------^-------------------------------^------------------"
done


# ------------------------------------------------------------------------------
# There are some info about parallel loading query of "INSERT" file,which has 
# been devided into lots of files ! 
# ------------------------------------------------------------------------------

for TABLE in `cat ${DUMP_TABLE_PATH}`
do :

echo "-----------------^-------------------------------^------------------"
echo " --:-- import table ${TABLE} start is --:--" $(date +"%Y-%m-%d %H:%M:%S")
echo "start to import table from database  ${DATABASE}.${TABLE} "

    for SPLITED_DUMP_FILE in ${DUMP_RESULT_FOLDER}/${TABLE}/*;do
    {
        mysql   --host=${LOAD_HOST} \
                --user=${LOAD_USER} \
                --password=${LOAD_PASSWORD} \
                --port=${LOAD_PORT} \
                --database=${LOAD_DATABASE}  < ${SPLITED_DUMP_FILE}
    }&
    done
    wait

echo " --:-- import table ${TABLE} end is --:--" $(date +"%Y-%m-%d %H:%M:%S")
echo "it's finished."
echo "-----------------^-------------------------------^------------------"
done
