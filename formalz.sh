#!/bin/bash
#
# Copyright 2020 e-UCM (http://www.e-ucm.es/), Ivan J. Perez Colado
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# This project has received funding from the European Union’s Horizon
# 2020 research and innovation programme under grant agreement No 644187.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0 (link is external)
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# 
# This script contains documentation and an automated step-by-step set up of the analytics server
# for FormalZ and IMPRESS. It sets up an user, gives him roles, configures access of routes,
# creates a game, gives it visualizations, enables them for teachers, configures a custom
# dashboard, and sets up everything needed for it to work with FormalZ
#
# Feel free to open an Issue in github https://github.com/e-ucm/rage-analytics, in the formalz
# branch, with any problem you find, or make a pull request with improvements.

echo -e "\n\n\e[31m### Installing jq as is needed for the script ###\n\n\e[0m"

apt-get install -y jq

# PREVIOUS CONFIGURATION FOR THE SCRIPT.
# Set it up as you want to. This configuration have been obtained from the
# analytics_webhook_control.php example file that have been provided to the
# IMPRESS partners.

developeruser='formalz-admin-test'
developeremail='formalz-admin-test@dev.dev'
developerpass='admintest123456'
domain='http://localhost:3000/'

# First, we need the analytics framework up an running. We'll check if a2
# is available, and if not, try to restart the whole infrastructure.
# If fails the script will exit.

if [ "`docker inspect -f '{{.State.Running}}' a2`" == true ]
then
  echo -e "\n\n #### A2 Running #### \n\n"
else
  echo -e "\n\n #### A2 is not running, attempting restart #### \n\n"
  ./rage-analytics.sh restart
  if [[ $? != 0 ]]; then
        echo "\n\n #### RAGE ANALYTICS NEEDS TO BE RUNNING #### \n\n"
        exit 1
  fi
fi

# For setting up the admin user for formalz, it is needed to have the
# root user authenticated in A2.

echo -e "\n\n\e[31m### Login as root user ###\n\n\e[0m"

rootpass=$(cat ".env" | awk -F'=' '{print $2}')

result=$(curl --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request POST \
  --data '{"username": "root", "password": "'"$rootpass"'"}' \
  http://localhost:3000/api/login)

echo -e "\n\n"

roottoken=$(echo "$result" | jq -r ".user.token")

# A developer user is created in A2 with gleaner developer role and
# also, to the same user, the role formalzadmin is added so it can
# be authorized to use the /api/login/formalz and the user_created
# event in the webhook

echo -e "\n\n\e[31m### Creating developer user ###\n\n\e[0m"

curl --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request POST \
  --data '{"username": "'"$developeruser"'", "email": "'"$developeremail"'", "password": "'"$developerpass"'", "role": "developer", "prefix": "gleaner"}' \
  http://localhost:3000/api/signup

# The user is logged and prepared to create the game and personalize
# it to add the dashboard configuration and also to get the id of the
# user for the root admin user to be able to add the role.

echo -e "\n\n\e[31m### User login ###\n\n\e[0m"

result=$(curl --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request POST \
  --data '{"username": "'"$developeruser"'", "password": "'"$developerpass"'"}' \
  http://localhost:3000/api/login)

echo -e "\n\n"

echo "$result"

authtoken=$(echo "$result" | jq -r ".user.token")
userid=$(echo "$result" | jq -r ".user._id")

echo -e "\n\n\e[31m### Adding permission to login route to $developeruser ###\n\n\e[0m"

result=$(curl --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --header "Authorization: Bearer $roottoken" \
  --request POST \
  --data '{"resources":["/api/login/formalz"],"permissions":["post"]}' \
  http://localhost:3000/api/roles/formalzadmin/resources)

echo "$result"

echo -e "\n\n\e[31m### Adding formalzadmin role to $developeruser ###\n\n\e[0m"

result=$(curl --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --header "Authorization: Bearer $roottoken" \
  --request POST \
  --data '["formalzadmin"]' \
  http://localhost:3000/api/users/$userid/roles)

echo "$result"

# The game is created with the title FormalZ using the bundle request
# that creates the game, version and dashboard in a single api call.
# It takes a bit more time but is more useful.

echo -e "\n\n\e[31m### Creating game ###\n\n\e[0m"

result=$(curl --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --header "Authorization: Bearer $authtoken" \
  --request POST \
  --data '{"title": "FormalZ"}' \
  http://localhost:3000/api/proxy/gleaner/games/bundle)

gameid=$(echo "$result" | jq -r "._id")

# The game version is obtained as it is needed for activity creation in
# the webhook and also for various management purposes.

echo -e "\n\n\e[31m### Obtaining game version ###\n\n\e[0m"

result=$(curl --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --header "Authorization: Bearer $authtoken" \
  --request GET \
  http://localhost:3000/api/proxy/gleaner/games/$gameid/versions)

echo "$result"

versionid=$(echo "$result" | jq -r ".[]._id")

echo -e "\n\ngameid: $gameid, versionid: $versionid\n\n"

# Now, for easier configuration, we'll get all the visualizations enabled
# for the teacher, and disable all of them one by one, giving ElasticSearch
# some time in between so it can persist the data.

echo -e "\n\n\e[31m### Disabling all visualizations for the created game and teacher ###\n\n\e[0m"

result=$(curl --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --header "Authorization: Bearer $authtoken" \
  --request GET \
  http://localhost:3000/api/proxy/gleaner/kibana/visualization/list/tch/$gameid)

for vis in $(echo "${result}" | jq -r '.[]'); do
    echo -e "\n\e[32m### Disabling visualization $vis ###\n\e[0m"

    result=$(curl --header "Content-Type: application/json" \
	  --header "Accept: application/json" \
	  --header "Authorization: Bearer $authtoken" \
	  --request DELETE \
	  http://localhost:3000/api/proxy/gleaner/kibana/visualization/list/$gameid/tch/$vis)

	echo "$result"

	sleep 1
done

# We init the list of visualizations that the final dashboard is going to have
# but right now we add only the already added ones.

visualizations=()
visualizations+=('TimePicker')
visualizations+=('TotalSessionPlayers-Cmn')

# In the dashboard template, (/dashboard/dashboard.json) all the visualizations
# have an id because the dashboard was created in kibana using real visualizations.
# This hash map helps to translate and relate each file with a visualization id in
# this dashboard.json so we can replace them later.

declare -A visconversion
visconversion['./dashboard/visualizations/1-averages.json']='AWn9B08ZAztPIDR8zmfS'
visconversion['./dashboard/visualizations/2-money_over_time.json']='AWn9B35AAztPIDR8zmfT'
visconversion['./dashboard/visualizations/3-towers_over_time.json']='AWn9B54eAztPIDR8zmfU'
visconversion['./dashboard/visualizations/4-lives_over_time.json']='AWn9B7kXAztPIDR8zmfV'
visconversion['./dashboard/visualizations/5-pre_proximity_over_time_with_writing_time.json']='AWn9B9qoAztPIDR8zmfW'
visconversion['./dashboard/visualizations/6-post_proximity_over_time_with_writing_time.json']='AWn9CAtHAztPIDR8zmfX'
visconversion['./dashboard/visualizations/7-pre_log_with_writing.json']='AWplWp8I8LDUP6r8gZBk'
visconversion['./dashboard/visualizations/8-post_log_with_writing.json']='AWn9CEi1AztPIDR8zmfZ'
visconversion['./dashboard/visualizations/9-prepost_whole_group.json']='AWn9e2vBAztPIDR8znG7'
visconversion['./dashboard/visualizations/10-correctincorrect_tries_per_student.json']='AWn9e4bBAztPIDR8znG8'

dashboard=$(cat "./dashboard/dashboard.json")

# Now we're starting to add all the visualizations that are located in the
# /dashboard/visualizations/ folder. Every visualization is saved for this user,
# the id is obtained and added to the visualizations list that we created earlier.

echo -e "\n\n\e[31m### Adding Visualizations ###\n\n\e[0m"

for filename in ./dashboard/visualizations/*.json; do
	echo -e "\n\n\e[31m### Adding visualization $filename ###\n\n\e[0m"
    visualization=$(cat "$filename")

    result=$(curl --header "Content-Type: application/json" \
	  --header "Accept: application/json" \
	  --header "Authorization: Bearer $authtoken" \
	  --request POST \
	  --data "$visualization" \
	  http://localhost:3000/api/proxy/gleaner/kibana/templates/visualization/author/$developeruser)

	visid=$(echo "$result" | jq -r "._id")
	echo -e "Replacing $visid with ${visconversion[$filename]} \n\n"
	dashboard=$(echo "${dashboard/${visconversion[$filename]}/$visid}" )

	visualizations+=("$visid")

	sleep 1
done

# After adding the visualizations to the backend, it is needed to enable them for
# the current game. For this, 3 steps have to be done. Added to the visualizations
# index of the game, create a tuple, and after all of this, the final list of 
# visualizationsTch can be put in the backend

echo -e "\n\n\e[31m### Enabling visualizations ###\n\n\e[0m"

for vis in "${visualizations[@]}"; do
	echo -e "\n\n\e[31m### Enabling visualization $vis ###\n\n\e[0m"

    result=$(curl --header "Content-Type: application/json" \
	  --header "Accept: application/json" \
	  --header "Authorization: Bearer $authtoken" \
	  --request POST \
	  --data "" \
	  http://localhost:3000/api/proxy/gleaner/kibana/visualization/game/$gameid/$vis)

	echo "$result"

	result=$(curl --header "Content-Type: application/json" \
	  --header "Accept: application/json" \
	  --header "Authorization: Bearer $authtoken" \
	  --request POST \
	  --data "{}" \
	  http://localhost:3000/api/proxy/gleaner/kibana/visualization/tuples/fields/game/$gameid)
	  
	sleep 1
done

echo -e "\n\n\e[31m### Finally enabling all the list of visualizations ###\n\n\e[0m"

visualizationslined=$(printf '%s\n' "${visualizations[@]}" | jq -R . | jq -s .)
visteachers=$(echo '{"visualizationsTch": '${visualizationslined}'}')

result=$(curl --header "Content-Type: application/json" \
	  --header "Accept: application/json" \
	  --header "Authorization: Bearer $authtoken" \
	  --request PUT \
	  --data "$visteachers" \
	  http://localhost:3000/api/proxy/gleaner/kibana/visualization/list/$gameid)

echo "$result"

# We need also to save the index object. IndexObject is a workaround of the index
# template that kibana has problems to work with. This index object is inserted
# in the traces index of kibana and then refreshed so the indextemplate is refreshed
# and all the visualizations are able to search and filter by custom fields.
# 
# In this case some of the custom fields are out.ext.time or out.ext.towers

echo -e "\n\n\e[31m### Saving index object ###\n\n\e[0m"

indexobject=$(cat "./dashboard/indexobject.json")

result=$(curl --header "Content-Type: application/json" \
	  --header "Accept: application/json" \
	  --header "Authorization: Bearer $authtoken" \
	  --request POST \
	  --data "$indexobject" \
	  http://localhost:3000/api/proxy/gleaner/kibana/object/$versionid)

echo "$result"

# Finally, the dashboard template is saved in the backend. When creating a dashboard
# in backend, by default, a super simple dashboard is created in kibana with all the
# visualizations randomized and poorly organized. The dashboard template allows the
# developers to download a modified dashboard and save it so the following created
# activities will have the same template.

echo -e "\n\n\e[31m### Saving dashboard template ###\n\n\e[0m"

dashboardtemplate=$(echo '{"_id": "'"$versionid"'", "teacher": '${dashboard}', "developer": null }')

result=$(curl --header "Content-Type: application/json" \
	  --header "Accept: application/json" \
	  --header "Authorization: Bearer $authtoken" \
	  --request POST \
	  --data "$dashboardtemplate" \
	  http://localhost:3000/api/proxy/gleaner/kibana/dashboardtemplates/$versionid)

echo "$result"

# The game is set up as public for the teachers to use it or for the webhook to be able
# to create activities with it.

echo -e "\n\n\e[31m### Setting the game as public game ###\n\n\e[0m"

result=$(curl --header "Content-Type: application/json" \
	  --header "Accept: application/json" \
	  --header "Authorization: Bearer $authtoken" \
	  --request PUT \
	  --data '{"public": true}' \
	  http://localhost:3000/api/proxy/gleaner/games/$gameid)

echo "$result"

echo -e "\n\n\e[31m### gameid: $gameid, versionid: $versionid ###\n\n\e[0m"

# And to close up everything, the docker-compose.yml is updated with the data obtained
# from this script including gameid, versionid and the public domain url for the dashboard
# link creation.

echo -e "\n\n\e[31m### Saving the configuration for webhook ###\n\n\e[0m"

compose=$(cat "docker-compose.yml" | sed 's/\(FORMALZ_GAME_ID=\)\(.*\)/\1'$gameid'/')
compose=$(echo "$compose" | sed 's/\(FORMALZ_VERSION_ID=\)\(.*\)/\1'$versionid'/')
compose=$(echo "$compose" | sed 's#\(FORMALZ_BASE_URL=\)\(.*\)#\1'$domain'#')

rm "docker-compose.yml"
echo "$compose" > "docker-compose.yml"

# The Webhook is restarted to update the environment variables.

echo -e "\n\n\e[31m### Restarting the webhook ###\n\n\e[0m"

./rage-analytics.sh stop webhook
./rage-analytics.sh start webhook

echo -e "\n\n\e[32m### CONGRATULATIONS, FORMALZ CONFIGURED ###\n\n\e[0m"