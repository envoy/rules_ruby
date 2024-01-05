load("//ruby/private:providers.bzl", "GemInfo")

def _rb_gem_install_impl(ctx):
    gem = ctx.file.src
    install_dir = ctx.actions.declare_directory(gem.basename[:-4])
    toolchain = ctx.toolchains["@rules_ruby//ruby:toolchain_type"]

    tools = [toolchain.gem]
    java_home = ""
    if toolchain.version.startswith("jruby"):
        java_toolchain = ctx.toolchains["@bazel_tools//tools/jdk:runtime_toolchain_type"]
        tools.extend(java_toolchain.java_runtime.files.to_list())
        java_home = java_toolchain.java_runtime.java_home

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
            "{java_home}": java_home,
        },
    )

    ctx.actions.run(
        inputs = depset([gem, gem_install]),
        executable = gem_install,
        outputs = [install_dir],
        use_default_shell_env = True,
        tools = tools,
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
