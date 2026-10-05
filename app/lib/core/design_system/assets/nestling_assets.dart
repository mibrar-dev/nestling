// GENERATED FILE - do not edit by hand.
// Source: flutter/manifest.json (schema nestling-assets/1), extracted from the 30
// OpenDesign screens + assets/*.svg in project nestling-uk-family-chores-mobile-ui-e9c1.
//
// QA round 1 applied: full-bleed app icon, ic_ball redrawn, ic_dot -> ic_circle,
// rasters for all 22 illustrations + 3 brand files, plus a precache list.
//
// QA round 2 applied: every icon was audited against its own drawing and 26 were
// redrawn, because the extraction named them by where they were USED, not by what
// they drew (ic_bin was a briefcase, ic_cafe a headset, ic_saved a male symbol,
// ic_washing_machine a minus-in-a-circle, ic_pizza a warning triangle). Names are
// now subject-accurate. ic_baking_bag was deleted as a duplicate of ic_bag.
// Verify with `node tools/render-icon-sheet.mjs` -> design/ICONS_OVERVIEW.png.
//
// Every icon is a 24x24 line SVG with stroke="currentColor" and stroke-width 2.
// Tint it with a ColorFilter / Icon colour and size it at the call site.
// Dart identifiers are lowerCamelCase; the file names on disk stay snake_case.

/// UI icons - `flutter/assets/icons/ic_*.svg`.
abstract final class NestlingIcons {
  const new _();

  // ---- Chrome & navigation -----------------------------------------------
  /// Nav back chevron.
  /// Screens: P03, P04, P05, P06, P11, P14, K02, K04, K06, K08, K09, K10, K11.
  static const String back = 'assets/icons/ic_back.svg';

  /// Paywall dismiss X.
  /// Screens: P07.
  static const String close = 'assets/icons/ic_close.svg';

  /// Add / New.
  /// Screens: P02, P05, P08, P16.
  static const String plus = 'assets/icons/ic_plus.svg';

  /// Pencil.
  /// Screens: P05, P14.
  static const String edit = 'assets/icons/ic_edit.svg';

  /// Show password.
  /// Screens: P03.
  static const String eye = 'assets/icons/ic_eye.svg';

  /// Lock / 'Grown-ups only'.
  /// Screens: P17, P15, P16, K01, K02, K03, K03b, K04, K05, K06, K08, K09, K10, K11.
  static const String lock = 'assets/icons/ic_lock.svg';

  /// Keypad delete key.
  /// Screens: P17.
  static const String backspace = 'assets/icons/ic_backspace.svg';

  /// Quest library search field.
  /// Screens: P10.
  static const String search = 'assets/icons/ic_search.svg';

  /// Evolution 'Meet Songbird Pip'.
  /// Screens: K07.
  static const String arrowRight = 'assets/icons/ic_arrow_right.svg';

  // ---- Tab bar (parent) --------------------------------------------------
  /// Tab bar 1/4 — Today.
  /// Screens: P08, P08b, P10, P12, P15, P16.
  static const String home = 'assets/icons/ic_home.svg';

  /// Tab bar 2/4 — Quests.
  /// Screens: P08, P08b, P10, P12, P15, P16.
  static const String quests = 'assets/icons/ic_quests.svg';

  /// Tab bar 3/4 — Money (wallet/card). Exact `components.css` tab-bar glyph:
  /// `rect x=3 y=6 w=18 h=13 rx=3` + `M3 10h18` + `M7 15h4`.
  /// Screens: P02, P08, P08b, P10, P12, P15, P16.
  static const String money = 'assets/icons/ic_money.svg';

  /// Tab bar 4/4 — Family.
  /// Screens: P07, P08, P08b, P10, P12, P15, P16.
  static const String family = 'assets/icons/ic_family.svg';

  // ---- Status & ticks ----------------------------------------------------
  /// Tick.
  /// Screens: P07, P12, P13, K03, K03b, K04, K10, K11.
  static const String check = 'assets/icons/ic_check.svg';

  /// Happy-day ring, K11 only.
  /// Screens: K11.
  static const String circle = 'assets/icons/ic_circle.svg';

  // ---- Quest & template icons --------------------------------------------
  /// Quest: make your bed.
  /// Screens: P08, P09, P10.
  static const String bed = 'assets/icons/ic_bed.svg';

  /// Quest: tidy your bedroom. Child sitting up: pillow, head, torso, thigh and shin.
  /// Screens: K03, K03b, K04.
  static const String bedSit = 'assets/icons/ic_bed_sit.svg';

  /// Quest library 'Lay the table' row. Top rail, splayed legs, two place settings.
  /// Screens: P10.
  static const String table = 'assets/icons/ic_table.svg';

  /// Quest: empty the dishwasher. Appliance box, control strip, dial dots, door seam, rack line.
  /// Screens: P08, P09, P10, K03, K03b.
  static const String dishwasher = 'assets/icons/ic_dishwasher.svg';

  /// Quest: hoover the stairs. Canister: drum body on two wheels, hose arcing to the nozzle.
  /// Screens: P09, P10.
  static const String hoover = 'assets/icons/ic_hoover.svg';

  /// Quest: put the bins out (wheelie bin). Overhanging lid, tapered body, door seam, two wheels.
  /// Screens: P08, P09, P10.
  static const String bin = 'assets/icons/ic_bin.svg';

  /// Laundry basket: handle arc, tapered body, weave ribs and two bands. Distinct from [bin].
  /// Screens: P02, P04.
  static const String basket = 'assets/icons/ic_basket.svg';

  /// P09 quest-editor Bed: flat mattress/bed-frame side view (no headboard
  /// arc). Exact `P09-quest-editor.html` glyph. Distinct from [bed] (which
  /// keeps the headboard arc for P08 `P08-today.html`).
  /// Screens: P09 (picker + `questIconAsset`), P10 ideas/active rows.
  static const String questBed = 'assets/icons/ic_quest_bed.svg';

  /// P09 quest-editor Dishes: handled basket (plain body + single arch
  /// handle). Exact `P09-quest-editor.html` glyph. Distinct from
  /// [dishwasher] (appliance) and [basket] (slatted laundry basket).
  /// Screens: P09, P08/P10 `Empty the dishwasher` rows.
  static const String questDishes = 'assets/icons/ic_quest_dishes.svg';

  /// P09 quest-editor Hoover: angular canister + angular hose + two leg
  /// lines. Exact `P09-quest-editor.html` glyph (P10 omits the legs).
  /// Distinct from [hoover] (rounded canister + dot wheels).
  /// Screens: P09, P10 `Hoover the stairs` rows.
  static const String questHoover = 'assets/icons/ic_quest_hoover.svg';

  /// P09 quest-editor Bins: small handled case with a clasp. Exact
  /// `P09-quest-editor.html` glyph (P10 omits the `M10 12h4` clasp).
  /// Distinct from [bin] (rimmed wheelie bin).
  /// Screens: P09, P08/P10 `Put the bins out` rows.
  static const String questBins = 'assets/icons/ic_quest_bins.svg';

  /// K09 kid Bins: lidded bin with a trapezoid lid. Exact
  /// `K09-jar.html:90` glyph (`M6 3h12l-2 5H8Z` lid +
  /// `M8 8v10a2 2 0 0 0 8 0V8` body). Distinct from [questBins] (P09
  /// handled case with clasp) and [bin] (rimmed wheelie bin). The kid
  /// designs disagree (K03/K04 draw no bins row, so the kid set fell back
  /// to the parent [questBins]); K09 is where bins appears most
  /// prominently, so the kid set now uses this K09-exact glyph.
  /// Screens: K09 (kid `bins`/`bin` via `questIconFor`).
  static const String questBinsKid = 'assets/icons/ic_quest_bins_kid.svg';

  /// K03/K04 kid Bed: headboard post, pillow bump, long base and legs.
  /// Exact `K03-kid-home.html` / `K04-quest-detail.html` tile glyph
  /// (`M2 18v-7 / M2 14h20v4 / …h-9v3 / M6 11V8h4v3`). Distinct from
  /// [questBed] (P09 flat frame, no headboard) and [bed] (P08 arch).
  /// Screens: K03, K04.
  static const String questBedKid = 'assets/icons/ic_quest_bed_kid.svg';

  /// K03 kid Dishes: dishwasher with top rack line and bottom text lines.
  /// Exact `K03-kid-home.html` `Empty the dishwasher` tile glyph
  /// (`rect 3/4/18/16 + M3 10h18 + circle 8/14.5 + M12 14h5…`). Distinct
  /// from [questDishes] (P09 handled basket) and [dishwasher] (appliance).
  /// Screens: K03.
  static const String questDishesKid = 'assets/icons/ic_quest_dishes_kid.svg';

  /// K03 kid Reading: open book with centre spine.
  /// Exact `K03-kid-home.html` `Reading – 20 minutes` tile glyph
  /// (`M12 6v14 + M3 4.6… + M21 4.6…`). Distinct from [book] (P09 closed
  /// book side view).
  /// Screens: K03.
  static const String questReadingKid = 'assets/icons/ic_quest_reading_kid.svg';

  /// Quest: read for 20 minutes.
  /// Screens: P08, P09, P10, K03, K03b.
  static const String book = 'assets/icons/ic_book.svg';

  /// P02 value-tour card 2 (Pip grows as they help).
  /// Screens: P02.
  static const String bookOpen = 'assets/icons/ic_book_open.svg';

  /// Quest: feed the pet.
  /// Screens: P09, P10.
  static const String paw = 'assets/icons/ic_paw.svg';

  /// Leaf sprig — quest library row slot 8. Stem, two leaves, soil line.
  /// Screens: P10.
  static const String sprout = 'assets/icons/ic_sprout.svg';

  /// Quest library row slot 7 (school bag). Backpack: grab handle, curved flap, clasp.
  /// Screens: P10.
  static const String schoolBag = 'assets/icons/ic_school_bag.svg';

  /// Quest library row slot 9. Square machine, round porthole door, three dial dots.
  /// Screens: P10.
  static const String washingMachine = 'assets/icons/ic_washing_machine.svg';

  /// Kid quest-card glyph. Card with a five-point star and two lines.
  /// Screens: K03, K03b.
  static const String questCard = 'assets/icons/ic_quest_card.svg';

  /// P02 value-tour card 3. Crescent moon + three z\u2019s.
  /// Screens: P02.
  static const String sleep = 'assets/icons/ic_sleep.svg';

  // ---- Trust & privacy ---------------------------------------------------
  /// Privacy list row: no ads or tracking.
  /// Screens: P04.
  static const String noAds = 'assets/icons/ic_no_ads.svg';

  /// Privacy list row: nickname only.
  /// Screens: P04.
  static const String person = 'assets/icons/ic_person.svg';

  /// Privacy list row: data stored in the UK.
  /// Screens: P04.
  static const String pinUk = 'assets/icons/ic_pin_uk.svg';

  /// Terms/privacy note glyph.
  /// Screens: P03.
  static const String shieldCheck = 'assets/icons/ic_shield_check.svg';

  /// P02 value-tour card 1 (set quests in seconds).
  /// Screens: P02.
  static const String target = 'assets/icons/ic_target.svg';

  /// Privacy list row: delete everything anytime (lid + body outline).
  /// Distinct from [bin] (wheeled cart) and [basket] (laundry basket).
  /// Screens: P04.
  static const String trash = 'assets/icons/ic_trash.svg';

  // ---- Money & rewards ---------------------------------------------------
  /// K09 'Pocket money' history row. A real \u00a3: hook, crossbar, base.
  /// Screens: K09.
  static const String poundCoin = 'assets/icons/ic_pound_coin.svg';

  /// K09 'Pocket money' history row — the design's geometric coin-slot
  /// mark. Exact `K09-jar.html:85` glyph (`circle r8` + `M12 8v8` +
  /// `M9.5 9.5h5` + `M9.5 14.5h5`). Distinct from [poundCoin] (a curved
  /// pound letterform in a circle); K09 must use this, not [poundCoin].
  /// Screens: K09.
  static const String jarPocketMoney = 'assets/icons/ic_jar_pocket_money.svg';

  /// K09 'Put the bins out' history row. Award rosette: outer + inner disc, two tails.
  /// Screens: K09.
  static const String ribbon = 'assets/icons/ic_ribbon.svg';

  /// Birthday money. Exact `K09-jar.html:95` gift glyph (`rect 3/9/18/12`
  /// + `M3 13h18` + `M12 9v12` + the two bow loops) — the shared file
  /// draws exactly those paths, so K09 reuses this (no `jarGift` file).
  /// Screens: P09, P12, K09.
  static const String gift = 'assets/icons/ic_gift.svg';

  /// K10 'went into your Lego fund' row. Piggy bank: body, ear, snout, eye, coin slot, legs.
  /// Screens: K10.
  static const String saved = 'assets/icons/ic_saved.svg';

  /// Reward: 30 min extra screen time.
  /// Screens: P14, K08.
  static const String screenTime = 'assets/icons/ic_screen_time.svg';

  /// Reward: pick Friday film (P14).
  /// Screens: P14.
  static const String film = 'assets/icons/ic_film.svg';

  /// Reward: pick Friday film (K08).
  /// Screens: K08.
  static const String filmStrip = 'assets/icons/ic_film_strip.svg';

  /// Reward: stay up 15 min later (P14).
  /// Screens: P14.
  static const String clock = 'assets/icons/ic_clock.svg';

  /// Reward: stay up 15 min later (K08).
  /// Screens: K08.
  static const String moon = 'assets/icons/ic_moon.svg';

  /// Reward: baking together (P14 + K08). K08 now shares this glyph; ic_baking_bag was deleted.
  /// Screens: P14, K08.
  static const String chefHat = 'assets/icons/ic_chef_hat.svg';

  /// Reward: trip to the park cafe. Cup, handle, saucer and two curls of steam.
  /// Screens: P14.
  static const String cafe = 'assets/icons/ic_cafe.svg';

  /// Lamp: trapezoid shade, stem, domed base. K08 uses [cafe] for its cafe-trip card.
  /// Screens: K08.
  static const String lamp = 'assets/icons/ic_lamp.svg';

  /// Reward: choose dinner. Slice with a rounded crust band and three pepperoni.
  /// Screens: K08.
  static const String pizza = 'assets/icons/ic_pizza.svg';

  /// Shared reward glyphs — exact `K08-shop.html` `.k8-art` paths, one per
  /// `rewards.icon` seed key (`tv`, `film`, `moon`, `cake`, `coffee`,
  /// `plate`). The single source is `rewardIconFor(key, audience:)` in
  /// `core/design_system/components/reward_icons.dart`; these `reward*`
  /// constants are its KID targets (`NestAudience.kid`). The PARENT targets
  /// are the P14-exact glyphs (`screenTime`, `film`, `clock`, `chefHat`,
  /// `rewardCoffeeParent`); `plate` has no P14 row, so both audiences use
  /// [rewardPlate]. Old look-alikes (`filmStrip`, `moon`, `cafe`, `pizza`)
  /// are untouched.
  /// Screens: K08 (kid); P14 uses the parent targets.
  static const String rewardTv = 'assets/icons/ic_reward_tv.svg';

  /// Shared reward glyph: pick Friday film — exact K08 film-strip
  /// (`rect 2.5/4/19/16` + side sprockets). Distinct from [film] (P14 play
  /// triangle, the parent target).
  /// Screens: K08.
  static const String rewardFilm = 'assets/icons/ic_reward_film.svg';

  /// Shared reward glyph: stay up 15 min later — exact K08 crescent moon.
  /// Distinct from [clock] (P14 clock, the parent target).
  /// Screens: K08.
  static const String rewardMoon = 'assets/icons/ic_reward_moon.svg';

  /// Shared reward glyph: baking together — exact K08 basket/bucket
  /// (arch handle + trapezoid body + top tick). Distinct from [chefHat]
  /// (P14 three-lobe hat, the parent target) and [basket] (slatted laundry
  /// basket).
  /// Screens: K08.
  static const String rewardCake = 'assets/icons/ic_reward_cake.svg';

  /// Shared reward glyph: park café trip — exact K08 takeaway cup
  /// (domed lid + tapered body, no handle/steam/saucer). Distinct from
  /// [cafe] (sit-down mug) and the P14 dome+box+legs glyph
  /// ([rewardCoffeeParent]).
  /// Screens: K08.
  static const String rewardCoffee = 'assets/icons/ic_reward_coffee.svg';

  /// Parent reward glyph: park café trip — exact P14 dome + box + legs
  /// (`M4 10a8 8 0 0 1 16 0` + `M7 10v8h10v-8` + `M9 18v2M15 18v2`).
  /// Distinct from [rewardCoffee] (K08 takeaway cup) and [cafe]
  /// (sit-down mug, matches neither design).
  /// Screens: P14.
  static const String rewardCoffeeParent =
      'assets/icons/ic_reward_coffee_parent.svg';

  /// Shared reward glyph: choose dinner — exact K08 plain triangle + three
  /// stroked dots (no crust band, dots are outlines). Distinct from [pizza]
  /// (crust band + filled dots). P14 has no dinner row in its HTML; the seed
  /// `plate` key uses this K08 glyph on both screens.
  /// Screens: P14, K08.
  static const String rewardPlate = 'assets/icons/ic_reward_plate.svg';

  /// Shopping bag. P12 history row, K03 dock 'Shop'. Also the canonical bag for K08 baking.
  /// Screens: P12, K03.
  static const String bag = 'assets/icons/ic_bag.svg';

  /// P08 'Hand to Maya or Leo'.
  /// Screens: P08.
  static const String phone = 'assets/icons/ic_phone.svg';

  /// P08 'Feed Biscuit the cat' tile (tint-coin). Coin with a four-point sparkle.
  /// Screens: P08.
  static const String coinSparkle = 'assets/icons/ic_coin_sparkle.svg';

  // ---- Kid mode ----------------------------------------------------------
  /// Kid happiness heart, filled.
  /// Screens: K03.
  static const String heart = 'assets/icons/ic_heart.svg';

  /// Kid happiness heart, empty (1 of 5).
  /// Screens: K03.
  static const String heartOutline = 'assets/icons/ic_heart_outline.svg';

  /// Pip face — K03 bottom dock 'Pip' button. Round head, tuft, two eyes, beak.
  /// Screens: K03.
  static const String pipFace = 'assets/icons/ic_pip_face.svg';

  /// K03 bottom dock 'My jar' button. Mason jar: lid band, shoulders, waist band.
  /// Screens: K03.
  static const String jar = 'assets/icons/ic_jar.svg';

  /// K06 care action: Feed (5). Bowl with a paw sitting in it.
  /// Screens: K06.
  static const String feedBowl = 'assets/icons/ic_feed_bowl.svg';

  /// K06 care action: Play (free).
  /// Screens: K06.
  static const String ball = 'assets/icons/ic_ball.svg';

  /// K06 care action: Bath.
  /// Screens: K06.
  static const String bubbles = 'assets/icons/ic_bubbles.svg';

  /// K06 wardrobe: scarf (owned). Hanging knitted stole: ribbed, with fringe.
  /// Screens: K06.
  static const String scarf = 'assets/icons/ic_scarf.svg';

  /// K06 wardrobe: sun hat (owned). Brim, dome, crown band.
  /// Screens: K06.
  static const String sunHat = 'assets/icons/ic_sun_hat.svg';

  /// K06 wardrobe: wellies (locked). Wellington profile: cuff, foot, sole line.
  /// Screens: K06.
  static const String wellies = 'assets/icons/ic_wellies.svg';

  /// K06 wardrobe: crown (locked).
  /// Screens: K06.
  static const String crown = 'assets/icons/ic_crown.svg';

  /// K06 design glyph: scarf, exact `K06-pip.html` `.k6-ward` paths
  /// (`M5 3h4v18H5z` + flag + tick). Distinct from [scarf] (fringed blanket
  /// look-alike); K06 must switch its wardrobe tile to this.
  /// Screens: K06.
  static const String wardrobeScarf = 'assets/icons/ic_wardrobe_scarf.svg';

  /// K06 design glyph: wellies, exact `K06-pip.html` `.k6-ward` paths
  /// (boot body + `M6 3h4M14 3h4` top ticks). Distinct from [wellies]
  /// (profile look-alike); K06 must switch its wardrobe tile to this.
  /// Screens: K06.
  static const String wardrobeWellies = 'assets/icons/ic_wardrobe_wellies.svg';

  /// K06 design glyph: sun hat, exact `K06-pip.html` `.k6-ward` paths
  /// (`M3 16h18l-1.6 2.4H4.6z` brim + `M7 16a5 5 0 0 1 10 0z` dome).
  /// Distinct from [sunHat] (dome-band look-alike with an extra band
  /// stroke); K06 must switch its wardrobe tile to this.
  /// Screens: K06.
  static const String wardrobeSunHat = 'assets/icons/ic_wardrobe_sun_hat.svg';

  /// K06 design glyph: Feed care action, exact `K06-pip.html` `.k6-care`
  /// paths (`M3 11h18a9 9 0 0 1-18 0Z` bowl + `M12 11V5` stem +
  /// `M9 5a3 3 0 0 1 6 0` morsel). Distinct from [feedBowl] (bowl with paw
  /// and kibble look-alike); K06 must switch its Feed button to this.
  /// Screens: K06.
  static const String kidFeed = 'assets/icons/ic_kid_feed.svg';

  /// K06 design glyph: Play care action, exact `K06-pip.html` `.k6-care`
  /// paths (`circle 12/12/9` ring + `M5 7.5c4 1 7 3.5 8 7.5` /
  /// `M19 7.5c-4 1-7 3.5-8 7.5` seams). Distinct from [ball] (star-panel
  /// look-alike); K06 must switch its Play button to this.
  /// Screens: K06.
  static const String kidPlay = 'assets/icons/ic_kid_play.svg';
}

/// Illustrations - `flutter/assets/illustrations/*.svg`. Keep their colours; they are
/// not colourable. Every one of them also has a WebP in [NestlingImages].
abstract final class NestlingIllustrations {
  const new _();

  /// Pip stage 1 — egg with lilac speckles and peeking eyes.
  /// Screens: P02, P08b.
  static const String pipStage1 = 'assets/illustrations/pip_stage_1.svg';

  /// Pip stage 2 — hatchling with half eggshell.
  /// Screens: P01, P02, P08, K01.
  static const String pipStage2 = 'assets/illustrations/pip_stage_2.svg';

  /// Pip stage 3 — fledgling with leaf-green wing tips.
  /// Screens: P02, P08, P15, P17, K01, K03, K03b, K04, K05, K06, K07.
  static const String pipStage3 = 'assets/illustrations/pip_stage_3.svg';

  /// Pip stage 4 — songbird with peach scarf and lilac tail.
  /// Screens: P07, K06, K07.
  static const String pipStage4 = 'assets/illustrations/pip_stage_4.svg';

  /// Twig nest used as the ground plane under Pip.
  /// Screens: P01, P07, K03, K03b, K06.
  static const String nest = 'assets/illustrations/nest.svg';

  /// Gold coin with an embossed leaf.
  /// Screens: P01, P02, P06, P07, P08, P12, P14, P15, P17, K03, K03b, K04, K05, K06, K08, K09.
  static const String coin = 'assets/illustrations/coin.svg';

  /// P04 hero — shield with a leaf/heart.
  /// Screens: P04.
  static const String privacyShield = 'assets/illustrations/privacy_shield.svg';

  /// Kid-mode bottom meadow.
  /// Screens: K01, K02, K03, K03b, K04, K05, K06, K08, K09, K10, K11.
  static const String meadowHill = 'assets/illustrations/meadow_hill.svg';

  /// K03b celebration confetti + sparkles.
  /// Screens: K03b.
  static const String confetti = 'assets/illustrations/confetti.svg';

  /// K05 coin burst.
  /// Screens: K05.
  static const String coinsBurst = 'assets/illustrations/coins_burst.svg';

  /// K07 evolution sparkles (lilac/leaf/gold/peach).
  /// Screens: K07.
  static const String sparkles = 'assets/illustrations/sparkles.svg';

  /// K09 money jar 62% full.
  /// Screens: K09.
  static const String jarCoins = 'assets/illustrations/jar_coins.svg';

  /// K10 payout-day jar with coins raining in.
  /// Screens: K10.
  static const String jarCoinsRain = 'assets/illustrations/jar_coins_rain.svg';

  /// K11 earned badge: First quest (gold ribbon, coin-tint disc, star).
  /// Screens: K11.
  static const String badgeFirstQuest =
      'assets/illustrations/badge_first_quest.svg';

  /// K11 earned badge: Bed maker x7 (lilac ribbon).
  /// Screens: K11.
  static const String badgeBedMaker =
      'assets/illustrations/badge_bed_maker.svg';

  /// K11 earned badge: Kind helper (peach ribbon, heart).
  /// Screens: K11.
  static const String badgeKindHelper =
      'assets/illustrations/badge_kind_helper.svg';

  /// K11 earned badge: Bookworm (sky ribbon, open book).
  /// Screens: K11.
  static const String badgeBookworm = 'assets/illustrations/badge_bookworm.svg';

  /// K11 not-yet badge: Bins out.
  /// Screens: K11.
  static const String badgeBinsOut = 'assets/illustrations/badge_bins_out.svg';

  /// K11 not-yet badge: Biscuit sitter (paw).
  /// Screens: K11.
  static const String badgeBiscuitSitter =
      'assets/illustrations/badge_biscuit_sitter.svg';

  /// K11 not-yet badge: Tidy hero (basket).
  /// Screens: K11.
  static const String badgeTidyHero =
      'assets/illustrations/badge_tidy_hero.svg';

  /// K11 not-yet badge: Early bird (sun).
  /// Screens: K11.
  static const String badgeEarlyBird =
      'assets/illustrations/badge_early_bird.svg';

  /// K11 not-yet badge: Plant waterer (watering can).
  /// Screens: K11.
  static const String badgePlantWaterer =
      'assets/illustrations/badge_plant_waterer.svg';
}

/// Brand & launcher artwork - `flutter/assets/brand/*`. 1024x1024, not colourable.
///
/// [appIcon] is a FULL-BLEED square: no rounded corners, no outer stroke, opaque.
/// iOS and Android apply their own masks, so an `rx` or any transparency baked into
/// this file produces a double-rounded, outlined launcher icon. Only
/// [appIconForeground] is transparent, because the adaptive-icon foreground must be.
///
/// The head sits at 62% of the canvas in [appIcon] and 66% in [appIconForeground].
/// That 4% delta is deliberate - 66% is Android's guaranteed-visible safe area.
abstract final class NestlingBrand {
  const new _();

  /// Full 1024 launcher icon: FULL-BLEED square, no rx, no outer stroke, opaque #17804F edge to edge.
  /// Screens: launcher, index, design-system.
  static const String appIcon = 'assets/brand/app_icon.svg';

  /// Pip head only, transparent background, sized for the Android adaptive-icon safe zone: the inner 66% of 1024 (676px), via translate(512 512) scale(0.88) translate(-510 -478).
  /// Screens: launcher.
  static const String appIconForeground =
      'assets/brand/app_icon_foreground.svg';

  /// Solid #17804F full-bleed 1024 square, no rounding, opaque - iOS/Android apply their own mask.
  /// Screens: launcher.
  static const String appIconBackground =
      'assets/brand/app_icon_background.svg';
}

/// Raster delivery - `flutter/assets/images/*.webp` and the 3 brand PNGs.
///
/// PENDING: the orchestrator has not generated these files yet. Each is emitted at
/// 1x / 2x / 3x and registered in pubspec under assets/images/. Until they land,
/// use [NestlingIllustrations] - the SVGs render identically and share these names,
/// so nothing breaks if a raster is dropped.
///
/// The 1x size for each is its LARGEST on-screen usage, so 2x and 3x cover heavier
/// devices. Exact numbers are in `rasterBox` in manifest.json.
abstract final class NestlingImages {
  const new _();

  /// Pip stage 1 — egg with lilac speckles and peeking eyes. 1x = 160x160.
  static const String pipStage1 = 'assets/images/pip_stage_1.webp';

  /// Pip stage 2 — hatchling with half eggshell. 1x = 160x160.
  static const String pipStage2 = 'assets/images/pip_stage_2.webp';

  /// Pip stage 3 — fledgling with leaf-green wing tips. 1x = 280x280.
  static const String pipStage3 = 'assets/images/pip_stage_3.webp';

  /// Pip stage 4 — songbird with peach scarf and lilac tail. 1x = 240x240.
  static const String pipStage4 = 'assets/images/pip_stage_4.webp';

  /// Twig nest used as the ground plane under Pip. 1x = 240x240.
  static const String nest = 'assets/images/nest.webp';

  /// Gold coin with an embossed leaf. 1x = 64x64.
  static const String coin = 'assets/images/coin.webp';

  /// K09 money jar 62% full. 1x = 168x168.
  static const String jarCoins = 'assets/images/jar_coins.webp';

  /// K10 payout-day jar with coins raining in. 1x = 168x168.
  static const String jarCoinsRain = 'assets/images/jar_coins_rain.webp';

  /// P04 hero — shield with a leaf/heart. 1x = 84x84.
  static const String privacyShield = 'assets/images/privacy_shield.webp';

  /// Kid-mode bottom meadow. 1x = 390x390.
  static const String meadowHill = 'assets/images/meadow_hill.webp';

  /// K03b celebration confetti + sparkles. 1x = 320x250.
  static const String confetti = 'assets/images/confetti.webp';

  /// K05 coin burst. 1x = 320x320.
  static const String coinsBurst = 'assets/images/coins_burst.webp';

  /// K07 evolution sparkles (lilac/leaf/gold/peach). 1x = 350x350.
  static const String sparkles = 'assets/images/sparkles.webp';

  /// K11 earned badge: First quest (gold ribbon, coin-tint disc, star). 1x = 104x104.
  static const String badgeFirstQuest = 'assets/images/badge_first_quest.webp';

  /// K11 earned badge: Bed maker x7 (lilac ribbon). 1x = 104x104.
  static const String badgeBedMaker = 'assets/images/badge_bed_maker.webp';

  /// K11 earned badge: Kind helper (peach ribbon, heart). 1x = 104x104.
  static const String badgeKindHelper = 'assets/images/badge_kind_helper.webp';

  /// K11 earned badge: Bookworm (sky ribbon, open book). 1x = 104x104.
  static const String badgeBookworm = 'assets/images/badge_bookworm.webp';

  /// K11 not-yet badge: Bins out. 1x = 104x104.
  static const String badgeBinsOut = 'assets/images/badge_bins_out.webp';

  /// K11 not-yet badge: Biscuit sitter (paw). 1x = 104x104.
  static const String badgeBiscuitSitter =
      'assets/images/badge_biscuit_sitter.webp';

  /// K11 not-yet badge: Tidy hero (basket). 1x = 104x104.
  static const String badgeTidyHero = 'assets/images/badge_tidy_hero.webp';

  /// K11 not-yet badge: Early bird (sun). 1x = 104x104.
  static const String badgeEarlyBird = 'assets/images/badge_early_bird.webp';

  /// K11 not-yet badge: Plant waterer (watering can). 1x = 104x104.
  static const String badgePlantWaterer =
      'assets/images/badge_plant_waterer.webp';

  // -- Launcher PNGs, rasterised from assets/brand/ at 1024x1024 ----------------

  /// Full-bleed 1024 launcher icon. Source of truth for `image_path_ios`.
  static const String appIconPng = 'assets/brand/app_icon.png';

  /// Pip head on transparency, for the Android adaptive-icon foreground.
  static const String appIconForegroundPng =
      'assets/brand/app_icon_foreground.png';

  /// Solid #17804F background layer, for `adaptive_icon_background`.
  static const String appIconBackgroundPng =
      'assets/brand/app_icon_background.png';

  /// Every raster above, in draw order - pass to `precacheImage` if you want the
  /// whole set warm. [precache] is the cheaper subset and what you normally want.
  static const List<String> all = <String>[
    pipStage1,
    pipStage2,
    pipStage3,
    pipStage4,
    nest,
    coin,
    jarCoins,
    jarCoinsRain,
    privacyShield,
    meadowHill,
    confetti,
    coinsBurst,
    sparkles,
    badgeFirstQuest,
    badgeBedMaker,
    badgeKindHelper,
    badgeBookworm,
    badgeBinsOut,
    badgeBiscuitSitter,
    badgeTidyHero,
    badgeEarlyBird,
    badgePlantWaterer,
    appIconPng,
    appIconForegroundPng,
    appIconBackgroundPng,
  ];

  /// Warm up the first frame.
  ///
  /// Pip, the nest and the coin are on screen on the very first paint (P01, P03b,
  /// K03, K06...), so decoding them lazily causes a visible hitch. Call this once
  /// during startup:
  ///
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   for (final String asset in NestlingImages.precache) {
  ///     precacheImage(AssetImage(asset), context);
  ///   }
  /// }
  /// ```
  ///
  /// Deliberately excludes the celebration art ([confetti], [coinsBurst],
  /// [sparkles]) and the badges - those only appear after a tap, so decoding them
  /// at startup would just delay the launch.
  static const List<String> precache = <String>[
    pipStage1,
    pipStage2,
    pipStage3,
    pipStage4,
    nest,
    coin,
  ];
}

/// Excluded on purpose - see the "excluded" entries in manifest.json and the README.
abstract final class NestlingExcluded {
  const new _();

  /// P03 "Continue with Apple" - use the official Sign in with Apple SDK button.
  static const String appleSignIn =
      'use official Sign in with Apple SDK button';

  /// P03 "Continue with Google" - use the official Google Sign-In SDK button.
  static const String googleSignIn = 'use official Google Sign-In SDK button';

  /// Status-bar signal / wifi / battery are drawn by iOS and Android. Never render.
  static const String statusBar = 'drawn by the OS - do not render';
}
