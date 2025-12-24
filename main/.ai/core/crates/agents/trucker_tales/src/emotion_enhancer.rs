// Emotion Enhancer - The soul of the stories
// Words carry weight. Emotions carry truth.

use anyhow::Result;
use crate::EmotionAnalysis;

pub struct EmotionEnhancer {}

impl EmotionEnhancer {
    pub fn new() -> Self {
        Self {}
    }
    
    pub async fn analyze(&self, content: &str) -> Result<EmotionAnalysis> {
        // Simple keyword-based emotion detection
        // In production, use a proper sentiment analysis model
        
        let lower = content.to_lowercase();
        
        let joy = self.detect_emotion(&lower, &[
            "happy", "great", "awesome", "love", "beautiful", "perfect",
            "amazing", "wonderful", "excited", "proud",
        ]);
        
        let fear = self.detect_emotion(&lower, &[
            "scared", "afraid", "nervous", "worried", "dangerous", "terrified",
            "panic", "fear", "anxious", "scary",
        ]);
        
        let anger = self.detect_emotion(&lower, &[
            "angry", "mad", "pissed", "furious", "hate", "stupid",
            "annoyed", "frustrated", "rage", "damn",
        ]);
        
        let sadness = self.detect_emotion(&lower, &[
            "sad", "depressed", "lonely", "miss", "hurt", "cry",
            "tears", "loss", "grief", "heartbreak",
        ]);
        
        let pride = self.detect_emotion(&lower, &[
            "proud", "accomplished", "achievement", "success", "victory",
            "conquered", "made it", "nailed it", "pulled through",
        ]);
        
        // Calculate overall sentiment
        let overall = (joy + pride) - (fear + anger + sadness);
        
        Ok(EmotionAnalysis {
            joy,
            fear,
            anger,
            sadness,
            pride,
            overall_sentiment: overall.clamp(-1.0, 1.0),
        })
    }
    
    fn detect_emotion(&self, text: &str, keywords: &[&str]) -> f32 {
        let mut score = 0.0;
        let words: Vec<&str> = text.split_whitespace().collect();
        
        for keyword in keywords {
            let count = words.iter().filter(|w| w.contains(keyword)).count();
            score += count as f32 * 0.2;
        }
        
        score.min(1.0)
    }
    
    pub fn enhance_narrative(&self, content: &str, emotion: &EmotionAnalysis) -> String {
        // Add emotional context markers
        let mut enhanced = content.to_string();
        
        if emotion.overall_sentiment > 0.5 {
            enhanced.push_str("\n\n[This was a moment of triumph.]");
        } else if emotion.overall_sentiment < -0.5 {
            enhanced.push_str("\n\n[This was a hard moment.]");
        }
        
        if emotion.fear > 0.6 {
            enhanced.push_str("\n[Fear was real here.]");
        }
        
        if emotion.pride > 0.6 {
            enhanced.push_str("\n[Pride earned.]");
        }
        
        enhanced
    }
}
