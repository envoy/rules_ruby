"Implementation details for fetch the bundler"

load("//ruby/private/bundle_fetch:gemfile_lock_parser.bzl", "parse_gemfile_lock")

_GEM_BUILD_FRAGMENT = """
rb_gem(
    name = "{name}",
    src = "vendor/cache/{gem}",
)
"""

_GEM_INSTALL_BUILD_FRAGMENT = """
rb_gem_install(
    name = "{name}",
    src = "vendor/cache/{gem}",
)
"""

def _download_gem(repository_ctx, gem):
    url = "{remote}gems/{filename}".format(remote = gem.remote, filename = gem.filename)
    repository_ctx.download(url = url, output = "vendor/cache/%s" % gem.filename)

def _get_gem_executables(repository_ctx, gem):
    executables = []
    repository_ctx.symlink("vendor/cache/" + gem.filename, gem.filename + ".tar")
    repository_ctx.extract(gem.filename + ".tar", output = gem.full_name)
    data = "/".join([gem.full_name, "data"])
    repository_ctx.extract("/".join([gem.full_name, "data.tar.gz"]), output = data)
    gem_contents = repository_ctx.path(data)

    # TODO: get executables from metadata.gz
    executable_dirnames = ["bin", "exe"]
    for executable_dirname in executable_dirnames:
        if gem_contents.get_child(executable_dirname).exists:
            for executable in gem_contents.get_child(executable_dirname).readdir():
                executables.append(executable.basename)

    _cleanup_downloads(repository_ctx, gem)
    return executables

def _cleanup_downloads(repository_ctx, gem):
    repository_ctx.delete(gem.full_name)
    repository_ctx.delete(gem.filename + ".tar")

def _join_and_indent(names):
    return "[\n        " + "\n        ".join(['"%s",' % name for name in names]) + "\n    ]"

def _normalize_bzlmod_repositor_name(name):
    return name.rpartition("~")[-1]

def _rb_bundle_fetch_impl(repository_ctx):
    gemfile_path = repository_ctx.path(repository_ctx.attr.gemfile)
    gemfile_lock_path = repository_ctx.path(repository_ctx.attr.gemfile_lock)

    repository_ctx.file("Gemfile", repository_ctx.read(gemfile_path))
    repository_ctx.file("Gemfile.lock", repository_ctx.read(gemfile_lock_path))
    srcs = []
    for src in repository_ctx.attr.srcs:
        srcs.append(src.name)
        repository_ctx.file(src.name, repository_ctx.read(src))

    executables = []
    gemfile_lock = parse_gemfile_lock(repository_ctx.read(gemfile_lock_path))
    gem_full_names = []
    gem_fragments = []
    gem_install_fragments = []

    # Fetch all gems.
    for gem in gemfile_lock.remote_packages:
        _download_gem(repository_ctx, gem)
        executables.extend(_get_gem_executables(repository_ctx, gem))
        gem_full_names.append(":%s" % gem.full_name)
        gem_fragments.append(_GEM_BUILD_FRAGMENT.format(name = gem.full_name, gem = gem.filename))

    # Fetch and install bundler.
    _download_gem(repository_ctx, gemfile_lock.bundler)
    executables.extend(_get_gem_executables(repository_ctx, gemfile_lock.bundler))
    gem_full_names.append(":%s" % gemfile_lock.bundler.full_name)
    gem_install_fragments.append(_GEM_INSTALL_BUILD_FRAGMENT.format(name = gemfile_lock.bundler.full_name, gem = gemfile_lock.bundler.filename))

    repository_ctx.template(
        "BUILD",
        repository_ctx.attr._build_tpl,
        executable = False,
        substitutions = {
            "{name}": _normalize_bzlmod_repositor_name(repository_ctx.name),
            "{srcs}": _join_and_indent(srcs),
            "{gems}": _join_and_indent(gem_full_names),
            "{gem_fragments}": "".join(gem_fragments),
            "{gem_install_fragments}": "".join(gem_install_fragments),
        },
    )

    repository_ctx.template(
        "bin/BUILD",
        repository_ctx.attr._bin_build_tpl,
        executable = False,
        substitutions = {
            "{name}": _normalize_bzlmod_repositor_name(repository_ctx.name),
        },
    )

    for executable in executables:
        repository_ctx.file("bin/%s" % executable)

rb_bundle_fetch = repository_rule(
    implementation = _rb_bundle_fetch_impl,
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
        # "env": attr.string_dict(
        #     doc = "Environment variables to use during installation.",
        # ),
        "_build_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:ruby/private/bundle_fetch/BUILD.tpl",
        ),
        "_bin_build_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:ruby/private/bundle_fetch/bin/BUILD.tpl",
        ),
    },
    doc = """
Fetches Bundler dependencies to be automatically installed by other targets.

Currently doesn't support installing gems from Git repositories.

`WORKSPACE`:
```bazel
load("@rules_ruby//ruby:deps.bzl", "rb_bundle_fetch")

rb_bundle_fetch(
    name = "bundle",
    gemfile = "//:Gemfile",
    gemfile_lock = "//:Gemfile.lock
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
