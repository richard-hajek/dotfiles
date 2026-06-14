if status is-interactive
    
    # Aliases
    alias lzd="lazydocker"
    alias dc="docker-compose"

    # https://stackoverflow.com/questions/13995857/suppress-or-customize-intro-message-in-fish-shell
    set fish_greeting

    # Commands to run in interactive sessions can go here
    zoxide init fish | source

    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        command yazi $argv --cwd-file="$tmp"
        if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end
end
