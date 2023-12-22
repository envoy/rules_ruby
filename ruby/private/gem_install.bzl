load("//ruby/private:providers.bzl", "GemInfo")

def _rb_gem_install_impl(ctx):
    gem = ctx.file.src
    install_dir = ctx.actions.declare_directory(gem.basename[:-4])
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

    windows_constraint = ctx.attr._windows_constraint[platform_common.ConstraintValueInfo]
    is_windows = ctx.target_platform_has_constraint(windows_constraint)
    if is_windows:
        toolchain_bindir = toolchain.bindir.replace("/", "\\")
        gem_binary = toolchain.gem.path.replace("/", "\\")
        gem_install = ctx.actions.declare_file("gem_install_{}.cmd".format(ctx.label.name))
        template = ctx.file._gem_install_cmd_tpl
    else:
        toolchain_bindir = toolchain.bindir
        gem_binary = toolchain.gem.path
        gem_install = ctx.actions.declare_file("gem_install_{}.sh".format(ctx.label.name))
        template = ctx.file._gem_install_sh_tpl

    ctx.actions.expand_template(
        template = template,
        output = gem_install,
        substitutions = {
            "{toolchain_bindir}": toolchain_bindir,
            "{gem_binary}": gem_binary,
            "{gem}": gem.path,
            "{install_dir}": install_dir.path,
        },
    )

    ctx.actions.run(
        inputs = depset([gem, gem_install]),
        executable = gem_install,
        outputs = [install_dir],
        # execution_requirements = {
        #     # "no-sandbox": "true",
        #     # "requires-network": "true",
        # },
        use_default_shell_env = True,
        tools = [toolchain.gem],
    )

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
        "src": attr.label(
            allow_single_file = [".gem"],
            mandatory = True,
            doc = "Gem file to install.",
        ),
        "_gem_install_cmd_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//ruby/private:gem_install/gem_install.cmd.tpl",
        ),
        "_gem_install_sh_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//ruby/private:gem_install/gem_install.sh.tpl",
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
