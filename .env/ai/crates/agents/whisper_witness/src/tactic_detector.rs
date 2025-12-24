// Tactic Detector - Recognizes broker manipulation patterns
// This is the intelligence that spots the BS

use anyhow::Result;
use regex::Regex;
use crate::{BrokerTactic, TacticDetection, TacticSeverity, TranscriptLine};

#[derive(Clone)]
pub struct TacticDetector {
    patterns: Vec<TacticPattern>,
}

struct TacticPattern {
    tactic: BrokerTactic,
    severity: TacticSeverity,
    patterns: Vec<Regex>,
    keywords: Vec<&'static str>,
}

impl TacticDetector {
    pub fn new() -> Result<Self> {
        Ok(Self {
            patterns: Self::load_patterns(),
        })
    }
    
    pub fn analyze_text(
        &self,
        text: &str,
        context: &[TranscriptLine],
    ) -> Result<Vec<TacticDetection>> {
        let text_lower = text.to_lowercase();
        let mut detections = Vec::new();
        
        for pattern in &self.patterns {
            // Check regex patterns
            for regex in &pattern.patterns {
                if regex.is_match(&text_lower) {
                    detections.push(TacticDetection {
                        tactic: pattern.tactic.clone(),
                        confidence: 0.85,
                        trigger_phrase: text.to_string(),
                        context: Self::get_context(context, 3),
                        timestamp: chrono::Utc::now(),
                        severity: pattern.severity.clone(),
                    });
                    break;
                }
            }
            
            // Check keywords
            let keyword_matches: usize = pattern.keywords.iter()
                .filter(|k| text_lower.contains(*k))
                .count();
            
            if keyword_matches >= 2 {
                detections.push(TacticDetection {
                    tactic: pattern.tactic.clone(),
                    confidence: 0.7,
                    trigger_phrase: text.to_string(),
                    context: Self::get_context(context, 3),
                    timestamp: chrono::Utc::now(),
                    severity: pattern.severity.clone(),
                });
            }
        }
        
        Ok(detections)
    }
    
    fn get_context(transcript: &[TranscriptLine], lines: usize) -> String {
        transcript.iter()
            .rev()
            .take(lines)
            .rev()
            .map(|l| l.text.as_str())
            .collect::<Vec<_>>()
            .join(" ")
    }
    
    fn load_patterns() -> Vec<TacticPattern> {
        vec![
            // URGENCY PRESSURE
            TacticPattern {
                tactic: BrokerTactic::UrgencyPressure,
                severity: TacticSeverity::Warning,
                patterns: vec![
                    Regex::new(r"won't last \d+ (minutes?|seconds?)").unwrap(),
                    Regex::new(r"need to know (right )?now").unwrap(),
                    Regex::new(r"have to decide (right )?now").unwrap(),
                ],
                keywords: vec!["urgent", "immediately", "right now", "won't last", "hurry"],
            },
            
            // FALSE SCARCITY
            TacticPattern {
                tactic: BrokerTactic::FalseSarcity,
                severity: TacticSeverity::Warning,
                patterns: vec![
                    Regex::new(r"\d+ (other )?drivers? (calling|interested)").unwrap(),
                    Regex::new(r"everyone wants this").unwrap(),
                    Regex::new(r"hot load").unwrap(),
                ],
                keywords: vec!["other drivers", "everyone wants", "calling about", "hot load"],
            },
            
            // TIME DECAY
            TacticPattern {
                tactic: BrokerTactic::TimeDecay,
                severity: TacticSeverity::Alert,
                patterns: vec![
                    Regex::new(r"rate (drops|goes down) \$?\d+").unwrap(),
                    Regex::new(r"price (drops|decreases) every (hour|day)").unwrap(),
                ],
                keywords: vec!["rate drops", "price drops", "every hour", "going down"],
            },
            
            // LOWBALLING
            TacticPattern {
                tactic: BrokerTactic::Lowballing,
                severity: TacticSeverity::Alert,
                patterns: vec![
                    Regex::new(r"best (I|we) can do").unwrap(),
                    Regex::new(r"that's all (I|we) have").unwrap(),
                    Regex::new(r"can't go any higher").unwrap(),
                ],
                keywords: vec!["best I can do", "all I have", "can't go higher", "final offer"],
            },
            
            // BAIT AND SWITCH
            TacticPattern {
                tactic: BrokerTactic::BaitAndSwitch,
                severity: TacticSeverity::Critical,
                patterns: vec![
                    Regex::new(r"actually (it's|the rate is)").unwrap(),
                    Regex::new(r"made a mistake").unwrap(),
                    Regex::new(r"rate (is now|changed)").unwrap(),
                ],
                keywords: vec!["actually", "changed", "mistake", "different"],
            },
            
            // GUILT TRIP
            TacticPattern {
                tactic: BrokerTactic::GuiltTrip,
                severity: TacticSeverity::Warning,
                patterns: vec![
                    Regex::new(r"help me out").unwrap(),
                    Regex::new(r"come on (man|buddy|dude)").unwrap(),
                    Regex::new(r"do (me|us) a (favor|solid)").unwrap(),
                ],
                keywords: vec!["help me", "come on", "favor", "please", "for me"],
            },
            
            // PERSONAL APPEAL
            TacticPattern {
                tactic: BrokerTactic::PersonalAppeal,
                severity: TacticSeverity::Info,
                patterns: vec![
                    Regex::new(r"take care of you").unwrap(),
                    Regex::new(r"best drivers?").unwrap(),
                    Regex::new(r"always call you first").unwrap(),
                ],
                keywords: vec!["take care", "best driver", "always call", "relationship"],
            },
            
            // FAKE RELATIONSHIP
            TacticPattern {
                tactic: BrokerTactic::FakeRelationship,
                severity: TacticSeverity::Warning,
                patterns: vec![
                    Regex::new(r"we('ve)? always").unwrap(),
                    Regex::new(r"you know (I|we)").unwrap(),
                    Regex::new(r"trust me").unwrap(),
                ],
                keywords: vec!["trust me", "you know", "always", "relationship", "partnership"],
            },
            
            // HIDDEN STOPS
            TacticPattern {
                tactic: BrokerTactic::HiddenStops,
                severity: TacticSeverity::Critical,
                patterns: vec![
                    Regex::new(r"(oh|actually|by the way).*(one more|another|additional) stop").unwrap(),
                    Regex::new(r"forgot to mention").unwrap(),
                ],
                keywords: vec!["another stop", "one more", "additional", "forgot", "by the way"],
            },
            
            // WEEKEND TRAP
            TacticPattern {
                tactic: BrokerTactic::WeekendTrap,
                severity: TacticSeverity::Warning,
                patterns: vec![
                    Regex::new(r"friday pickup.*monday delivery").unwrap(),
                    Regex::new(r"weekend load").unwrap(),
                ],
                keywords: vec!["friday pickup", "monday delivery", "weekend", "saturday", "sunday"],
            },
            
            // DEADHEAD MINIMIZATION
            TacticPattern {
                tactic: BrokerTactic::DeadheadMinimization,
                severity: TacticSeverity::Warning,
                patterns: vec![
                    Regex::new(r"only \d+ miles? deadhead").unwrap(),
                    Regex::new(r"basically no deadhead").unwrap(),
                ],
                keywords: vec!["only", "deadhead", "basically no", "just", "short"],
            },
            
            // DETENTION LIE
            TacticPattern {
                tactic: BrokerTactic::DetentionLie,
                severity: TacticSeverity::Warning,
                patterns: vec![
                    Regex::new(r"(never|rarely) (have|get) detention").unwrap(),
                    Regex::new(r"in and out (quick|fast)").unwrap(),
                ],
                keywords: vec!["never detention", "quick", "in and out", "no wait"],
            },
        ]
    }
}
