#!/bin/bash

# ============================================================
#  Multi-LLM Chatbot
#  Claude | GPT-4o | Gemini | OpenRouter | Groq
# ============================================================

ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-metti-la-tua-key}"
OPENAI_API_KEY="${OPENAI_API_KEY:-metti-la-tua-key}"
GEMINI_API_KEY="${GEMINI_API_KEY:-metti-la-tua-key}"
OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-inserire apykey}"
GROQ_API_KEY="${GROQ_API_KEY:-inserire apice}"

# Colori
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
ORANGE='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

# ============================================================
#  Modelli disponibili
# ============================================================
OPENROUTER_MODELS=(
    "nvidia/nemotron-3-super-120b-a12b:free|nemotron (Nvidia)"
    "google/gemma-3-27b-it:free|Gemma 3 27B (Google)"
    "deepseek/deepseek-r1:free|DeepSeek R1"
    "mistralai/mistral-7b-instruct:free|Mistral 7B"
    "microsoft/phi-4-reasoning:free|Phi-4 Reasoning (Microsoft)"
    "qwen/qwen3-14b:free|Qwen3 14B (Alibaba)"
)

GROQ_MODELS=(
    "llama-3.3-70b-versatile|Llama 3.3 70B"
    "llama3-8b-8192|Llama 3 8B"
    "mixtral-8x7b-32768|Mixtral 8x7B"
    "gemma2-9b-it|Gemma 2 9B"
    "deepseek-r1-distill-llama-70b|DeepSeek R1 Distill 70B"
)

# Stato globale — mai dentro $() per evitare subshell
SELECTED_OR_MODEL="nvidia/nemotron-3-super-120b-a12b:free"
SELECTED_OR_LABEL="nemotron (Nvidia)"
SELECTED_GROQ_MODEL="llama-3.3-70b-versatile"
SELECTED_GROQ_LABEL="Llama 3.3 70B"
CURRENT_MODEL="openrouter"

# ============================================================
#  Escape JSON sicuro tramite argomento (niente pipe)
# ============================================================
json_escape() {
    python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$1"
}

# ============================================================
#  Label del modello (stampa diretta, non catturata)
# ============================================================
print_model_label() {
    case "$1" in
        claude)     echo -e "${BLUE}🤖 Claude${RESET}" ;;
        gpt)        echo -e "${GREEN}🟢 GPT-4o${RESET}" ;;
        gemini)     echo -e "${YELLOW}✨ Gemini${RESET}" ;;
        openrouter) echo -e "${MAGENTA}🔀 OpenRouter ${CYAN}[$SELECTED_OR_LABEL]${RESET}" ;;
        groq)       echo -e "${ORANGE}⚡ Groq ${CYAN}[$SELECTED_GROQ_LABEL]${RESET}" ;;
    esac
}

model_name() {
    case "$1" in
        claude)     echo "Claude" ;;
        gpt)        echo "GPT-4o" ;;
        gemini)     echo "Gemini" ;;
        openrouter) echo "OpenRouter [$SELECTED_OR_LABEL]" ;;
        groq)       echo "Groq [$SELECTED_GROQ_LABEL]" ;;
    esac
}

# ============================================================
#  Funzioni LLM — risultato in variabile globale LLM_RESPONSE
# ============================================================
LLM_RESPONSE=""

ask_claude() {
    local json_prompt
    json_prompt=$(json_escape "$1")
    local raw
    raw=$(curl -s https://api.anthropic.com/v1/messages \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "{\"model\":\"claude-opus-4-5\",\"max_tokens\":1024,\"messages\":[{\"role\":\"user\",\"content\":$json_prompt}]}")
    local err
    err=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d.get('error',{}).get('message',''))" "$raw" 2>/dev/null)
    if [[ -n "$err" && "$err" != "None" ]]; then
        LLM_RESPONSE="${RED}[Errore Claude: $err]${RESET}"
    else
        LLM_RESPONSE=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d['content'][0]['text'])" "$raw" 2>/dev/null)
        [[ -z "$LLM_RESPONSE" ]] && LLM_RESPONSE="${RED}[Errore Claude: risposta vuota]${RESET}"
    fi
}

ask_gpt() {
    local json_prompt
    json_prompt=$(json_escape "$1")
    local raw
    raw=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"gpt-4o\",\"messages\":[{\"role\":\"user\",\"content\":$json_prompt}]}")
    local err
    err=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d.get('error',{}).get('message',''))" "$raw" 2>/dev/null)
    if [[ -n "$err" && "$err" != "None" ]]; then
        LLM_RESPONSE="${RED}[Errore GPT: $err]${RESET}"
    else
        LLM_RESPONSE=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d['choices'][0]['message']['content'])" "$raw" 2>/dev/null)
        [[ -z "$LLM_RESPONSE" ]] && LLM_RESPONSE="${RED}[Errore GPT: risposta vuota]${RESET}"
    fi
}

ask_gemini() {
    local json_prompt
    json_prompt=$(json_escape "$1")
    local raw
    raw=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$GEMINI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"contents\":[{\"parts\":[{\"text\":$json_prompt}]}]}")
    local err
    err=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d.get('error',{}).get('message',''))" "$raw" 2>/dev/null)
    if [[ -n "$err" && "$err" != "None" ]]; then
        LLM_RESPONSE="${RED}[Errore Gemini: $err]${RESET}"
    else
        LLM_RESPONSE=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d['candidates'][0]['content']['parts'][0]['text'])" "$raw" 2>/dev/null)
        [[ -z "$LLM_RESPONSE" ]] && LLM_RESPONSE="${RED}[Errore Gemini: risposta vuota]${RESET}"
    fi
}

ask_openrouter() {
    local json_prompt
    json_prompt=$(json_escape "$1")
    local raw
    raw=$(curl -s https://openrouter.ai/api/v1/chat/completions \
        -H "Authorization: Bearer $OPENROUTER_API_KEY" \
        -H "Content-Type: application/json" \
        -H "HTTP-Referer: https://github.com/multi-llm-bash" \
        -H "X-Title: Multi-LLM Bash Chat" \
        -d "{\"model\":\"$SELECTED_OR_MODEL\",\"messages\":[{\"role\":\"user\",\"content\":$json_prompt}]}")
    local err
    err=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d.get('error',{}).get('message',''))" "$raw" 2>/dev/null)
    if [[ -n "$err" && "$err" != "None" ]]; then
        LLM_RESPONSE="${RED}[Errore OpenRouter: $err]${RESET}"
    else
        LLM_RESPONSE=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d['choices'][0]['message']['content'])" "$raw" 2>/dev/null)
        [[ -z "$LLM_RESPONSE" ]] && LLM_RESPONSE="${RED}[Errore OpenRouter: risposta vuota]${RESET}"
    fi
}

ask_groq() {
    local json_prompt
    json_prompt=$(json_escape "$1")
    local raw
    raw=$(curl -s https://api.groq.com/openai/v1/chat/completions \
        -H "Authorization: Bearer $GROQ_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"$SELECTED_GROQ_MODEL\",\"max_tokens\":1024,\"messages\":[{\"role\":\"user\",\"content\":$json_prompt}]}")
    local err
    err=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d.get('error',{}).get('message',''))" "$raw" 2>/dev/null)
    if [[ -n "$err" && "$err" != "None" ]]; then
        LLM_RESPONSE="${RED}[Errore Groq: $err]${RESET}"
    else
        LLM_RESPONSE=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d['choices'][0]['message']['content'])" "$raw" 2>/dev/null)
        [[ -z "$LLM_RESPONSE" ]] && LLM_RESPONSE="${RED}[Errore Groq: risposta vuota]${RESET}"
    fi
}

call_llm() {
    case "$1" in
        claude)      ask_claude "$2" ;;
        gpt)         ask_gpt "$2" ;;
        gemini)      ask_gemini "$2" ;;
        openrouter)  ask_openrouter "$2" ;;
        groq)        ask_groq "$2" ;;
    esac
}

# ============================================================
#  Selezione modello OpenRouter — scrive in globale, no $()
# ============================================================
choose_openrouter_model() {
    echo -e "\n${BOLD}${MAGENTA}Modelli OpenRouter gratuiti:${RESET}"
    local i=1
    for entry in "${OPENROUTER_MODELS[@]}"; do
        echo -e "  ${CYAN}$i)${RESET} ${entry##*|}  ${YELLOW}(free)${RESET}"
        ((i++))
    done
    echo -ne "\n${BOLD}Scelta [1-${#OPENROUTER_MODELS[@]}]: ${RESET}"
    read -r choice
    local idx=$((choice-1))
    if [[ $idx -ge 0 && $idx -lt ${#OPENROUTER_MODELS[@]} ]]; then
        SELECTED_OR_MODEL="${OPENROUTER_MODELS[$idx]%%|*}"
        SELECTED_OR_LABEL="${OPENROUTER_MODELS[$idx]##*|}"
        echo -e "✅ Selezionato: ${CYAN}$SELECTED_OR_LABEL${RESET}"
    else
        echo -e "${RED}Scelta non valida, rimane: $SELECTED_OR_LABEL${RESET}"
    fi
}

# ============================================================
#  Selezione modello Groq — scrive in globale, no $()
# ============================================================
choose_groq_model() {
    echo -e "\n${BOLD}${ORANGE}Modelli Groq gratuiti:${RESET}"
    local i=1
    for entry in "${GROQ_MODELS[@]}"; do
        echo -e "  ${CYAN}$i)${RESET} ${entry##*|}  ${GREEN}(free)${RESET}"
        ((i++))
    done
    echo -ne "\n${BOLD}Scelta [1-${#GROQ_MODELS[@]}]: ${RESET}"
    read -r choice
    local idx=$((choice-1))
    if [[ $idx -ge 0 && $idx -lt ${#GROQ_MODELS[@]} ]]; then
        SELECTED_GROQ_MODEL="${GROQ_MODELS[$idx]%%|*}"
        SELECTED_GROQ_LABEL="${GROQ_MODELS[$idx]##*|}"
        echo -e "✅ Selezionato: ${CYAN}$SELECTED_GROQ_LABEL${RESET}"
    else
        echo -e "${RED}Scelta non valida, rimane: $SELECTED_GROQ_LABEL${RESET}"
    fi
}

# ============================================================
#  Selezione modello principale — scrive in CURRENT_MODEL, no $()
# ============================================================
choose_model() {
    echo -e "\n${BOLD}Scegli il modello principale:${RESET}"
    echo -e "  ${BLUE}1) Claude${RESET}          ${RED}(a pagamento)${RESET}"
    echo -e "  ${GREEN}2) GPT-4o${RESET}          ${RED}(a pagamento)${RESET}"
    echo -e "  ${YELLOW}3) Gemini${RESET}          ${RED}(a pagamento)${RESET}"
    echo -e "  ${MAGENTA}4) OpenRouter${RESET}      ${GREEN}(gratis ✓)${RESET}"
    echo -e "  ${ORANGE}5) Groq${RESET}            ${GREEN}(gratis ✓)${RESET}"
    echo -ne "\n${BOLD}Scelta [1-5]: ${RESET}"
    read -r choice
    case "$choice" in
        1) CURRENT_MODEL="claude" ;;
        2) CURRENT_MODEL="gpt" ;;
        3) CURRENT_MODEL="gemini" ;;
        4) choose_openrouter_model; CURRENT_MODEL="openrouter" ;;
        5) choose_groq_model; CURRENT_MODEL="groq" ;;
        *) echo -e "${YELLOW}Scelta non valida, uso OpenRouter.${RESET}"; CURRENT_MODEL="openrouter" ;;
    esac
}

# ============================================================
#  Analisi incrociata
# ============================================================
do_analyze() {
    local primary_model="$1"
    local last_prompt="$2"
    local last_response="$3"

    echo -e "\n${CYAN}${BOLD}══════════════════════════════════════════${RESET}"
    echo -e "${CYAN}  🔍 Analisi Incrociata${RESET}"
    echo -e "${CYAN}${BOLD}══════════════════════════════════════════${RESET}"
    echo -e "\n${BOLD}Quale modello analizzerà la risposta?${RESET}"

    local i=1
    local models_list=()
    for m in claude gpt gemini openrouter groq; do
        [[ "$m" == "$primary_model" ]] && continue
        echo -ne "  ${CYAN}$i)${RESET} "
        print_model_label "$m"
        models_list+=("$m")
        ((i++))
    done

    echo -ne "\nScelta [1-$((i-1))]: "
    read -r achoice
    local analyzer="${models_list[$((achoice-1))]}"
    if [[ -z "$analyzer" ]]; then
        echo -e "${RED}Scelta non valida.${RESET}"
        return
    fi

    echo -ne "\n${BOLD}Istruzione per l'analisi${RESET} (INVIO = generica): "
    read -r instruction
    [[ -z "$instruction" ]] && instruction="Analizza criticamente questa risposta: evidenzia punti di forza, debolezze e aggiungi integrazioni utili."

    local analysis_prompt="Domanda originale: \"$last_prompt\"

Risposta da analizzare:
---
$last_response
---

Istruzione: $instruction"

    echo -ne "\n⏳ "
    print_model_label "$analyzer"
    echo -e " sta analizzando...\n"
    call_llm "$analyzer" "$analysis_prompt"

    echo -e "${BOLD}📊 Analisi di $(model_name "$analyzer"):${RESET}"
    echo -e "${CYAN}──────────────────────────────────────────${RESET}"
    echo -e "$LLM_RESPONSE"
    echo -e "${CYAN}──────────────────────────────────────────${RESET}"
}

# ============================================================
#  Compare: stessa domanda a tutti
# ============================================================
do_compare() {
    echo -ne "${BOLD}Domanda da inviare a tutti: ${RESET}"
    read -r compare_prompt
    [[ -z "$compare_prompt" ]] && echo -e "${RED}Domanda vuota.${RESET}" && return
    echo -e "\n${BOLD}📡 Invio a tutti i modelli...${RESET}"
    for m in claude gpt gemini openrouter groq; do
        echo -ne "\n⏳ "
        print_model_label "$m"
        echo -e " sta pensando..."
        call_llm "$m" "$compare_prompt"
        echo -e "\n${BOLD}$(model_name "$m"):${RESET}"
        echo -e "──────────────────────────────────────────"
        echo -e "$LLM_RESPONSE"
        echo -e "──────────────────────────────────────────"
    done
}

# ============================================================
#  Help
# ============================================================
show_help() {
    echo -e "\n${BOLD}╔══════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}║           Comandi disponibili            ║${RESET}"
    echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
    echo -e "  ${YELLOW}/switch${RESET}        Cambia modello principale"
    echo -e "  ${YELLOW}/model or${RESET}      Cambia modello OpenRouter"
    echo -e "  ${YELLOW}/model groq${RESET}    Cambia modello Groq"
    echo -e "  ${YELLOW}/analyze${RESET}       Analisi incrociata sull'ultima risposta"
    echo -e "  ${YELLOW}/compare${RESET}       Stessa domanda a TUTTI i modelli"
    echo -e "  ${YELLOW}/help${RESET}          Mostra questi comandi"
    echo -e "  ${YELLOW}/exit${RESET}          Esci\n"
}

# ============================================================
#  Main
# ============================================================
main() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║        🧠 Multi-LLM Chatbot              ║"
    echo "  ║  Claude · GPT · Gemini · OR · Groq       ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e "  ${GREEN}✓ OpenRouter e Groq sono GRATUITI${RESET} — ottimi per iniziare!"
    echo -e "  Digita ${YELLOW}/help${RESET} per vedere tutti i comandi.\n"

    # Selezione iniziale — scrive direttamente in CURRENT_MODEL (no subshell)
    choose_model

    echo -ne "\n✅ Modello attivo: "
    print_model_label "$CURRENT_MODEL"
    echo ""

    local last_prompt=""
    local last_response=""

    while true; do
        echo -ne "\n${BOLD}Tu: ${RESET}"
        read -r user_input

        [[ -z "$user_input" ]] && continue

        case "$user_input" in
            /exit)
                echo -e "\n👋 Arrivederci!\n"
                exit 0
                ;;
            /help)
                show_help
                ;;
            /switch)
                choose_model
                echo -ne "✅ Modello: "
                print_model_label "$CURRENT_MODEL"
                ;;
            "/model or")
                choose_openrouter_model
                ;;
            "/model groq")
                choose_groq_model
                ;;
            /analyze)
                if [[ -z "$last_response" ]]; then
                    echo -e "${RED}Fai prima una domanda normale.${RESET}"
                else
                    do_analyze "$CURRENT_MODEL" "$last_prompt" "$last_response"
                fi
                ;;
            /compare)
                do_compare
                ;;
            /*)
                echo -e "${RED}Comando non riconosciuto. Digita /help per la lista.${RESET}"
                ;;
            *)
                last_prompt="$user_input"
                echo -ne "\n⏳ "
                print_model_label "$CURRENT_MODEL"
                echo -e " sta pensando...\n"

                call_llm "$CURRENT_MODEL" "$user_input"
                last_response="$LLM_RESPONSE"

                echo -e "${BOLD}$(model_name "$CURRENT_MODEL"):${RESET}"
                echo -e "──────────────────────────────────────────"
                echo -e "$last_response"
                echo -e "──────────────────────────────────────────"
                echo -e "${YELLOW}💡 /analyze → analisi incrociata  |  /compare → tutti i modelli${RESET}"
                ;;
        esac
    done
}

main
