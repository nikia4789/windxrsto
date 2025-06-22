# shellcheck shell=bash
# arguments of the form X="$I" are parsed as parameters X of type string

T="tcurl"; $T --help >/dev/null 2>&1 || T="curl"

# import some environment variables from Variables and export them
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
$T -s -H "Authorization: Bearer $WM_TOKEN" \
  "$BASE_INTERNAL_URL/api/w/$WM_WORKSPACE/variables/get_value/u/Nikia/${x}" | jq -r .
)
export ${x} # make this variable available to children scripts
#echo "$x": "${!x}" >&2
done

# pipedream specific stuff doesn't apply here
umask 077;PIPEDREAM_EXPORTS=$(mktemp "/tmp/XXXXXX"); trap "\rm -f $PIPEDREAM_EXPORTS" 0;
export PIPEDREAM_EXPORTS
#export PIPEDREAM_EXPORTS=./result.out    # ./result.out is a special file
export PIPEDREAM_STEPS=/dev/null


get_counter(){
$T -s -H "Authorization: Bearer $WM_TOKEN" \
  "$BASE_INTERNAL_URL/api/w/$WM_WORKSPACE/resources/get_value_interpolated/u/Nikia/stored_items_c_counter" | jq -r .value
}

update_counter(){  # $1: new value
$T -s -H "Authorization: Bearer $WM_TOKEN" \
  -X POST -H 'Content-Type: application/json' \
  "$BASE_INTERNAL_URL/api/w/$WM_WORKSPACE/resources/update/u/Nikia/stored_items_c_counter" -d '{"value":
    {"value":'"$1"'}
  }'
  echo
}

COUNTER=$(get_counter)
echo "old COUNTER: $COUNTER" >&2
unset T
#exit

### -------------------------------------------------------------------------------------------------------------
#!/bin/sh
# using environment variables:
# GOODDAY_APITOKEN GOODDAY_URL4

# $PIPEDREAM_STEPS file contains data from previous steps
#cat $PIPEDREAM_STEPS | jq .trigger.context.id

# Write data to $PIPEDREAM_EXPORTS to return it from the step
# Exports must be written as key=value
#echo foo=bar >> $PIPEDREAM_EXPORTS

export LANG='el_GR.UTF-8'
export TZ='Europe/Athens'
export PATH=/bin:/usr/bin:/usr/local/bin     # required in order to find openssl

[ -s $PIPEDREAM_STEPS ] && COUNTER=$(< $PIPEDREAM_STEPS jq -r -M '.["get_counter_from_datastore"]["$return_value"]["tasks"]')
echo >&2 "tasks created so far: $COUNTER"

me=$(basename "$0"); umask 077;tf=$(mktemp "/tmp/${me}_XXXXXX");trap "\rm -f \"$tf\" " 0
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.3'

T="tcurl"; $T --help >/dev/null 2>&1 || T="curl"

task_description_to_base64_string(){
jq -r -M '
.[]
|select(has("messageRTF"))
|.messageRTF.content
|select(has("root"))
|.root
|select(map("children"))
|.children[]
|select(map("children"))
|select(has("children") and ((.children|length) == 1))
|.children[0].text
' 2>/dev/null 
}


### get a shell script
$T --silent -A "$UA" \
 -H "gd-api-token: $GOODDAY_APITOKEN" \
 "$GOODDAY_URL4" |
task_description_to_base64_string |
base64 -d > $tf
echo -n >&2 'shell script md5sum: '; < $tf md5sum >&2

if [ ! -s "$tf" ]; then
  echo >&2 got empty shell script
  exit 1
fi

#sed -n '1p; $p;' $tf >&2    # show first and last line
export PIPEDREAM_EXPORTS     # necessary for non-pipedream platforms
bash "$tf" "$COUNTER"

### -------------------------------------------------------------------------------------------------------------
echo "#--- child script output ---" >&2
cat $PIPEDREAM_EXPORTS >&2
echo "#--- child script output ---" >&2

#grep -E -q goodday_response "$PIPEDREAM_EXPORTS"   # don't use grep/egrep; it will throw an error
< $PIPEDREAM_EXPORTS awk '/goodday_response/{exit 1}'
if [ $? = 0 ]; then
  echo "No new items stored" >&2 
else # [ $? = 1 ]
  update_counter $(($COUNTER + 1))
  COUNTER=$(get_counter)
  echo "new COUNTER: $COUNTER" >&2
fi


# the last line of the stdout is the return value
# unless you write json to './result.json' or a string to './result.out'
#echo "Hello $msg"
