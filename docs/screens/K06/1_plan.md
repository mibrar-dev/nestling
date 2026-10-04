# K06 · Pip's nest (`/pip`) — build plan (stage 1)

Sources: `design/screens/light/K06-pip.png` + `design/screens/dark/K06-pip.png`
(1170x2532 @3x; /3 = logical px), `design/html-source/screens/K06-pip.html`,
DESIGN_SPEC section 5 K06, SPACING_SPEC (section 2 btn-kid, section 7 pet-stage
and lock-btn.lg, section 8 K06 scroll bottom), orchestrator rules in the loop
brief. No ORCHESTRATOR_NOTES.md exists under docs/screens/K06.
Existing code: app/lib/features/pip/ (bloc watches wardrobe only, placeholder
view), PipRepository/PipRepositoryImpl, PipProfile/PipStage entities, PipAvatar
(core/design_system/motion/pip_avatar.dart), KidScope plus NestMeadow
(core/design_system/theme/), NestPetStage, NestKidButton, NestProgress,
NestLockButton, NestIcon/NestIcons, KidScope pattern plus gate tap guard in
kid_home_view.dart, seed (core/data/seed.dart).

## 0. Data truth (database over design numbers)

- Active child = app_state.activeChildId ('maya' in demo seed).
- Maya: pipStyle mochi, pipSkin sunny, pipAccessory none, pipStage 3,
  pipTotalCoins 175, coins 120, happiness 4. Leo: bolt/sky/none/stage 2.
- Growth: evolveAtCoins = 250 (PipProfile), fraction 175/250 = 0.7, left label
  "<totalCoins> coins", right label "250 to grow". Matches the design 70 pct bar.
- CONFLICT 1 (design wins, feature-local fix): HTML shows Bath costing 3 coins,
  but PipRepositoryImpl.play/bathe are both free (_care with cost 0; doc comment
  says playing and bathing are free). Feed = 5 matches HTML. Fix in feature
  data dir: add bathCostCoins = 3, bathe() uses cost 3. Play stays free.
  Allowed by RULES section 1 (feature data dir).
- CONFLICT 2 (database wins): HTML wardrobe prices Wellies 30 / Crown 60, but
  the demo seed says wellies 40 / crown 120 (maya). Render DB prices
  (watchWardrobe priceCoins), never the HTML numbers.
- CONFLICT 3 (design order wins, feature-local fix): watchWardrobe orders by
  item (alphabetical: crown, scarf, sunhat, wellies) but design order is Scarf,
  Sun hat, Wellies, Crown. Sort in the repository mapping to explicit order
  scarf/sunhat/wellies/crown.
- CONFLICT 4 (design copy wins, feature-local fix): _itemName maps to Cosy
  scarf / Sunny hat / Muddy wellies / Star crown but design names are Scarf,
  Sun hat, Wellies, Crown. Change _itemName to the design names. detail stays
  'Owned' / '<price> coins'.

## 1. Widget tree top to bottom (tokens only, no hard codes)

KidScope (default meadow 136, bottom 0, never a local hill) ->
Scaffold(backgroundColor transparent) -> Column:

1. NestStatusBar() — reserves 47 px only; OS draws glyphs (ignore in checks).
2. Top row (HTML .k6-top: space-between center, padding 0 20 4):
   - Back: 56x56, radius 18 (nav-back.lg). Icon NestIcons.back 26 px ink.
     Semantics Back. onTap -> context.pop(), fallback go(KidHomeRoutePaths.home)
     (/kid-home) when nothing to pop.
   - NestLockButton(large true, 56x56 r18, semanticLabel 'Grown-ups') ->
     push(ParentalGateRoutePaths.gate) (/parental-gate) with the K03
     _GateLockButton _busy tap guard (one gate route per gesture burst).
   - PNG logical: back box x20-76 y47-103; lock box x314-370 y47-103.
3. Expanded + ListView (horizontal padding 20, separator 16 = s4; bottom
   padding 58 = homeH 34 + s6 24 per SPACING_SPEC section 1; add 6 px shadow
   room under kid-bordered cards so sh-kid is never clipped):
   a. Title 'Pip · Fledgling' — NestType.kidTitle(ink), centered, maxLines 2.
      Middle dot U+00B7 exactly as HTML &middot;. Text = 'Pip · <StageName>'
      with Egg/Hatchling/Fledgling/Songbird (pip feature keeps its own stage
      name helper, do NOT import from kid_home). PNG y about 115-150.
   b. Pet slot (HTML .k6-pet 230x206, margin-top 9; .pip 134x134 at bottom 81):
      NestPetStage(pip: PipAvatar(style/skin/accessory of CHILD, stage,
      inNest false), nestWidth 230, nestHeight for the 230x206 slot,
      fixedPipHeight 134, semanticLabel 'Pip the Fledgling...'). NOTE: K06 slot
      is 230x206, not K03 236x188 — pass K06 numbers, do not copy K03 consts.
      PipAvatar keeps design size/position; never v1 pip_stage SVGs
      (orchestrator PIP rule). PNG slot y about 159-365.
   c. Growth card (HTML .k6-grow: lilacTint bg, 3 px ink border, r-l 24,
      kidShadow, padding 12 14; screen-local Container with tokens, no shared
      kid panel card exists):
      - Row gap 8: PipAvatar(style/skin of child, stage min(stage+1,4),
        size 30) as next-stage preview (HTML pip-stage-4.svg 30 px slot) plus
        Text('Growing into a Songbird', NestType.h3 ink, 18/24 w800).
      - NestProgress(fraction totalCoins/250, kid true,
        semanticLabel 'Pip is 70 percent of the way to Songbird').
      - Row spaceBetween: two Text with NestType.kidCaption(ink2) 15/20 w700
        (.kcap): '<total> coins' / '250 to grow'.
      - PNG card y about 381-533.
   d. Care row (HTML .k6-care: gap 12, 3x Expanded): NestKidButton vertical
      axis, gap 3, minHeight 88, contentPadding vertical 8 horizontal 4,
      fontSize 17 (17/20 extension, SPACING_SPEC section 2):
      - Feed: peach, icon NestIcons.feedBowl, label Feed plus coin trailing
        (coin svg 16 + 5). semanticLabel 'Feed Pip, costs 5 coins'.
        onPressed -> PipCareRequested.feed.
      - Play: sky, icon NestIcons.ball, label Play plus Free pill (surface bg,
        ink text, r-pill, padding 3 8, 13/800, HTML .k6-free).
        semanticLabel 'Play with Pip, free'. -> PipCareRequested.play.
      - Bath: white, icon NestIcons.bubbles, label Bath plus coin 3.
        semanticLabel 'Bathe Pip, costs 3 coins'. -> PipCareRequested.bathe.
      - Coin trailing: coin svg 16 px + Text 14/900 ink. Unaffordable
        feed/bath -> onPressed null plus opacity 0.45 (shared NestKidButton
        behaviour). Play never disabled.
      - PNG row y about 549-640.
   e. Section "Pip's wardrobe" (curly apostrophe U+2019): HTML .k6-sec is
      20/26 w900 Nunito; closest token kidName is 22/26. Use
      NestType.h3(ink).copyWith(fontSize 20, height 26/20) — 20/26 from HTML,
      tokens only. Left-aligned, maxLines 1 ellipsis. PNG y about 656-682.
   f. Wardrobe grid (HTML .k6-ward: gap 12, 4x Expanded; col about 78.5):
      per item (HTML .k6-item: padding 8 4, gap 4, column, center):
      - Owned: surface bg, 3 px ink border, r-l 24, kidShadow; art circle 52
        (lilacTint bg, ink icon 30); name 14/18 w800 ink; status Owned 14/900
        leafInk.
      - Locked: surface2 bg, 3 px dashed ink2 border, NO shadow; art circle 52
        surface bg, ink2 icon 30; name ink2; price row coin 16 + price 14/900
        ink. Dashed border is screen-local in pip/presentation/widgets/ (no
        shared dashed-border widget exists; tokens only).
      - Icons: scarf -> NestIcons.scarf, sunhat -> NestIcons.sunHat,
        wellies -> NestIcons.wellies, crown -> NestIcons.crown.
      - Whole tile is the button (Semantics button + onTap): owned ->
        PipWardrobeEquipRequested(item), mapping scarf -> scarf, sunhat -> cap;
        wellies/crown have no accessory node -> toast only, no DB write.
        Locked -> PipWardrobeBuyRequested(item); repo guards affordability;
        failure -> toast 'Not enough coins yet — keep going!' (kind, no shame).
      - PNG row y about 694-830.
   g. Caption 'Nothing here is a chore — it is all just for fun.' (em dash
      U+2014 exactly as HTML &mdash;) — NestType.kidCaption(ink2), centered.
4. NO bottom bar or dock on K06 (HTML ends at home-indicator): KidScope meadow
   runs to the physical edge (owner BOTTOM EDGE rule). NestHomeIndicator()
   last (shrinks to 0 in app; OS draws the pill).

Dark mode: all colours via tokens (lilacTint, surface, surface2, ink, ink2,
leafInk, kidShadow dark). Pet glow handled inside NestPetStage. Free pill bg =
surface. Verify both PNGs in the UI stage.

## 2. BLoC plus repository (local Drift via existing repo)

New entity PipNest { PipProfile profile, List PipStage items }
(domain/entities/pip_nest.dart, Equatable). Repository additions
(domain/pip_repository.dart + data/pip_repository_impl.dart, feature-local):

- Stream watchActiveChildId(): db.watchAppState() -> activeChildId.
- Stream watchNest(): switchMap activeChildId -> combine watchProfile(childId)
  + ordered watchWardrobe (explicit scarf/sunhat/wellies/crown order, design
  names per section 0) into PipNest; null child -> null. Builder picks
  stream_combine.dart or asyncExpand, in one place.
- feed (cost 5), play (free), bathe (cost 3, CHANGED), buyItem, updateLook
  (equip scarf/cap) — all existing except bath cost; all no-op when coins
  insufficient (never negative); happiness +1 clamped 0..5. No DateTime.now();
  clock package only (no timestamps needed here).

Bloc (presentation/bloc/): state PipState { status, PipNest? nest,
actionError?, actionNonce } (PipStatus initial/loading/loaded/failure kept):

- PipLoadRequested -> emit.forEach(watchNest(), onData loaded(nest), onError
  failure). Never re-add load events (RULES section 4).
- PipCareRequested(kind feed/play/bathe) -> await repo.feed/play/bathe with
  the cached active child id; on throw -> actionError + actionNonce++ (toast
  listener). The stream re-emits the new profile automatically.
- PipWardrobeBuyRequested(item) / PipWardrobeEquipRequested(item) -> same
  error-toast pattern; success needs no event (stream updates).
- Active child id is cached from the last watchNest emission; null -> ignore.

## 3. Interactions plus navigation (route constants)

- Back top-left -> context.pop(), fallback go(KidHomeRoutePaths.home)
  (/kid-home). Back to kid home.
- Lock top-right 'Grown-ups' -> push(ParentalGateRoutePaths.gate)
  (/parental-gate) with _busy tap guard. Parental gate.
- Feed / Play / Bath -> PipCareRequested -> coins/happiness update in DB.
  Stays on screen; toast on error.
- Owned wardrobe tile scarf/sunhat -> updateLook(accessory). Pip re-renders.
- Locked wardrobe tile, affordable -> buyItem -> owned, coins deducted.
- Locked tile, unaffordable -> toast only, stays.
- Caption / progress / title are informative, no action.
- No auto-push to K07 evolution from here (K07 is a separate route/screen).

## 4. Empty / loading / error states

- initial/loading: KidScope + NestStatusBar + top row + centered
  CircularProgressIndicator(leaf) with Semantics label 'Loading Pip'.
- failure: same chrome + friendly card (neutral mochi/sunny PipAvatar when a
  child was known, 'Oh no! Pip got lost.' / "Let's try again." + Try again
  NestKidButton.white -> PipLoadRequested). Mirrors K03 _KidFailure shape.
- No active child (loaded nest null): title "Who's playing?" + Choose
  NestKidButton.lilac -> go(KidHomeRoutePaths.picker) (/who-is-playing).
  Mirrors K03 _NoActiveChild.
- If items is empty, omit heading (e) + grid (f) but keep the caption.

## 5. Accessibility

- Every control exposes SemanticsAction.tap: back (Back), lock (Grown-ups via
  NestLockButton), care buttons (labels above, button true, enabled false when
  unaffordable with NO tap action), wardrobe tiles ('<Name>, Owned' /
  '<Name>, <price> coins'). Never wrap in Semantics(excludeSemantics true)
  without onTap — pass tap through on the wrapper.
- performAction(tap) must change real DB state (feed -5, bath -3, buy deducts
  price). Assert in tests.
- Progress: NestProgress.semanticLabel ('Pip is <pct> percent of the way to
  Songbird'); pet: image semantics 'Pip the <Stage>, stage <n> of 4'.
- Targets: back/lock 56, care minHeight 88, wardrobe tiles minHeight 56.
- Text scale 1.0 to 1.3: title wraps maxLines 2; care labels 17 px may shrink
  via FittedBox/scaleDown, never overflow; wardrobe names 14 px ellipsis
  maxLines 1; coin rows softWrap false. Clamp textScaler to 1.0-1.3
  (SPACING_SPEC section 10).
- Width 320: care row 3x Expanded (col about 82.6); wardrobe 4x Expanded (col
  about 61, art 52 fits); grid from width, never fixed 78.5 except at 390.

## 6. Test plan (app/test/features/pip/ — check existing dir first; RULES
section 1 allows app/test/features/pip/**)

- Repository (Drift memory DB + Seed.demo): feed deducts 5 coins and +1
  happiness; play free +1 happiness; bath deducts 3 (new); happiness clamps at
  5; feed/bath with insufficient coins is a no-op; buyItem marks owned and
  deducts DB price (wellies 40 for maya); buyItem unaffordable is a no-op;
  watchNest emits profile + items in scarf/sunhat/wellies/crown order with
  design names and DB prices; watchNest null child -> null.
- Bloc: PipLoadRequested emits loading then loaded with nest; care events call
  the repo and the stream updates; errors set actionError/actionNonce.
- Widget (pumpAppRoute '/pip', end every test with disposeApp per RULES
  section 7): title 'Pip · Fledgling'; own PipAvatar for maya
  (mochi/sunny/stage 3, in nest slot 230x206 / pip 134); progress 0.7 with
  '175 coins' / '250 to grow'; Feed 5 / Play Free / Bath 3 labels; wardrobe
  Scarf+Sun hat Owned, Wellies 40 + Crown 120 locked from DB; caption with em
  dash; every control has SemanticsAction.tap and performAction mutates the
  DB; back pops to /kid-home; lock pushes /parental-gate; dark theme renders;
  textScaler 1.3 + width 320 render without overflow (no warn/error).
- No google_fonts imports anywhere (orchestrator FONTS rule); no
  DateTime.now(); no new ids (no new rows written by this screen).

## 7. SHARED_REQUEST

None. Bath cost, wardrobe order/names and PipNest stream are all inside the
pip feature dirs (presentation/domain/data), which RULES section 1 lets this
screen edit. Routes (/kid-home, /parental-gate, /who-is-playing), KidScope,
NestPetStage, PipAvatar, NestKidButton, NestProgress, NestLockButton,
NestIcons (feedBowl, ball, bubbles, scarf, sunHat, wellies, crown) and tokens
all exist on main. Dashed locked border stays screen-local (no shared widget
requested). Builder must NOT touch app/lib/core/** or app/lib/app/**.

VERDICT: PASS
