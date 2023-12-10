load(
    "//ruby/private:providers.bzl",
    "BundlerInfo",
    "RubyFilesInfo",
)

def _rb_bundle_gem_install_impl(ctx):
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
    args.add("--env-shebang")
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
    )

    return [
        DefaultInfo(
            files = depset([gem, install_dir]),
        ),
    ]

rb_bundle_gem_install = rule(
    _rb_bundle_gem_install_impl,
    attrs = {
        "gem": attr.label(
            allow_single_file = True,
        ),
    },
    toolchains = [
        "@rules_ruby//ruby:toolchain_type",
        "@bazel_tools//tools/jdk:runtime_toolchain_type",
    ],
)

def _rb_bundle_install_impl(ctx):
    toolchain = ctx.toolchains["@rules_ruby//ruby:toolchain_type"]

    vendor = ctx.actions.declare_directory("vendor")
    prepare_bundle_path = ctx.actions.declare_file("prepare_bundle_path.rb")
    ctx.actions.expand_template(
        template = ctx.file._prepare_bundle_path_tpl,
        output = prepare_bundle_path,
        substitutions = {
            "{vendor_path}": vendor.path,
        },
    )

    args = ctx.actions.args()
    args.add(prepare_bundle_path)
    args.add_all(ctx.files.gems, expand_directories = False)
    ctx.actions.run(
        inputs = ctx.files.gems + [prepare_bundle_path],
        executable = toolchain.ruby,
        arguments = [args],
        outputs = [vendor],
    )

    binstubs = ctx.actions.declare_directory("bin")
    args = ctx.actions.args()
    args.add("install")
    args.add("--local")
    args.add("--no-cache")
    ctx.actions.run(
        inputs = depset([vendor, ctx.file.gemfile, ctx.file.gemfile_lock] + ctx.files.srcs),
        executable = toolchain.bundle,
        arguments = [args],
        outputs = [binstubs],
        env = {
            "BUNDLE_BIN": "../../" + binstubs.path,
            "BUNDLE_CACHE_PATH": "../../" + vendor.path + "/cache",
            "BUNDLE_DEPLOYMENT": "true",
            "BUNDLE_GEMFILE": ctx.file.gemfile.path,
            "BUNDLE_PATH": "../../" + vendor.path + "/bundle",
            "BUNDLE_SHEBANG": toolchain.ruby.short_path,
        },
        tools = [toolchain.ruby, toolchain.bundle],
    )

    return [
        DefaultInfo(
            files = depset([ctx.file.gemfile, ctx.file.gemfile_lock, binstubs] + ctx.files.srcs),
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
            vendor = vendor,
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
