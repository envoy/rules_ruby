"Implementation details for rb_gem"

load("//ruby/private:providers.bzl", "GemInfo")

def _rb_gem_impl(ctx):
    gem = ctx.file.src

    return [
        DefaultInfo(
            files = depset([gem]),
        ),
        GemInfo(
            name = ctx.attr.name.rpartition("-")[0],
            version = ctx.attr.name.rpartition("-")[-1],
        ),
    ]

rb_gem = rule(
    _rb_gem_impl,
    attrs = {
        "src": attr.label(
            allow_single_file = [".gem"],
            mandatory = True,
            doc = "Gem file.",
        ),
    },
)
