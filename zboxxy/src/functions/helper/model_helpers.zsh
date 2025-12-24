# ============================================================================
# MODEL HELPERS (helpers/model_helpers.zsh)
# ============================================================================

#!/bin/zsh
# Model communication and formatting helpers

function model_format_prompt() {
    local system_prompt="$1"
    local user_prompt="$2"
    local format="${3:-chat}"  # chat, instruct, raw
    
    case "$format" in
        "chat")
            cat << EOF
System: $system_prompt
User: $user_prompt
EOF
            ;;
        "instruct")
            cat << EOF
### System:
$system_prompt

### Human:
$user_prompt

### Assistant:
EOF
            ;;
        "raw")
            echo "$user_prompt"
            ;;
    esac
}

function model_parse_response() {
    local response="$1"
    local format="${2:-json}"  # json, text, markdown
    
    case "$format" in
        "json")
            if validate_json "$response"; then
                echo "$response" | jq '.'
            else
                # Wrap non-JSON response
                jq -n --arg response "$response" '{response: $response, format: "text"}'
            fi
            ;;
        "markdown")
            # Add markdown formatting if not present
            if [[ "$response" != *"#"* && "$response" != *"**"* ]]; then
                echo "## Response"
                echo ""
                echo "$response"
            else
                echo "$response"
            fi
            ;;
        *)
            echo "$response"
            ;;
    esac
}

function model_estimate_tokens() {
    local text="$1"
    local model_type="${2:-gpt}"  # gpt, claude, llama
    
    # Rough token estimation (varies by model)
    local char_count=${#text}
    local word_count=$(echo "$text" | wc -w)
    
    case "$model_type" in
        "gpt"|"openai")
            # ~4 chars per token for GPT models
            echo $((char_count / 4))
            ;;
        "claude"|"anthropic")
            # ~3.5 chars per token for Claude
            echo $((char_count * 10 / 35))
            ;;
        "llama")
            # ~4.2 chars per token for LLaMA
            echo $((char_count * 10 / 42))
            ;;
        *)
            # Default estimation
            echo $((word_count * 4 / 3))
            ;;
    esac
}

function model_truncate_to_tokens() {
    local text="$1"
    local max_tokens="$2"
    local model_type="${3:-gpt}"
    
    local estimated_tokens=$(model_estimate_tokens "$text" "$model_type")
    
    if [[ $estimated_tokens -gt $max_tokens ]]; then
        # Calculate approximate character limit
        local chars_per_token
        case "$model_type" in
            "gpt") chars_per_token=4 ;;
            "claude") chars_per_token=3.5 ;;
            "llama") chars_per_token=4.2 ;;
            *) chars_per_token=4 ;;
        esac
        
        local max_chars=$(echo "$max_tokens * $chars_per_token" | bc)
        echo "${text:0:$max_chars}..."
    else
        echo "$text"
    fi
}

function model_clean_response() {
    local response="$1"
    
    # Remove common unwanted patterns
    response=$(echo "$response" | sed 's/^Assistant: //')
    response=$(echo "$response" | sed 's/^AI: //')
    response=$(echo "$response" | sed 's/^Response: //')
    
    # Remove excessive newlines
    response=$(echo "$response" | sed '/^$/N;/^\n$/d')
    
    # Trim whitespace
    response=$(echo "$response" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    echo "$response"
}

function model_add_context_markers() {
    local text="$1"
    local context_type="$2"  # conversation, memory, system
    
    case "$context_type" in
        "conversation")
            echo "<!-- CONVERSATION_CONTEXT -->"
            echo "$text"
            echo "<!-- /CONVERSATION_CONTEXT -->"
            ;;
        "memory")
            echo "<!-- MEMORY_CONTEXT -->"
            echo "$text"
            echo "<!-- /MEMORY_