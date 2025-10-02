# Changelog - Red Hat Family Day 2025 AI Vision Quest

## Version 0.2 - Enhanced Qwen Model & Kid-Friendly Improvements

### 🎯 Major Changes

#### Model Upgrade
- **Changed from:** SmolVLM-500M-Instruct (500M parameters)
- **Changed to:** Qwen/Qwen2-VL-2B-Instruct (2B parameters)
- **Benefits:**
  - 4x larger model with significantly better instruction following
  - Reliable YES/NO responses for game challenges
  - Better vision understanding for objects, emotions, and actions
  - Optimized for real-time family gameplay

#### Request Interval
- **Default changed from:** 2 seconds → 1 second
- **Reason:** Faster gameplay for kids, Qwen2-VL-2B can handle it

#### AI Response Enhancements
1. **Added Explanations**
   - AI now explains WHY it says YES or NO
   - Format: "YES - I can see a red book in the image"
   - Helps kids understand the AI's reasoning

2. **Smarter Validation Logic**
   - Primary: Checks for explicit "YES" at start
   - Fallback: Infers positive response from descriptions
   - Safety: Overrides to NO if negative keywords detected
   - Example: "You are holding a book" → Automatically awards points

3. **Better Prompts**
   - Added "IMPORTANT: You MUST start with YES if you see [item]"
   - Clearer formatting instructions for AI
   - More reliable for consistent responses

#### UI Improvements
1. **Styled Challenge Selection Modal**
   - Replaced plain alert() with beautiful modal
   - Matches leaderboard and name modal design
   - Kid-friendly with emojis and animations
   - Keyboard support (ESC/Enter to close)

2. **Enhanced Response Display**
   - Shows "✅ AI SAYS YES!" with explanation
   - Shows "❌ AI SAYS NO" with reasoning
   - Clear feedback for open-ended questions

### 📝 Documentation Updates

All documentation updated to reflect Qwen2-VL-2B-Instruct:
- ✅ deploy-to-openshift.sh
- ✅ PRODUCTION_README.md
- ✅ PRODUCTION_DEPLOYMENT.md
- ✅ CONTAINER_DEPLOYMENT.md
- ✅ QUICK_START.md

### 🔧 Technical Details

#### Prompt Engineering
```
IMPORTANT: If you see [item], you MUST start with YES. If you don't see it, start with NO.

Format: YES - [reason] or NO - [reason]
```

#### Validation Logic
```javascript
// Layer 1: Explicit YES
if (response starts with "YES") → Award points

// Layer 2: Affirmative Inference
if (response contains "holding", "I see", "there is", etc.) → Award points

// Layer 3: Negative Override
if (response contains "no", "not", "don't") → Reject
```

#### Token Limits
- Increased from 50 to 100 tokens for explanation support
- Temperature: 0 (maximum determinism)

### 🎮 Game Experience Improvements

**Before:**
- AI often didn't follow YES/NO format
- False negatives (AI sees item but doesn't say YES)
- Plain alert dialogs
- 2-second delay felt slow

**After:**
- Reliable YES/NO responses with explanations
- Smart inference catches correct answers
- Beautiful themed modals
- 1-second delay keeps kids engaged

### 🚀 Production Ready

- Container image: `quay.io/rh_ee_micyang/family-day-web-prod:0.1`
- Works with Red Hat AI Inference Server (vLLM)
- Cross-namespace OpenShift deployment supported
- Health checks and resource limits configured

### 📊 Model Comparison

| Feature | SmolVLM-500M | Qwen2-VL-2B |
|---------|--------------|-------------|
| Size | 500M params | 2B params |
| VRAM | ~2GB | ~4GB |
| Instruction Following | ⭐ Poor | ⭐⭐⭐⭐ Very Good |
| Vision Quality | ⭐⭐ Fair | ⭐⭐⭐⭐ Very Good |
| Speed | ⚡⚡⚡ Very Fast | ⚡⚡ Fast |
| Kid-Friendly | ❌ Frustrating | ✅ Great! |

### 🎉 Result

The game is now:
- ✅ More fun for kids (faster, clearer feedback)
- ✅ More accurate (better AI, smarter validation)
- ✅ More transparent (explanations included)
- ✅ More polished (styled modals, better UX)

Perfect for Red Hat Family Day 2025! 🎩👨‍👩‍👧‍👦

