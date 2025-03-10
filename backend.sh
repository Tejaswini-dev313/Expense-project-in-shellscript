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

dnf module disable nodejs -y | tee -a $LOG_FILE
VALIDATE $? "Disable default nodejs"

dnf module enable nodejs:20 -y | tee -a $LOG_FILE
VALIDATE $? "Enable nodejs"

dnf install nodejs -y | tee -a $LOG_FILE
VALIDATE $? "Install nodejs"

id expense | tee -a $LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "expense user not exist...$G creating $N"
    useradd expense | tee -a $LOG_FILE
    VALIDATE $? "Creating expense user"
else
    echo -e "expense user already exists..$Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip | tee -a $LOG_FILE
VALIDATE $? "Downloading backend application code"

cd /app
rm -rf /app/* # remove the existing code
unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "Extracting backend application code"

npm install &>>$LOG_FILE
cp /home/ec2-user/Expense-project-in-shellscript/backend.service /etc/systemd/system/backend.service

# load the data before running backend

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "installing mysql client"

mysql -h mysql.tejudevops.shop -uroot -pExpenseApp@1 < /app/schema/backend.sql 
VALIDATE $? "Schema loading"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "Enabled backend"

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "Restarted backend"