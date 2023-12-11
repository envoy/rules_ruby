load("//ruby/private:providers.bzl", "GemInfo")

def _rb_gem_install_impl(ctx):
    gem = ctx.file.gem
    install_dir = ctx.actions.declare_directory(gem.basename[:-4])

    args = ctx.actions.args()
    args.add("install")
    args.add(gem)
    args.add("--install-dir")
    args.add(install_dir.path)
    args.add("--bindir")
    args.add(install_dir.path + "/bin")
    args.add("--wrappers")
    args.add("--no-env-shebang")
    args.add("--ignore-dependencies")
    args.add("--no-document")
    args.add("--local")
    args.add("--quiet")
    args.add("--silent")

    ctx.actions.run(
        inputs = depset([gem]),
        executable = ctx.toolchains["@rules_ruby//ruby:toolchain_type"].gem,
        arguments = [args],
        outputs = [install_dir],
        use_default_shell_env = True,
    )

    return [
        DefaultInfo(
            files = depset([gem, install_dir]),
        ),
        GemInfo(
            name = ctx.attr.name.rpartition("-")[0],
            version = ctx.attr.name.rpartition("-")[-1],
        ),
    ]

rb_gem_install = rule(
    _rb_gem_install_impl,
    attrs = {
        "gem": attr.label(
            allow_single_file = [".gem"],
            mandatory = True,
            doc = """
Gem file to install.
            """,
        ),
    },
    toolchains = [
        "@rules_ruby//ruby:toolchain_type",
        "@bazel_tools//tools/jdk:runtime_toolchain_type",
    ],
)
