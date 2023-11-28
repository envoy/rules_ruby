load(
    "//ruby/private:providers.bzl",
    "RubyFilesInfo",
)

def _rb_bundle_install_impl(ctx):
    windows_constraint = ctx.attr._windows_constraint[platform_common.ConstraintValueInfo]
    is_windows = ctx.target_platform_has_constraint(windows_constraint)
    tools = depset([])
    java_toolchain = ctx.toolchains["@bazel_tools//tools/jdk:runtime_toolchain_type"]
    ruby_toolchain = ctx.toolchains["@rules_ruby//ruby:toolchain_type"]

    binstubs = ctx.actions.declare_directory("binstubs")
    # rake = ctx.actions.declare_file("binstubs/rake")

    env = {
        "BUNDLE_ALLOW_OFFLINE_INSTALL": "true",
        "BUNDLE_BIN": binstubs.short_path,
        "BUNDLE_SHEBANG": ruby_toolchain.ruby.path,
        "BUNDLE_CACHE_PATH": "../bundle/vendor/cache",
        # "BUNDLE_DISABLE_VERSION_CHECK": "true",
        "BUNDLE_DISABLE_CHECKSUM_VALIDATION": "true",
        "BUNDLE_GEMFILE": "external/bundle/Gemfile",
        # "BUNDLE_STANDALONE": "true",
        # "PATH": ruby_toolchain.ruby.dirname,
    }

    if ruby_toolchain.version.startswith("jruby"):
        env["JAVA_HOME"] = java_toolchain.java_runtime.java_home
        tools = java_toolchain.java_runtime.files
        if is_windows:
            env["PATH"] = ruby_toolchain.ruby.dirname

    args = ctx.actions.args()
    args.add("install")
    args.add("--local")

    inputs = ctx.files.srcs + [ctx.file.gemfile, ctx.file.gemfile_lock]

    ctx.actions.run(
        inputs = depset(inputs),
        executable = ruby_toolchain.bundle,
        arguments = [args],
        outputs = [binstubs],
        env = env,
        # use_default_shell_env = not is_windows,
        tools = tools,
    )

    return [
        RubyFilesInfo(
            transitive_data = depset([binstubs]),
            transitive_deps = depset([]),
            transitive_srcs = depset(inputs),
            bundle_env = {},
        ),
    ]

rb_bundle_install = rule(
    implementation = _rb_bundle_install_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            doc = """
List of Ruby source files used to build the library.
            """,
        ),
        "gemfile": attr.label(
            allow_single_file = ["Gemfile"],
            doc = """
Gemfile to install dependencies from.
            """,
        ),
        "gemfile_lock": attr.label(
            allow_single_file = ["Gemfile.lock"],
            doc = """
Gemfile.lock to install dependencies from.
            """,
        ),
        "_windows_constraint": attr.label(
            default = "@platforms//os:windows",
        ),
    },
    toolchains = [
        "@rules_ruby//ruby:toolchain_type",
        "@bazel_tools//tools/jdk:runtime_toolchain_type",
    ],
)
