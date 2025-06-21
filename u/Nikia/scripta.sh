# shellcheck shell=bash
# arguments of the form X="$I" are parsed as parameters X of type string

# import some environment variables from Variables
for x in \
ENCRYPTION_SHARED_KEY \
GOODDAY_APITOKEN \
GOODDAY_URL1 \
GOODDAY_URL2 \
GOODDAY_URL2_PROJECTID \
GOODDAY_URL2_USERID \
GOODDAY_URL3 \
GOODDAY_URL4 \
REDIS_KEY \
REDIS_URL \
WEBPAGE \

do read "${x}" <  <(
curl -s -H "Authorization: Bearer $WM_TOKEN" \
  "$BASE_INTERNAL_URL/api/w/$WM_WORKSPACE/variables/get_value/u/Nikia/${x}" | jq -r .
)
#echo "$x": "${!x}" >&2
done

# the last line of the stdout is the return value
# unless you write json to './result.json' or a string to './result.out'
echo "Hello $msg"
