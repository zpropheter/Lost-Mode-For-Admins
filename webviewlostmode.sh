#!/bin/bash

#Dependencies 
# pip3 install pywebview

###########################################
# server connection information
url="$4"
client_id="$5"
client_secret="$6"

getAccessToken() {
  response=$(curl --silent --location --request POST "${url}/api/oauth/token" \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "client_id=${client_id}" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "client_secret=${client_secret}")
  access_token=$(echo "$response" | plutil -extract access_token raw -)
  token_expires_in=$(echo "$response" | plutil -extract expires_in raw -)
  token_expiration_epoch=$(($current_epoch + $token_expires_in - 1))
}

checkTokenExpiration() {
  current_epoch=$(date +%s)
  if [[ token_expiration_epoch -ge current_epoch ]]
  then
    echo "Token valid until the following epoch time: " "$token_expiration_epoch"
  else
    echo "No valid token available, getting new token"
    getAccessToken
  fi
}

invalidateToken() {
  responseCode=$(curl -w "%{http_code}" -H "Authorization: Bearer ${access_token}" $url/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
  if [[ ${responseCode} == 204 ]]
  then
    echo "Token successfully invalidated"
    access_token=""
    token_expiration_epoch="0"
  elif [[ ${responseCode} == 401 ]]
  then
    echo "Token already invalid"
  else
    echo "An unknown error occurred invalidating the token"
  fi
}

##############################################################################################################################

getAccessToken  

JSON2=$(curl -X 'GET' \
"$url/api/v2/mobile-devices/detail?section=USER_AND_LOCATION&section=SECURITY&page=0&page-size=100&sort=&filter=lostModeEnabled%3D%3Dtrue" \
-H 'accept: application/json' \
-H "Authorization: Bearer $access_token")

# --- Extract all email addresses with jq ---
EMAILS=$(echo "$JSON2" | jq -r '.results[].userAndLocation.emailAddress' | sort -u)

# Bail if no emails
if [[ -z "$EMAILS" ]]; then
  osascript -e 'display dialog "No devices in Lost Mode were found." buttons {"OK"} default button "OK"'
  exit 0
fi

# Convert into AppleScript list syntax
EMAIL_LIST=$(printf '"%s", ' $EMAILS | sed 's/, $//')

# --- Ask admin to choose email ---
SELECTED_EMAIL=$(osascript <<EOF
set emailList to {$EMAIL_LIST}
choose from list emailList with prompt "Select a Lost Mode user:" default items {item 1 of emailList} OK button name "Select" cancel button name "Cancel"
EOF
)

# If cancel pressed or empty
if [[ "$SELECTED_EMAIL" == "false" || -z "$SELECTED_EMAIL" ]]; then
  echo "❌ User cancelled."
  exit 1
fi

echo "✅ Admin selected: $SELECTED_EMAIL"
# --- Encode selected email for URL ---
ENCODED_EMAIL=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$SELECTED_EMAIL'))")

# --- Run follow-up query ---
JSON=$(curl -s -H "Authorization: Bearer $access_token" \
  "$url/api/v2/mobile-devices/detail?section=USER_AND_LOCATION&section=SECURITY&filter=emailAddress%3D%3D%22$ENCODED_EMAIL%22")

# --- Extract coordinates ---
LAT=$(echo "$JSON" | jq -r '.results[0].security.lostModeLocation.lostModeLocationLatitude')
LONG=$(echo "$JSON" | jq -r '.results[0].security.lostModeLocation.lostModeLocationLongitude')

if [[ -z "$LAT" || -z "$LONG" || "$LAT" == "null" || "$LONG" == "null" ]]; then
  osascript -e 'display dialog "⚠️ No Lost Mode location found for that user." buttons {"OK"} default button "OK"'
  exit 0
fi


python3 <<EOF
import webview

lat = "$LAT"
lon = "$LONG"

if lat and lon and lat != "null" and lon != "null":
  url = f"https://www.google.com/maps?q={lat},{lon}"
  webview.create_window("Lost Mode Location", url, width=800, height=600)
  webview.start()
else:
  print("⚠️ No Lost Mode location available")
EOF
