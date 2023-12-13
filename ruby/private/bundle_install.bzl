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
    gem_path = "123"
    for gem in ctx.attr.gems:
        if gem[GemInfo].name == "bundler":
            bundler_path = gem.files.to_list()[-1].path + "/bin/bundle"
            gem_path = gem.files.to_list()[-1].path
            tools.extend(gem.files.to_list())

    binstubs = ctx.actions.declare_directory("bin")
    bpath = ctx.actions.declare_directory("vendor/bundle")
    home = ctx.actions.declare_directory("home")
    script = ctx.actions.declare_file("bundle_install.sh")
    ctx.actions.expand_template(
        template = ctx.file._bundle_install_tpl,
        output = script,
        substitutions = {
            "{binstubs_path}": "../../" + binstubs.path,
            "{gemfile_path}": ctx.file.gemfile.path,
            "{bundle_path}": "../../" + bpath.path,
            "{home_path}": "../../" + home.path,
            "{bundler_path}": bundler_path,
            "{ruby_path}": toolchain.ruby.path,
            "{gem_path}": gem_path,
            "{path}": toolchain.bindir,
        },
    )

    ctx.actions.run(
        inputs = depset([cache, ctx.file.gemfile, ctx.file.gemfile_lock] + ctx.files.srcs),
        executable = script,
        outputs = [binstubs, bpath, home],
        execution_requirements = {
            "requires-network": "true",
        },
        use_default_shell_env = True,
        tools = tools,
    )

    return [
        DefaultInfo(
            files = depset([
                ctx.file.gemfile,
                ctx.file.gemfile_lock,
                binstubs,
                home,
                cache,
                bpath,
            ] + ctx.files.srcs),
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
        "_bundle_install_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//ruby/private:bundle_install/bundle_install.sh.tpl",
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
