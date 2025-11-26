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
    fs::create_dir_all(&build_dir).expect("❌ Failed to create build dir");

    // 1) Configure cmake
    const CMAKE_FLAGS: &[&str] = &[
        "-S", ".", "-B", "build", "-G", "Unix Makefiles",
        "-DBUILD_SHARED_LIBS=OFF",
        "-DLLAMA_BUILD_TESTS=OFF",
        "-DLLAMA_BUILD_EXAMPLES=OFF",
        "-DLLAMA_BUILD_SERVER=OFF",
        "-DLLAMA_BUILD_TOOLS=OFF",
        "-DCMAKE_POSITION_INDEPENDENT_CODE=ON",
        "-DCMAKE_BUILD_TYPE=Release",
    ];

    Command::new("cmake")
        .args(CMAKE_FLAGS)
        .current_dir(&llama_root)
        .status()
        .expect("❌ cmake configure failed")
        .success()
        .then_some(())
        .expect("❌ cmake configure returned error");

    // 2) Build
    Command::new("cmake")
        .args(["--build", "build", "--parallel"])
        .current_dir(&llama_root)
        .status()
        .expect("❌ cmake build failed")
        .success()
        .then_some(())
        .expect("❌ build returned error");

    // 3) Link static llama libs
    println!("cargo:rustc-link-search=native={}", build_dir.join("src").display());
    println!("cargo:rustc-link-search=native={}", build_dir.join("ggml").join("src").display());

    for lib in ["llama", "ggml", "ggml-base", "ggml-cpu"] {
        println!("cargo:rustc-link-lib=static={}", lib);
    }

    for sys in ["stdc++", "m", "pthread", "gomp"] {
        println!("cargo:rustc-link-lib=dylib={}", sys);
    }

    // 4) Watch for changes
    println!("cargo:rerun-if-changed=wrapper.h");
    println!("cargo:rerun-if-changed=llama.cpp/CMakeLists.txt");

    // 5) Auto-regenerate bindings if wrapper is newer or feature is enabled
    let out_path = PathBuf::from("bindings/llama_cpp.rs");
    if should_regenerate("wrapper.h", &out_path)
        || env::var("CARGO_FEATURE_REGEN_BINDINGS").is_ok()
    {
        generate_bindings(&llama_root, &out_path);
    }
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
        fs::rename(&out_path, &backup_path)
            .unwrap_or_else(|e| panic!("❌ Failed to backup old llama_cpp.rs: {}", e));
        println!("cargo:warning=📦 Backed up old bindings → llama_cpp.old.rs");
    }

    // Generate new
    let bindings = bindgen::Builder::default()
        .header("wrapper.h")
        .parse_callbacks(Box::new(bindgen::CargoCallbacks::new()))
        .allowlist_function("llama_.*")
        .allowlist_type("llama_.*")
        .allowlist_var("llama_.*")
        .clang_arg(format!("-I{}", llama_root.join("include").display()))
        .clang_arg(format!("-I{}", llama_root.join("ggml/include").display()))
        .generate()
        .expect("❌ bindgen generation failed");

    let mut file = fs::File::create(out_path)
        .unwrap_or_else(|e| panic!("❌ Failed to write {}: {}", out_path.display(), e));
    file.write_all(bindings.to_string().as_bytes())
        .expect("❌ Failed to write bindings");

    println!("cargo:warning=✅ FFI bindings regenerated → {}", out_path.display());
}
