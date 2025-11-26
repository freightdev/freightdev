#!  ╔═══════════════════════════════════════════╗
#?    Color Settings - Environment Source (Zsh)  
#!  ╚═══════════════════════════════════════════╝

# Standard colors (0-15)
typeset -gA fg bg
fg[black]="%F{0}"       bg[black]="%K{0}"
fg[red]="%F{1}"         bg[red]="%K{1}"
fg[green]="%F{2}"       bg[green]="%K{2}"
fg[yellow]="%F{3}"      bg[yellow]="%K{3}"
fg[blue]="%F{4}"        bg[blue]="%K{4}"
fg[magenta]="%F{5}"     bg[magenta]="%K{5}"
fg[cyan]="%F{6}"        bg[cyan]="%K{6}"
fg[white]="%F{7}"       bg[white]="%K{7}"

# Bright colors (8-15)
fg[bright_black]="%F{8}"    bg[bright_black]="%K{8}"
fg[bright_red]="%F{9}"      bg[bright_red]="%K{9}"
fg[bright_green]="%F{10}"   bg[bright_green]="%K{10}"
fg[bright_yellow]="%F{11}"  bg[bright_yellow]="%K{11}"
fg[bright_blue]="%F{12}"    bg[bright_blue]="%K{12}"
fg[bright_magenta]="%F{13}" bg[bright_magenta]="%K{13}"
fg[bright_cyan]="%F{14}"    bg[bright_cyan]="%K{14}"
fg[bright_white]="%F{15}"   bg[bright_white]="%K{15}"

# Extended colors (16-255)
fg[gray]="%F{240}"          fg[dark_gray]="%F{236}"
fg[light_gray]="%F{250}"    fg[orange]="%F{208}"
fg[purple]="%F{135}"        fg[pink]="%F{211}"
fg[lime]="%F{154}"          fg[teal]="%F{37}"
fg[navy]="%F{17}"           fg[maroon]="%F{52}"
fg[olive]="%F{58}"          fg[silver]="%F{188}"
fg[gold]="%F{220}"          fg[coral]="%F{203}"
fg[salmon]="%F{209}"        fg[tan]="%F{180}"
fg[brown]="%F{94}"          fg[beige]="%F{230}"
fg[mint]="%F{121}"          fg[lavender]="%F{183}"
fg[turquoise]="%F{80}"      fg[crimson]="%F{160}"
fg[indigo]="%F{54}"         fg[violet]="%F{99}"
fg[khaki]="%F{185}"         fg[peach]="%F{216}"

