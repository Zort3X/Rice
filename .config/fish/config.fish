if status is-interactive
    fastfetch

    set -g fish_color_normal ebdbb2
    set -g fish_color_command b8bb26 --bold
    set -g fish_color_param d5c4a1
    set -g fish_color_redirection fabd2f
    set -g fish_color_comment 928374
    set -g fish_color_error fb4934
    set -g fish_color_operator 83a598
    set -g fish_color_escape 8ec07c
    set -g fish_color_autosuggestion 665c54

    function fish_prompt
        set_color b8bb26 --bold
        printf "[%s]" (prompt_pwd)
        set_color ebdbb2 --bold
        printf " -> "
        set_color normal
    end

    function fish_greeting
    end
end

fish_add_path /home/zert/.opencode/bin
