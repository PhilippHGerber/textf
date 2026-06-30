# Span builder uses resolveLinkConfiguration and discards five of six fields

`TextfStyleResolver` exposes a single public link-style method: `resolveLinkConfiguration(inheritedStyle)`, which returns a `LinkStyleConfiguration` bundling style, hover style, cursor, on-tap callback, on-hover callback, and alignment. `TextfSpanBuilder` calls this method and reads only the `style` field, discarding the rest.

The alternative was to keep a separate `resolveLinkStyle` method on the resolver so the span builder could call it directly without computing unused fields. This was rejected because the extra computation is negligible (five null-checks and property reads) while a second public link-style method would fragment the resolver's interface and invite future callers to bypass `LinkStyleConfiguration`. Accepting the minor waste preserves a single, narrow link-style surface on the resolver.
