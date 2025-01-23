#!/usr/bin/env zsh

klone() {
    local url="$1"
    local fullpath
    __klone_helper_parse_toml $(__klone_helper_toml_file)

    fullpath=$(__klone_helper_extract_full_path "$url")
    mkdir -p $fullpath

    pushd $(dirname $fullpath) >/dev/null
    $(__klone_helper_clone_tool) $*
    popd >/dev/null

    if [[ ${klone_toml_general_cd_after_clone} = 'true' ]]; then
        cd $fullpath
    fi

    __klone_helper_cleanup_vars
}


__klone_helper_toml_file() {
    if [[ -n ${KLONE_CONFIG} ]]; then
        echo "${KLONE_CONFIG}"
    else
        echo $HOME/.config/klone.toml
    fi
}

__klone_helper_clone_tool() {
    if [[ -n ${klone_toml_general_clone_command} ]]; then
        echo "${klone_toml_general_clone_command}"
    else
        echo git clone
    fi
}

__klone_helper_extract_full_path() {
    if [[ "$1" =~ '^git@|^ssh://git@' ]]; then
        __klone_helper_extract_full_path_ssh "$1"
    else
        __klone_helper_extract_full_path_https "$1"
    fi
}

__klone_helper_extract_full_path_ssh() {
    local schemaless
    schemaless=${1#*@}
    schemaless=${schemaless//:/\/}
    schemaless=${schemaless%.git}
    __klone_helper_extract_full_path_generic "$schemaless"
}

__klone_helper_extract_full_path_https() {
    local schemaless
    schemaless=${1#https://}
    schemaless=${schemaless%.git}
    __klone_helper_extract_full_path_generic "$schemaless"
}

__klone_helper_extract_full_path_generic() {
    local fqdn
    fqdn=${1%%/*}
    local fish_friendly_fqdn
    fish_friendly_fqdn=${fqdn//[.:-]/_}

    local domain
    local domain_var="klone_toml_domain_alias_${fish_friendly_fqdn}"
    if [[ -n ${(P)domain_var+x} ]]; then
        domain=${(P)domain_var}
    else
        domain=${fqdn%%.*}
    fi

    local unfiltered_path
    unfiltered_path=${1#*/}

    local filtered_path="$unfiltered_path"
    local path_replace_0_var="klone_toml_path_replace_${fish_friendly_fqdn}_0"
    local path_replace_1_var="klone_toml_path_replace_${fish_friendly_fqdn}_1"

    if [[ -n ${(P)path_replace_0_var+x} ]] && [[ -n ${(P)path_replace_1_var+x} ]]; then
        filtered_path=${unfiltered_path//${(P)path_replace_0_var}/${(P)path_replace_1_var}}
    fi

    local base_dir
    if [[ -n ${klone_toml_general_base_dir+x} ]]; then
        base_dir=${klone_toml_general_base_dir}
        #explicitly replace ~/ with $HOME
        case "$klone_toml_general_base_dir" in "~/"*)
            base_dir="${HOME}/${klone_toml_general_base_dir#"~/"}"
        esac
    else
        base_dir="${HOME}/workspace"
    fi

    echo "$base_dir/$domain/$filtered_path"
}

### TOML handling

# Function to clean up environment variables when done
__klone_helper_cleanup_vars() {
    local vars
    vars=(${(M)parameters[(I)klone_toml_*]})
    for var in "${vars[@]}"; do
        unset "$var"
    done
}

# Function to escape special characters in keys
__klone_helper_escape_key() {
    echo "$1" | tr '.:' '_'
}

# Function to parse a TOML file
__klone_helper_parse_toml() {
    local file="$1"
    local current_section=""

    # Clear any existing TOML variables
    __klone_helper_cleanup_vars

    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # Match section headers
        if [[ "$line" =~ '^\[(.*)\]$' ]]; then
            current_section="${match[1]}"
            continue
        fi

        # Match key-value pairs
        if [[ "$line" =~ ^([a-zA-Z0-9_.]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
            local key="${match[1]}"
            local value="${match[2]}"

            # Remove surrounding quotes if present
            if [[ "$value" =~ ^\"(.*)\"$ ]]; then
                value="${match[1]}"
            fi

            local storage_key="klone_toml_$(__klone_helper_escape_key "${current_section}.${key}")"
            if [[ "$value" =~ '^\[(.*)\]$' ]]; then
                __klone_helper_parse_array "$value" "$storage_key"
            else
                export "$storage_key=$value"
            fi
        fi
    done < "$file"
}

# Function to parse array values
__klone_helper_parse_array() {
    if [[ $1 =~ \[[[:space:]]*\"([^\"]+)\"[[:space:]]*,[[:space:]]*\"([^\"]+)\"[[:space:]]*\] ]]; then
        local storage_key="$2"
        export "${storage_key}_0=${match[1]}"
        export "${storage_key}_1=${match[2]}"
    fi
}
