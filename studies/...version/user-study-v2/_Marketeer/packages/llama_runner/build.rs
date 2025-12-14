//! build.rs — Enhanced build with pronunciation optimization
use std::{
    env,
    fs,
    io::Write,
    path::{Path, PathBuf},
    process::Command,
    time::SystemTime,
};

fn main() {
    let llama_root = PathBuf::from("llama.cpp");
    let build_dir = llama_root.join("build");
    
    // Ensure llama.cpp submodule exists
    if !llama_root.exists() {
        panic!("❌ llama.cpp directory not found. Run: git submodule update --init --recursive");
    }
    
    fs::create_dir_all(&build_dir).expect("❌ Failed to create build dir");
    
    // Detect platform and capabilities
    let build_config = detect_build_configuration();
    let cmake_flags = build_cmake_flags(&build_config);
    
    // 1) Configure cmake
    let mut cmd = Command::new("cmake");
    cmd.args(&cmake_flags)
       .current_dir(&llama_root);
    
    execute_command(cmd, "cmake configure");
    
    // 2) Build with optimization
    build_with_optimization(&llama_root, &build_config);
    
    // 3) Link libraries
    setup_linking(&build_dir, &build_config);
    
    // 4) Watch for changes
    setup_rerun_triggers();
    
    // 5) Generate bindings with pronunciation features
    generate_enhanced_bindings(&llama_root);
    
    // 6) Create pronunciation optimization config
    create_pronunciation_config();
}

#[derive(Debug)]
struct BuildConfig {
    generator: String,
    make_cmd: String,
    target_arch: String,
    optimization_level: String,
    has_gpu: bool,
    cpu_features: Vec<String>,
}

fn detect_build_configuration() -> BuildConfig {
    let target_arch = env::var("CARGO_CFG_TARGET_ARCH").unwrap_or_else(|_| "unknown".to_string());
    
    let (generator, make_cmd) = if cfg!(windows) {
        if Command::new("where").arg("msbuild").output().map_or(false, |o| o.status.success()) {
            ("Visual Studio 17 2022".to_string(), "msbuild".to_string())
        } else if Command::new("where").arg("ninja").output().map_or(false, |o| o.status.success()) {
            ("Ninja".to_string(), "ninja".to_string())
        } else {
            ("MinGW Makefiles".to_string(), "mingw32-make".to_string())
        }
    } else if Command::new("which").arg("ninja").output().map_or(false, |o| o.status.success()) {
        ("Ninja".to_string(), "ninja".to_string())
    } else {
        ("Unix Makefiles".to_string(), "make".to_string())
    };

    let optimization_level = env::var("PROFILE")
        .unwrap_or_else(|_| "release".to_string());

    let has_gpu = detect_gpu_support();
    let cpu_features = detect_advanced_cpu_features();

    BuildConfig {
        generator,
        make_cmd,
        target_arch,
        optimization_level,
        has_gpu,
        cpu_features,
    }
}

fn detect_gpu_support() -> bool {
    // Check for NVIDIA
    if Command::new("nvidia-smi").output().map_or(false, |o| o.status.success()) {
        return true;
    }
    
    // Check for AMD ROCm
    if Path::new("/opt/rocm").exists() {
        return true;
    }
    
    // Check for Apple Metal (macOS)
    if cfg!(target_os = "macos") {
        return true;
    }
    
    false
}

fn detect_advanced_cpu_features() -> Vec<String> {
    let mut features = Vec::new();
    
    #[cfg(target_arch = "x86_64")]
    {
        if std::arch::is_x86_feature_detected!("avx2") {
            features.push("AVX2".to_string());
        }
        if std::arch::is_x86_feature_detected!("fma") {
            features.push("FMA".to_string());
        }
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
        "-S".to_string(), ".".to_string(),
        "-B".to_string(), "build".to_string(),
        "-G".to_string(), config.generator.clone(),
        "-DBUILD_SHARED_LIBS=OFF".to_string(),
        "-DLLAMA_BUILD_TESTS=OFF".to_string(),
        "-DLLAMA_BUILD_EXAMPLES=OFF".to_string(),
        "-DLLAMA_BUILD_SERVER=OFF".to_string(),
        "-DLLAMA_BUILD_TOOLS=OFF".to_string(),
        "-DCMAKE_POSITION_INDEPENDENT_CODE=ON".to_string(),
    ];
    
    // Enhanced build type with pronunciation optimizations
    let cmake_build_type = match config.optimization_level.as_str() {
        "release" => "Release",
        "dev" | "debug" => "RelWithDebInfo", // Better for debugging pronunciation issues
        _ => "Release",
    };
    flags.push(format!("-DCMAKE_BUILD_TYPE={}", cmake_build_type));
    
    // Pronunciation-focused optimizations
    flags.push("-DCMAKE_CXX_FLAGS=-O3 -march=native -mtune=native".to_string());
    flags.push("-DCMAKE_C_FLAGS=-O3 -march=native -mtune=native".to_string());
    
    // CPU features for better inference performance
    for feature in &config.cpu_features {
        match feature.as_str() {
            "AVX2" => flags.push("-DLLAMA_AVX2=ON".to_string()),
            "FMA" => flags.push("-DLLAMA_FMA=ON".to_string()),
            "AVX512F" => flags.push("-DLLAMA_AVX512=ON".to_string()),
            "AVX512BW" => flags.push("-DLLAMA_AVX512_BF16=ON".to_string()),
            "NEON" => flags.push("-DLLAMA_NEON=ON".to_string()),
            _ => {}
        }
    }
    
    // GPU acceleration if available
    if config.has_gpu {
        if cfg!(target_os = "macos") {
            flags.push("-DLLAMA_METAL=ON".to_string());
        } else if env::var("ROCM_PATH").is_ok() {
            flags.push("-DLLAMA_HIPBLAS=ON".to_string());
        } else {
            flags.push("-DLLAMA_CUDA=ON".to_string());
        }
    }
    
    // Enable native optimizations for pronunciation accuracy
    flags.push("-DLLAMA_NATIVE=ON".to_string());
    flags.push("-DLLAMA_LTO=ON".to_string());
    
    flags
}

fn build_with_optimization(llama_root: &Path, config: &BuildConfig) {
    let mut build_cmd = Command::new("cmake");
    build_cmd.args(["--build", "build"])
             .current_dir(llama_root);
    
    // Use all available cores for faster builds
    let jobs = env::var("NUM_JOBS")
        .ok()
        .or_else(|| std::thread::available_parallelism().ok().map(|n| n.get().to_string()))
        .unwrap_or_else(|| "4".to_string());
    
    build_cmd.args(["--parallel", &jobs]);
    
    // Add build-specific optimizations
    if config.optimization_level == "release" {
        build_cmd.args(["--config", "Release"]);
    }
    
    execute_command(build_cmd, "cmake build with optimizations");
}

fn setup_linking(build_dir: &Path, config: &BuildConfig) {
    // Enhanced library search
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
    
    // Core libraries
    println!("cargo:rustc-link-lib=static=llama");
    println!("cargo:rustc-link-lib=static=ggml");
    
    // Platform-specific linking
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

fn generate_enhanced_bindings(llama_root: &Path) {
    let out_path = PathBuf::from("bindings/llama_cpp.rs");
    let bindings_dir = out_path.parent().unwrap();
    
    fs::create_dir_all(bindings_dir).expect("❌ Failed to create bindings dir");
    
    let mut builder = bindgen::Builder::default()
        .header("wrapper.h")
        .parse_callbacks(Box::new(bindgen::CargoCallbacks::new()))
        // Enhanced function allowlist for pronunciation features
        .allowlist_function("llama_.*")
        .allowlist_function("ggml_.*")
        .allowlist_type("llama_.*")
        .allowlist_type("ggml_.*")
        .allowlist_var("LLAMA_.*")
        .allowlist_var("GGML_.*")
        // Include paths
        .clang_arg(format!("-I{}", llama_root.join("include").display()))
        .clang_arg(format!("-I{}", llama_root.join("ggml/include").display()))
        .clang_arg(format!("-I{}", llama_root.join("common").display()))
        // Better type generation
        .derive_default(true)
        .derive_debug(true)
        .derive_copy(false) // Prevent issues with large structs
        .derive_hash(false)
        // Pronunciation-specific bindings
        .allowlist_function("llama_token_to_piece")
        .allowlist_function("llama_tokenize")
        .allowlist_function("llama_detokenize")
        .generate_comments(true);
    
    // Platform-specific flags
    if cfg!(target_os = "macos") {
        builder = builder.clang_arg("-stdlib=libc++");
    }
    
    let bindings = builder
        .generate()
        .expect("❌ bindgen generation failed");
    
    let mut file = fs::File::create(&out_path)
        .unwrap_or_else(|e| panic!("❌ Failed to write {}: {}", out_path.display(), e));
    
    file.write_all(bindings.to_string().as_bytes())
        .expect("❌ Failed to write bindings");
    
    println!("cargo:warning=✅ Enhanced FFI bindings generated → {}", out_path.display());
}

fn create_pronunciation_config() {
    let config_content = r#"
// Pronunciation optimization configuration
// This will be used by the tokenizer for better name pronunciation

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
"#;    
    let config_path = PathBuf::from("src/pronunciation_config.rs");
    fs::write(&config_path, config_content)
        .expect("❌ Failed to write pronunciation config");
    
    println!("cargo:warning=✅ Pronunciation config created → {}", config_path.display());
}

fn execute_command(mut cmd: Command, operation: &str) {
    println!("cargo:warning=🔧 Executing: {}", operation);
    
    let status = cmd.status()
        .unwrap_or_else(|e| panic!("❌ Failed to execute {}: {}", operation, e));
    
    if !status.success() {
        panic!("❌ {} failed with exit code: {:?}", operation, status.code());
    }
    
    println!("cargo:warning=✅ {} completed successfully", operation);
}

fn setup_rerun_triggers() {
    // Watch critical files
    println!("cargo:rerun-if-changed=wrapper.h");
    println!("cargo:rerun-if-changed=llama.cpp/CMakeLists.txt");
    println!("cargo:rerun-if-changed=llama.cpp/src");
    println!("cargo:rerun-if-changed=llama.cpp/ggml/src");
    
    // Environment variables that affect build
    println!("cargo:rerun-if-env-changed=LLAMA_CUDA");
    println!("cargo:rerun-if-env-changed=LLAMA_METAL");
    println!("cargo:rerun-if-env-changed=LLAMA_BLAS");
    println!("cargo:rerun-if-env-changed=NUM_JOBS");
    
    // Pronunciation-specific triggers
    println!("cargo:rerun-if-changed=src/pronunciation_config.rs");
}