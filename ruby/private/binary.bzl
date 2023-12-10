"Implementation details for rb_binary"

load("//ruby/private:library.bzl", LIBRARY_ATTRS = "ATTRS")
load(
    "//ruby/private:providers.bzl",
    "BundlerInfo",
    "RubyFilesInfo",
    "get_bundle_env",
    "get_transitive_data",
    "get_transitive_deps",
    "get_transitive_runfiles",
    "get_transitive_srcs",
)
load("//ruby/private/binary:rlocation.bzl", "BASH_RLOCATION_FUNCTION", "BATCH_RLOCATION_FUNCTION")

ATTRS = {
    "main": attr.label(
        executable = True,
        allow_single_file = True,
        cfg = "exec",
        doc = """
Ruby script to run. It may also be a binary stub generated by Bundler.
If omitted, it defaults to the Ruby interpreter.

Use a built-in `args` attribute to pass extra arguments to the script.
        """,
    ),
    "env": attr.string_dict(
        doc = "Environment variables to use during execution.",
    ),
    "env_inherit": attr.string_list(
        doc = "List of environment variable names to be inherited by the test runner.",
    ),
    "_binary_cmd_tpl": attr.label(
        allow_single_file = True,
        default = "@rules_ruby//ruby/private/binary:binary.cmd.tpl",
    ),
    "_binary_sh_tpl": attr.label(
        allow_single_file = True,
        default = "@rules_ruby//ruby/private/binary:binary.sh.tpl",
    ),
    "_runfiles_library": attr.label(
        allow_single_file = True,
        default = "@bazel_tools//tools/bash/runfiles",
    ),
    "_windows_constraint": attr.label(
        default = "@platforms//os:windows",
    ),
}

_EXPORT_ENV_VAR_COMMAND = "{command} {name}={value}"
_EXPORT_BATCH_COMMAND = "set"
_EXPORT_BASH_COMMAND = "export"

# buildifier: disable=function-docstring
def generate_rb_binary_script(ctx, binary, bundler = False, args = [], env = {}, java_bin = ""):
    windows_constraint = ctx.attr._windows_constraint[platform_common.ConstraintValueInfo]
    is_windows = ctx.target_platform_has_constraint(windows_constraint)
    toolchain = ctx.toolchains["@rules_ruby//ruby:toolchain_type"]
    toolchain_bindir = toolchain.bindir

    if binary:
        binary_path = binary.short_path
    else:
        binary_path = ""

    if is_windows:
        binary_path = binary_path.replace("/", "\\")
        export_command = _EXPORT_BATCH_COMMAND
        rlocation_function = BATCH_RLOCATION_FUNCTION
        script = ctx.actions.declare_file("{}.rb.cmd".format(ctx.label.name))
        toolchain_bindir = toolchain_bindir.replace("/", "\\")
        template = ctx.file._binary_cmd_tpl
    else:
        export_command = _EXPORT_BASH_COMMAND
        rlocation_function = BASH_RLOCATION_FUNCTION
        script = ctx.actions.declare_file("{}.rb.sh".format(ctx.label.name))
        template = ctx.file._binary_sh_tpl

    if bundler:
        bundler_command = "bundle exec"
    else:
        bundler_command = ""

    args = " ".join(args)
    args = ctx.expand_location(args)

    environment = []
    for (name, value) in env.items():
        command = _EXPORT_ENV_VAR_COMMAND.format(command = export_command, name = name, value = value)
        environment.append(command)

    ctx.actions.expand_template(
        template = template,
        output = script,
        is_executable = True,
        substitutions = {
            "{args}": args,
            "{binary}": binary_path,
            "{toolchain_bindir}": toolchain_bindir,
            "{env}": "\n".join(environment),
            "{bundler_command}": bundler_command,
            "{ruby_binary_name}": toolchain.ruby.basename,
            "{java_bin}": java_bin,
            "{rlocation_function}": rlocation_function,
        },
    )

    return script

# buildifier: disable=function-docstring
def rb_binary_impl(ctx):
    bundler = False
    env = {}
    java_bin = ""

    # TODO: avoid expanding the depset to a list, it may be expensive in a large graph
    transitive_data = get_transitive_data(ctx.files.data, ctx.attr.deps).to_list()
    transitive_deps = get_transitive_deps(ctx.attr.deps).to_list()
    transitive_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps).to_list()

    ruby_toolchain = ctx.toolchains["@rules_ruby//ruby:toolchain_type"]
    tools = [ruby_toolchain.ruby, ruby_toolchain.bundle, ruby_toolchain.gem, ctx.file._runfiles_library]

    if ruby_toolchain.version.startswith("jruby"):
        java_toolchain = ctx.toolchains["@bazel_tools//tools/jdk:runtime_toolchain_type"]
        tools.extend(java_toolchain.java_runtime.files.to_list())
        java_bin = java_toolchain.java_runtime.java_executable_runfiles_path[3:]

    for dep in ctx.attr.deps:
        if BundlerInfo in dep:
            info = dep[BundlerInfo]
            env.update({"BUNDLE_GEMFILE": info.gemfile.short_path.partition("/")[-1]})
            env.update({"BUNDLE_PATH": info.vendor.short_path.partition("/")[-1] + "/bundle"})
            transitive_srcs.extend([info.gemfile, info.bin, info.vendor])
            bundler = True

    bundle_env = get_bundle_env(ctx.attr.env, ctx.attr.deps)
    env.update(bundle_env)
    env.update(ctx.attr.env)

    runfiles = ctx.runfiles(transitive_srcs + transitive_data + tools)
    runfiles = get_transitive_runfiles(runfiles, ctx.attr.srcs, ctx.attr.deps, ctx.attr.data)

    script = generate_rb_binary_script(
        ctx,
        ctx.executable.main,
        bundler = bundler,
        env = env,
        java_bin = java_bin,
    )

    return [
        DefaultInfo(
            executable = script,
            files = depset(transitive_srcs + transitive_data + tools),
            runfiles = runfiles,
        ),
        RubyFilesInfo(
            transitive_data = depset(transitive_data),
            transitive_deps = depset(transitive_deps),
            transitive_srcs = depset(transitive_srcs),
            bundle_env = bundle_env,
        ),
        RunEnvironmentInfo(
            environment = env,
            inherited_environment = ctx.attr.env_inherit,
        ),
    ]

rb_binary = rule(
    implementation = rb_binary_impl,
    executable = True,
    attrs = dict(
        ATTRS,
        srcs = LIBRARY_ATTRS["srcs"],
        data = LIBRARY_ATTRS["data"],
        deps = LIBRARY_ATTRS["deps"],
    ),
    toolchains = [
        "@rules_ruby//ruby:toolchain_type",
        "@bazel_tools//tools/jdk:runtime_toolchain_type",
    ],
    doc = """
Runs a Ruby binary.

Suppose you have the following Ruby gem, where `rb_library()` is used
in `BUILD` files to define the packages for the gem.

```output
|-- BUILD
|-- Gemfile
|-- WORKSPACE
|-- gem.gemspec
`-- lib
    |-- BUILD
    |-- gem
    |   |-- BUILD
    |   |-- add.rb
    |   |-- subtract.rb
    |   `-- version.rb
    `-- gem.rb
```

One of the files can be run as a Ruby script:

`lib/gem/version.rb`:
```ruby
module GEM
  VERSION = '0.1.0'
end

puts "Version is: #{GEM::VERSION}" if __FILE__ == $PROGRAM_NAME
```

You can run this script by defining a target:

`lib/gem/BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_binary", "rb_library")

rb_library(
    name = "version",
    srcs = ["version.rb"],
)

rb_binary(
    name = "print-version",
    args = ["lib/gem/version.rb"],
    deps = [":version"],
)
```

```output
$ bazel run lib/gem:print-version
INFO: Analyzed target //lib/gem:print-version (1 packages loaded, 3 targets configured).
INFO: Found 1 target...
Target //lib/gem:print-version up-to-date:
  bazel-bin/lib/gem/print-version.rb.sh
INFO: Elapsed time: 0.121s, Critical Path: 0.01s
INFO: 4 processes: 4 internal.
INFO: Build completed successfully, 4 total actions
INFO: Build completed successfully, 4 total actions
Version is: 0.1.0
```

You can also run general purpose Ruby scripts that rely on a Ruby interpreter in PATH:

`lib/gem/add.rb`:
```ruby
#!/usr/bin/env ruby

a, b = *ARGV
puts Integer(a) + Integer(b)
```

`lib/gem/BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_binary", "rb_library")

rb_library(
    name = "add",
    srcs = ["add.rb"],
)

rb_binary(
    name = "add-numbers",
    main = "add.rb",
    deps = [":add"],
)
```

```output
$ bazel run lib/gem:add-numbers 1 2
INFO: Analyzed target //lib/gem:add-numbers (1 packages loaded, 3 targets configured).
INFO: Found 1 target...
Target //lib/gem:add-numbers up-to-date:
  bazel-bin/lib/gem/add-numbers.rb.sh
INFO: Elapsed time: 0.092s, Critical Path: 0.00s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
INFO: Build completed successfully, 1 total action
3
```

You can also run a Ruby binary script available in Gemfile dependencies,
by passing `bin` argument with a path to a Bundler binary stub:

`BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_binary")

package(default_visibility = ["//:__subpackages__"])

rb_binary(
    name = "rake",
    main = "@bundle//:bin/rake",
    deps = [
        "//lib:gem",
        "@bundle",
    ],
)
```

```output
$ bazel run :rake -- --version
INFO: Analyzed target //:rake (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
Target //:rake up-to-date:
  bazel-bin/rake.rb.sh
INFO: Elapsed time: 0.073s, Critical Path: 0.00s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
INFO: Running command line: bazel-bin/rake.rb.sh --version
rake, version 10.5.0
```
    """,
)
