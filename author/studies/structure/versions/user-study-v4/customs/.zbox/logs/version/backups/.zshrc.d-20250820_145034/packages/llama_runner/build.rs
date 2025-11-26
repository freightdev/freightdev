//! build.rs — production-grade llama.cpp build and bindgen
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
    let (generator, make_cmd) = detect_build_system();
    let cmake_flags = build_cmake_flags(&generator);
    
    // 1) Configure cmake
    let mut cmd = Command::new("cmake");
    cmd.args(&cmake_flags)
       .current_dir(&llama_root);
    
    execute_command(cmd, "cmake configure");
    
    // 2) Build
    let mut build_cmd = Command::new("cmake");
    build_cmd.args(["--build", "build"])
             .current_dir(&llama_root);
    
    // Use parallel builds when possible
    if let Some(jobs) = env::var("NUM_JOBS").ok().or_else(|| {
        std::thread::available_parallelism().ok().map(|n| n.get().to_string())
    }) {
        build_cmd.args(["--parallel", &jobs]);
    } else {
        build_cmd.arg("--parallel");
    }
    
    execute_command(build_cmd, "cmake build");
    
    // 3) Link libraries
    setup_linking(&build_dir);
    
    // 4) Watch for changes
    setup_rerun_triggers();
    
    // 5) Generate bindings if needed
    let out_path = PathBuf::from("bindings/llama_cpp.rs");
    if should_regenerate("wrapper.h", &out_path)
        || env::var("CARGO_FEATURE_REGEN_BINDINGS").is_ok()
        || !out_path.exists()
    {
        generate_bindings(&llama_root, &out_path);
    }
}

fn detect_build_system() -> (String, &'static str) {
    if cfg!(windows) {
        // Try Visual Studio first, then Ninja, then MinGW
        if Command::new("where").arg("msbuild").output().map_or(false, |o| o.status.success()) {
            ("Visual Studio 17 2022".to_string(), "msbuild")
        } else if Command::new("where").arg("ninja").output().map_or(false, |o| o.status.success()) {
            ("Ninja".to_string(), "ninja")
        } else {
            ("MinGW Makefiles".to_string(), "mingw32-make")
        }
    } else if Command::new("which").arg("ninja").output().map_or(false, |o| o.status.success()) {
        ("Ninja".to_string(), "ninja")
    } else {
        ("Unix Makefiles".to_string(), "make")
    }
}

fn build_cmake_flags(generator: &str) -> Vec<String> {
    let mut flags = vec![
        "-S".to_string(), ".".to_string(),
        "-B".to_string(), "build".to_string(),
        "-G".to_string(), generator.to_string(),
        "-DBUILD_SHARED_LIBS=OFF".to_string(),
        "-DLLAMA_BUILD_TESTS=OFF".to_string(),
        "-DLLAMA_BUILD_EXAMPLES=OFF".to_string(),
        "-DLLAMA_BUILD_SERVER=OFF".to_string(),
        "-DLLAMA_BUILD_TOOLS=OFF".to_string(),
        "-DCMAKE_POSITION_INDEPENDENT_CODE=ON".to_string(),
    ];
    
    // Build type
    let build_type = env::var("PROFILE").unwrap_or_else(|_| "release".to_string());
    let cmake_build_type = if build_type == "release" { "Release" } else { "Debug" };
    flags.push(format!("-DCMAKE_BUILD_TYPE={}", cmake_build_type));
    
    // CPU optimizations
    detect_cpu_features(&mut flags);
    
    // Optional features from environment
    if env::var("CARGO_FEATURE_CUDA").is_ok() || env::var("LLAMA_CUDA").is_ok() {
        flags.push("-DLLAMA_CUDA=ON".to_string());
        println!("cargo:rustc-link-lib=dylib=cuda");
        println!("cargo:rustc-link-lib=dylib=cublas");
    }
    
    if env::var("CARGO_FEATURE_METAL").is_ok() || (cfg!(target_os = "macos") && env::var("LLAMA_METAL").is_ok()) {
        flags.push("-DLLAMA_METAL=ON".to_string());
    }
    
    if env::var("CARGO_FEATURE_BLAS").is_ok() {
        flags.push("-DLLAMA_BLAS=ON".to_string());
        if cfg!(target_os = "macos") {
            flags.push("-DLLAMA_BLAS_VENDOR=Apple".to_string());
        }
    }
    
    flags
}

fn detect_cpu_features(flags: &mut Vec<String>) {
    // Enable common CPU optimizations
    if cfg!(target_arch = "x86_64") {
        // Most modern x86_64 CPUs support these
        if is_x86_feature_available("avx2") {
            flags.push("-DLLAMA_AVX2=ON".to_string());
        }
        if is_x86_feature_available("fma") {
            flags.push("-DLLAMA_FMA=ON".to_string());
        }
        if is_x86_feature_available("avx512f") {
            flags.push("-DLLAMA_AVX512=ON".to_string());
        }
    }
    
    // Enable native optimizations unless cross-compiling
    if env::var("TARGET").unwrap_or_default() == env::var("HOST").unwrap_or_default() {
        flags.push("-DLLAMA_NATIVE=ON".to_string());
    }
}

fn is_x86_feature_available(feature: &str) -> bool {
    #[cfg(target_arch = "x86_64")]
    {
        match feature {
            "avx2" => std::arch::is_x86_feature_detected!("avx2"),
            "fma" => std::arch::is_x86_feature_detected!("fma"),
            "avx512f" => std::arch::is_x86_feature_detected!("avx512f"),
            _ => false,
        }
    }
    #[cfg(not(target_arch = "x86_64"))]
    false
}

fn execute_command(mut cmd: Command, operation: &str) {
    let status = cmd.status()
        .unwrap_or_else(|e| panic!("❌ Failed to execute {}: {}", operation, e));
    
    if !status.success() {
        panic!("❌ {} failed with exit code: {:?}", operation, status.code());
    }
}

fn setup_linking(build_dir: &Path) {
    // Add search paths
    println!("cargo:rustc-link-search=native={}", build_dir.join("src").display());
    println!("cargo:rustc-link-search=native={}", build_dir.join("ggml").join("src").display());
    
    // Dynamically discover built libraries
    let lib_patterns = ["libllama.a", "libggml*.a"];
    let mut found_libs = Vec::new();
    
    for pattern in &lib_patterns {
        if let Ok(entries) = fs::read_dir(build_dir.join("src")) {
            for entry in entries.flatten() {
                let name = entry.file_name().to_string_lossy().to_string();
                if pattern.contains('*') {
                    let prefix = pattern.split('*').next().unwrap();
                    if name.starts_with(prefix) && name.ends_with(".a") {
                        let lib_name = name.trim_start_matches("lib").trim_end_matches(".a");
                        found_libs.push(lib_name.to_string());
                    }
                } else if name == pattern.trim_start_matches("lib") {
                    let lib_name = pattern.trim_start_matches("lib").trim_end_matches(".a");
                    found_libs.push(lib_name.to_string());
                }
            }
        }
    }
    
    // Link found libraries
    for lib in found_libs {
        println!("cargo:rustc-link-lib=static={}", lib);
    }
    
    // System libraries
    #[cfg(unix)]
    {
        for sys in ["stdc++", "m", "pthread"] {
            println!("cargo:rustc-link-lib=dylib={}", sys);
        }
        
        // OpenMP support if available
        if env::var("CARGO_FEATURE_OPENMP").is_ok() {
            println!("cargo:rustc-link-lib=dylib=gomp");
        }
    }
    
    #[cfg(windows)]
    {
        // Windows specific libraries
        println!("cargo:rustc-link-lib=dylib=kernel32");
        println!("cargo:rustc-link-lib=dylib=user32");
        println!("cargo:rustc-link-lib=dylib=shell32");
    }
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
}

fn should_regenerate(wrapper: &str, out_path: &Path) -> bool {
    let wrapper_time = fs::metadata(wrapper)
        .and_then(|m| m.modified())
        .unwrap_or(SystemTime::UNIX_EPOCH);
    let bindings_time = fs::metadata(out_path)
        .and_then(|m| m.modified())
        .unwrap_or(SystemTime::UNIX_EPOCH);
    wrapper_time > bindings_time
}

fn generate_bindings(llama_root: &Path, out_path: &Path) {
    let bindings_dir = out_path.parent().unwrap();
    let backup_path = bindings_dir.join("llama_cpp.old.rs");
    
    fs::create_dir_all(bindings_dir).expect("❌ Failed to create bindings dir");
    
    // Backup old if exists
    if out_path.exists() {
        let _ = fs::remove_file(&backup_path);
        fs::rename(out_path, &backup_path)
            .unwrap_or_else(|e| panic!("❌ Failed to backup old llama_cpp.rs: {}", e));
        println!("cargo:warning=📦 Backed up old bindings → llama_cpp.old.rs");
    }
    
    // Generate new bindings
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
        .derive_default(true)
        .derive_debug(true);
    
    // Add platform-specific flags
    if cfg!(target_os = "macos") {
        builder = builder.clang_arg("-stdlib=libc++");
    }
    
    let bindings = builder
        .generate()
        .expect("❌ bindgen generation failed");
    
    let mut file = fs::File::create(out_path)
        .unwrap_or_else(|e| panic!("❌ Failed to write {}: {}", out_path.display(), e));
    
    file.write_all(bindings.to_string().as_bytes())
        .expect("❌ Failed to write bindings");
    
    println!("cargo:warning=✅ FFI bindings regenerated → {}", out_path.display());
}