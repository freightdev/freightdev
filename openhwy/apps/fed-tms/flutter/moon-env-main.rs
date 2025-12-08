// File: moon-env/src/main.rs
// Moon Environment - Lua-based agent sandbox

use mlua::{Lua, Result as LuaResult, Table, Function, UserData, UserDataMethods};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;
use std::process::Command;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct MoonConfig {
    name: String,
    cpu_limit: Option<f32>,
    memory_limit: Option<String>,
    allowed_paths: Vec<String>,
    allowed_tools: Vec<String>,
    network_enabled: bool,
    max_execution_time: Option<u64>,
}

struct MoonEnvironment {
    config: MoonConfig,
    lua: Lua,
    state: HashMap<String, String>,
}

impl MoonEnvironment {
    fn new(config: MoonConfig) -> LuaResult<Self> {
        let lua = Lua::new();
        
        // Setup sandbox
        Self::setup_sandbox(&lua, &config)?;
        
        Ok(MoonEnvironment {
            config,
            lua,
            state: HashMap::new(),
        })
    }

    fn setup_sandbox(lua: &Lua, config: &MoonConfig) -> LuaResult<()> {
        let globals = lua.globals();

        // Create moon namespace
        let moon = lua.create_table()?;

        // Add safe functions
        moon.set("print", lua.create_function(|_, msg: String| {
            println!("[MOON] {}", msg);
            Ok(())
        })?)?;

        moon.set("log", lua.create_function(|_, (level, msg): (String, String)| {
            println!("[MOON:{}] {}", level.to_uppercase(), msg);
            Ok(())
        })?)?;

        // Add file operations (with path restrictions)
        let allowed_paths = config.allowed_paths.clone();
        moon.set("read_file", lua.create_function(move |_, path: String| {
            if !is_path_allowed(&path, &allowed_paths) {
                return Err(mlua::Error::RuntimeError(
                    format!("Access denied: {}", path)
                ));
            }
            match fs::read_to_string(&path) {
                Ok(content) => Ok(content),
                Err(e) => Err(mlua::Error::RuntimeError(e.to_string())),
            }
        })?)?;

        let allowed_paths = config.allowed_paths.clone();
        moon.set("write_file", lua.create_function(move |_, (path, content): (String, String)| {
            if !is_path_allowed(&path, &allowed_paths) {
                return Err(mlua::Error::RuntimeError(
                    format!("Access denied: {}", path)
                ));
            }
            match fs::write(&path, content) {
                Ok(_) => Ok(()),
                Err(e) => Err(mlua::Error::RuntimeError(e.to_string())),
            }
        })?)?;

        let allowed_paths = config.allowed_paths.clone();
        moon.set("list_dir", lua.create_function(move |_, path: String| {
            if !is_path_allowed(&path, &allowed_paths) {
                return Err(mlua::Error::RuntimeError(
                    format!("Access denied: {}", path)
                ));
            }
            match fs::read_dir(&path) {
                Ok(entries) => {
                    let files: Vec<String> = entries
                        .filter_map(|e| e.ok())
                        .map(|e| e.file_name().to_string_lossy().to_string())
                        .collect();
                    Ok(files)
                }
                Err(e) => Err(mlua::Error::RuntimeError(e.to_string())),
            }
        })?)?;

        // Add tool execution (with tool restrictions)
        let allowed_tools = config.allowed_tools.clone();
        moon.set("exec", lua.create_function(move |_, (tool, args): (String, Vec<String>)| {
            if !allowed_tools.contains(&tool) {
                return Err(mlua::Error::RuntimeError(
                    format!("Tool not allowed: {}", tool)
                ));
            }
            
            match Command::new(&tool).args(&args).output() {
                Ok(output) => {
                    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
                    let stderr = String::from_utf8_lossy(&output.stderr).to_string();
                    Ok((stdout, stderr, output.status.code()))
                }
                Err(e) => Err(mlua::Error::RuntimeError(e.to_string())),
            }
        })?)?;

        // Add state management
        moon.set("set_state", lua.create_function(|_, (key, value): (String, String)| {
            // This would need to be connected to the actual state HashMap
            // For now, just acknowledge
            println!("[MOON:STATE] Set {} = {}", key, value);
            Ok(())
        })?)?;

        moon.set("get_state", lua.create_function(|_, key: String| {
            // This would need to be connected to the actual state HashMap
            println!("[MOON:STATE] Get {}", key);
            Ok::<Option<String>, mlua::Error>(None)
        })?)?;

        // Add network operations (if enabled)
        if config.network_enabled {
            moon.set("http_get", lua.create_function(|_, url: String| {
                // Simple HTTP GET using curl
                match Command::new("curl").arg("-s").arg(&url).output() {
                    Ok(output) => Ok(String::from_utf8_lossy(&output.stdout).to_string()),
                    Err(e) => Err(mlua::Error::RuntimeError(e.to_string())),
                }
            })?)?;
        }

        // Set moon as global
        globals.set("moon", moon)?;

        // Restrict dangerous globals
        globals.set("os", mlua::Nil)?;
        globals.set("io", mlua::Nil)?;
        globals.set("require", mlua::Nil)?;
        globals.set("dofile", mlua::Nil)?;
        globals.set("loadfile", mlua::Nil)?;

        Ok(())
    }

    fn execute_script(&self, script: &str) -> LuaResult<()> {
        self.lua.load(script).exec()
    }

    fn execute_file(&self, path: &str) -> LuaResult<()> {
        let script = fs::read_to_string(path)
            .map_err(|e| mlua::Error::RuntimeError(e.to_string()))?;
        self.execute_script(&script)
    }

    fn call_function(&self, name: &str, args: Vec<String>) -> LuaResult<String> {
        let globals = self.lua.globals();
        let func: Function = globals.get(name)?;
        
        // Convert args to Lua values
        let lua_args: Vec<mlua::Value> = args
            .into_iter()
            .map(|s| mlua::Value::String(self.lua.create_string(&s).unwrap()))
            .collect();
        
        let result: mlua::Value = func.call(lua_args)?;
        
        match result {
            mlua::Value::String(s) => Ok(s.to_str()?.to_string()),
            mlua::Value::Nil => Ok(String::new()),
            _ => Ok(format!("{:?}", result)),
        }
    }
}

fn is_path_allowed(path: &str, allowed_paths: &[String]) -> bool {
    let path = PathBuf::from(path);
    
    for allowed in allowed_paths {
        let allowed_path = PathBuf::from(allowed);
        if path.starts_with(&allowed_path) {
            return true;
        }
    }
    
    false
}

fn main() -> LuaResult<()> {
    println!("🌙 Moon Environment - Agent Sandbox");
    println!();

    // Load config
    let config_path = std::env::args()
        .nth(1)
        .unwrap_or_else(|| "moon.toml".to_string());

    let config = load_config(&config_path)?;
    
    println!("Loading environment: {}", config.name);
    println!("  CPU Limit: {:?}", config.cpu_limit);
    println!("  Memory Limit: {:?}", config.memory_limit);
    println!("  Allowed Paths: {}", config.allowed_paths.len());
    println!("  Allowed Tools: {}", config.allowed_tools.len());
    println!("  Network: {}", if config.network_enabled { "enabled" } else { "disabled" });
    println!();

    // Create environment
    let env = MoonEnvironment::new(config)?;

    // Interactive mode or script mode
    let script_path = std::env::args().nth(2);
    
    if let Some(script) = script_path {
        println!("Executing: {}", script);
        env.execute_file(&script)?;
    } else {
        println!("Entering interactive mode...");
        println!("Type Lua code and press Ctrl+D to execute, or 'exit' to quit.");
        println!();
        
        use std::io::{self, BufRead};
        let stdin = io::stdin();
        let mut buffer = String::new();
        
        for line in stdin.lock().lines() {
            let line = line?;
            
            if line.trim() == "exit" {
                break;
            }
            
            buffer.push_str(&line);
            buffer.push('\n');
            
            // Try to execute
            if let Err(e) = env.execute_script(&buffer) {
                eprintln!("Error: {}", e);
            }
            
            buffer.clear();
        }
    }

    Ok(())
}

fn load_config(path: &str) -> LuaResult<MoonConfig> {
    if !std::path::Path::new(path).exists() {
        // Return default config
        return Ok(MoonConfig {
            name: "default".to_string(),
            cpu_limit: Some(1.0),
            memory_limit: Some("512M".to_string()),
            allowed_paths: vec![
                "/home/admin/WORKSPACE".to_string(),
                "/tmp".to_string(),
            ],
            allowed_tools: vec![
                "ls".to_string(),
                "cat".to_string(),
                "grep".to_string(),
                "curl".to_string(),
            ],
            network_enabled: true,
            max_execution_time: Some(300),
        });
    }

    let content = fs::read_to_string(path)
        .map_err(|e| mlua::Error::RuntimeError(e.to_string()))?;
    
    toml::from_str(&content)
        .map_err(|e| mlua::Error::RuntimeError(e.to_string()))
}
