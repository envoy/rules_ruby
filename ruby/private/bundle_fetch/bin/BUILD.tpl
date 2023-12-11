load("@rules_ruby//ruby:defs.bzl", "rb_library")

package(default_visibility = ["//visibility:public"])

rb_library(
    name = "bin",
    data = glob(["*"]),
    deps = ["//:{name}"],
)

# vim: ft=bzl
