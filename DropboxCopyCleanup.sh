#!/bin/bash

# This script helps clean up file conflict issues caused by Dropbox failing to resolve which files are current, between online and local files. 
# The script is supposed to avoid the difficulty of having to manually decide this for each file.
# The script assumes that you have decided to retain either the server files or the local ones.
# It is highly recommended that the script should be ran while Dropbox is running.

# Written by: Wilson Nandolo (wilsonandolo@gmail.com)
# Disclaimer: you use this script at your own risk

# Base directory name
echo -e "\nEnter the absolute path of the base directory (with a forward slash at the end):"
read DIR
while ! [[ -d "$DIR" ]]; do
	echo -e "\nThe path you entered does not exist. Please ENTER the absolute path of the base directory (with a forward slash at the end):"
	read DIR
done

# File retention policy
echo -e "\nType \"d\" to retain Dropbox files or \"l\" to retain local files:"
read RETENTION
while ! [[ "ld" == *"$RETENTION"* ]]; do
	echo -e "\nYou entered an illegal option. Please TYPE \"d\" to retain Dropbox files OR \"l\" to retain local files:"
	read RETENTION
done

# Backup directory
WD=`pwd`
RANDOM=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 ; echo ''`
BACKUP=`echo "$WD/$RANDOM/"`
mkdir "${BACKUP}"
echo -e "\nFiles that are going to be changed are going to be temporarily backed up in the directory \"${BACKUP}\"."

# Make the changes
find $DIR -type f | awk '/conflicted copy/' | cat -n | while read n i; do
	ROOT=`echo $i | sed 's/[^/]*$//'`
	LOCAL=`echo $i | awk -F/ '{print $NF}'`
	SERVER=`echo $LOCAL | sed 's/ (.*)//'`
	
	# Progress information
	if [[  "$RETENTION" == "l" ]]; 
		then echo "Renaming \"${ROOT}${LOCAL}\" to \"${ROOT}${SERVER}\"..."
		else echo "Deleting \"${ROOT}${LOCAL}\"..."
	fi

	# Backup
	rsync -R "${ROOT}${SERVER}" "${BACKUP}"
	rsync -R "${ROOT}${LOCAL}" "${BACKUP}"
	
	# File rename
	if [[  "${RETENTION}" == "l" ]]; 
		then mv "${ROOT}${LOCAL}" "${ROOT}${SERVER}" 
		else rm "${ROOT}${LOCAL}"
	fi
 done

# Final decision about whether or not to accept the changes
echo -e "\nFile renaming has been done. You can review the files that have been changed in the directory \"$BACKUP\". If you are not happy with the changes and would like to reverse them, please type \"r\" to reverse the changes, or \"o\" to make the changes permanent."
read FEEDBACK
while ! [[ "or" == *"$FEEDBACK"* ]]; do
	echo -e "\nYou entered an illegal option. Please TYPE \"r\" to reverse the changes, or \"o\" to make the changes permanent."
	read FEEDBACK
done

# Implement the final decision
if [[ "$FEEDBACK" == "r"  ]];
	then 	
		find  "${BACKUP}" -type f | cat -n | while read n FILE; do
			DESTINATION=`echo $FILE | awk -v delimiter=$RANDOM 'BEGIN{OFS=delimiter;}{print $2}'`
			mv "${FILE}" "${DESTINATION}"
		done
		#rm -r "$BACKUP"
		echo -e "\nAll changes have been reversed."
	else
		#rm -r "$BACKUP"
		echo -e "\nAll changes have been effected."
fi
# End of script
