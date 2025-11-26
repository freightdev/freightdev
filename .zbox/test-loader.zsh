#!/bin/zsh
#############################
# ZBOX Loader Test Script
#############################

echo "==================================="
echo "ZBOX Environment Loader - Test"
echo "==================================="
echo

# Test 1: Source the loader
echo "[1] Sourcing main.zsh..."
. ~/.zbox/main.zsh
echo "    ✓ Loaded"
echo

# Test 2: Check variables
echo "[2] Checking environment variables:"
echo "    ZBOX_DIR:              $ZBOX_DIR"
echo "    ZBOX_CFG:              $ZBOX_CFG"
echo "    ZBOX_SRC:              $ZBOX_SRC"
echo "    ZBOX_FUNCTIONS_LOADED: $ZBOX_FUNCTIONS_LOADED"
echo "    ZBOX_READY:            $ZBOX_READY"
echo

# Test 3: Check functions
echo "[3] Checking loaded functions:"
functions_to_check=(scana finda senda serva)
for func in "${functions_to_check[@]}"; do
    if type -w "$func" &>/dev/null; then
        echo "    ✓ $func loaded"
    else
        echo "    ✗ $func NOT loaded"
    fi
done
echo

# Test 4: Test conditional reload
echo "[4] Testing conditional reload (should skip):"
old_timestamp=$ZBOX_FUNCTIONS_LOADED
. ~/.zbox/main.zsh
new_timestamp=$ZBOX_FUNCTIONS_LOADED
if [[ "$old_timestamp" == "$new_timestamp" ]]; then
    echo "    ✓ Conditional loading working (timestamp unchanged)"
else
    echo "    ✗ Reloaded when it shouldn't have"
fi
echo

# Test 5: Test force reload
echo "[5] Testing force reload:"
sleep 1
ZBOX_FORCE_RELOAD=1 . ~/.zbox/main.zsh
force_timestamp=$ZBOX_FUNCTIONS_LOADED
if [[ "$force_timestamp" != "$old_timestamp" ]]; then
    echo "    ✓ Force reload working (new timestamp: $force_timestamp)"
else
    echo "    ✗ Force reload failed"
fi
echo

echo "==================================="
echo "✓ All tests completed!"
echo "==================================="
