"Implementation details for rb_bundle_install"

load("//ruby/private:providers.bzl", "BundlerInfo", "GemInfo", "RubyFilesInfo")
load(
    "//ruby/private:utils.bzl",
    _environment_commands = "environment_commands",
    _is_windows = "is_windows",
)

def _rb_bundle_install_impl(ctx):
    toolchain = ctx.toolchains["@rules_ruby//ruby:toolchain_type"]

    tools = [toolchain.ruby, toolchain.bundle]
    bundler_exe = toolchain.bundle.path

    for gem in ctx.attr.gems:
        if gem[GemInfo].name == "bundler":
            full_name = "%s-%s" % (gem[GemInfo].name, gem[GemInfo].version)
            bundler_exe = gem.files.to_list()[-1].path + "/gems/" + full_name + "/exe/bundle"
            tools.extend(gem.files.to_list())

    binstubs = ctx.actions.declare_directory("bin")
    bpath = ctx.actions.declare_directory("vendor/bundle")

    env = {}
    env.update(toolchain.env)
    if toolchain.version.startswith("jruby"):
        java_toolchain = ctx.toolchains["@bazel_tools//tools/jdk:runtime_toolchain_type"]
        tools.extend(java_toolchain.java_runtime.files.to_list())
        env.update({"JAVA_HOME": java_toolchain.java_runtime.java_home})

    if _is_windows(ctx):
        bundle_path = bpath.path.replace("/", "\\")
        gemfile_path = ctx.file.gemfile.path.replace("/", "\\")
        path = toolchain.bindir.replace("/", "\\")
        ruby_path = toolchain.ruby.path.replace("/", "\\")
        script = ctx.actions.declare_file("bundle_install_{}.cmd".format(ctx.label.name))
        bundler_exe = bundler_exe.replace("/", "\\")
        template = ctx.file._bundle_install_cmd_tpl
        env.update({"PATH": path + ":%PATH%"})
    else:
        bundle_path = bpath.path
        gemfile_path = ctx.file.gemfile.path
        path = toolchain.bindir
        ruby_path = toolchain.ruby.path
        script = ctx.actions.declare_file("bundle_install_{}.sh".format(ctx.label.name))
        template = ctx.file._bundle_install_sh_tpl
        env.update({"PATH": "%s:$PATH" % path})

    env.update({
        "BUNDLE_BIN": "../../%s" % binstubs.path,
        "BUNDLE_DEPLOYMENT": "1",
        "BUNDLE_DISABLE_SHARED_GEMS": "1",
        "BUNDLE_DISABLE_VERSION_CHECK": "1",
        "BUNDLE_GEMFILE": gemfile_path,
        "BUNDLE_IGNORE_CONFIG": "1",
        "BUNDLE_PATH": "../../%s" % bundle_path,
        "BUNDLE_SHEBANG": ruby_path,
    })

    ctx.actions.expand_template(
        template = template,
        output = script,
        substitutions = {
            "{env}": _environment_commands(ctx, env),
            "{bundler_exe}": bundler_exe,
            "{ruby_path}": ruby_path,
        },
    )

    ctx.actions.run(
        inputs = depset([ctx.file.gemfile, ctx.file.gemfile_lock] + ctx.files.srcs + ctx.files.gems),
        executable = script,
        outputs = [binstubs, bpath],
        use_default_shell_env = True,
        tools = tools,
    )

    files = [
        ctx.file.gemfile,
        ctx.file.gemfile_lock,
        binstubs,
        bpath,
    ] + ctx.files.srcs

    return [
        DefaultInfo(
            files = depset(files),
            runfiles = ctx.runfiles(files),
        ),
        RubyFilesInfo(
            transitive_srcs = depset([ctx.file.gemfile, ctx.file.gemfile_lock] + ctx.files.srcs),
            transitive_deps = depset(),
            transitive_data = depset([]),
            bundle_env = {},
        ),
        BundlerInfo(
            bin = binstubs,
            gemfile = ctx.file.gemfile,
            path = bpath,
            # vendor = vendor,
        ),
    ]

rb_bundle_install = rule(
    _rb_bundle_install_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            doc = "List of Ruby source files used to build the library.",
        ),
        "gemfile": attr.label(
            allow_single_file = ["Gemfile"],
            doc = "Gemfile to install dependencies from.",
        ),
        "gemfile_lock": attr.label(
            allow_single_file = ["Gemfile.lock"],
            doc = "Gemfile to install dependencies from.",
        ),
        "gems": attr.label_list(
            allow_files = True,
            doc = "List of runtime dependencies needed by a program that depends on this library.",
        ),
        "_runfiles_library": attr.label(
            allow_single_file = True,
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "_bundle_install_sh_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//ruby/private:bundle_install/bundle_install.sh.tpl",
        ),
        "_bundle_install_cmd_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//ruby/private:bundle_install/bundle_install.cmd.tpl",
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
