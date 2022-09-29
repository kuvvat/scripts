#!/bin/bash

function now() {
        date +%Y-%m-%d\ %H:%M:%S
}

LOG=/var/log/backups/db_main_chk_hourly.log 

PORT=5432
DB_DIR=/opt/PostgreSQL/10/data
BACKUP_DIR=/tmp/backup/hourly/main
WALS_DIR=/tmp/archived_wals/hourly/main

CHK_FILE_s3=/tmp/chk_backups/db_main_chk_hourly_s3

#get last modified element in s3 bucket
BUCKET="bucket_name"
SERVER="server_ip_5432"
BACKUP=$(aws --endpoint-url=https://storage.yandexcloud.net s3 ls s3://$BUCKET/$SERVER/hourly/ | sort | tail -n 1 | awk '{print $2}')

#1-start checking backups in s3
#clean old 
rm -rf $BACKUP_DIR/* 

#download
echo "`now` - start download $BACKUP from s3." >> $LOG
aws --endpoint-url=https://storage.yandexcloud.net s3 cp s3://$BUCKET/$SERVER/hourly/$BACKUP $BACKUP_DIR/ --recursive >> $LOG
echo "`now` - download $BACKUP from s3 done." >> $LOG

#restore db
sudo -u postgres /opt/PostgreSQL/10/bin/pg_ctl stop -m fast -w -D "$DB_DIR"  

rm -rf $DB_DIR/*
rm -rf $WALS_DIR/*

echo "`now` -  start extracting archive files $BACKUP s3." >> $LOG
tar xvf $BACKUP_DIR/pg_wal.tar.gz -C $WALS_DIR/
tar xvf $BACKUP_DIR/base.tar.gz -C $DB_DIR/

if [ $? != 0 ]; then
        echo "`now` - unable to extract archive files $BACKUP s3. Exit with status 1" >> $LOG
        echo "0" > $CHK_FILE_s3
else
        echo "`now` -  extract archive files $BACKUP s3- done." >> $LOG
        
        sed -i -e 's/^log_directory/#&/' -e 's/^log_filename/#&/' $DB_DIR/postgresql.conf
        sed -i -e 's/^hba_file/#&/' -e 's/^ident_file/#&/' $DB_DIR/postgresql.conf
        echo restore_command = \'cp $WALS_DIR/%f "%p" \' > $DB_DIR/recovery.conf

        chown postgres:postgres -R /opt/PostgreSQL/10/
        chmod -R 700 $DB_DIR

        sudo -u postgres /opt/PostgreSQL/10/bin/pg_ctl start -w -D "$DB_DIR" -o "-p $PORT -h localhost" -l "/var/log/postgres/db_main_startup_hourly.log" 
        sleep 5m

        #check data
        /opt/PostgreSQL/10/bin/psql -t -A -U postgres -d databasename -c "select last_opened_on from recent_agents where last_opened_on > now()-'8 hour'::interval order by last_opened_on desc limit 1;"  | wc -l > $CHK_FILE_s3
fi
