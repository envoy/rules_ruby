load("//ruby/private:providers.bzl", "GemInfo")

def _rb_gem_install_impl(ctx):
    gem = ctx.file.gem

    # install_dir = ctx.actions.declare_directory(gem.basename[:-4])
    toolchain = ctx.toolchains["@rules_ruby//ruby:toolchain_type"]

    # args = ctx.actions.args()
    # args.add("install")
    # args.add(gem)
    # args.add("--install-dir")
    # args.add(install_dir.path)
    # args.add("--bindir")
    # args.add(install_dir.path + "/bin")
    # args.add("--wrappers")
    # args.add("--no-env-shebang")
    # args.add("--ignore-dependencies")
    # args.add("--no-document")
    # args.add("--local")
    # # args.add("--quiet")
    # # args.add("--silent")

    # gem_install = ctx.actions.declare_file("gem_install_%s.sh" % ctx.attr.name)
    # ctx.actions.expand_template(
    #     template = ctx.file._gem_install_tpl,
    #     output = gem_install,
    #     substitutions = {
    #         "{toolchain_bindir}": toolchain.bindir,
    #         "{gem_binary}": toolchain.gem.path,
    #         "{gem}": gem.path,
    #         "{install_dir}": install_dir.path,
    #     },
    # )

    # ctx.actions.run(
    #     inputs = depset([gem, gem_install]),
    #     executable = gem_install,
    #     outputs = [install_dir],
    #     # execution_requirements = {
    #     #     # "no-sandbox": "true",
    #     #     # "requires-network": "true",
    #     # },
    #     use_default_shell_env = True,
    #     tools = [toolchain.ruby, toolchain.gem],
    # )

    # TODO: Use tar to pack output files.
    # https://github.com/bazelbuild/bazel/issues/18140

    # ctx.actions.run(
    #     inputs = depset([gem]),
    #     executable = ctx.toolchains["@rules_ruby//ruby:toolchain_type"].gem,
    #     arguments = [args],
    #     outputs = [install_dir],
    #     # env = {
    #     #     "PATH": ctx.toolchains["@rules_ruby//ruby:toolchain_type"].bindir,
    #     # },
    #     use_default_shell_env = True,
    #     tools = [ctx.toolchains["@rules_ruby//ruby:toolchain_type"].ruby],
    # )

    return [
        DefaultInfo(
            files = depset([gem]),
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
        "_gem_install_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//ruby/private:gem_install/gem_install.sh.tpl",
        ),
    },
    toolchains = [
        "@rules_ruby//ruby:toolchain_type",
        "@bazel_tools//tools/jdk:runtime_toolchain_type",
    ],
)
