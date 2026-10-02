# Shared request — P04 Privacy consent
Need: new trash-can line icon for the 4th promise row ("Delete everything anytime").
The HTML source draws a trash can (lid + body + legs path); no existing asset matches:
`ic_bin` is a wheeled cart and `ic_basket` is a laundry basket (verified by reading
both SVGs). Add `app/assets/icons/ic_trash.svg` (24×24, stroke currentColor, 2px,
round caps) plus a `NestIcons.trash` entry in
`app/lib/core/design_system/assets/nestling_assets.dart`.
Files: `app/assets/icons/ic_trash.svg`,
`app/lib/core/design_system/assets/nestling_assets.dart`
Blocks: yes — without it P04 cannot match the design (wrong-bin glyph is a visible
defect). P04 builds layout-complete with the 40×40 tile reserved behind a
`TODO(P04)` until this lands.
