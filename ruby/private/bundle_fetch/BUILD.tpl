"""@generated by @rules_ruby//:ruby/private/bundle_fetch.bzl"""

load("@rules_ruby//ruby:defs.bzl", "rb_bundle_install", "rb_gem_install")

package(default_visibility = ["//visibility:public"])

rb_bundle_install(
    name = "{name}",
    srcs = {srcs},
    gemfile = "Gemfile",
    gemfile_lock = "Gemfile.lock",
    gems = {gems},
)

{gem_installs}

# vim: ft=bzl