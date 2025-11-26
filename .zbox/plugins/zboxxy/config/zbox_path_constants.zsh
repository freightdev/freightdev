#*  ╔═══════════════════╗
#?       zBox Paths
#*  ╚═══════════════════╝


#!      zBox Configurations
#? ================================ <===== Everything runs inside the main zBox Environment
export zBOX_DIR=$HOME/.zbox
export zBOX_MAIN=$zBOX_DIR/zbox
export zBOX_BIN=$zBOX_DIR/bin
export zBOX_ETC=$zBOX_DIR/etc
export zBOX_LIB=$zBOX_DIR/lib
export zBOX_LIB64=$zBOX_DIR/lib64
export zBOX_SHARE=$zBOX_DIR/share
export zBOX_MAN=$zBOX_DIR/manifest.yml

#!      Tenant Configurations
#? ================================ <===== Every tenant gets to have their own little zboxxies running inside a contained zBox Environment
export MYzBOX_HOME=$zBOX_DIR/zboxxies
export MYzBOX_DIR=$MYzBOX_HOME/myzboxxy
export MYzBOX_BIN=$MYzBOX_DIR/bin
export MYzBOX_ETC=$MYzBOX_DIR/etc
export MYzBOX_LIB=$MYzBOX_DIR/lib
export MYzBOX_LIB64=$MYzBOX_DIR/lib64
export MYzBOX_SHARE=$MYzBOX_DIR/share

export MYzBOX_MAN=$MYzBOX_DIR/manifest.yml

#!     zBoxxy Configurations
#? ================================ <===== zBoxxy is a zbox handler for all logic and placement inside of zboxxies.
export zBOXXY_DIR=$MYzBOX_DIR/.zboxxy
export zBOXXY_MAIN=$zBOXXY_DIR/zboxxy
export zBOXXY_CFGS=$zBOXXY_DIR/configs
export zBOXXY_MODS=$zBOXXY_DIR/modules
export zBOXXY_RSRC=$zBOXXY_DIR/resources
export zBOXXY_TMPS=$zBOXXY_DIR/templates

export zBOXXY_MAN=$zBOXXY_DIR/manifest.yml

