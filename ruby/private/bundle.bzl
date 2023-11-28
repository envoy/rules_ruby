"Implementation details for calling the bundler"

# https://github.com/rubygems/rubygems/blob/f8c76eae24bbeabb9c9cb5387dbd89df45566eb9/bundler/lib/bundler/installer.rb#L147
_BINSTUB_CMD = """@ruby -x "%~f0" %*
@exit /b %ERRORLEVEL%
{}
"""

DOWNLOAD_GEMS = """
require 'bundler'
require 'json'

parser = Bundler::LockfileParser.new(File.read(ARGV.first))
gems = []
parser.specs.map do |spec|
  if remote = spec.source.options.fetch('remotes', []).first
    gems << [spec.full_name, "#{remote}gems/#{spec.full_name}.gem", ]
  end
end
File.write("Gemfile.lock.json", gems.to_json)
"""

EXECUTABLES = """

"""

def _rb_bundle_impl(repository_ctx):
    binstubs_path = repository_ctx.path("bin")
    bundle_path = repository_ctx.path(".")
    gemfile_path = repository_ctx.path(repository_ctx.attr.gemfile)
    gemfile_lock_path = repository_ctx.path(repository_ctx.attr.gemfile_lock)
    cache_path = repository_ctx.path("vendor/cache")
    toolchain_path = repository_ctx.path(repository_ctx.attr.toolchain).dirname

    repository_ctx.file("Gemfile", repository_ctx.read(gemfile_path))
    repository_ctx.file("Gemfile.lock", repository_ctx.read(gemfile_lock_path))
    for src in repository_ctx.attr.srcs:
        repository_ctx.file(src.name, repository_ctx.read(src))

    if repository_ctx.os.name.startswith("windows"):
        # bundle = repository_ctx.path("%s/dist/bin/bundle.cmd" % toolchain_path)
        path_separator = ";"
        if repository_ctx.path("%s/dist/bin/jruby.exe" % toolchain_path).exists:
            ruby = repository_ctx.path("%s/dist/bin/jruby.exe" % toolchain_path)
        else:
            ruby = repository_ctx.path("%s/dist/bin/ruby.exe" % toolchain_path)
    else:
        # bundle = repository_ctx.path("%s/dist/bin/bundle" % toolchain_path)
        path_separator = ":"
        if repository_ctx.path("%s/dist/bin/jruby" % toolchain_path).exists:
            ruby = repository_ctx.path("%s/dist/bin/jruby" % toolchain_path)
        else:
            ruby = repository_ctx.path("%s/dist/bin/ruby" % toolchain_path)

    # repository_ctx.template(
    #     "BUILD",
    #     repository_ctx.attr._build_tpl,
    #     executable = False,
    # )

    path = repository_ctx.path("download_gems.rb")
    repository_ctx.file(path, content = DOWNLOAD_GEMS)

    env = {
        "BUNDLE_BIN": repr(binstubs_path),
        "BUNDLE_GEMFILE": repr(gemfile_path),
        "BUNDLE_IGNORE_CONFIG": "1",
        "BUNDLE_PATH": repr(bundle_path),
        "BUNDLE_SHEBANG": repr(ruby),
        "PATH": path_separator.join([repr(ruby.dirname), repository_ctx.os.environ["PATH"]]),
    }
    env.update(repository_ctx.attr.env)

    # print(repository_ctx.read(gemfile_lock_path))
    # repository_ctx.symlink("Gemfilek", repository_ctx)

    bundle_env = {k: v for k, v in env.items() if k.startswith("BUNDLE_")}
    repository_ctx.file(
        "defs.bzl",
        "BUNDLE_ENV = %s" % bundle_env,
    )

    repository_ctx.file(
        "BUILD",
        """
load("@rules_ruby//ruby:defs.bzl", "rb_bundle_install", "rb_library")

package(default_visibility = ["//visibility:public"])

rb_bundle_install(
    name = "bundle",
    srcs = {},
    gemfile = "{}",
    gemfile_lock = "{}",
)
        """.format(
            [f.name for f in repository_ctx.attr.srcs],
            repository_ctx.attr.gemfile.name,
            repository_ctx.attr.gemfile_lock.name,
        ),
    )

    """
    gems.bzl


    """

    # repository_ctx.report_progress("Running bundle install")
    result = repository_ctx.execute(
        [ruby, path, "Gemfile.lock"],
        environment = env,
        quiet = not repository_ctx.os.environ.get("RUBY_RULES_DEBUG", default = False),
    )

    if result.return_code != 0:
        fail("%s\n%s" % (result.stdout, result.stderr))

    srcs = [f.name for f in repository_ctx.attr.srcs]
    gems = json.decode(repository_ctx.read("Gemfile.lock.json"))
    for (gem, url) in gems:
        # Generate gems.bzl;
        # http_archive(...)
        #

        path = "%s/%s" % (repr(cache_path), gem)
        srcs.append("vendor/cache/%s.gem" % gem)
        repository_ctx.download(url, "%s.gem" % path)
        repository_ctx.download(url, "%s.gem.tar" % path)
        repository_ctx.extract("%s.gem.tar" % path, path)
        # repository_ctx.extract("%s/data.tar.gz" % path, "%s/%s" % (path, gem))
        # repository_ctx.extract("%s/%s/metadata.gz" % (repr(cache_path), gem))

    repository_ctx.file(
        "BUILD",
        """
load("@rules_ruby//ruby:defs.bzl", "rb_bundle_install", "rb_library")

package(default_visibility = ["//visibility:public"])

rb_bundle_install(
    name = "bundle",
    srcs = {},
    gemfile = "{}",
    gemfile_lock = "{}",
)
        """.format(
            srcs,
            repository_ctx.attr.gemfile.name,
            repository_ctx.attr.gemfile_lock.name,
        ),
    )

    repository_ctx.file(
        "bin/BUILD",
        """
load("@rules_ruby//ruby:defs.bzl", "rb_bundle_install", "rb_library", "rb_binary")

package(default_visibility = ["//visibility:public"])

# rb_bundle_install(
#     name = "bundle_install",
# )

rb_binary(
    name = "rake1",
    main = "rake",
    deps = ["//:bundle"],
    # bundle_env = BUNDLE_ENV,
)
        """,
    )
    repository_ctx.file("bin/rake")

    # # repository_ctx.report_progress("Running bundle install")
    # result = repository_ctx.execute(
    #     [ruby, path, gemfile_lock_path],
    #     environment = env,
    #     quiet = not repository_ctx.os.environ.get("RUBY_RULES_DEBUG", default = False),
    # )

rb_bundle = repository_rule(
    implementation = _rb_bundle_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            doc = """
List of Ruby source files used to build the library.
            """,
        ),
        "toolchain": attr.label(
            mandatory = True,
        ),
        "gemfile": attr.label(
            allow_single_file = ["Gemfile"],
            doc = """
Gemfile to install dependencies from.
            """,
        ),
        "gemfile_lock": attr.label(
            allow_single_file = ["Gemfile.lock"],
            doc = """
Gemfile.lock to install dependencies from.
            """,
        ),
        "env": attr.string_dict(
            doc = "Environment variables to use during installation.",
        ),
        "_build_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:ruby/private/bundle/BUILD.tpl",
        ),
    },
    doc = """
Installs Bundler dependencies and registers an external repository
that can be used by other targets.

`WORKSPACE`:
```bazel
load("@rules_ruby//ruby:deps.bzl", "rb_bundle")

rb_bundle(
    name = "bundle",
    gemfile = "//:Gemfile",
    srcs = [
        "//:gem.gemspec",
        "//:lib/gem/version.rb",
    ]
)
```

All the installed gems can be accessed using `@bundle` target and additionally
gems binary files can also be used:

`BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_binary")

package(default_visibility = ["//:__subpackages__"])

rb_binary(
    name = "rubocop",
    main = "@bundle//:bin/rubocop",
    deps = ["@bundle"],
)
```
    """,
)
