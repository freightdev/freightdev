// build.rs — Enhanced build with pronunciation optimization

#![deny(warnings)]

use std::{
    env,
    fs,
    path::{Path, PathBuf},
    process::Command,
};

fn main() {
    let llama_root = PathBuf::from("engines/llama.cpp");
    let build_dir = llama_root.join("build");

    // Ensure engines/llama.cpp submodule exists
    if !llama_root.exists() {
        eprintln!("❌ engines/llama.cpp directory not found. Run: engines/install-llama-engine.sh");
        std::process::exit(1);
    }

    if let Err(e) = fs::create_dir_all(&build_dir) {
        eprintln!("❌ Failed to create build directory: {}", e);
        std::process::exit(1);
    }

    // Detect platform and capabilities
    let build_config = detect_build_configuration();
    let cmake_flags = build_cmake_flags(&build_config);

    // 1) Configure CMake
    let mut cmd = Command::new("cmake");
    cmd.args(&cmake_flags);
    cmd.current_dir(&llama_root);
    if !run_command(cmd, "CMake configure") {
        std::process::exit(1);
    }

    // 2) Build with optimization
    if !build_with_optimization(&llama_root, &build_config) {
        std::process::exit(1);
    }

    // 3) Link libraries
    setup_linking(&build_dir, &build_config);

    // 4) Watch for changes
    setup_rerun_triggers();

    // 5) Generate bindings
    if !generate_enhanced_bindings(&llama_root) {
        std::process::exit(1);
    }

    // 6) Create pronunciation config
    if !create_pronunciation_config() {
        eprintln!("⚠️ Pronunciation config not created, but continuing build");
    }
}

#[derive(Debug)]
struct BuildConfig {
    generator: String,
    optimization_level: String,
    has_gpu: bool,
    cpu_features: Vec<String>,
}

/// Detect build configuration
fn detect_build_configuration() -> BuildConfig {
    let optimization_level = env::var("PROFILE").unwrap_or_else(|_| "release".to_string());
    let has_gpu = detect_gpu_support();
    let cpu_features = detect_advanced_cpu_features();

    // Destructure both values correctly
    let (generator, _) = detect_build_generator();

    BuildConfig {
        generator,
        optimization_level,
        has_gpu,
        cpu_features,
    }
}


/// OS-specific CMake generator detection
#[cfg(windows)]
fn detect_build_generator() -> (String, String) {
    if Command::new("where")
        .arg("msbuild")
        .output()
        .map_or(false, |o| o.status.success())
    {
        ("Visual Studio 17 2022".to_string(), "msbuild".to_string())
    } else if Command::new("where")
        .arg("ninja")
        .output()
        .map_or(false, |o| o.status.success())
    {
        ("Ninja".to_string(), "ninja".to_string())
    } else {
        ("MinGW Makefiles".to_string(), "mingw32-make".to_string())
    }
}

#[cfg(unix)]
fn detect_build_generator() -> (String, String) {
    if Command::new("which")
        .arg("ninja")
        .output()
        .map_or(false, |o| o.status.success())
    {
        ("Ninja".to_string(), "ninja".to_string())
    } else {
        ("Unix Makefiles".to_string(), "make".to_string())
    }
}

fn detect_gpu_support() -> bool {
    #[cfg(target_os = "macos")]
    {
        return true; // assume Metal is available
    }

    if Command::new("nvidia-smi")
        .output()
        .map_or(false, |o| o.status.success())
    {
        return true;
    }

    if Path::new("/opt/rocm").exists() {
        return true;
    }

    false
}

fn detect_advanced_cpu_features() -> Vec<String> {
    let mut features = Vec::new();
    
    #[cfg(target_arch = "x86_64")]
    {
        if std::arch::is_x86_feature_detected!("avx512f") {
            features.push("AVX512F".to_string());
        }
        if std::arch::is_x86_feature_detected!("avx512bw") {
            features.push("AVX512BW".to_string());
        }
    }
    
    #[cfg(target_arch = "aarch64")]
    {
        features.push("NEON".to_string());
    }
    
    features
}

fn build_cmake_flags(config: &BuildConfig) -> Vec<String> {
    let mut flags = vec![
        "-S".to_string(),
        ".".to_string(),
        "-B".to_string(),
        "build".to_string(),
        "-G".to_string(),
        config.generator.clone(),
        "-DBUILD_SHARED_LIBS=OFF".to_string(),
        "-DLLAMA_BUILD_TESTS=OFF".to_string(),
        "-DLLAMA_BUILD_EXAMPLES=OFF".to_string(),
        "-DLLAMA_BUILD_SERVER=OFF".to_string(),
        "-DLLAMA_BUILD_TOOLS=OFF".to_string(),
        "-DCMAKE_POSITION_INDEPENDENT_CODE=ON".to_string(),
    ];

    let cmake_build_type = match config.optimization_level.as_str() {
        "release" => "Release",
        "dev" | "debug" => "RelWithDebInfo",
        _ => "Release",
    };
    flags.push(format!("-DCMAKE_BUILD_TYPE={}", cmake_build_type));

    for feature in &config.cpu_features {
        match feature.as_str() {
            "AVX512F" => flags.push("-DLLAMA_AVX512=ON".to_string()),
            "AVX512BW" => flags.push("-DLLAMA_AVX512_BF16=ON".to_string()),
            "NEON" => flags.push("-DLLAMA_NEON=ON".to_string()),
            _ => {}
        }
    }

    if config.has_gpu {
        #[cfg(target_os = "macos")]
        flags.push("-DLLAMA_METAL=ON".to_string());
        #[cfg(not(target_os = "macos"))]
        {
            if env::var("ROCM_PATH").is_ok() {
                flags.push("-DLLAMA_HIPBLAS=ON".to_string());
            } else {
                flags.push("-DLLAMA_CUDA=ON".to_string());
            }
        }
    }

    flags.push("-DCMAKE_CXX_FLAGS=-O3 -march=native -mtune=native".to_string());
    flags.push("-DCMAKE_C_FLAGS=-O3 -march=native -mtune=native".to_string());

    flags.push("-DGGML_NATIVE=ON".to_string());

    flags
}

fn build_with_optimization(llama_root: &Path, config: &BuildConfig) -> bool {
    let mut cmd = Command::new("cmake");
    cmd.args(["--build", "build"]).current_dir(llama_root);

    let jobs = env::var("NUM_JOBS")
        .ok()
        .or_else(|| std::thread::available_parallelism().ok().map(|n| n.get().to_string()))
        .unwrap_or_else(|| "4".to_string());

    cmd.args(["--parallel", &jobs]);

    if config.optimization_level == "release" {
        cmd.args(["--config", "Release"]);
    }

    run_command(cmd, "CMake build with optimizations")
}

fn setup_linking(build_dir: &Path, config: &BuildConfig) {
    let search_paths = [
        build_dir.join("src"),
        build_dir.join("ggml").join("src"),
        build_dir.join("common"),
    ];

    for path in &search_paths {
        if path.exists() {
            println!("cargo:rustc-link-search=native={}", path.display());
        }
    }

    println!("cargo:rustc-link-lib=static=llama");
    println!("cargo:rustc-link-lib=static=ggml");

    #[cfg(unix)]
    {
        for lib in ["stdc++", "m", "pthread"] {
            println!("cargo:rustc-link-lib=dylib={}", lib);
        }

        if config.has_gpu && !cfg!(target_os = "macos") {
            println!("cargo:rustc-link-lib=dylib=cuda");
            println!("cargo:rustc-link-lib=dylib=cublas");
        }
    }

    #[cfg(target_os = "macos")]
    {
        if config.has_gpu {
            println!("cargo:rustc-link-lib=framework=Metal");
            println!("cargo:rustc-link-lib=framework=MetalKit");
        }
    }

    #[cfg(windows)]
    {
        for lib in ["kernel32", "user32", "shell32"] {
            println!("cargo:rustc-link-lib=dylib={}", lib);
        }
    }
}

fn setup_rerun_triggers() {
    println!("cargo:rerun-if-changed=include/llama_wrapper.h");
    println!("cargo:rerun-if-changed=engines/llama.cpp/CMakeLists.txt");
    println!("cargo:rerun-if-changed=engines/llama.cpp/src");
    println!("cargo:rerun-if-changed=engines/llama.cpp/ggml/src");
    println!("cargo:rerun-if-env-changed=LLAMA_CUDA");
    println!("cargo:rerun-if-env-changed=LLAMA_METAL");
    println!("cargo:rerun-if-env-changed=LLAMA_BLAS");
    println!("cargo:rerun-if-env-changed=NUM_JOBS");
    println!("cargo:rerun-if-changed=src/configs/pronunciation_config.rs");
}

fn generate_enhanced_bindings(llama_root: &Path) -> bool {
    let out_path = PathBuf::from("src/bindings/llama_cpp.rs");
    if let Some(parent) = out_path.parent() {
        if let Err(e) = fs::create_dir_all(parent) {
            eprintln!("❌ Failed to create bindings directory {}: {}", parent.display(), e);
            return false;
        }
    }

    let builder = bindgen::Builder::default()
        .header("include/llama_wrapper.h")
        .parse_callbacks(Box::new(bindgen::CargoCallbacks::new()))
        .allowlist_function("llama_.*")
        .allowlist_function("ggml_.*")
        .allowlist_type("llama_.*")
        .allowlist_type("ggml_.*")
        .allowlist_var("LLAMA_.*")
        .allowlist_var("GGML_.*")
        .clang_arg(format!("-I{}", llama_root.join("include").display()))
        .clang_arg(format!("-I{}", llama_root.join("ggml/include").display()))
        .clang_arg(format!("-I{}", llama_root.join("common").display()))
        .derive_default(true)
        .derive_debug(true)
        .derive_copy(false)
        .derive_hash(false)
        .allowlist_function("llama_token_to_piece")
        .allowlist_function("llama_tokenize")
        .allowlist_function("llama_detokenize")
        .generate_comments(true);

    #[cfg(target_os = "macos")]
    {
        builder.clang_arg("-stdlib=libc++");
    }

    match builder.generate() {
        Ok(bindings) => {
            if let Err(e) = fs::write(&out_path, bindings.to_string()) {
                eprintln!("❌ Failed to write bindings: {}", e);
                false
            } else {
                println!("cargo:warning=✅ Enhanced FFI bindings generated → {}", out_path.display());
                true
            }
        }
        Err(e) => {
            eprintln!("❌ bindgen generation failed: {:?}", e);
            false
        }
    }
}

fn create_pronunciation_config() -> bool {
    let config_content = r##"
// Pronunciation optimization configuration
pub const PRONUNCIATION_CONFIG: &str = r#"{
    "special_tokens": {
        "proper_nouns": {
            "names": true,
            "places": true,
            "brands": true
        },
        "phonetic_hints": true,
        "stress_patterns": true
    },
    "tokenization": {
        "preserve_capitalization": true,
        "word_boundaries": true,
        "syllable_breaks": false
    },
    "generation": {
        "temperature": 0.1,
        "top_p": 0.9,
        "repetition_penalty": 1.1
    }
}"#;
"##;

    let config_path = PathBuf::from("src/configs/pronunciation_config.rs");

    if let Some(parent) = config_path.parent() {
        if let Err(e) = fs::create_dir_all(parent) {
            eprintln!("❌ Failed to create directory {}: {}", parent.display(), e);
            return false;
        }
    }

    match fs::write(&config_path, config_content) {
        Ok(_) => {
            println!("cargo:warning=✅ Pronunciation config created → {}", config_path.display());
            true
        }
        Err(e) => {
            eprintln!("❌ Failed to write pronunciation config: {}", e);
            false
        }
    }
}

// --- run_command also returns bool instead of panicking ---
fn run_command(mut cmd: Command, operation: &str) -> bool {
    println!("cargo:warning=🔧 Executing: {}", operation);
    match cmd.status() {
        Ok(status) if status.success() => {
            println!("cargo:warning=✅ {} completed successfully", operation);
            true
        }
        Ok(status) => {
            eprintln!("❌ {} failed with exit code: {:?}", operation, status.code());
            false
        }
        Err(e) => {
            eprintln!("❌ Failed to execute {}: {}", operation, e);
            false
        }
    }
}