#!/bin/bash
set -e

# forked from https://serverfault.com/questions/1021883/how-to-delete-docker-images-older-than-x-days-from-docker-hub-using-a-shell-scri

#Script will delete all images in all repositories of your docker hub account which are older than 50 days

set -e

# set username and password
UNAME="$1"
UPASS="$2"

if [ -z "$UNAME" ] || [ -z "$UPASS" ]; then
  echo "Usage: $0 <username> <password>"
  exit 1
fi

# get token to be able to talk to Docker Hub
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${UNAME}'", "password": "'${UPASS}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

# get list of namespaces accessible by user (not in use right now)
#NAMESPACES=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/namespaces/ | jq -r '.namespaces|.[]')

#echo $TOKEN
echo
# get list of repos for that user account
echo "List of Repositories in ${UNAME} Docker Hub account"
sleep 5
REPO_LIST=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${UNAME}/?page_size=10000 | jq -r '.results|.[]|.name')
echo $REPO_LIST
echo
# build a list of all images & tags
for i in ${REPO_LIST}
do
  # get tags for repo
  IMAGE_TAGS=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${UNAME}/${i}/tags/?page_size=10000 | jq -r '.results|.[]|.name')

  # build a list of images from tags
  for j in ${IMAGE_TAGS}
  do
    # add each tag to list
    FULL_IMAGE_LIST="${FULL_IMAGE_LIST} ${UNAME}/${i}:${j}"
      
  done
done
sleep 10
echo
echo "Identifying and deleting images which are older than 50 days in ${UNAME} docker hub account"
sleep 10
# Note!!! Please un-comment below line if you wanna perform operation on all repositories of your Docker Hub account
for i in ${REPO_LIST}
#for i in randomRepo
#NOTE!!! For deleting Specific repositories images please include only those repositories in for loop  like below for loop which has repos mygninx and mykibana 
#for i in  mynginx mykibana 
do
  # get tags for repo
  echo
  echo "Looping Through $i repository in ${UNAME} account"
  IMAGE_TAGS=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${UNAME}/${i}/tags/?page_size=10000 | jq -r '.results|.[]|.name')

  # build a list of images from tags
  for j in ${IMAGE_TAGS}
  do
    # add last_updated_time
    fullResponse=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${UNAME}/${i}/tags/${j}/?page_size=10000)
    echo $fullResponse | jq
    exit
    updated_time=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${UNAME}/${i}/tags/${j}/?page_size=10000 | jq -r '.last_updated')
    #echo $updated_time
    datetime=$updated_time
    timeago='14 days ago'
    
    dtSec=$(date --date "$datetime" +'%s')
    taSec=$(date --date "$timeago" +'%s')

    #echo "INFO: dtSec=$dtSec, taSec=$taSec" 

           if [ $dtSec -lt $taSec ] && [ "$j" != "latest" ]
           then
              echo "This image ${UNAME}/${i}:${j} is older than 14 days, deleting this image"
              ## Please uncomment below line to delete docker hub images of docker hub repositories
              curl -s  -X DELETE  -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${UNAME}/${i}/tags/${j}/
           fi      
  done
done

echo "Script execution ends"