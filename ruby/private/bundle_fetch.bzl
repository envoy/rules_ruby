"Implementation details for fetch the bundler"

load("//ruby/private/bundle:gemfile_lock_parser.bzl", "parse_gemfile_lock")

def _rb_bundle_fetch_impl(repository_ctx):
    gemfile_path = repository_ctx.path(repository_ctx.attr.gemfile)
    gemfile_lock_path = repository_ctx.path(repository_ctx.attr.gemfile_lock)

    repository_ctx.file("Gemfile", repository_ctx.read(gemfile_path))
    repository_ctx.file("Gemfile.lock", repository_ctx.read(gemfile_lock_path))
    srcs = []
    for src in repository_ctx.attr.srcs:
        srcs.append(src.name)
        repository_ctx.file(src.name, repository_ctx.read(src))

    gems = []
    gemfile_lock = parse_gemfile_lock(repository_ctx.read(gemfile_lock_path))
    for gem in gemfile_lock.remote_packages:
        gems.append("%s-%s" % (gem.name, gem.version))
        repository_ctx.download(
            url = "https://rubygems.org/gems/{filename}".format(filename = gem.filename),
            output = gem.filename,
        )

    repository_ctx.template(
        "BUILD",
        repository_ctx.attr._build_tpl,
        executable = False,
        substitutions = {
            "{name}": repository_ctx.name,
            "{srcs}": repr(srcs),
            "{gems}": repr(gems),
        },
    )

    repository_ctx.file(
        "bin/BUILD",
        """
load("@rules_ruby//ruby:defs.bzl", "rb_library")

package(default_visibility = ["//visibility:public"])

rb_library(
    name = "bin",
    data = glob(["*"]),
    deps = ["//:bundle"],
)
        """,
    )

    repository_ctx.file("bin/rake")
    repository_ctx.file("bin/rspec")
    repository_ctx.file("bin/rubocop")

    # binstubs_path = repository_ctx.path("bin")
    # bundle_path = repository_ctx.path(".")
    # gemfile_path = repository_ctx.path(repository_ctx.attr.gemfile)
    # toolchain_path = repository_ctx.path(repository_ctx.attr.toolchain).dirname
    #
    # if repository_ctx.os.name.startswith("windows"):
    #     bundle = repository_ctx.path("%s/dist/bin/bundle.cmd" % toolchain_path)
    #     path_separator = ";"
    #     if repository_ctx.path("%s/dist/bin/jruby.exe" % toolchain_path).exists:
    #         ruby = repository_ctx.path("%s/dist/bin/jruby.exe" % toolchain_path)
    #     else:
    #         ruby = repository_ctx.path("%s/dist/bin/ruby.exe" % toolchain_path)
    # else:
    #     bundle = repository_ctx.path("%s/dist/bin/bundle" % toolchain_path)
    #     path_separator = ":"
    #     if repository_ctx.path("%s/dist/bin/jruby" % toolchain_path).exists:
    #         ruby = repository_ctx.path("%s/dist/bin/jruby" % toolchain_path)
    #     else:
    #         ruby = repository_ctx.path("%s/dist/bin/ruby" % toolchain_path)
    #
    # repository_ctx.template(
    #     "BUILD",
    #     repository_ctx.attr._build_tpl,
    #     executable = False,
    # )
    #
    # env = {
    #     "BUNDLE_BIN": repr(binstubs_path),
    #     "BUNDLE_GEMFILE": repr(gemfile_path),
    #     "BUNDLE_IGNORE_CONFIG": "1",
    #     "BUNDLE_PATH": repr(bundle_path),
    #     "BUNDLE_SHEBANG": repr(ruby),
    #     "PATH": path_separator.join([repr(ruby.dirname), repository_ctx.os.environ["PATH"]]),
    # }
    # env.update(repository_ctx.attr.env)
    #
    # bundle_env = {k: v for k, v in env.items() if k.startswith("BUNDLE_")}
    # repository_ctx.file(
    #     "defs.bzl",
    #     "BUNDLE_ENV = %s" % bundle_env,
    # )
    #
    # repository_ctx.report_progress("Running bundle install")
    # result = repository_ctx.execute(
    #     [bundle, "install"],
    #     environment = env,
    #     working_directory = repr(gemfile_path.dirname),
    #     quiet = not repository_ctx.os.environ.get("RUBY_RULES_DEBUG", default = False),
    # )
    #
    # if result.return_code != 0:
    #     fail("%s\n%s" % (result.stdout, result.stderr))

rb_bundle_fetch = repository_rule(
    implementation = _rb_bundle_fetch_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            doc = """
List of Ruby source files used to build the library.
            """,
        ),
        "gemfile": attr.label(
            allow_single_file = ["Gemfile"],
            doc = "Gemfile to install dependencies from.",
        ),
        "gemfile_lock": attr.label(
            allow_single_file = ["Gemfile.lock"],
            doc = "Gemfile to install dependencies from.",
        ),
        # "env": attr.string_dict(
        #     doc = "Environment variables to use during installation.",
        # ),
        "_build_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:ruby/private/bundle_fetch/BUILD.tpl",
        ),
    },
)
