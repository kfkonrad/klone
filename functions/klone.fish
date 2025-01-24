function klone
  set url $argv[1]
  __klone_helper_parse_toml (__klone_helper_toml_file)

  set fullpath (__klone_helper_extract_full_path "$url")
  mkdir -p $fullpath

  pushd (dirname $fullpath)
  eval (__klone_helper_clone_tool) $argv
  popd

  if test "$klone_toml_general_cd_after_clone" = 'true'
    cd $fullpath
  end

  __klone_helper_cleanup_vars
end

function __klone_helper_toml_file
  if set -q KLONE_CONFIG && test -f "$KLONE_CONFIG"
    echo "$KLONE_CONFIG"
  else if test -f "$HOME/.config/klone/config.toml"
    echo "$HOME/.config/klone/config.toml"
  end
end

function __klone_helper_clone_tool
  if set -q klone_toml_general_clone_command
    echo "$klone_toml_general_clone_command"
  else
    echo git clone
  end
end

function __klone_helper_extract_full_path
  if grep -qe "^git@" -e "^ssh://git@" (echo $argv[1] | psub)
    __klone_helper_extract_full_path_ssh $argv[1]
  else
    __klone_helper_extract_full_path_https $argv[1]
  end
end

function __klone_helper_extract_full_path_ssh
  set schemaless (echo $argv[1] | sed 's/.*@//;s|:|/|;s|\.git$||')
  __klone_helper_extract_full_path_generic $schemaless
end

function __klone_helper_extract_full_path_https
  set schemaless (echo $argv[1] | sed 's|^https://||;s|\.git$||')
  __klone_helper_extract_full_path_generic $schemaless
end

function __klone_helper_extract_full_path_generic
  set fqdn (echo $argv[1] | sed 's|/.*||')
  set fish_friendly_fqdn (echo $fqdn | sed 's/[.:-]/_/g')
  if set -q klone_toml_domain_alias_$fish_friendly_fqdn
    set domain (eval echo \$klone_toml_domain_alias'_'$fish_friendly_fqdn)
  else
    set domain (echo $fqdn | sed 's|\..*$||')
  end

  set unfiltered_path (echo $argv[1] | sed 's|[^/]*/||')
  if set -q klone_toml_path_replace_$fish_friendly_fqdn"_0" && set -q klone_toml_path_replace_$fish_friendly_fqdn"_1"
    set path_filter_0 (eval echo \$klone_toml_path_replace'_'$fish_friendly_fqdn"_0")
    set path_filter_1 (eval echo \$klone_toml_path_replace'_'$fish_friendly_fqdn"_1")
    set filtered_path (echo $unfiltered_path | string replace -ra "$path_filter_0" "$path_filter_1")
  else
    set filtered_path $unfiltered_path
  end

  if set -q klone_toml_general_base_dir
    set base_dir (echo $klone_toml_general_base_dir | string replace -r '^~/' "$HOME/")
  else
    set base_dir $HOME/workspace
  end
  echo $base_dir/$domain/$filtered_path
end


### TOML handling

# Function to clean up environment variables when done
function __klone_helper_cleanup_vars
  set -l vars (set -n | string match -r "klone_toml_.*")
  for var in $vars
    set -e $var
  end
end

# Function to escape special characters in keys
function __klone_helper_escape_key
  echo $argv[1] | sed 's/[.:-]/_/g'
end

# Function to parse a TOML file
function __klone_helper_parse_toml
  set -l file $argv[1]
  set -l current_section ""

  # Clear any existing TOML variables
  __klone_helper_cleanup_vars

  if test -f "$file"
    while read -l line
      # Trim whitespace
      set line (string trim $line)

      # Skip empty lines and comments
      if test -z "$line" -o (string sub -l 1 "$line") = "#"
        continue
      end

      # Match section headers
      if string match -qr '^\[(.*)\]$' "$line"
        set current_section (string match -r '^\[(.*)\]$' "$line")[2]
        continue
      end

      # Match key-value pairs
      if string match -qr '^([a-zA-Z0-9_.]+)\s*=\s*(.*)$' "$line"
        set -l captures (string match -r '^([a-zA-Z0-9_.]+)\s*=\s*(.*)$' "$line")
        set -l key $captures[2]
        set -l value $captures[3]

        # Remove surrounding quotes if present
        if string match -qr '^"(.*)"$' "$value"
          set value (string match -r '^"(.*)"$' "$value")[2]
        end

        set -l storage_key "klone_toml_"(__klone_helper_escape_key "$current_section.$key")
        if string match -qr '^\[(.*)\]$' "$value"
          __klone_helper_parse_array $value $storage_key
        else
          set -g $storage_key $value
        end
      end
    end < $file
  end
end

function __klone_helper_parse_array
  set -l parsed (string match -r '\[\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\]' $argv[1])
  set -l storage_key $argv[2]

  if test (count $parsed) -eq 3
    set -g $storage_key"_0" $parsed[2]
    set -g $storage_key"_1" $parsed[3]
  end
end
