def --env klone [url: string, --dry-run (-n)] {
    let $klone_config: record = open (klone_helper_toml_file)
    if $dry_run {
        let clone_command = if ($klone_config.general?.clone_command? != null) {
            $klone_config.general.clone_command
        } else {
            "git clone"
        }
        print $"dry run: would clone repo to (klone_helper_extract_full_path $url $klone_config)"
        print $"dry run: would clone repo using ($clone_command) ($url)"
        return
    }

    let fullpath = klone_helper_extract_full_path $url $klone_config
    mkdir ($fullpath)

    let current_dir = $env.PWD
    cd (dirname $fullpath)
    klone_helper_clone_tool $url $klone_config
    cd $current_dir

    if ($klone_config.general.cd_after_clone? == true) {
        cd $fullpath
    }
}

def klone_helper_toml_file [] {
    if ($env.KLONE_CONFIG? != null) and (($env.KLONE_CONFIG | path exists)) {
        $env.KLONE_CONFIG
    } else if ($"($nu.home-path)/.config/klone/config.toml" | path exists) {
        $"($nu.home-path)/.config/klone/config.toml"
    } else {
        ""
    }
}

def klone_helper_clone_tool [url: string klone_config: record] {
    if ($klone_config.general.clone_command? != null) {
        let clone_command = $klone_config.general.clone_command | split row --number 2 " "
        ^$clone_command.0 ...($clone_command.1 | split row " ") $url
    } else {
        git clone $url
    }
}

def klone_helper_extract_full_path [url: string klone_config: record] {
    if ($url | str starts-with "git@") or ($url | str starts-with "ssh://git@") {
        klone_helper_extract_full_path_ssh $url $klone_config
    } else {
        klone_helper_extract_full_path_https $url $klone_config
    }
}

def klone_helper_extract_full_path_ssh [url: string klone_config: record] {
    let schemaless = $url | str replace -r ".*@" "" | str replace -r ":" "/" | str replace -r "[.]git$" ""
    klone_helper_extract_full_path_generic $schemaless $klone_config
}

def klone_helper_extract_full_path_https [url: string klone_config: record] {
    let schemaless = $url | str replace -r "^https://" "" | str replace -r "[.]git$" ""
    klone_helper_extract_full_path_generic $schemaless $klone_config
}

def klone_helper_extract_full_path_generic [url: string klone_config: record] {
    let fqdn = $url | str replace -r "/.*" ""
    let nu_friendly_fqdn = $fqdn | str replace -a ":" "." | str replace -a "-" "." | split row '.' | into cell-path

    let domain_var = $klone_config.domain_alias? | get -o $nu_friendly_fqdn
    let domain = if $domain_var != null {
        $domain_var
    } else {
        $fqdn | str replace -r "[.].*$" ""
    }

    let unfiltered_path = $url | str replace -r "[^/]*/" ""

    let path_filter = $klone_config.path_replace? | get -o $nu_friendly_fqdn

    let filtered_path = if ($path_filter.0?) != null and ($path_filter.1?) != null {
        $unfiltered_path | str replace -a $path_filter.0 $path_filter.1
    } else {
        $unfiltered_path
    }

    let base_dir = if ($klone_config.general?.base_dir? != null) {
        $klone_config.general.base_dir | str replace -r "^~/" $"($nu.home-path)/"
    } else {
        $"($nu.home-path)/workspace"
    }

    $"($base_dir)/($domain)/($filtered_path)"
}
