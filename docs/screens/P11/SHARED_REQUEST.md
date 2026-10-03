# Shared request — P11 quote rows have no data source

Need: the P11 design's `.qn` quote lines (“I stacked everything neatly!”
etc.) have no backing column — `quest_completions` carries no child
message/note (only id/questId/childId/familyId/status/coins/createdAt(+Tz)/
decidedAt(+Tz)). Cards render without the quote row. If the owners want the
quotes, add `note TEXT DEFAULT ''` to `quest_completions` (+ seed values)
and P11 will render it.

Files: `app/lib/core/data/app_database.dart`, `app/lib/core/data/seed.dart`

Blocks: no.
