if status is-interactive
    # Commands to run in interactive sessions can go here

    # Aliases
    alias lzd="lazydocker"
    alias dc="docker-compose"

    # https://stackoverflow.com/questions/13995857/suppress-or-customize-intro-message-in-fish-shell
    set fish_greeting

    if type -q zoxide
        zoxide init fish | source
    end

    if type -q direnv-instant; 
        direnv-instant hook fish | source
    else if type -q direnv;
        echo "direnv-instant not found, trying direnv..."
        direnv hook fish | source
    end

    source ~/.config/shellrc_aliases
    source ~/.config/shellrc_defaults

    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        command yazi $argv --cwd-file="$tmp"
        if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end
end
