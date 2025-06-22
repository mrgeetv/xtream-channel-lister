#!/bin/bash
set -e -o pipefail

if ! command -v jq &>/dev/null; then
    echo "Error: 'jq' command not found. Please install jq." >&2
    exit 1
fi
if ! command -v curl &>/dev/null; then
    echo "Error: 'curl' command not found. Please install curl." >&2
    exit 1
fi

CASE_SENSITIVE=false
CATEGORY_CONTAINS_ARG=""
CATEGORY_PREFIX_ARG=""
DEFAULT_TIMEOUT=10
HOST_ARG=""
PASSWORD_ARG=""
PASSWORD_PROVIDED_VIA_ARG=false
USERNAME_ARG=""
VERBOSE=false

show_help() {
    cat <<EOF
Usage: $(basename "$0") -H <host> -u <username> [-p <password>] [-P <prefix>] [-c <contains_string>] [-s] [-t <timeout>] [-v] [--help]

Fetches and displays live channels from an Xtream Codes IPTV provider.
Category filtering (-P and -c) is case-insensitive by default.

Required Arguments:
  -H, --host <HOST_URL>      The Xtream Codes panel URL (e.g., http://domain.com:port).
  -u, --username <USER>      Your IPTV username.

Optional Arguments:
  -p, --password <PASS>      Your IPTV password. If not provided, you will be prompted securely.
  -P, --prefix <PREFIX>      Only show categories where the name starts with this prefix.
  -c, --contains <STRING>    Only show categories where the name contains this string.
                             Can be used with -P for more specific filtering.
  -s, --sensitive            Perform case-sensitive matching for -P (prefix) and -c (contains).
  -t, --timeout <SECONDS>    Connection timeout for API requests (default: ${DEFAULT_TIMEOUT}).
  -v, --verbose              Enable verbose output.
  --help                     Display this help message and exit.

Examples:
  # Basic usage: List all categories and their channels. Password will be prompted.
  $(basename "$0") -H http://myiptv.example.com:8000 -u myusername

  # Filter categories: List channels from categories starting with "24/7" (case-insensitive).
  # Password is provided directly on the command line.
  $(basename "$0") -H http://myiptv.example.com:8000 -u myusername -p mysecretpass -P "24/7"

  # Filter categories: List channels from categories containing "movie" (case-insensitive).
  $(basename "$0") -H http://myiptv.example.com:8000 -u myusername -p mysecretpass -c "movie"

  # Combined filtering: List channels from categories starting with "us" AND containing "news" (case-insensitive).
  $(basename "$0") -H http://myiptv.example.com:8000 -u myusername -p mysecretpass -P "us" -c "news"

  # Case-sensitive filtering: List channels from categories starting with "USA" (exact case match).
  $(basename "$0") -H http://myiptv.example.com:8000 -u myusername -p mysecretpass -P "USA" -s
EOF
}

# ... (rest of the script remains the same)
# (I'm omitting the rest of the script for brevity as it was already provided and corrected)

while [[ "$#" -gt 0 ]]; do
    case $1 in
    -H | --host)
        HOST_ARG="$2"
        shift
        ;;
    -u | --username)
        USERNAME_ARG="$2"
        shift
        ;;
    -p | --password)
        PASSWORD_ARG="$2"
        PASSWORD_PROVIDED_VIA_ARG=true
        shift
        ;;
    -P | --prefix)
        CATEGORY_PREFIX_ARG="$2"
        shift
        ;;
    -c | --contains)
        CATEGORY_CONTAINS_ARG="$2"
        shift
        ;;
    -s | --sensitive) CASE_SENSITIVE=true ;;
    -t | --timeout)
        TIMEOUT_ARG="$2"
        shift
        ;;
    -v | --verbose) VERBOSE=true ;;
    --help)
        show_help
        exit 0
        ;;
    *)
        echo "Unknown parameter passed: $1" >&2
        show_help >&2
        exit 1
        ;;
    esac
    shift
done

if [ -z "$HOST_ARG" ]; then
    echo "Error: Host (-H or --host) is required." >&2
    show_help >&2
    exit 1
fi
if [ -z "$USERNAME_ARG" ]; then
    echo "Error: Username (-u or --username) is required." >&2
    show_help >&2
    exit 1
fi

if ! $PASSWORD_PROVIDED_VIA_ARG; then
    read -s -r -p "Enter IPTV password for user '${USERNAME_ARG}': " PASSWORD_ARG
    echo
    if [ -z "$PASSWORD_ARG" ]; then
        echo "Error: Password is required." >&2
        exit 1
    fi
fi

TIMEOUT=${TIMEOUT_ARG:-$DEFAULT_TIMEOUT}
if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]] || [ "$TIMEOUT" -le 0 ]; then
    echo "Error: Timeout must be a positive integer." >&2
    show_help >&2
    exit 1
fi

API_PATH="/player_api.php"
FULL_API_ENDPOINT="${HOST_ARG}${API_PATH}"
PLAYER_API_URL="${FULL_API_ENDPOINT}?username=${USERNAME_ARG}&password=${PASSWORD_ARG}"

if $VERBOSE; then
    echo "Verbose mode enabled."
    echo "Host: ${HOST_ARG}"
    echo "API Path: ${API_PATH}"
    echo "Full API Endpoint: ${FULL_API_ENDPOINT}"
    echo "API Base URL (credentials part): ${FULL_API_ENDPOINT}?username=${USERNAME_ARG}&password=********"
fi

echo "Fetching IPTV data..."

if $VERBOSE; then
    echo "Calling API for categories: ${PLAYER_API_URL}&action=get_live_categories"
fi

categories_json=""
curl_output_file=$(mktemp)
trap 'rm -f "$curl_output_file"' EXIT

http_status_code=$(curl --connect-timeout "$TIMEOUT" -sSL -w "%{http_code}" -o "$curl_output_file" "${PLAYER_API_URL}&action=get_live_categories")
categories_json=$(<"$curl_output_file")

if [ "$http_status_code" -ne 200 ]; then
    echo "Error: API request failed with HTTP status code: $http_status_code" >&2
    case "$http_status_code" in
    000)
        echo "This indicates a network issue, timeout, or that the host/port is incorrect or unreachable." >&2
        echo "Host tried: ${HOST_ARG}" >&2
        echo "Timeout: ${TIMEOUT}s" >&2
        ;;
    404)
        echo "A '404 Not Found' error was received. This could mean:" >&2
        echo "  1. The Host URL ('${HOST_ARG}') or the API path ('${API_PATH}') is incorrect." >&2
        echo "  2. The provider's server is misconfigured or the player API is not enabled." >&2
        echo "  3. Some providers return 404 for incorrect username/password or other access issues." >&2
        echo "Please double-check all connection details and credentials." >&2
        ;;
    401 | 403)
        echo "An 'Authorization Required' (401) or 'Forbidden' (403) error suggests an issue with credentials or access rights." >&2
        echo "Please verify your username and password." >&2
        echo "It's also possible your IP is blocked or the account is inactive." >&2
        ;;
    *)
        echo "The server returned an unexpected HTTP error." >&2
        ;;
    esac
    if [ -n "$categories_json" ]; then
        echo "Server response (first 10 lines):" >&2
        echo "$categories_json" | head -n 10 >&2
    fi
    exit 1
fi

if ! echo "$categories_json" | jq -e . >/dev/null 2>&1; then
    echo "Error: API request was successful (HTTP 200), but the response was not valid JSON." >&2
    echo "This could mean the provider's API is misconfigured, or it returned an HTML page for other reasons (e.g., a redirect, a soft error page)." >&2
    echo "It might also indicate an issue with username/password if the provider returns non-JSON on auth failure even with HTTP 200." >&2
    echo "Please verify all details, including credentials." >&2
    echo "Response (first 10 lines):" >&2
    echo "$categories_json" | head -n 10 >&2
    exit 1
fi

if [ -n "$CATEGORY_PREFIX_ARG" ] || [ -n "$CATEGORY_CONTAINS_ARG" ]; then
    filter_description_parts=()
    if [ -n "$CATEGORY_PREFIX_ARG" ]; then filter_description_parts+=("starting with \"$CATEGORY_PREFIX_ARG\""); fi
    if [ -n "$CATEGORY_CONTAINS_ARG" ]; then filter_description_parts+=("containing \"$CATEGORY_CONTAINS_ARG\""); fi

    _filter_desc_tmp=$(printf " and %s" "${filter_description_parts[@]}")
    filter_description=${_filter_desc_tmp#" and "}

    sensitivity_text=$($CASE_SENSITIVE && echo "case-sensitive" || echo "case-insensitive")
    echo ""
    echo "Filtering for categories $filter_description ($sensitivity_text):"
else
    echo ""
    echo "Processing all live categories:"
fi
echo "---------------------------------------------------"

found_any_matching_categories=false
total_matching_categories_count=0
overall_total_channels_count=0

select_conditions=()
jq_args=()

if [ -n "$CATEGORY_PREFIX_ARG" ]; then
    jq_args+=(--arg prefix_arg "$CATEGORY_PREFIX_ARG")
    if $CASE_SENSITIVE; then
        select_conditions+=("(.category_name | startswith(\$prefix_arg))")
    else
        select_conditions+=("(.category_name | ascii_downcase | startswith(\$prefix_arg | ascii_downcase))")
    fi
fi
if [ -n "$CATEGORY_CONTAINS_ARG" ]; then
    jq_args+=(--arg contains_arg "$CATEGORY_CONTAINS_ARG")
    if $CASE_SENSITIVE; then
        select_conditions+=("(.category_name | contains(\$contains_arg))")
    else
        select_conditions+=("(.category_name | ascii_downcase | contains(\$contains_arg | ascii_downcase))")
    fi
fi

jq_filter_part=""
if [ ${#select_conditions[@]} -gt 0 ]; then
    _joined_cond_tmp=$(printf " and %s" "${select_conditions[@]}")
    joined_conditions=${_joined_cond_tmp#" and "}
    jq_filter_part="select(${joined_conditions}) | "
fi
jq_category_query=".[] | ${jq_filter_part}\"\\(.category_id)\\t\\(.category_name)\""

while IFS=$'\t' read -r category_id category_name; do
    found_any_matching_categories=true
    total_matching_categories_count=$((total_matching_categories_count + 1))

    echo
    echo "Category: ${category_name} (ID: ${category_id})"

    if $VERBOSE; then
        echo "  Calling API for streams in category ${category_id}: ${PLAYER_API_URL}&action=get_live_streams&category_id=${category_id}"
    fi
    streams_json=$(curl --connect-timeout "$TIMEOUT" -sSL "${PLAYER_API_URL}&action=get_live_streams&category_id=${category_id}")

    if [ -z "$streams_json" ]; then
        echo "  Warning: Failed to fetch streams for category '${category_name}'. No response." >&2
        continue
    elif ! echo "$streams_json" | jq -e . >/dev/null 2>&1; then
        echo "  Warning: Received non-JSON for streams in category '${category_name}'." >&2
        if $VERBOSE || [ -n "$streams_json" ]; then echo "$streams_json" | head -n 10 >&2; fi
        continue
    fi

    channel_count_for_this_category=0
    actual_api_stream_count=$(echo "$streams_json" | jq 'if type == "array" then length else 0 end')

    while IFS= read -r channel_name_from_stream; do
        if [ -n "$channel_name_from_stream" ]; then
            echo "  ${channel_name_from_stream}"
            channel_count_for_this_category=$((channel_count_for_this_category + 1))
            overall_total_channels_count=$((overall_total_channels_count + 1))
        fi
    done < <(echo "$streams_json" | jq -r '.[]? | (.name // "Unnamed Channel")')

    if [ "$channel_count_for_this_category" -eq 0 ]; then
        if [ "$actual_api_stream_count" -eq 0 ]; then
            echo "  (No channels returned by API for this category)"
        else
            echo "  (Streams found by API, but no valid channel names to display after filtering)"
        fi
    fi
done < <(echo "$categories_json" | jq -r "${jq_args[@]}" "$jq_category_query")

echo "---------------------------------------------------"

if ! $found_any_matching_categories; then
    is_categories_empty_array=$(echo "$categories_json" | jq -r 'if type == "array" and length == 0 then "true" else "false" end')
    if [ "$is_categories_empty_array" = "true" ]; then
        echo "Successfully connected (HTTP 200) and received valid JSON, but the provider returned no live categories." >&2
        echo "This could mean:" >&2
        echo "  1. There are genuinely no categories available on your account." >&2
        echo "  2. Your account is inactive or has restrictions." >&2
        echo "  3. It's possible your username/password was incorrect, and the provider returns an empty list instead of a specific error for this action." >&2
    elif [ -n "$CATEGORY_PREFIX_ARG" ] || [ -n "$CATEGORY_CONTAINS_ARG" ]; then
        echo "No categories found matching your filter criteria."
    else
        echo "No live categories were processed. The response from the provider might have been valid JSON but not in the expected array format for categories." >&2
    fi
else
    echo "Summary:"
    summary_filter_parts=()
    if [ -n "$CATEGORY_PREFIX_ARG" ]; then summary_filter_parts+=("prefix \"$CATEGORY_PREFIX_ARG\""); fi
    if [ -n "$CATEGORY_CONTAINS_ARG" ]; then summary_filter_parts+=("containing \"$CATEGORY_CONTAINS_ARG\""); fi

    if [ ${#summary_filter_parts[@]} -gt 0 ]; then
        _summary_text_tmp=$(printf " and %s" "${summary_filter_parts[@]}")
        summary_filter_text=${_summary_text_tmp#" and "}
    else
        summary_filter_text=""
    fi

    if [ -n "$summary_filter_text" ]; then
        sensitivity_text=$($CASE_SENSITIVE && echo "case-sensitive" || echo "case-insensitive")
        echo "  Categories matching criteria ($summary_filter_text, $sensitivity_text): $total_matching_categories_count"
    else
        echo "  Total live categories processed: $total_matching_categories_count"
    fi
    echo "  Overall total channels listed:   $overall_total_channels_count"
fi

echo ""
echo "Done."
