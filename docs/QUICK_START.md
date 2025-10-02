# 🚀 Quick Start Guide - AI Vision Quest

## Setup in 5 Minutes!

### Step 1: Start Your AI Model Server
You need to have either **vLLM** (recommended for production), **Ollama**, or **llama.cpp** running with a vision model.

#### Option A: Using vLLM on OpenShift (Production - Recommended)
For production deployment with Qwen2-VL-2B-Instruct, see **PRODUCTION_DEPLOYMENT.md** or **PRODUCTION_README.md**.

The production version (`prod-index.html`) uses:
- **Model:** Qwen/Qwen2-VL-2B-Instruct (2B parameters)
- **Server:** Red Hat AI Inference Server (vLLM)
- **Benefits:** Better instruction following, faster responses, kid-friendly

#### Option B: Using Ollama (Local Development)
```bash
# Install Ollama if you haven't
# Download from: https://ollama.ai

# Pull a vision model (SmolVLM for testing, Qwen for better performance)
ollama pull hf.co/ggml-org/SmolVLM-500M-Instruct-GGUF:Q8_0

# Start Ollama with CORS enabled
OLLAMA_ORIGINS=* ollama serve
```

#### Option C: Using llama.cpp
```bash
# Start llama.cpp server with CORS enabled
./server --model your-vision-model.gguf --cors
```

---

### Step 2: Open the Game
Simply open `index.html` in a web browser (Chrome recommended)

Or serve it with a simple HTTP server:
```bash
# Python 3
python -m http.server 8000

# Node.js
npx http-server -p 8000
```

Then visit: `http://localhost:8000`

---

### Step 3: Configure API Connection

1. **Click "Test Connection"** button to verify your AI server is running
2. **Select a game mode** (Scavenger Hunt is great to start!)
3. **Allow camera access** when prompted
4. **Click "Start Game! 🎮"** and have fun!

---

## 🎮 How to Play

### For Kids:
1. Pick a challenge from the right panel (with fun icons!)
2. Click the "Start Game" button
3. Show the camera what the challenge asks for
4. The AI will tell you if you got it right!
5. Earn points and add your name to the leaderboard!

### For Parents/Organizers:
- Challenges automatically rotate based on game mode
- Click "New Challenges" to refresh the challenge list
- Switch between game modes using the buttons
- The scoreboard tracks everything automatically
- Leaderboard shows top 10 players with persistence
- Each challenge can only be completed once per game

---

## 🎯 Game Modes Explained

### 🔍 Scavenger Hunt
Find objects around you! Great for getting kids moving.
- "Find something red!"
- "Show me a book!"
- "Find something round!"
- "Show me a phone or tablet!"

### 😊 Emotion Detective  
Make funny faces and expressions!
- "Show me a happy face! 😊"
- "Make a surprised face! 😮"
- "Can you look silly? 🤪"
- "Show me a cool face! 😎"

### 🎨 Color Explorer
All about colors and visual recognition!
- "Find something yellow!"
- "Show me 3 different colors!"
- "Find the brightest thing!"
- "Show me something purple!"

### 🔢 Counting Challenge
Numbers and quantities!
- "Show me 2 things!"
- "How many fingers?"
- "Find 3 different objects!"
- "Show me 5 fingers!"

### 🤸 Actions Mode
Get moving with action challenges!
- "Wave hello to the camera!"
- "Give a thumbs up! 👍"
- "Clap your hands!"
- "Jump up and down!"
- "Do a silly dance!"
- "Make a heart with your hands! ❤️"

### ✋ Body Parts Mode
Show specific body parts!
- "Show me your hands!"
- "Point to your eyes!"
- "Show me your feet!"
- "Touch your ears!"
- "Wiggle your fingers!"

### 🧘 Extreme Yoga (Full-Width Special Mode!)
Strike a pose! Don't need to be perfect, just try!
- "Stand like a tree! 🌳" (one foot up, arms high)
- "Make a star pose! ⭐" (arms and legs wide)
- "Do warrior pose! ⚔️" (lunge with arms out)
- "Airplane pose! ✈️" (balance on one leg)
- "Superhero pose! 🦸" (hands on hips)
- "Downward dog! 🐕" (make a triangle)

---

## ⚙️ Settings

### Request Interval
How often the AI checks the camera:
- **1 second** (default) - Good balance for families
- **500ms** - Faster, more responsive
- **250ms** - Very fast, for advanced players

### API Endpoint
- **llama.cpp**: `http://localhost:8080` (default)
- **Ollama**: `http://localhost:11434`
- Use preset buttons for quick setup!

---

## 🏆 Scoring & Leaderboard

### Points
- **Easy challenges**: 10-15 points 🟢
- **Medium challenges**: 20-25 points 🟡  
- **Hard challenges**: 30-35 points 🔴
- **Streak bonus**: Keep going for bigger scores!

### Leaderboard Features
- 🏅 Automatically shows top 10 players
- 📝 Enter your name after each game
- 💾 Scores saved in browser (localStorage)
- 🥇 Special styling for top 3 (Gold, Silver, Bronze)
- 🔒 Password-protected clearing (password: `2025`)

### Name Entry
- After each game with score > 0, you'll be asked for your name
- Choose to add to leaderboard or skip
- Name entry required every game (great for multiple players!)

---

## 🎨 Challenge Features

### Visual Icons
Each challenge has a unique icon:
- 🔴 Red items
- 📚 Books
- 😊 Happy faces
- 🧘 Yoga poses
- And many more!

### Challenge Completion
- ✅ Each challenge can only be completed once per game
- Completed challenges show a checkmark
- Prevents point exploitation
- Fresh challenges when switching modes

### Dynamic AI Prompts
- AI instructions update based on specific challenge
- Highlights exactly what to look for (in UPPERCASE)
- Default to "NO" for accuracy
- Clear YES/NO criteria

---

## 🐛 Troubleshooting

### Camera not working?
- Make sure you allowed camera permissions
- Try using HTTPS or localhost
- Check if another app is using the camera

### AI not responding?
- Click "Test Connection" to verify server is running
- Check the API endpoint is correct
- Make sure the model is loaded in Ollama/llama.cpp
- Check browser console for errors (F12)

### AI always says YES or NO?
- The AI now defaults to "NO" for accuracy
- Only says "YES" when clearly seeing the requested item
- This makes the game more challenging and fair!

### CORS errors?
For Ollama:
```bash
OLLAMA_ORIGINS=* ollama serve
```

For llama.cpp:
```bash
./server --model your-model.gguf --cors
```

### Leaderboard not showing?
- Scores are saved in browser localStorage
- Clearing browser data will reset leaderboard
- Each browser/device has its own leaderboard

---

## 📱 Mobile/Tablet Use

This works great on tablets!
- Use landscape orientation for best experience
- Camera permissions may need special settings
- Consider using a stand for the tablet
- External camera can be connected if needed
- Responsive design adapts to screen size

---

## 🎪 Multi-Station Setup

Running multiple stations? Here's the quick setup:

1. Copy the entire folder to each device
2. Point all devices to the same Ollama/llama.cpp server
3. Or run separate servers on each device
4. Each station maintains its own leaderboard
5. Combine scores manually for event-wide rankings

---

## 💡 Tips for Success

✅ **Test everything** before the event
✅ **Good lighting** makes AI work better
✅ **Have props** ready for finding challenges  
✅ **Explain rules** clearly to kids
✅ **Encourage everyone** regardless of score
✅ **Take photos** of high scores!
✅ **Show kids** how to select different challenges
✅ **Let them explore** all 7 game modes!

---

## 🎮 Game Controls

### Keyboard Shortcuts
- **Spacebar**: Start/Stop game
- **Enter**: Submit name in modal

### Button Controls
- **Start Game**: Begin playing
- **Stop Game**: End current session
- **New Challenges**: Refresh challenge list
- **Award Points**: Manual scoring for open-ended challenges
- **Test Connection**: Verify AI server
- **Dark Mode**: Toggle theme

---

## 🌟 Special Features

### Open-Ended Challenges
Some challenges need description (not YES/NO):
- "What colors do you see?"
- "How many fingers am I holding up?"
- "Count the objects you can see!"

For these, use the green "✅ Award Points" button manually.

### Auto-Scoring Challenges
Most challenges auto-score when AI says YES:
- Flash effect on success
- Confetti animation
- Success sound
- Points added automatically

---

## 🎉 Next Steps

Want to enhance the game? Check out `FAMILY_DAY_IDEAS.md` for:
- Tournament structures
- Team building activities
- Advanced features
- Event planning tips
- And much more!

**Enjoy your AI Vision Quest! 🎮✨**
