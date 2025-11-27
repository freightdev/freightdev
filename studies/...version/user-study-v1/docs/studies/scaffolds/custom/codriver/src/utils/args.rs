//! args.rs - Defines and centralizes all Clap arguments for CoDriver CLI.

use clap::{Arg, ArgAction, Command};

pub fn build_args() -> Command {
    Command::new("codriver")
        .version("0.1.0")
        .author("Jesse E.E.W. Conley")
        .about("CoDriver - Built to drive devs forward, not backward")
        .arg(Arg::new("ask").long("ask").value_name("DIR").help("Ask a question about the project").num_args(1))
        .arg(Arg::new("chat").long("chat").value_name("DIR").help("Start an interactive chat session").num_args(1))
        .arg(Arg::new("clean").long("clean").help("Clean temp memory, logs, and cache"))
        .arg(Arg::new("create").long("create").value_name("PATH").help("Create a new file/module from instruction").num_args(1))
        .arg(Arg::new("edit").long("edit").value_name("FILE").help("Edit file using AI instruction").num_args(1))
        .arg(Arg::new("explain").long("explain").value_name("FILE").help("Explain selected code or file").num_args(1))
        .arg(Arg::new("fix").long("fix").value_name("FILE").help("Fix problems in a file").num_args(1))
        .arg(Arg::new("learn").long("learn").value_name("FILE").help("Break down code into learning steps").num_args(1))
        .arg(Arg::new("scan").long("scan").value_name("DIR").help("Scan project for patterns, TODOs, and structure").num_args(1))
        .arg(Arg::new("setup").long("setup").help("Initialize prompts, config, and memory"))
        .arg(Arg::new("test").long("test").value_name("FILE").help("Generate, run, or validate tests").num_args(1))

        // Shared optional arguments
        .arg(Arg::new("instruction").long("instruction").value_name("TEXT").help("Instruction to guide AI").num_args(1))
        .arg(Arg::new("question").long("question").value_name("TEXT").help("Ask a freeform question").num_args(1))
        .arg(Arg::new("line").long("line").value_name("N").value_parser(clap::value_parser!(usize)).help("Target a specific line"))
        .arg(Arg::new("range").long("range").value_name("START:END").help("Target a line range").num_args(1))
        .arg(Arg::new("mode").long("mode").value_name("MODE").help("Specify mode (generate, run, validate)").num_args(1))
        .arg(Arg::new("ext").long("ext").num_args(1..).help("File extensions to include (default: rs,ts,js,py,sh)"))

        // Toggles
        .arg(Arg::new("diff").long("diff").help("Show diff instead of raw output").action(ArgAction::SetTrue))
        .arg(Arg::new("write").long("write").help("Write output directly to file").action(ArgAction::SetTrue))
        .arg(Arg::new("log").long("log").help("Save output to .logs").action(ArgAction::SetTrue))
        .arg(Arg::new("clipboard").long("clipboard").help("Copy output to clipboard").action(ArgAction::SetTrue))
        .arg(Arg::new("debug").long("debug").help("Print prompt and trace details").action(ArgAction::SetTrue))
        .arg(Arg::new("dry-run").long("dry-run").help("Preview cleanup actions without deleting").action(ArgAction::SetTrue))
        .arg(Arg::new("benchmark").long("benchmark").help("Print run time").action(ArgAction::SetTrue))
}
