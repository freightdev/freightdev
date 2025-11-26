#*  ╔═══════════════════╗
#?      zBox Settings     
#*  ╚═══════════════════╝


#!      zBox Configurations
#? ================================ <===== Everything runs inside the main zBox Environment
: "${zBOX_DIR:=$HOME/.zbox}"
: "${zBOX_MAIN:=$zBOX_DIR/zbox}"
: "${zBOX_BIN:=$zBOX_DIR/bin}"
: "${zBOX_ETC:=$zBOX_DIR/etc}"
: "${zBOX_LIB:=$zBOX_DIR/lib}"
: "${zBOX_LIB64:=$zBOX_DIR/lib64}"
: "${zBOX_SHARE:=$zBOX_DIR/share}"

: "${zBOX_MAN:=$zBOX_DIR/manifest.yml}"

#!      Tenant Configurations
#? ================================ <===== Every tenant gets to have their own little zboxxies running inside a contained zBox Environment
: "${MYzBOX_HOME:=$zBOX_DIR/zboxxies}"
: "${MYzBOX_DIR:=$MYzBOX_HOME/myzboxxy}"
: "${MYzBOX_BIN:=$MYzBOX_DIR/bin}"
: "${MYzBOX_ETC:=$MYzBOX_DIR/etc}"
: "${MYzBOX_LIB:=$MYzBOX_DIR/lib}"
: "${MYzBOX_LIB64:=$MYzBOX_DIR/lib64}"
: "${MYzBOX_SHARE:=$MYzBOX_DIR/share}"

: "${MYzBOX_MAN:=$MYzBOX_DIR/manifest.yml}"

#!     zBoxxy Configurations
#? ================================ <===== zBoxxy is a zbox handler for all logic and placement inside of zboxxies.
: "${zBOXXY_DIR:=$MYzBOX_DIR/.zboxxy}"
: "${zBOXXY_MAIN:=$zBOXXY_DIR/zboxxy}"
: "${zBOXXY_CFGS:=$zBOXXY_DIR/configs}"
: "${zBOXXY_MODS:=$zBOXXY_DIR/modules}"
: "${zBOXXY_RSRC:=$zBOXXY_DIR/resources}"
: "${zBOXXY_TMPS:=$zBOXXY_DIR/templates}"

: "${zBOXXY_MAN:=$zBOXXY_DIR/manifest.yml}"

