using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))
products = [
    LibraryProduct(prefix, ["libduckdb"], :libduckdb),
]

# Download binaries from hosted location
bin_prefix = "https://github.com/RelationalAI-oss/duckdb-builder.jl/releases/download/0.0.1-new"

# Listing of files generated by BinaryBuilder:
download_info = Dict(
    MacOS(:x86_64) => ("$bin_prefix/duckdb.v0.0.1.x86_64-apple-darwin14.tar.gz", "be067442943548166ea6fbe4c478e50c8a38786bb858db2bdbe810b486c3bded"),
    Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(:gcc7, :cxx11)) => ("$bin_prefix/duckdb.v0.0.1.x86_64-linux-gnu-gcc7-cxx11.tar.gz", "d9b12c796779ad74e1c0825803b0173c3bfdd59fffb89885c25b59dd2392d380"),
)

# Install unsatisfied or updated dependencies:
unsatisfied = any(!satisfied(p; verbose=verbose) for p in products)
dl_info = choose_download(download_info, platform_key_abi())
if dl_info === nothing && unsatisfied
    # If we don't have a compatible .tar.gz to download, complain.
    # Alternatively, you could attempt to install from a separate provider,
    # build from source or something even more ambitious here.
    error("Your platform (\"$(Sys.MACHINE)\", parsed as \"$(triplet(platform_key_abi()))\") is not supported by this package!")
end

# If we have a download, and we are unsatisfied (or the version we're
# trying to install is not itself installed) then load it up!
if unsatisfied || !isinstalled(dl_info...; prefix=prefix)
    # Download and install binaries
    install(dl_info...; prefix=prefix, force=true, verbose=verbose)
end

# Write out a deps.jl file that will contain mappings for our products
write_deps_file(joinpath(@__DIR__, "deps.jl"), products, verbose=verbose)
