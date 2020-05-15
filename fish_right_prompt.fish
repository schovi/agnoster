# You can override some default right prompt options in your config.fish:
#     set -g theme_date_format "+%a %H:%M"
#     set -g theme_date_timezone America/Los_Angeles

function __bobthefish_cmd_duration -S -d 'Show command duration'
    [ "$theme_display_cmd_duration" = "no" ]
    and return

    [ -z "$CMD_DURATION" -o "$CMD_DURATION" -lt 100 ]
    and return

    if [ "$CMD_DURATION" -lt 5000 ]
        echo -ns $CMD_DURATION 'ms'
    else if [ "$CMD_DURATION" -lt 60000 ]
        __bobthefish_pretty_ms $CMD_DURATION s
    else if [ "$CMD_DURATION" -lt 3600000 ]
        set_color $fish_color_error
        __bobthefish_pretty_ms $CMD_DURATION m
    else
        set_color $fish_color_error
        __bobthefish_pretty_ms $CMD_DURATION h
    end

    set_color $fish_color_normal
    set_color $fish_color_autosuggestion

    # [ "$theme_display_date" = "no" ]
    # or echo -ns ' ' $__bobthefish_left_arrow_glyph
    echo -ns ' | '
end

function __bobthefish_pretty_ms -S -a ms -a interval -d 'Millisecond formatting for humans'
    set -l interval_ms
    set -l scale 1

    switch $interval
        case s
            set interval_ms 1000
        case m
            set interval_ms 60000
        case h
            set interval_ms 3600000
            set scale 2
    end

    math -s$scale "$ms/$interval_ms"
    echo -ns $interval
end

# function __bobthefish_timestamp -S -d 'Show the current timestamp'
#     [ "$theme_display_date" = "no" ]
#     and return

#     set -q theme_date_format
#     or set -l theme_date_format "+%c"

#     echo -n ' '
#     env TZ="$theme_date_timezone" date $theme_date_format
# end

function __bobthefish_k8s_context -S -d 'Get the current k8s context'
    set -l config_paths "$HOME/.kube/config"
    [ -n "$KUBECONFIG" ]
    and set config_paths (string split ':' "$KUBECONFIG") $config_paths

    for file in $config_paths
        [ -f "$file" ]
        or continue

        while read -l key val
            if [ "$key" = 'current-context:' ]
                set -l context (string trim -c '"\' ' -- $val)
                [ -z "$context" ]
                and return 1

                echo $context
                return
            end
        end <$file
    end

    return 1
end

function __bobthefish_k8s_namespace -S -d 'Get the current k8s namespace'
    kubectl config view --minify --output "jsonpath={..namespace}"
end

function __bobthefish_prompt_k8s_context -S -d 'Show current Kubernetes context'
    # [ "$theme_display_k8s_context" = 'yes' ]
    # or return

    set -l context (__bobthefish_k8s_context)
    or return

    # [ "$theme_display_k8s_namespace" = 'yes' ]
    set -l namespace (__bobthefish_k8s_namespace)

    # [ -z $context -o "$context" = 'default' ]
    # and [ -z $namespace -o "$namespace" = 'default' ]
    # and return

    set -l segment $context

    [ -n "$namespace" ]
    and set segment $segment "/" $namespace

    [ "$theme_display_k8s_production" = "$context" ]
    and set_color $fish_color_error

    echo -ns $segment " "

    set_color $fish_color_normal
    set_color $fish_color_autosuggestion
end

function fish_right_prompt -d 'bobthefish is all about the right prompt'
    set -l __bobthefish_left_arrow_glyph \uE0B3
    if [ "$theme_powerline_fonts" = "no" -a "$theme_nerd_fonts" != "yes" ]
        set __bobthefish_left_arrow_glyph '<'
    end

    set_color $fish_color_autosuggestion

    __bobthefish_cmd_duration
    __bobthefish_prompt_k8s_context
    # __bobthefish_timestamp
    set_color normal
end