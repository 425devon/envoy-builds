#!/usr/bin/env python

# file in format CONTRIB_EXTENSIONS = {...}
exec(open('contrib/contrib_build_config.bzl').read())
exec(open('source/extensions/extensions_build_config.bzl').read())

# By default all contrib are disabled. Use whitelisting to enable
enable_contrib_extensions = [
    "envoy.filters.network.kafka_broker"
]

# By default all source extensions are enabled. Use blacklisting to disable
disable_source_extensions = [
    "envoy.filters.http.file_system_buffer",
    "envoy.transport_sockets.tcp_stats"
    
]

# Filtered list of extensions to be whitelisted / blacklisted per envoy tag
desired = []

for k, v in CONTRIB_EXTENSIONS.items():
    desired.append('--{target}:enabled={isEnabled}'.format(
        target=v.split(":")[0],
        isEnabled=(k in enable_contrib_extensions))
    )

for k, v in EXTENSIONS.items():
    desired.append('--{target}:enabled={isEnabled}'.format(
        target=v.split(":")[0],
        isEnabled=(not k in disable_source_extensions))
    )

print(' '.join(desired))
