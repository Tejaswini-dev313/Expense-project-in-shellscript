#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOGS_FOLDER

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
then
    echo "Please run the script root priveleges" | tee -a $LOG_FILE
    exit 1
fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then 
        echo -e "$2 is...$R FAILED $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 is...$G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

echo "Script started executing at: $(date)" | tee -a $LOG_FILE

CHECK_ROOT

dnf install mysql-server -y
VALIDATE $? "Installing mysql server"

systemctl enable mysqld | tee -a $LOG_FILE
VALIDATE $? "Enabled mysql server"

systemctl start mysqld | tee -a $LOG_FILE
VALIDATE $? "Started mysql server"

mysql -h mysql.tejudevops.shop -u root -pExpenseApp@1 -e 'show databases;' | tee -a $LOG_FILE
if [ $? -ne 0 ]
then
    echo "Mysql root password is not setup, setting now" | tee -a $LOG_FILE
    mysql_secure_installation --set-root-pass ExpenseApp@1 | tee -a $LOG_FILE
    VALIDATE $? "Setting up the root password"
else
    echo -e "Mysql root password is already setup...$Y SKIPPING $N" | tee -a $LOG_FILE
fi