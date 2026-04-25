## Usage
chmod +x multi_llm_chat.sh

## insert api key
ES 
ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-metti-la-tua-key}"
OPENAI_API_KEY="${OPENAI_API_KEY:-metti-la-tua-key}"
GEMINI_API_KEY="${GEMINI_API_KEY:-metti-la-tua-key}"
OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-inserire apykey}"
GROQ_API_KEY="${GROQ_API_KEY:-inserire apikey}"


./multi_llm_chat.sh
