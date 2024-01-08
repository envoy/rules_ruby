"Implementation details for rb_gem_install"

load("//ruby/private:providers.bzl", "GemInfo")
load(
    "//ruby/private:utils.bzl",
    _environment_commands = "environment_commands",
    _is_windows = "is_windows",
)

def _rb_gem_install_impl(ctx):
    gem = ctx.file.src
    install_dir = ctx.actions.declare_directory(gem.basename[:-4])
    toolchain = ctx.toolchains["@rules_ruby//ruby:toolchain_type"]

    env = {}
    tools = [toolchain.gem]
    java_home = ""
    if toolchain.version.startswith("jruby"):
        java_toolchain = ctx.toolchains["@bazel_tools//tools/jdk:runtime_toolchain_type"]
        tools.extend(java_toolchain.java_runtime.files.to_list())
        java_home = java_toolchain.java_runtime.java_home
        env.update({
            "JAVA_HOME": java_home,
            "JAVA_OPTS": "-Djdk.io.File.enableADS=true",
        })
    elif toolchain.version.startswith("truffleruby"):
        env.update({"LANG": "en_US.UTF-8"})

    if _is_windows(ctx):
        toolchain_bindir = toolchain.bindir.replace("/", "\\")
        gem_binary = toolchain.gem.path.replace("/", "\\")
        gem_install = ctx.actions.declare_file("gem_install_{}.cmd".format(ctx.label.name))
        template = ctx.file._gem_install_cmd_tpl
        env.update({"PATH": toolchain_bindir + ":%PATH%"})
    else:
        toolchain_bindir = toolchain.bindir
        gem_binary = toolchain.gem.path
        gem_install = ctx.actions.declare_file("gem_install_{}.sh".format(ctx.label.name))
        template = ctx.file._gem_install_sh_tpl
        env.update({"PATH": "%s:$PATH" % toolchain_bindir})

    ctx.actions.expand_template(
        template = template,
        output = gem_install,
        substitutions = {
            "{env}": _environment_commands(ctx, env),
            "{gem_binary}": gem_binary,
            "{gem}": gem.path,
            "{install_dir}": install_dir.path,
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
