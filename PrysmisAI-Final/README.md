# PrysmisAI

Advanced Roblox Game Development AI powered by Ollama Llama 3.2

## Setup Instructions

### Prerequisites
- Node.js (v14 or higher)
- Ollama installed and running on your system

### Installation

1. Install dependencies:
```bash
npm install
```

2. Set up the PrysmisAI model:
```bash
npm run setup-ollama
```

This will:
- Pull the Llama 3.2 model from Ollama
- Create a custom "PrysmisAI" model with specialized Roblox development prompts
- Configure the model for optimal performance

3. Start the server:
```bash
npm start
```

The application will be available at `http://localhost:3000`

## Features

- **AI Chat Interface**: Interact with PrysmisAI for Roblox development assistance
- **Script Generation**: Generate Lua/Luau scripts for Roblox Studio
- **Code Debugging**: Get help fixing errors and optimizing code
- **Studio Integration**: Connect with Roblox Studio plugin for seamless workflow
- **Image Analysis**: Upload screenshots for visual debugging and analysis

## Model Configuration

The PrysmisAI model is configured with:
- Base model: Llama 3.2
- Temperature: 0.7 (balanced creativity)
- Max tokens: 4096
- Specialized system prompt for Roblox development

## Environment Variables

Optional environment variables:
- `PORT`: Server port (default: 3000)
- `OLLAMA_BASE_URL`: Ollama API URL (default: http://localhost:11434)

## Usage

1. Navigate to `http://localhost:3000`
2. Click "Get started" to create an account or "Try the AI" for direct access
3. Start chatting with PrysmisAI about your Roblox development needs

## Plugin Integration

To connect with Roblox Studio:
1. Generate a token in Settings > Studio
2. Install the PrysmisAI Studio plugin
3. Use the token to connect your workspace

## Troubleshooting

- Ensure Ollama is running before starting the server
- Verify the PrysmisAI model was created successfully with `ollama list`
- Check that port 3000 is available if using default settings
