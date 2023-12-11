"Implementation details for fetch the bundler"

load("//ruby/private/bundle_fetch:gemfile_lock_parser.bzl", "parse_gemfile_lock")

def _download_gem(repository_ctx, gem):
    url = "{remote}gems/{filename}".format(remote = gem.remote, filename = gem.filename)
    repository_ctx.download(url = url, output = gem.filename)
    repository_ctx.download(url = url, output = gem.filename + ".tar")

def _get_gem_executables(repository_ctx, gem):
    executables = []
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

    return executables

def _cleanup_downloads(repository_ctx, gem):
    repository_ctx.delete(gem.full_name)
    repository_ctx.delete(gem.filename + ".tar")

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
    gems = []
    gemfile_lock = parse_gemfile_lock(repository_ctx.read(gemfile_lock_path))
    for gem in gemfile_lock.remote_packages:
        gems.append(gem.full_name)
        _download_gem(repository_ctx, gem)
        executables.extend(_get_gem_executables(repository_ctx, gem))
        _cleanup_downloads(repository_ctx, gem)

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

    repository_ctx.template(
        "bin/BUILD",
        repository_ctx.attr._bin_build_tpl,
        executable = False,
        substitutions = {
            "{name}": repository_ctx.name,
        },
    )
    for executable in executables:
        repository_ctx.file("/".join(["bin", executable]))

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
)
