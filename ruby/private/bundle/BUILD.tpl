"""@generated by @rules_ruby//:ruby/private/binary.bzl"""
load("@rules_ruby//ruby:defs.bzl", "rb_library")
load("//:defs.bzl", "BUNDLE_ENV")

package(default_visibility = ["//visibility:public"])

rb_library(
    name = "bundle",
    data = glob(["**/*"]),
    bundle_env = BUNDLE_ENV,
)

# vim: ft=bzl
