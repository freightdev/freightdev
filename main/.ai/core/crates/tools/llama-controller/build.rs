//! build.rs - Final definitive build script for echo-ops with LLaMA.cpp integration
#![deny(warnings)]

use std::{
    env,
    fs,
    path::{Path, PathBuf},
    process::Command,
};

fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-changed=libs/include/llama_wrapper.h");
    println!("cargo:rerun-if-changed=libs/include/llama_wrapper.c");

    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let target_dir = env::var("TARGET_DIR")
        .map(PathBuf::from)
        .or_else(|_| {
            env::var("OUT_DIR").map(|d| {
                let out = PathBuf::from(d);
                out.parent().unwrap().parent().unwrap().parent().unwrap().to_path_buf()
            })
        })
        .unwrap_or_else(|_| manifest_dir.join("target"));
    let target = env::var("TARGET").unwrap();

    // Setup build structure
    let llama_build_dir = target_dir.join("llama_cpp/builds");
    fs::create_dir_all(&llama_build_dir).unwrap_or_else(|e| {
        panic!("❌ Failed to create build directory {}: {}", llama_build_dir.display(), e);
    });

    // Check for wrapper files
    let wrapper_h = manifest_dir.join("libs/include/llama_wrapper.h");
    let wrapper_c = manifest_dir.join("libs/include/llama_wrapper.c");

    if !wrapper_h.exists() || !wrapper_c.exists() {
        panic!("❌ Required wrapper files missing: {} or {}", wrapper_h.display(), wrapper_c.display());
    }

    // Check if artifacts already exist
    let lib_llama = llama_build_dir.join(get_lib_name("llama", &target));
    let lib_ggml = llama_build_dir.join(get_lib_name("ggml", &target));
    let ffi_bindings = llama_build_dir.join("ffi_bindings.rs");

    let need_build = !lib_llama.exists() || !lib_ggml.exists();
    let need_bindings = !ffi_bindings.exists() || should_regenerate_bindings(&wrapper_h, &ffi_bindings);

    if need_build {
        println!("🔨 Building LLaMA.cpp artifacts...");
        build_llama_artifacts(&target_dir, &llama_build_dir, &target);
    } else {
        println!("✅ LLaMA.cpp artifacts found, skipping build");
    }

    if need_bindings {
        println!("🔧 Generating FFI bindings...");
        generate_ffi_bindings(&manifest_dir, &llama_build_dir, &target_dir);
    } else {
        println!("✅ FFI bindings up to date");
    }

    build_wrapper(&manifest_dir, &target, &llama_build_dir, &target_dir);
    setup_linking(&llama_build_dir, &target);
    
    println!("✅ Build completed successfully");
}

fn get_lib_name(base: &str, target: &str) -> String {
    if target.contains("windows") {
        format!("lib{}.a", base)
    } else {
        format!("lib{}.a", base)
    }
}

fn should_regenerate_bindings(wrapper_header: &Path, bindings_path: &Path) -> bool {
    if !bindings_path.exists() { return true; }
    if !wrapper_header.exists() { return false; }

    if let (Ok(header_meta), Ok(bindings_meta)) = (wrapper_header.metadata(), bindings_path.metadata()) {
        if let (Ok(header_time), Ok(bindings_time)) = (header_meta.modified(), bindings_meta.modified()) {
            return header_time > bindings_time;
        }
    }
    false
}

fn build_llama_artifacts(target_dir: &Path, llama_build_dir: &Path, target: &str) {
    let temp_llama_dir = target_dir.join("temp_llama_cpp");
    
    // Clean up any existing temp directory
    if temp_llama_dir.exists() {
        fs::remove_dir_all(&temp_llama_dir).unwrap_or_else(|e| {
            println!("⚠️  Warning: Could not remove existing temp directory: {}", e);
        });
    }

    // Clone llama.cpp to temp location
    println!("📥 Cloning LLaMA.cpp repository...");
    let clone_status = Command::new("git")
        .args([
            "clone",
            "--depth", "1",
            "--single-branch",
            "https://github.com/ggerganov/llama.cpp.git",
            temp_llama_dir.to_str().unwrap(),
        ])
        .status()
        .expect("Failed to execute git clone");

    if !clone_status.success() {
        panic!("❌ Failed to clone LLaMA.cpp repository");
    }

    // Build LLaMA.cpp
    let build_dir = temp_llama_dir.join("build");
    fs::create_dir_all(&build_dir).unwrap();

    let mut cmake_args = vec![
        "-B", "build",
        "-DBUILD_SHARED_LIBS=OFF",
        "-DLLAMA_BUILD_TESTS=OFF",
        "-DLLAMA_BUILD_EXAMPLES=OFF",
        "-DLLAMA_BUILD_SERVER=OFF",
        "-DCMAKE_POSITION_INDEPENDENT_CODE=ON",
        "-DCMAKE_BUILD_TYPE=Release",
    ];

    // Feature-based compilation flags
    if cfg!(feature = "cuda") { 
        cmake_args.push("-DLLAMA_CUDA=ON"); 
        println!("🔥 CUDA support enabled");
    }
    if cfg!(feature = "metal") { 
        cmake_args.push("-DLLAMA_METAL=ON"); 
        println!("🍎 Metal support enabled");
    }
    if cfg!(feature = "rocm") { 
        cmake_args.push("-DLLAMA_HIPBLAS=ON"); 
        println!("🔴 ROCm support enabled");
    }
    if cfg!(feature = "vulkan") { 
        cmake_args.push("-DLLAMA_VULKAN=ON"); 
        println!("🌋 Vulkan support enabled");
    }
    if cfg!(feature = "blas") {
        cmake_args.push("-DLLAMA_BLAS=ON");
        println!("🔢 BLAS support enabled");
    }
    if cfg!(feature = "openmp") {
        cmake_args.push("-DLLAMA_OPENMP=ON");
        println!("🔄 OpenMP support enabled");
    }
    if cfg!(feature = "mkl") {
        cmake_args.push("-DLLAMA_BLAS=ON");
        cmake_args.push("-DLLAMA_BLAS_VENDOR=Intel10_64lp");
        println!("🧠 Intel MKL support enabled");
    }

    #[cfg(target_os = "macos")]
    if cfg!(feature = "accelerate") { 
        cmake_args.push("-DLLAMA_ACCELERATE=ON"); 
        println!("⚡ Accelerate framework enabled");
    }

    println!("🔧 Configuring LLaMA.cpp build...");
    let cmake_config = Command::new("cmake")
        .current_dir(&temp_llama_dir)
        .args(&cmake_args)
        .status()
        .expect("Failed to configure LLaMA.cpp");

    if !cmake_config.success() {
        cleanup_temp_dir(&temp_llama_dir);
        panic!("❌ CMake configure failed");
    }

    println!("🔨 Building LLaMA.cpp libraries...");
    let mut build_cmd = Command::new("cmake");
    build_cmd.current_dir(&temp_llama_dir);
    build_cmd.args(["--build", "build", "--config", "Release"]);

    // Parallel build optimization
    if let Ok(jobs) = env::var("NUM_JOBS") {
        build_cmd.args(["--parallel", &jobs]);
    } else if let Ok(par) = std::thread::available_parallelism() {
        build_cmd.args(["--parallel", &par.get().to_string()]);
    }

    let build_status = build_cmd.status().expect("Failed to build LLaMA.cpp");
    if !build_status.success() {
        cleanup_temp_dir(&temp_llama_dir);
        panic!("❌ LLaMA build failed");
    }

    // Extract artifacts
    extract_build_artifacts(&temp_llama_dir, llama_build_dir, target);

    // Clean up temp directory
    cleanup_temp_dir(&temp_llama_dir);
    println!("🧹 Temporary source cleaned up");
}

fn extract_build_artifacts(temp_llama_dir: &Path, llama_build_dir: &Path, target: &str) {
    let build_dir = temp_llama_dir.join("build");

    // Copy library files
    let search_paths = [
        build_dir.join("src"),
        build_dir.join("ggml/src"),
        build_dir.join("common"),
        build_dir.clone(),
    ];

    let lib_extensions = if target.contains("windows") {
        vec!["lib", "a"]
    } else {
        vec!["a", "so", "dylib"]
    };

    for search_path in &search_paths {
        if !search_path.exists() { continue; }

        if let Ok(entries) = fs::read_dir(search_path) {
            for entry in entries.flatten() {
                let path = entry.path();
                if let Some(ext) = path.extension() {
                    if lib_extensions.contains(&ext.to_string_lossy().as_ref()) {
                        if let Some(filename) = path.file_name() {
                            let dst = llama_build_dir.join(filename);
                            if let Err(e) = fs::copy(&path, &dst) {
                                println!("⚠️  Failed to copy {}: {}", path.display(), e);
                            } else {
                                println!("📦 Extracted: {}", filename.to_string_lossy());
                            }
                        }
                    }
                }
            }
        }
    }

    // Copy all headers from include and ggml/include
    let include_dirs = [
        temp_llama_dir.join("include"),
        temp_llama_dir.join("ggml/include"),
    ];

    for dir in &include_dirs {
        if dir.exists() {
            for entry in fs::read_dir(dir).unwrap() {
                let entry = entry.unwrap();
                let path = entry.path();
                if path.is_file() && path.extension().map(|e| e == "h").unwrap_or(false) {
                    let dst = llama_build_dir.join(path.file_name().unwrap());
                    if let Err(e) = fs::copy(&path, &dst) {
                        println!("⚠️  Failed to copy header {}: {}", path.display(), e);
                    } else {
                        println!("📄 Header copied: {}", path.file_name().unwrap().to_string_lossy());
                    }
                }
            }
        }
    }
}


fn cleanup_temp_dir(temp_dir: &Path) {
    if temp_dir.exists() {
        if let Err(e) = fs::remove_dir_all(temp_dir) {
            println!("⚠️  Warning: Could not clean up temporary directory {}: {}", temp_dir.display(), e);
        }
    }
}

fn generate_ffi_bindings(manifest_dir: &Path, llama_build_dir: &Path, target_dir: &Path) {
    let wrapper_header = manifest_dir.join("libs/include/llama_wrapper.h");
    let bindings_path = llama_build_dir.join("llama_ffi_bindings.rs");

    let temp_llama_dir = target_dir.join("temp_llama_cpp");
    let mut builder = bindgen::Builder::default()
        .header(wrapper_header.to_string_lossy())
        .parse_callbacks(Box::new(bindgen::CargoCallbacks::new()))
        .allowlist_function("llama_wrapper_.*")
        .allowlist_type("llama_wrapper_.*")
        .allowlist_var("LLAMA_WRAPPER_.*")
        .allowlist_function("llama_.*")
        .allowlist_function("ggml_.*")
        .allowlist_type("llama_.*")
        .allowlist_type("ggml_.*")
        .allowlist_var("LLAMA_.*")
        .allowlist_var("GGML_.*")
        .clang_arg(format!("-I{}", manifest_dir.join("libs/include").display()))
        .clang_arg(format!("-I{}", llama_build_dir.display()))
        .derive_default(true)
        .derive_debug(true)
        .derive_copy(false)
        .derive_hash(false)
        .generate_comments(true)
        .layout_tests(false)
        .size_t_is_usize(true);

    // Add temp llama includes if they exist (for initial generation)
    if temp_llama_dir.exists() {
        builder = builder
            .clang_arg(format!("-I{}", temp_llama_dir.join("include").display()))
            .clang_arg(format!("-I{}", temp_llama_dir.join("ggml/include").display()))
            .clang_arg(format!("-I{}", temp_llama_dir.join("common").display()));
    }

    let target = env::var("TARGET").unwrap();
    if target.contains("apple") {
        builder = builder.clang_arg("-stdlib=libc++");
    }

    match builder.generate() {
        Ok(bindings) => {
            fs::write(&bindings_path, bindings.to_string())
                .unwrap_or_else(|e| panic!("❌ Failed to write bindings: {}", e));
            println!("✅ FFI bindings generated: {}", bindings_path.display());
        },
        Err(e) => panic!("❌ Failed to generate bindings: {}", e),
    }
}

fn build_wrapper(manifest_dir: &Path, target: &str, llama_build_dir: &Path, target_dir: &Path) {
    println!("🔧 Building C++ wrapper...");
    let wrapper_c = manifest_dir.join("libs/include/llama_wrapper.c");
    let mut cc_build = cc::Build::new();
    
    cc_build
        .file(&wrapper_c)
        .include(manifest_dir.join("libs/include"))
        .include(llama_build_dir)
        .cpp(true)
        .std("c++11")
        .opt_level(3)
        .flag("-fPIC");

    // Add temp llama includes if they exist
    let temp_llama_dir = target_dir.join("temp_llama_cpp");
    if temp_llama_dir.exists() {
        cc_build
            .include(temp_llama_dir.join("include"))
            .include(temp_llama_dir.join("ggml/include"))
            .include(temp_llama_dir.join("common"));
    }

    if target.contains("windows") {
        cc_build.flag("/std:c++11").flag("/O2");
    } else {
        cc_build.flag("-std=c++11").flag("-O3");
        if !target.contains("aarch64") {
            cc_build.flag("-march=native");
        }
    }

    cc_build.compile("llamawrapper");
    println!("✅ C++ wrapper compiled");
}

fn setup_linking(llama_build_dir: &Path, target: &str) {
    println!("🔗 Setting up library linking...");
    println!("cargo:rustc-link-search=native={}", llama_build_dir.display());
    
    // Link static libraries
    println!("cargo:rustc-link-lib=static=llama");
    println!("cargo:rustc-link-lib=static=ggml");
    println!("cargo:rustc-link-lib=static=llamawrapper");

    // Platform-specific linking
    if target.contains("windows") {
        println!("cargo:rustc-link-lib=dylib=kernel32");
        println!("cargo:rustc-link-lib=dylib=user32");
        println!("cargo:rustc-link-lib=dylib=shell32");
        if cfg!(feature = "cuda") {
            println!("cargo:rustc-link-lib=dylib=cudart");
            println!("cargo:rustc-link-lib=dylib=cublas");
        }
    } else if target.contains("apple") {
        println!("cargo:rustc-link-lib=dylib=c++");
        println!("cargo:rustc-link-lib=framework=Accelerate");
        if cfg!(feature = "metal") {
            println!("cargo:rustc-link-lib=framework=Metal");
            println!("cargo:rustc-link-lib=framework=MetalKit");
        }
    } else {
        println!("cargo:rustc-link-lib=dylib=stdc++");
        println!("cargo:rustc-link-lib=dylib=m");
        println!("cargo:rustc-link-lib=dylib=pthread");
        if cfg!(feature = "cuda") {
            println!("cargo:rustc-link-lib=dylib=cudart");
            println!("cargo:rustc-link-lib=dylib=cublas");
        }
        if cfg!(feature = "blas") {
            println!("cargo:rustc-link-lib=dylib=openblas");
        }
    }

    println!("✅ Library linking configured");
}