load("//ruby/private:providers.bzl", "BundlerInfo", "GemInfo", "RubyFilesInfo")

def _rb_bundle_install_impl(ctx):
    toolchain = ctx.toolchains["@rules_ruby//ruby:toolchain_type"]

    cache = ctx.actions.declare_directory("vendor/cache")
    prepare_bundle_path = ctx.actions.declare_file("prepare_bundle_path.rb")
    ctx.actions.expand_template(
        template = ctx.file._prepare_bundle_path_tpl,
        output = prepare_bundle_path,
        substitutions = {
            "{cache_path}": cache.path,
        },
    )

    args = ctx.actions.args()
    args.add(prepare_bundle_path)
    args.add_all(ctx.files.gems, expand_directories = False)
    ctx.actions.run(
        inputs = ctx.files.gems + [prepare_bundle_path],
        executable = toolchain.ruby,
        arguments = [args],
        outputs = [cache],
    )

    tools = [toolchain.ruby, toolchain.bundle]
    bundler_path = toolchain.bundle.path
    gem_path = ""
    for gem in ctx.attr.gems:
        if gem[GemInfo].name == "bundler":
            bundler_path = gem.files.to_list()[-1].path + "/bin/bundle"
            gem_path = gem.files.to_list()[-1].path
            tools.extend(gem.files.to_list())

    binstubs = ctx.actions.declare_directory("bin")
    bpath = ctx.actions.declare_directory("vendor/bundle")
    home = ctx.actions.declare_directory("home")

    windows_constraint = ctx.attr._windows_constraint[platform_common.ConstraintValueInfo]
    is_windows = ctx.target_platform_has_constraint(windows_constraint)
    if is_windows:
        path = toolchain.bindir.replace("/", "\\")
        ruby_path = toolchain.ruby.path.replace("/", "\\")
        script = ctx.actions.declare_file("{}.cmd".format(ctx.label.name))
        bundler_path = bundler_path.replace("/", "\\")
        template = ctx.file._bundle_install_cmd_tpl
    else:
        path = toolchain.bindir
        ruby_path = toolchain.ruby.path
        script = ctx.actions.declare_file("{}.sh".format(ctx.label.name))
        template = ctx.file._bundle_install_sh_tpl

    ctx.actions.expand_template(
        template = template,
        output = script,
        substitutions = {
            "{binstubs_path}": "../../" + binstubs.path,
            "{bundle_path}": bpath.path,
            "{gemfile_path}": ctx.file.gemfile.path,
            "{cache_path}": "../../" + cache.path,
            "{home_path}": "../../" + home.path,
            "{bundler_path}": bundler_path,
            "{ruby_path}": ruby_path,
            "{gem_path}": gem_path,
            "{path}": path,
        },
    )

    ctx.actions.run(
        inputs = depset([cache, ctx.file.gemfile, ctx.file.gemfile_lock, ctx.file._runfiles_library] + ctx.files.srcs),
        executable = script,
        outputs = [binstubs, bpath, home],
        execution_requirements = {
            # "requires-network": "true",
        },
        use_default_shell_env = True,
        tools = tools + [ctx.file._runfiles_library],
    )

    files = [
        ctx.file.gemfile,
        ctx.file.gemfile_lock,
        binstubs,
        home,
        cache,
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
            transitive_data = depset([home]),
            bundle_env = {},
        ),
        BundlerInfo(
            bin = binstubs,
            gemfile = ctx.file.gemfile,
            cache = cache,
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
        "_prepare_bundle_path_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//ruby/private:bundle_install/prepare_bundle_path.rb.tpl",
        ),
    },
    toolchains = [
        "@rules_ruby//ruby:toolchain_type",
        "@bazel_tools//tools/jdk:runtime_toolchain_type",
    ],
)
