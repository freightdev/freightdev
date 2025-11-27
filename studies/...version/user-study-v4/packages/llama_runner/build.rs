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
        panic!("❌ llama.cpp directory not found. Run: scripts/install-llama-engine.sh");
    }
    
    fs::create_dir_all(&build_dir).expect("❌ Failed to create build directory");
    
    // Detect platform and capabilities
    let build_config = detect_build_configuration();
    let cmake_flags = build_cmake_flags(&build_config);
    
    // 1) Configure CMake
    run_command(
        Command::new("cmake").args(&cmake_flags).current_dir(&llama_root),
        "CMake configure",
    );

    // 2) Build with optimization
    build_with_optimization(&llama_root, &build_config);

    // 3) Link libraries
    setup_linking(&build_dir, &build_config);

    // 4) Watch for changes
    setup_rerun_triggers();

    // 5) Generate bindings
    generate_enhanced_bindings(&llama_root);

    // 6) Create pronunciation config
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
    let optimization_level = env::var("PROFILE").unwrap_or_else(|_| "release".to_string());
    let has_gpu = detect_gpu_support();
    let cpu_features = detect_cpu_features();

    let (generator, make_cmd) = detect_build_generator();

    BuildConfig {
        generator,
        make_cmd,
        target_arch,
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

    // CPU features
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

    // GPU
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
    flags.push("-DLLAMA_NATIVE=ON".to_string());
    flags.push("-DLLAMA_LTO=ON".to_string());

    flags
}

fn build_with_optimization(llama_root: &Path, config: &BuildConfig) {
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

    run_command(cmd, "CMake build with optimizations");
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

fn generate_enhanced_bindings(llama_root: &Path) {
    let out_path = PathBuf::from("bindings/llama_cpp.rs");
    if let Some(parent) = out_path.parent() {
        fs::create_dir_all(parent).expect("❌ Failed to create bindings directory");
    }

    let mut builder = bindgen::Builder::default()
        .header("wrapper.h")
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
        builder = builder.clang_arg("-stdlib=libc++");
    }

    let bindings = builder.generate().expect("❌ bindgen generation failed");

    fs::write(&out_path, bindings.to_string()).expect("❌ Failed to write bindings");

    println!(
        "cargo:warning=✅ Enhanced FFI bindings generated → {}",
        out_path.display()
    );
}

fn create_pronunciation_config() {
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
    fs::write(&config_path, config_content)
        .expect("❌ Failed to write pronunciation config");
    
    println!("cargo:warning=✅ Pronunciation config created → {}",
    config_path.display());
}


fn setup_rerun_triggers() {
    println!("cargo:rerun-if-changed=wrapper.h");
    println!("cargo:rerun-if-changed=llama.cpp/CMakeLists.txt");
    println!("cargo:rerun-if-changed=llama.cpp/src");
    println!("cargo:rerun-if-changed=llama.cpp/ggml/src");
    println!("cargo:rerun-if-env-changed=LLAMA_CUDA");
    println!("cargo:rerun-if-env-changed=LLAMA_METAL");
    println!("cargo:rerun-if-env-changed=LLAMA_BLAS");
    println!("cargo:rerun-if-env-changed=NUM_JOBS");
    println!("cargo:rerun-if-changed=src/pronunciation_config.rs");
}

fn run_command(mut cmd: Command, operation: &str) {
    println!("cargo:warning=🔧 Executing: {}", operation);
    let status = cmd
        .status()
        .unwrap_or_else(|e| panic!("❌ Failed to execute {}: {}", operation, e));
    if !status.success() {
        panic!("❌ {} failed with exit code: {:?}", operation, status.code());
    }
    println!("cargo:warning=✅ {} completed successfully", operation);
}