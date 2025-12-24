src/
├── main.rs
├── libs.rs
├── kernel/
│   ├── mod.rs
│   ├── boot.rs
│   ├── runloop.rs
│   ├── dispatch.rs
│   ├── orchestrator.rs
│   ├── kernel.rs
│   ├── pulse.rs
├── core/
│   ├── mod.rs
│   ├── engine.rs
│   ├── parser.rs
│   ├── router.rs
│   ├── controller.rs
│   ├── bridge.rs
│   ├── reasoner.rs
│   ├── reactor.rs
├── context/
│   ├── mod.rs
│   ├── session.rs
│   ├── runtime.rs
│   ├── global.rs
│   ├── web.rs
│   ├── memory.rs
│   └── auth.rs
├── agent/
│   ├── mod.rs
│   ├── profile.rs
│   ├── persona.rs
│   ├── memory.rs
│   ├── scope.rs
│   ├── registry.rs
│   ├── access.rs
│   └── fallback.rs
├── protocol/
│   ├── mod.rs
│   ├── mark.rs
│   ├── trail.rs
│   ├── ribbon.rs
│   ├── scroll.rs
│   ├── page.rs
│   ├── cover.rs
│   ├── chapter.rs
│   ├── marker.rs
│   ├── bookmark.rs
│   └── process.rs
├── scheduler/
│   ├── mod.rs
│   ├── task.rs
│   ├── queue.rs
│   ├── runner.rs
│   ├── priority.rs
│   ├── timeout.rs
│   └── window.rs
├── kvcache/
│   ├── mod.rs
│   ├── buffer.rs
│   ├── memstore.rs
│   ├── segment.rs
│   ├── ttl.rs
│   ├── journal.rs
│   ├── watcher.rs
│   └── policy.rs
├── hooks/
│   ├── mod.rs
│   ├── pre.rs
│   ├── post.rs
│   ├── runtime.rs
│   ├── fs.rs
│   ├── agent.rs
│   └── ui.rs
├── cli/
│   ├── mod.rs
│   ├── runner.rs
│   ├── commands/
│   │   ├── mark/
│   │   ├── trail/
│   │   ├── page/
│   │   ├── book/
│   │   ├── ribbon/
│   │   ├── scroll/
│   │   ├── marker/
│   │   └── agent/
│   └── flags/
│       ├── parse.rs
│       ├── plan.rs
│       ├── simulate.rs
│       ├── walk.rs
│       ├── replay.rs
│       ├── fast.rs
│       ├── safe.rs
│       ├── lint.rs
│       ├── score.rs
│       └── view.rs
├── io/
│   ├── mod.rs
│   ├── input.rs
│   ├── output.rs
│   ├── prompt.rs
│   ├── renderer.rs
│   ├── template.rs
│   ├── highlighter.rs
│   └── formatter.rs
├── tokenizer/
│   ├── mod.rs
│   ├── decode.rs
│   ├── encode.rs
│   ├── normalize.rs
│   ├── builder.rs
│   ├── analyzer.rs
│   ├── vocab.rs
│   ├── special.rs
│   ├── stats.rs
│   └── batch.rs
├── system/
│   ├── mod.rs
│   ├── buildinfo.rs
│   ├── args.rs
│   ├── fs.rs
│   ├── deps.rs
│   ├── log.rs
│   ├── env/
│   │   ├── env.rs
│   │   ├── panic.rs
│   │   ├── telemetry.rs
│   │   └── time.rs
│   ├── config/
│   │   ├── config.rs
│   │   ├── constants.rs
│   │   ├── version.rs
│   │   └── policy.rs
│   ├── setup/
│   │   ├── init.rs
│   │   ├── validate.rs
│   │   ├── prelube.rs
│   │   └── setup.rs
│   └── state/
│       ├── cache.rs
│       └── state.rs
├── types/
│   ├── mod.rs
│   ├── types.rs
│   ├── context.rs
│   ├── session.rs
│   ├── schema.rs
│   ├── traits.rs
│   ├── token.rs
│   ├── meta.rs
│   ├── model.rs
│   ├── flags.rs
│   ├── enums.rs
│   ├── request.rs
│   └── response.rs
├── utils/
│   ├── mod.rs
│   ├── fs.rs
│   ├── id.rs
│   ├── style.rs
│   ├── hook.rs
│   ├── path.rs
│   ├── format.rs
│   ├── fix.rs
│   ├── output.rs
│   ├── macros.rs
│   ├── time.rs
│   ├── metrics.rs
│   └── agents.rs
├── tests/
│   ├── unit/
│   │   └── main_test.rs
│   └── integration/
│       ├── runner_test.rs
│       └── ribbon_test.rs
